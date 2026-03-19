#!/bin/bash
# =============================================================================
# Random Motif Generator - Coherent ensemble music from a single seed
# =============================================================================
#
# Generates ONE motif, then derives all instrument parts from it:
#   - Lead instrument plays the primary melody
#   - Other instruments play transposed/harmonized versions
#   - Bass doubles the melody two octaves down
#   - Drums provide rhythmic support (if ensemble includes them)
#
# This ensures all parts are musically coherent - they play the SAME
# melodic material at different pitches, not unrelated random notes.
#
# Instrumentation uses common ensemble groupings:
#   - String Quartet, Jazz Trio, Rock Band, Brass Quintet, etc.
#
# Options:
#   -v, --verbose         Show detailed internal steps
#   -l, --log-file        Write timestamped log (default: music-pipe-rs-<timestamp>.log)
#   -s, --seed            Use specific seed instead of current time
#   -r, --use-rounds 0|1  Force harmony (0) or rounds/canon (1) mode
#   -b, --bpm BPM         Override tempo (beats per minute)
#   -t, --style HINT      Style hint: [fast-|slow-]CATEGORY
#                          Categories: strings, brass, woodwind, jazz, rock, synth, folk, keys
#                          Examples: fast-strings, slow-brass, jazz, fast
#   -h, --help            Show this help
#
# Output: examples/gend-motif.wav (20 seconds)

set -e
cd "$(dirname "$0")/.."

# Default options
VERBOSE=0
LOG_FILE=""
CUSTOM_SEED=""
USE_ROUNDS=""  # Empty means use seed to decide; 0/1 means explicit choice
DURATION_SECS=20  # Target duration in seconds
CUSTOM_BPM=""  # Empty means derive from seed
STYLE_HINT=""  # Empty means derive from seed

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--verbose)
            VERBOSE=1
            shift
            ;;
        -l|--log-file)
            if [[ -n "$2" && "$2" != -* ]]; then
                LOG_FILE="$2"
                shift 2
            else
                LOG_FILE="music-pipe-rs-$(date +%Y%m%dT%H%M%S).log"
                shift
            fi
            ;;
        -s|--seed)
            CUSTOM_SEED="$2"
            shift 2
            ;;
        -r|--use-rounds)
            case "$2" in
                1|true|yes)
                    USE_ROUNDS=1
                    shift 2
                    ;;
                0|false|no)
                    USE_ROUNDS=0
                    shift 2
                    ;;
                *)
                    echo "Error: --use-rounds requires 0/1, true/false, or yes/no"
                    exit 1
                    ;;
            esac
            ;;
        -b|--bpm)
            CUSTOM_BPM="$2"
            shift 2
            ;;
        -t|--style)
            STYLE_HINT="$2"
            shift 2
            ;;
        -d|--duration)
            DURATION_SECS="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -v, --verbose           Show detailed internal steps"
            echo "  -l, --log-file          Write timestamped log (optionally specify filename)"
            echo "  -s, --seed SEED         Use specific seed instead of current time"
            echo "  -r, --use-rounds 0|1    Force harmony mode (0) or rounds mode (1)"
            echo "  -b, --bpm BPM           Override tempo (beats per minute, 40-240)"
            echo "  -t, --style HINT        Style hint: [fast-|slow-]CATEGORY"
            echo "                           Categories: strings, brass, woodwind, jazz, rock,"
            echo "                                       synth, folk, keys"
            echo "                           Examples: fast-strings, slow-brass, jazz, fast"
            echo "  -d, --duration SECS     Target duration in seconds (default: 20)"
            echo "  -h, --help              Show this help"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Logging function
log() {
    local msg="[$(date +%Y-%m-%dT%H:%M:%S.%3N)] $*"
    if [[ $VERBOSE -eq 1 ]]; then
        echo "$msg"
    fi
    if [[ -n "$LOG_FILE" ]]; then
        echo "$msg" >> "$LOG_FILE"
    fi
}

# Log command execution
log_cmd() {
    local cmd="$*"
    log "CMD: $cmd"
}

