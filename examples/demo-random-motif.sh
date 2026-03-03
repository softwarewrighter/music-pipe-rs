#!/bin/bash
# =============================================================================
# Random Motif Generator - Every run produces unique music
# =============================================================================
#
# Uses milliseconds since epoch as the primary seed, then derives random
# values for tempo, key, mode, instruments, complexity, and more.
#
# Instrumentation uses common ensemble groupings:
#   - String Quartet, Jazz Trio, Rock Band, Brass Quintet, etc.
#
# Options:
#   -v, --verbose     Show detailed internal steps
#   -l, --log-file    Write timestamped log (default: music-pipe-rs-<timestamp>.log)
#   -s, --seed        Use specific seed instead of current time
#   -h, --help        Show this help
#
# Output: examples/gend-motif.wav (20 seconds)

set -e
cd "$(dirname "$0")/.."

# Default options
VERBOSE=0
LOG_FILE=""
CUSTOM_SEED=""

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
        -h|--help)
            echo "Usage: $0 [-v|--verbose] [-l|--log-file [FILE]] [-s|--seed SEED]"
            echo ""
            echo "Options:"
            echo "  -v, --verbose     Show detailed internal steps"
            echo "  -l, --log-file    Write timestamped log (optionally specify filename)"
            echo "  -s, --seed SEED   Use specific seed instead of current time"
            echo "  -h, --help        Show this help"
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
BASE_NOTE=$(( 48 + ((SEED / 1000) % 24) ))
ROOT_IDX=$(( (SEED / 100) % 12 ))
MODE_IDX=$(( (SEED / 10000) % 8 ))
COMPLEXITY=$(( 1 + ((SEED / 100000) % 10) ))
NUM_NOTES=$(( 12 + ((SEED / 1000000) % 20) ))
VELOCITY=$(( 70 + ((SEED / 10) % 40) ))
DUR_IDX=$(( (SEED / 500) % 4 ))
REST_PROB_IDX=$(( (SEED / 2000) % 4 ))
CHORD_PROB_IDX=$(( (SEED / 3000) % 4 ))
SWING_IDX=$(( (SEED / 4000) % 3 ))

# Ensemble selection
ENSEMBLE_IDX=$(( (SEED / 9000) % 12 ))
SIMILARITY=$(( (SEED / 12000) % 4 ))
OVERLAP=$(( (SEED / 13000) % 4 ))

log "Derived values: BPM=$BPM BASE_NOTE=$BASE_NOTE COMPLEXITY=$COMPLEXITY NUM_NOTES=$NUM_NOTES"
log "Ensemble selection: ENSEMBLE_IDX=$ENSEMBLE_IDX SIMILARITY=$SIMILARITY OVERLAP=$OVERLAP"

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
    esac
}

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
echo "  BPM: $BPM"
echo "  Root: $ROOT, Mode: $MODE"
echo "  Base Note: $BASE_NOTE"
echo "  Complexity: $COMPLEXITY"
echo "  Notes: $NUM_NOTES"
echo "  Velocity: $VELOCITY"
echo "  Duration: $DUR"
echo "  Rest Prob: $REST_PROB"
echo "  Swing: $SWING"
echo ""
echo "Ensemble: $ENSEMBLE_NAME ($NUM_INSTRUMENTS instruments)"
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
echo "  Similarity: $SIMILARITY (0=varied, 3=similar)"
echo "  Overlap: $OVERLAP (0=sparse, 3=dense)"
echo ""

# Clear temp files
rm -f /tmp/random-motif-*.jsonl