# Initialize log file
if [[ -n "$LOG_FILE" ]]; then
    echo "=== Random Motif Generator Log ===" > "$LOG_FILE"
    echo "Started: $(date)" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
fi

# Primary seed: milliseconds since epoch or custom
if [[ -n "$CUSTOM_SEED" ]]; then
    SEED="$CUSTOM_SEED"
else
    SEED=$(python3 -c "import time; print(int(time.time() * 1000))")
fi

echo "=== Random Motif Generator ==="
echo "Seed: $SEED"
log "SEED: $SEED"

# Derive random values using simple hash-like operations
BPM=$(( 80 + (SEED % 100) ))
# Base note in comfortable mid-range (C3=48 to G4=67) - avoid extreme highs
BASE_NOTE=$(( 48 + ((SEED / 1000) % 20) ))
ROOT_IDX=$(( (SEED / 100) % 12 ))
MODE_IDX=$(( (SEED / 10000) % 8 ))
COMPLEXITY=$(( 1 + ((SEED / 100000) % 10) ))
NUM_NOTES=$(( 12 + ((SEED / 1000000) % 20) ))
VELOCITY=$(( 70 + ((SEED / 10) % 40) ))
DUR_IDX=$(( (SEED / 500) % 4 ))
REST_PROB_IDX=$(( (SEED / 2000) % 4 ))
CHORD_PROB_IDX=$(( (SEED / 3000) % 4 ))
SWING_IDX=$(( (SEED / 4000) % 3 ))

# Ensemble selection (may be overridden by --style)
ENSEMBLE_IDX=$(( (SEED / 9000) % 13 ))
OVERLAP=$(( (SEED / 13000) % 4 ))

# Style: 0=harmony (transposed parts), 1=rounds (canonical entries)
if [ -n "$USE_ROUNDS" ]; then
    STYLE=$USE_ROUNDS
else
    STYLE=$(( (SEED / 15000) % 2 ))
fi

# For rounds: how many bars between entries (1-2 for tighter canon)
ROUND_BARS=$(( 1 + ((SEED / 16000) % 2) ))

log "Derived values: BPM=$BPM BASE_NOTE=$BASE_NOTE COMPLEXITY=$COMPLEXITY NUM_NOTES=$NUM_NOTES"
log "Ensemble selection: ENSEMBLE_IDX=$ENSEMBLE_IDX OVERLAP=$OVERLAP STYLE=$STYLE ROUND_BARS=$ROUND_BARS"

# Arrays for lookups
ROOTS=("C" "C#" "D" "D#" "E" "F" "F#" "G" "G#" "A" "A#" "B")
MODES=("major" "minor" "dorian" "phrygian" "lydian" "mixolydian" "pentatonic" "blues")
DURS=("0.25" "0.5" "0.75" "1.0")
REST_PROBS=("0.0" "0.1" "0.2" "0.3")
CHORD_PROBS=("0.0" "0.15" "0.25" "0.4")
SWINGS=("0.0" "0.2" "0.33")

ROOT="${ROOTS[$ROOT_IDX]}"
MODE="${MODES[$MODE_IDX]}"
DUR="${DURS[$DUR_IDX]}"
REST_PROB="${REST_PROBS[$REST_PROB_IDX]}"
CHORD_PROB="${CHORD_PROBS[$CHORD_PROB_IDX]}"
SWING="${SWINGS[$SWING_IDX]}"

log "Scale: ROOT=$ROOT MODE=$MODE"
log "Note params: DUR=$DUR REST_PROB=$REST_PROB CHORD_PROB=$CHORD_PROB SWING=$SWING"

# Define ensembles
get_ensemble() {
    case $1 in
        0)  ENSEMBLE_NAME="String Quartet"
            PATCHES=(40 40 41 42)
            HAS_DRUMS=0; HAS_BASS=0; BASS_PATCH=32;;
        1)  ENSEMBLE_NAME="Jazz Trio"
            PATCHES=(0 0 0)
            HAS_DRUMS=2; HAS_BASS=1; BASS_PATCH=32;;
        2)  ENSEMBLE_NAME="Rock Band"
            PATCHES=(27 29 29)
            HAS_DRUMS=2; HAS_BASS=1; BASS_PATCH=33;;
        3)  ENSEMBLE_NAME="Brass Quintet"
            PATCHES=(56 56 60 57 58)
            HAS_DRUMS=0; HAS_BASS=0; BASS_PATCH=32;;
        4)  ENSEMBLE_NAME="Big Band"
            PATCHES=(65 66 66 56 56 57)
            HAS_DRUMS=2; HAS_BASS=1; BASS_PATCH=32;;
        5)  ENSEMBLE_NAME="Woodwind Quintet"
            PATCHES=(73 68 71 70 60)
            HAS_DRUMS=0; HAS_BASS=0; BASS_PATCH=32;;
        6)  ENSEMBLE_NAME="Piano Trio"
            PATCHES=(0 40 42)
            HAS_DRUMS=0; HAS_BASS=0; BASS_PATCH=32;;
        7)  ENSEMBLE_NAME="Synth Pop"
            PATCHES=(80 81 88 89)
            HAS_DRUMS=2; HAS_BASS=1; BASS_PATCH=38;;
        8)  ENSEMBLE_NAME="Folk Ensemble"
            PATCHES=(25 105 40 22)
            HAS_DRUMS=0; HAS_BASS=1; BASS_PATCH=32;;
        9)  ENSEMBLE_NAME="Organ Trio"
            PATCHES=(16 16 26)
            HAS_DRUMS=2; HAS_BASS=0; BASS_PATCH=32;;
        10) ENSEMBLE_NAME="Chamber Orchestra"
            PATCHES=(48 48 40 42 73)
            HAS_DRUMS=0; HAS_BASS=0; BASS_PATCH=32;;
        11) ENSEMBLE_NAME="Latin Jazz"
            PATCHES=(0 56 65)
            HAS_DRUMS=2; HAS_BASS=1; BASS_PATCH=32;;
        12) ENSEMBLE_NAME="Rockabilly"
            PATCHES=(0 27 25)
            HAS_DRUMS=2; HAS_BASS=1; BASS_PATCH=32;;
    esac
}