# Generate each melodic instrument
for (( i=0; i<NUM_INSTRUMENTS; i++ )); do
    PATCH=${PATCHES[$i]}

    # Vary parameters based on similarity
    if [ $SIMILARITY -eq 3 ]; then
        INST_SEED=$((SEED + i))
        INST_NOTES=$NUM_NOTES
        INST_COMPLEXITY=$COMPLEXITY
        INST_DUR=$DUR
        INST_REST=$REST_PROB
        INST_BASE=$((BASE_NOTE + (i % 2) * 12))
    elif [ $SIMILARITY -eq 2 ]; then
        INST_SEED=$((SEED + i * 100))
        INST_NOTES=$(( NUM_NOTES + ((i * 3) % 5) - 2 ))
        INST_COMPLEXITY=$COMPLEXITY
        INST_DUR=$DUR
        INST_REST="${REST_PROBS[$(( (REST_PROB_IDX + i) % 4 ))]}"
        INST_BASE=$((BASE_NOTE + (i % 3 - 1) * 7))
    elif [ $SIMILARITY -eq 1 ]; then
        INST_SEED=$((SEED + i * 1000))
        INST_NOTES=$(( NUM_NOTES / 2 + ((i * 5) % NUM_NOTES) ))
        INST_COMPLEXITY=$(( (COMPLEXITY + i * 2) % 10 + 1 ))
        INST_DUR="${DURS[$(( (DUR_IDX + i) % 4 ))]}"
        INST_REST="${REST_PROBS[$(( (REST_PROB_IDX + i * 2) % 4 ))]}"
        INST_BASE=$((BASE_NOTE + (i % 4 - 2) * 5))
    else
        INST_SEED=$((SEED + i * 10000))
        INST_NOTES=$(( 6 + ((SEED / (100 + i)) % 20) ))
        INST_COMPLEXITY=$(( 1 + ((SEED / (200 + i*7)) % 10) ))
        INST_DUR="${DURS[$(( (SEED / (300 + i*11)) % 4 ))]}"
        INST_REST="${REST_PROBS[$(( (SEED / (400 + i*13)) % 4 ))]}"
        INST_BASE=$((36 + ((SEED / (500 + i*17)) % 36)))
    fi

    if [ $INST_NOTES -lt 4 ]; then INST_NOTES=4; fi

    INST_VEL=$(( VELOCITY - 20 + ((i * 7) % 40) ))
    if [ $INST_VEL -lt 50 ]; then INST_VEL=50; fi
    if [ $INST_VEL -gt 120 ]; then INST_VEL=120; fi

    INST_REPEAT=$(( 2 + OVERLAP + (i % 2) ))

    log "Instrument $i: patch=$PATCH seed=$INST_SEED base=$INST_BASE notes=$INST_NOTES complexity=$INST_COMPLEXITY dur=$INST_DUR rest=$INST_REST vel=$INST_VEL repeat=$INST_REPEAT"

    echo "Generating: $(patch_name $PATCH)..."

    CMD="./target/release/seed $INST_SEED | ./target/release/motif --base $INST_BASE --notes $INST_NOTES --complexity $INST_COMPLEXITY --bpm $( [ $i -eq 0 ] && echo $BPM || echo 0 ) --ch $i --vel $INST_VEL --patch $PATCH --dur $INST_DUR --rest-prob $INST_REST --chord-prob $CHORD_PROB --swing $SWING --repeat $INST_REPEAT | ./target/release/scale --root $ROOT --mode $MODE"
    log_cmd "$CMD"

    ./target/release/seed $INST_SEED | \
        ./target/release/motif \
            --base $INST_BASE \
            --notes $INST_NOTES \
            --complexity $INST_COMPLEXITY \
            --bpm $( [ $i -eq 0 ] && echo $BPM || echo 0 ) \
            --ch $i \
            --vel $INST_VEL \
            --patch $PATCH \
            --dur $INST_DUR \
            --rest-prob $INST_REST \
            --chord-prob $CHORD_PROB \
            --swing $SWING \
            --repeat $INST_REPEAT | \
        ./target/release/scale --root $ROOT --mode $MODE \
        > /tmp/random-motif-inst$i.jsonl

    log "Generated /tmp/random-motif-inst$i.jsonl ($(wc -l < /tmp/random-motif-inst$i.jsonl) lines)"
done

# Generate bass
if [ $HAS_BASS -gt 0 ]; then
    BASS_BASE=$(( BASE_NOTE - 24 ))
    BASS_COMPLEXITY=$(( (COMPLEXITY + 1) / 2 ))
    BASS_NOTES=$(( NUM_NOTES / 2 ))
    if [ $BASS_NOTES -lt 6 ]; then BASS_NOTES=6; fi
    BASS_REPEAT=$(( 3 + OVERLAP ))

    log "Bass: patch=$BASS_PATCH base=$BASS_BASE notes=$BASS_NOTES complexity=$BASS_COMPLEXITY repeat=$BASS_REPEAT"
    echo "Generating: $(patch_name $BASS_PATCH) (bass)..."

    ./target/release/seed $((SEED + 1000)) | \
        ./target/release/motif \
            --base $BASS_BASE \
            --notes $BASS_NOTES \
            --complexity $BASS_COMPLEXITY \
            --bpm 0 \
            --ch 7 \
            --vel $(( VELOCITY - 10 )) \
            --patch $BASS_PATCH \
            --dur 1.0 \
            --rest-prob 0.1 \
            --repeat $BASS_REPEAT | \
        ./target/release/scale --root $ROOT --mode $MODE \
        > /tmp/random-motif-bass.jsonl

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
ffmpeg -y -i /tmp/random-motif-raw.wav -t 20 -af "afade=t=out:st=18:d=2" examples/gend-motif.wav 2>/dev/null
log "Created examples/gend-motif.wav"

echo ""
echo "Created: examples/gend-motif.wav (20 seconds)"
echo "Ensemble: $ENSEMBLE_NAME"
if [[ -n "$LOG_FILE" ]]; then
    echo "Log: $LOG_FILE"
fi
echo "Run again for a completely different piece!"
echo ""
echo "Playing..."
afplay examples/gend-motif.wav