# =============================================================================
# Apply style hint overrides
# =============================================================================
# Parse style hint into tempo modifier and category
if [[ -n "$STYLE_HINT" ]]; then
    STYLE_TEMPO=""
    STYLE_CATEGORY="$STYLE_HINT"

    # Extract tempo prefix if present
    case "$STYLE_HINT" in
        fast-*)
            STYLE_TEMPO="fast"
            STYLE_CATEGORY="${STYLE_HINT#fast-}"
            ;;
        slow-*)
            STYLE_TEMPO="slow"
            STYLE_CATEGORY="${STYLE_HINT#slow-}"
            ;;
        fast)
            STYLE_TEMPO="fast"
            STYLE_CATEGORY=""
            ;;
        slow)
            STYLE_TEMPO="slow"
            STYLE_CATEGORY=""
            ;;
    esac

    # Apply tempo modifier (only if --bpm not explicitly set)
    if [[ -z "$CUSTOM_BPM" && -n "$STYLE_TEMPO" ]]; then
        case "$STYLE_TEMPO" in
            fast) BPM=$(( 140 + (SEED % 41) )) ;;   # 140-180
            slow) BPM=$(( 55 + (SEED % 26) )) ;;     # 55-80
        esac
    fi

    # Map category to eligible ensemble indices
    if [[ -n "$STYLE_CATEGORY" ]]; then
        case "$STYLE_CATEGORY" in
            strings)   ELIGIBLE=(0 10) ;;              # String Quartet, Chamber Orchestra
            brass)     ELIGIBLE=(3) ;;                # Brass Quintet
            woodwind)  ELIGIBLE=(5) ;;                # Woodwind Quintet
            jazz)      ELIGIBLE=(1 9 11) ;;           # Jazz Trio, Organ Trio, Latin Jazz
            rock)      ELIGIBLE=(2 12) ;;             # Rock Band, Rockabilly
            synth)     ELIGIBLE=(7) ;;                # Synth Pop
            folk)      ELIGIBLE=(8) ;;                # Folk Ensemble
            keys)      ELIGIBLE=(1 6 9) ;;            # Piano/keys: Jazz Trio, Piano Trio, Organ Trio
            *)
                echo "Unknown style category: $STYLE_CATEGORY"
                echo "Valid categories: strings, brass, woodwind, jazz, rock, synth, folk, keys"
                exit 1
                ;;
        esac
        # Pick from eligible ensembles using seed
        NUM_ELIGIBLE=${#ELIGIBLE[@]}
        ENSEMBLE_IDX=${ELIGIBLE[$(( SEED % NUM_ELIGIBLE ))]}
        log "Style hint '$STYLE_HINT' -> eligible ensembles: ${ELIGIBLE[*]}, selected idx: $ENSEMBLE_IDX"
    fi
fi

# Apply explicit BPM override (takes precedence over everything)
if [[ -n "$CUSTOM_BPM" ]]; then
    BPM=$CUSTOM_BPM
fi

get_ensemble $ENSEMBLE_IDX
NUM_INSTRUMENTS=${#PATCHES[@]}
log "Ensemble: $ENSEMBLE_NAME (${#PATCHES[@]} instruments) PATCHES=(${PATCHES[*]})"
log "Rhythm section: HAS_DRUMS=$HAS_DRUMS HAS_BASS=$HAS_BASS BASS_PATCH=$BASS_PATCH"

# Instrument names
patch_name() {
    case $1 in
        0) echo "Acoustic Piano";; 4) echo "Electric Piano";; 16) echo "Drawbar Organ";;
        22) echo "Harmonica";; 25) echo "Steel Guitar";; 26) echo "Jazz Guitar";;
        27) echo "Clean Guitar";; 29) echo "Overdriven Guitar";; 32) echo "Acoustic Bass";;
        33) echo "Electric Bass";; 38) echo "Synth Bass";; 40) echo "Violin";;
        41) echo "Viola";; 42) echo "Cello";; 48) echo "String Ensemble";;
        56) echo "Trumpet";; 57) echo "Trombone";; 58) echo "Tuba";;
        60) echo "French Horn";; 65) echo "Alto Sax";; 66) echo "Tenor Sax";;
        68) echo "Oboe";; 70) echo "Bassoon";; 71) echo "Clarinet";;
        73) echo "Flute";; 80) echo "Square Lead";; 81) echo "Sawtooth Lead";;
        88) echo "Fantasia";; 89) echo "Warm Pad";; 105) echo "Banjo";;
        *) echo "Patch $1";;
    esac
}

# Report configuration
echo ""
echo "Configuration:"
if [[ -n "$CUSTOM_BPM" ]]; then
    echo "  BPM: $BPM (override)"
elif [[ -n "$STYLE_HINT" ]]; then
    echo "  BPM: $BPM (from style: $STYLE_HINT)"
else
    echo "  BPM: $BPM"
fi
echo "  Root: $ROOT, Mode: $MODE"
echo "  Base Note: $BASE_NOTE"
echo "  Complexity: $COMPLEXITY"
echo "  Notes: $NUM_NOTES"
echo "  Velocity: $VELOCITY"
echo "  Duration: $DUR"
echo "  Rest Prob: $REST_PROB"
echo "  Swing: $SWING"
echo ""
if [[ -n "$STYLE_HINT" ]]; then
    echo "Ensemble: $ENSEMBLE_NAME ($NUM_INSTRUMENTS instruments) [style: $STYLE_HINT]"
else
    echo "Ensemble: $ENSEMBLE_NAME ($NUM_INSTRUMENTS instruments)"
fi
for (( i=0; i<NUM_INSTRUMENTS; i++ )); do
    echo "  Ch $i: $(patch_name ${PATCHES[$i]}) (patch ${PATCHES[$i]})"
done
if [ $HAS_BASS -gt 0 ]; then
    echo "  Bass: $(patch_name $BASS_PATCH) (patch $BASS_PATCH)"
fi
if [ $HAS_DRUMS -gt 0 ]; then
    echo "  Drums: $( [ $HAS_DRUMS -eq 2 ] && echo "Full kit" || echo "Simple" )"
fi
echo ""
echo "  Density: $OVERLAP (0=sparse, 3=dense)"
if [ $STYLE -eq 1 ]; then
    echo "  Style: ROUNDS (canon - entries $ROUND_BARS bar(s) apart)"
    if [[ -n "$CUSTOM_BPM" ]]; then
        echo "  (Adjusted: longer notes, no chords; BPM kept at $BPM per override)"
    else
        echo "  (Adjusted: BPM 70-90, longer notes, no chords)"
    fi
else
    echo "  Style: HARMONY (transposed parts, tight entries)"
fi
echo ""

# Clear temp files
rm -f /tmp/random-motif-*.jsonl

# =============================================================================
# Generate ONE shared motif, then derive all parts from it
# =============================================================================

# HARMONY mode: transposed parts with tight entries
# Transposition offsets (in semitones): lead unchanged, others harmonize
# Prefer downward transpositions to avoid shrillness
HARMONY_TRANSPOSE=(0 -12 -5 -7 -24 -19 -12 -24)
HARMONY_DELAYS=(0 240 480 120 360 600 180 420)

# ROUNDS mode: canonical entries at bar intervals
# For clearer canon effect, minimal transposition (octave down only for lower voices)
ROUNDS_TRANSPOSE=(0 0 0 -12 0 0 -12 0)

# Velocity offsets (lead is loudest, others slightly softer)
VEL_OFFSETS=(0 -10 -5 -15 -8 -12 -6 -18)

# Calculate bar length in ticks (480 ticks per beat, 4 beats per bar)
TICKS_PER_BAR=$((480 * 4))
ROUND_DELAY_TICKS=$((ROUND_BARS * TICKS_PER_BAR))

# Adjust parameters for rounds mode
ACTUAL_BPM=$BPM
ACTUAL_NOTES=$NUM_NOTES
ACTUAL_DUR=$DUR
ACTUAL_CHORD_PROB=$CHORD_PROB

if [ $STYLE -eq 1 ]; then
    # Rounds work better with:
    # - Slower tempo (70-90 BPM range) - unless user overrode BPM
    # - Longer phrases (more notes)
    # - Longer note durations
    # - No chords (cleaner counterpoint)
    if [[ -z "$CUSTOM_BPM" ]]; then
        ACTUAL_BPM=$(( 70 + (BPM % 20) ))
    fi
    ACTUAL_NOTES=$(( NUM_NOTES + 8 ))
    ACTUAL_DUR="0.75"
    ACTUAL_CHORD_PROB="0.0"
fi

# Calculate repeat count dynamically to fill the target duration
# Formula: total_seconds = (notes * repeat * dur * 60) / bpm
# So: repeat = ceil(target_seconds * bpm / (notes * dur * 60))
REPEAT_COUNT=$(python3 -c "
import math
bpm = $ACTUAL_BPM
notes = $ACTUAL_NOTES
dur = $ACTUAL_DUR
target = $DURATION_SECS
repeats = math.ceil((target * bpm) / (notes * dur * 60))
# At least 2 repeats, and add extra for rounds (staggered entries need more material)
minimum = 2
if $STYLE == 1:
    minimum = $NUM_INSTRUMENTS + 2
print(max(repeats, minimum))
")

log "Calculated REPEAT_COUNT=$REPEAT_COUNT for ${DURATION_SECS}s at ${ACTUAL_BPM}bpm (${ACTUAL_NOTES} notes, dur=${ACTUAL_DUR})"

echo "Generating shared motif (seed: $SEED)..."
log "Generating shared motif with seed=$SEED base=$BASE_NOTE notes=$ACTUAL_NOTES complexity=$COMPLEXITY"

# Generate the PRIMARY motif once - all instruments derive from this
./target/release/seed $SEED | \
    ./target/release/motif \
        --base $BASE_NOTE \
        --notes $ACTUAL_NOTES \
        --complexity $COMPLEXITY \
        --bpm $ACTUAL_BPM \
        --ch 0 \
        --vel $VELOCITY \
        --patch ${PATCHES[0]} \
        --dur $ACTUAL_DUR \
        --rest-prob $REST_PROB \
        --chord-prob $ACTUAL_CHORD_PROB \
        --swing $SWING \
        --repeat $REPEAT_COUNT | \
    ./target/release/scale --root $ROOT --mode $MODE \
    > /tmp/random-motif-primary.jsonl

log "Generated primary motif: /tmp/random-motif-primary.jsonl ($(wc -l < /tmp/random-motif-primary.jsonl) lines)"

# Now create each instrument's part by transforming the primary motif
for (( i=0; i<NUM_INSTRUMENTS; i++ )); do
    PATCH=${PATCHES[$i]}
    VEL_OFFSET=${VEL_OFFSETS[$((i % ${#VEL_OFFSETS[@]}))]}

    if [ $STYLE -eq 1 ]; then
        # ROUNDS mode: canonical entries at bar intervals
        TRANSPOSE=${ROUNDS_TRANSPOSE[$((i % ${#ROUNDS_TRANSPOSE[@]}))]}
        DELAY=$((i * ROUND_DELAY_TICKS))
        STYLE_DESC="round entry at bar $((i * ROUND_BARS))"
    else
        # HARMONY mode: transposed parts with small timing offsets
        TRANSPOSE=${HARMONY_TRANSPOSE[$((i % ${#HARMONY_TRANSPOSE[@]}))]}
        DELAY=${HARMONY_DELAYS[$((i % ${#HARMONY_DELAYS[@]}))]}
        STYLE_DESC="harmony"
    fi

    # Calculate target velocity
    TARGET_VEL=$((VELOCITY + VEL_OFFSET))
    if [ $TARGET_VEL -lt 50 ]; then TARGET_VEL=50; fi
    if [ $TARGET_VEL -gt 120 ]; then TARGET_VEL=120; fi

    log "Instrument $i: patch=$PATCH transpose=$TRANSPOSE vel=$TARGET_VEL delay=$DELAY ($STYLE_DESC)"
    echo "Deriving: $(patch_name $PATCH) (transpose: $TRANSPOSE, delay: $DELAY ticks)..."

    # Transform the primary motif for this instrument:
    # - Change channel to $i
    # - Change patch to $PATCH
    # - Transpose notes by $TRANSPOSE semitones
    # - Delay all events by $DELAY ticks
    # - Adjust velocity
    jq -c "
        if .type == \"ProgramChange\" then
            .ch = $i | .patch = $PATCH
        elif .type == \"NoteOn\" or .type == \"NoteOff\" then
            .ch = $i | .note = (.note + $TRANSPOSE) |
            if .type == \"NoteOn\" then .vel = ((.vel + $VEL_OFFSET) | if . < 50 then 50 elif . > 120 then 120 else . end) else . end
        elif .type == \"Tempo\" then
            if $i > 0 then empty else . end
        else
            .
        end |
        if .tick != null then .tick = (.tick + $DELAY) else . end
    " /tmp/random-motif-primary.jsonl > /tmp/random-motif-inst$i.jsonl

    log "Generated /tmp/random-motif-inst$i.jsonl ($(wc -l < /tmp/random-motif-inst$i.jsonl) lines)"
done

# Generate bass - derived from primary motif, transposed down 2 octaves
if [ $HAS_BASS -gt 0 ]; then
    BASS_TRANSPOSE=-24  # Two octaves down
    BASS_VEL_OFFSET=-10

    log "Bass: patch=$BASS_PATCH transpose=$BASS_TRANSPOSE"
    echo "Deriving: $(patch_name $BASS_PATCH) (bass from melody, -2 octaves)..."

    # Transform the primary motif for bass:
    # - Change to channel 7 with bass patch
    # - Transpose down 2 octaves
    # - Slightly lower velocity
    jq -c "
        if .type == \"ProgramChange\" then
            .ch = 7 | .patch = $BASS_PATCH
        elif .type == \"NoteOn\" or .type == \"NoteOff\" then
            .ch = 7 | .note = (.note + $BASS_TRANSPOSE) |
            if .type == \"NoteOn\" then .vel = ((.vel + $BASS_VEL_OFFSET) | if . < 50 then 50 elif . > 120 then 120 else . end) else . end
        elif .type == \"Tempo\" then
            empty
        else
            .
        end
    " /tmp/random-motif-primary.jsonl > /tmp/random-motif-bass.jsonl

    log "Generated /tmp/random-motif-bass.jsonl ($(wc -l < /tmp/random-motif-bass.jsonl) lines)"
fi

# Generate drums
if [ $HAS_DRUMS -gt 0 ]; then
    STEPS=$(( 8 + ((SEED / 6000) % 8) ))
    PULSES=$(( 2 + ((SEED / 7000) % 5) ))

    log "Drums: steps=$STEPS pulses=$PULSES"
    echo "Generating: Drums..."

    ./target/release/seed $((SEED + 3)) | \
        ./target/release/euclid --steps $STEPS --pulses $PULSES --note 36 --ch 9 --vel 90 --repeat 12 \
        > /tmp/random-motif-kick.jsonl

    ./target/release/seed $((SEED + 4)) | \
        ./target/release/euclid --steps 16 --pulses $(( 6 + ((SEED / 8000) % 6) )) --note 42 --ch 9 --vel 60 --repeat 12 \
        > /tmp/random-motif-hihat.jsonl

    if [ $HAS_DRUMS -eq 2 ]; then
        ./target/release/seed $((SEED + 5)) | \
            ./target/release/euclid --steps $STEPS --pulses $(( 1 + (PULSES / 2) )) --note 38 --ch 9 --vel 80 --repeat 12 \
            > /tmp/random-motif-snare.jsonl
    fi

    log "Generated drum tracks"
fi

# Combine all tracks
echo "Combining tracks..."
log "Combining tracks..."

cat /tmp/random-motif-inst*.jsonl \
    $( [ -f /tmp/random-motif-bass.jsonl ] && echo /tmp/random-motif-bass.jsonl ) \
    $( [ -f /tmp/random-motif-kick.jsonl ] && echo /tmp/random-motif-kick.jsonl ) \
    $( [ -f /tmp/random-motif-hihat.jsonl ] && echo /tmp/random-motif-hihat.jsonl ) \
    $( [ -f /tmp/random-motif-snare.jsonl ] && echo /tmp/random-motif-snare.jsonl ) | \
    ./target/release/viz > /tmp/random-motif-full.jsonl

log "Combined into /tmp/random-motif-full.jsonl ($(wc -l < /tmp/random-motif-full.jsonl) lines)"

# Convert to MIDI
echo "Converting to MIDI..."
log "Converting to MIDI..."
cat /tmp/random-motif-full.jsonl | ./target/release/to-midi --out /tmp/random-motif.mid
log "Created /tmp/random-motif.mid"

# Render with FluidSynth
echo "Rendering to WAV..."
log "Rendering with FluidSynth..."
SF2="${HOME}/github/softwarewrighter/midi-cli-rs/soundfonts/GeneralUser_GS.sf2"
fluidsynth -ni -F /tmp/random-motif-raw.wav "$SF2" /tmp/random-motif.mid
log "Created /tmp/random-motif-raw.wav"

# Trim to 20 seconds
log "Trimming to 20 seconds with fade..."
# Trim to target duration with fade
FADE_START=$((DURATION_SECS - 2))
ffmpeg -y -i /tmp/random-motif-raw.wav -t $DURATION_SECS -af "afade=t=out:st=$FADE_START:d=2" examples/gend-motif.wav 2>/dev/null
log "Created examples/gend-motif.wav"

echo ""
echo "Created: examples/gend-motif.wav (${DURATION_SECS} seconds)"
echo "Ensemble: $ENSEMBLE_NAME"
if [[ -n "$LOG_FILE" ]]; then
    echo "Log: $LOG_FILE"
fi
echo "Run again for a completely different piece!"
echo ""
echo "Playing..."
afplay examples/gend-motif.wav
