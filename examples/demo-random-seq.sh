#!/bin/bash
# =============================================================================
# Random Sequence Generator - Melody from millisecond digits
# =============================================================================
#
# Takes the last 5 digits of milliseconds-since-epoch and transforms them
# into a melody with multiple permutations.
#
# Options:
#   -v, --verbose     Show detailed internal steps
#   -l, --log-file    Write timestamped log (default: music-pipe-rs-<timestamp>.log)
#   -s, --seed        Use specific seed instead of current time
#   -h, --help        Show this help
#
# Output: examples/gend-seq.wav (20 seconds)

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
    echo "=== Random Sequence Generator Log ===" > "$LOG_FILE"
    echo "Started: $(date)" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
fi

# Get milliseconds since epoch
if [[ -n "$CUSTOM_SEED" ]]; then
    MS="$CUSTOM_SEED"
else
    MS=$(python3 -c "import time; print(int(time.time() * 1000))")
fi

echo "=== Random Sequence Generator ==="
echo "Timestamp: $MS"
log "SEED/TIMESTAMP: $MS"

# Extract last 5 digits
LAST5="${MS: -5}"
D1="${LAST5:0:1}"
D2="${LAST5:1:1}"
D3="${LAST5:2:1}"
D4="${LAST5:3:1}"
D5="${LAST5:4:1}"

echo "Seed digits: $D1 $D2 $D3 $D4 $D5"
log "Digits: $D1 $D2 $D3 $D4 $D5"

# Map digits to pentatonic notes
digit_to_note() {
    local d=$1
    case $d in
        0) echo "C4";; 1) echo "D4";; 2) echo "E4";; 3) echo "G4";; 4) echo "A4";;
        5) echo "C5";; 6) echo "D5";; 7) echo "E5";; 8) echo "G5";; 9) echo "A5";;
    esac
}

N1=$(digit_to_note $D1)
N2=$(digit_to_note $D2)
N3=$(digit_to_note $D3)
N4=$(digit_to_note $D4)
N5=$(digit_to_note $D5)

echo "Base notes: $N1 $N2 $N3 $N4 $N5"
log "Notes: $N1 $N2 $N3 $N4 $N5"
echo ""

# Derive parameters
BPM=$(( 90 + (MS % 60) ))
VEL_BASE=$(( 70 + ((MS / 10) % 30) ))
ENSEMBLE_IDX=$(( (MS / 9000) % 12 ))
SIMILARITY=$(( (MS / 12000) % 4 ))
OVERLAP=$(( (MS / 13000) % 4 ))

log "Derived: BPM=$BPM VEL_BASE=$VEL_BASE ENSEMBLE_IDX=$ENSEMBLE_IDX SIMILARITY=$SIMILARITY OVERLAP=$OVERLAP"

# Instrument names
patch_name() {
    case $1 in
        0) echo "Acoustic Piano";; 4) echo "Electric Piano";; 11) echo "Vibraphone";;
        16) echo "Drawbar Organ";; 22) echo "Harmonica";; 24) echo "Nylon Guitar";;
        25) echo "Steel Guitar";; 26) echo "Jazz Guitar";; 27) echo "Clean Guitar";;
        29) echo "Overdriven Guitar";; 32) echo "Acoustic Bass";; 33) echo "Electric Bass";;
        38) echo "Synth Bass";; 40) echo "Violin";; 41) echo "Viola";; 42) echo "Cello";;
        46) echo "Harp";; 48) echo "String Ensemble";; 56) echo "Trumpet";;
        57) echo "Trombone";; 58) echo "Tuba";; 60) echo "French Horn";;
        65) echo "Alto Sax";; 66) echo "Tenor Sax";; 68) echo "Oboe";;
        70) echo "Bassoon";; 71) echo "Clarinet";; 73) echo "Flute";;
        74) echo "Recorder";; 75) echo "Pan Flute";; 80) echo "Square Lead";;
        81) echo "Sawtooth Lead";; 88) echo "Fantasia";; 89) echo "Warm Pad";;
        104) echo "Sitar";; 105) echo "Banjo";; *) echo "Patch $1";;
    esac
}

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
        10) ENSEMBLE_NAME="Flute Choir"
            PATCHES=(73 73 74 75)
            HAS_DRUMS=0; HAS_BASS=0; BASS_PATCH=32;;
        11) ENSEMBLE_NAME="World Music"
            PATCHES=(104 46 73 11)
            HAS_DRUMS=1; HAS_BASS=0; BASS_PATCH=32;;
    esac
}

get_ensemble $ENSEMBLE_IDX
NUM_INSTRUMENTS=${#PATCHES[@]}
log "Ensemble: $ENSEMBLE_NAME PATCHES=(${PATCHES[*]}) HAS_DRUMS=$HAS_DRUMS HAS_BASS=$HAS_BASS"

# Duration patterns
DUR_PATTERN=$(( (MS / 1000) % 6 ))
case $DUR_PATTERN in
    0) DURS=("4" "4" "4" "4" "4");;
    1) DURS=("8" "8" "4" "8" "8");;
    2) DURS=("2" "4" "4" "4" "2");;
    3) DURS=("8" "4" "2" "4" "8");;
    4) DURS=("4" "8" "16" "8" "4");;
    5) DURS=("2" "2" "1" "2" "2");;
esac
log "Duration pattern: $DUR_PATTERN (${DURS[*]})"

# Rest patterns
REST_PATTERNS=(
    "" "" "" "" ""
    "R/8 " "" "R/8 " "" "R/8 "
    "" "R/4 " "" "R/4 " ""
    "R/8 " "R/8 " "R/4 " "R/8 " "R/8 "
)

echo "Configuration:"
echo "  BPM: $BPM"
echo "  Duration pattern: $DUR_PATTERN (${DURS[*]})"
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

# Shift note by octave
shift_note() {
    local note=$1
    local shift=$2
    local octave="${note: -1}"
    local name="${note%?}"
    case $shift in
        +2) echo "${name}$((octave + 2))";; +1) echo "${name}$((octave + 1))";;
        -1) echo "${name}$((octave - 1))";; -2) echo "${name}$((octave - 2))";;
        *) echo "$note";;
    esac
}

# Build phrase
build_phrase() {
    local n1=$1 n2=$2 n3=$3 n4=$4 n5=$5
    local vel_mod=$6
    local oct_shift=$7
    local rest_idx=$8

    local sn1=$(shift_note "$n1" "$oct_shift")
    local sn2=$(shift_note "$n2" "$oct_shift")
    local sn3=$(shift_note "$n3" "$oct_shift")
    local sn4=$(shift_note "$n4" "$oct_shift")
    local sn5=$(shift_note "$n5" "$oct_shift")

    local v1=$(( VEL_BASE + vel_mod ))
    local v2=$(( VEL_BASE + vel_mod - 5 ))
    local v3=$(( VEL_BASE + vel_mod + 5 ))
    local v4=$(( VEL_BASE + vel_mod - 3 ))
    local v5=$(( VEL_BASE + vel_mod + 3 ))

    local r_base=$(( rest_idx * 5 ))
    local r1="${REST_PATTERNS[$r_base]}"
    local r2="${REST_PATTERNS[$((r_base + 1))]}"
    local r3="${REST_PATTERNS[$((r_base + 2))]}"
    local r4="${REST_PATTERNS[$((r_base + 3))]}"
    local r5="${REST_PATTERNS[$((r_base + 4))]}"

    echo "${r1}${sn1}/${DURS[0]}*${v1} ${r2}${sn2}/${DURS[1]}*${v2} ${r3}${sn3}/${DURS[2]}*${v3} ${r4}${sn4}/${DURS[3]}*${v4} ${r5}${sn5}/${DURS[4]}*${v5}"
}

# Clear temp files
rm -f /tmp/random-seq-*.jsonl

# Generate each instrument's part
for (( i=0; i<NUM_INSTRUMENTS; i++ )); do
    PATCH=${PATCHES[$i]}

    # Determine variation based on similarity
    if [ $SIMILARITY -eq 3 ]; then
        OCT_SHIFT=$(( (i % 3) - 1 ))
        [ $OCT_SHIFT -eq 1 ] && OCT="+1" || ([ $OCT_SHIFT -eq -1 ] && OCT="-1" || OCT="")
        VEL_MOD=$(( (i * 3) % 10 ))
        REST_IDX=$(( (MS / 5000) % 4 ))
        PHRASE1=$(build_phrase "$N1" "$N2" "$N3" "$N4" "$N5" $VEL_MOD "$OCT" $REST_IDX)
        PHRASE2=$(build_phrase "$N5" "$N4" "$N3" "$N2" "$N1" $((VEL_MOD + 5)) "$OCT" $REST_IDX)
        PHRASE3=$(build_phrase "$N1" "$N2" "$N3" "$N4" "$N5" $((VEL_MOD + 10)) "$OCT" $REST_IDX)
        PHRASE4=$(build_phrase "$N5" "$N4" "$N3" "$N2" "$N1" $VEL_MOD "$OCT" $REST_IDX)
    elif [ $SIMILARITY -eq 2 ]; then
        OCT_SHIFTS=("+1" "" "-1" "+2" "-2" "" "+1" "-1")
        OCT="${OCT_SHIFTS[$((i % 8))]}"
        VEL_MOD=$(( (i * 5 - 10) ))
        REST_IDX=$(( ((MS / 5000) + i) % 4 ))
        PHRASE1=$(build_phrase "$N1" "$N2" "$N3" "$N4" "$N5" $VEL_MOD "$OCT" $REST_IDX)
        PHRASE2=$(build_phrase "$N5" "$N4" "$N3" "$N2" "$N1" $((VEL_MOD + 5)) "$OCT" $REST_IDX)
        PHRASE3=$(build_phrase "$N1" "$N2" "$N3" "$N4" "$N5" $((VEL_MOD - 5)) "$OCT" $REST_IDX)
        PHRASE4=$(build_phrase "$N5" "$N4" "$N3" "$N2" "$N1" $VEL_MOD "$OCT" $REST_IDX)
    elif [ $SIMILARITY -eq 1 ]; then
        OCT_SHIFTS=("+1" "-1" "+2" "-2" "" "+1" "-1" "")
        OCT="${OCT_SHIFTS[$((i % 8))]}"
        VEL_MOD=$(( (i * 7 - 15) ))
        REST_IDX=$(( ((MS / 5000) + i * 2) % 4 ))
        case $(( i % 4 )) in
            0) PHRASE1=$(build_phrase "$N1" "$N2" "$N3" "$N4" "$N5" $VEL_MOD "$OCT" $REST_IDX);;
            1) PHRASE1=$(build_phrase "$N2" "$N3" "$N4" "$N5" "$N1" $VEL_MOD "$OCT" $REST_IDX);;
            2) PHRASE1=$(build_phrase "$N3" "$N4" "$N5" "$N1" "$N2" $VEL_MOD "$OCT" $REST_IDX);;
            3) PHRASE1=$(build_phrase "$N4" "$N5" "$N1" "$N2" "$N3" $VEL_MOD "$OCT" $REST_IDX);;
        esac
        PHRASE2=$(build_phrase "$N5" "$N4" "$N3" "$N2" "$N1" $((VEL_MOD + 3)) "$OCT" $REST_IDX)
        PHRASE3=$(build_phrase "$N3" "$N1" "$N5" "$N2" "$N4" $((VEL_MOD - 3)) "$OCT" $REST_IDX)
        PHRASE4=$(build_phrase "$N4" "$N2" "$N5" "$N1" "$N3" $VEL_MOD "$OCT" $REST_IDX)
    else
        OCT_SHIFTS=("+2" "-2" "+1" "-1" "" "+2" "-2" "+1")
        OCT="${OCT_SHIFTS[$((i % 8))]}"
        VEL_MOD=$(( ((MS / (100 + i*7)) % 30) - 15 ))
        REST_IDX=$(( (MS / (500 + i*11)) % 4 ))
        PERM=$(( (MS / (1000 + i*13)) % 5 ))
        case $PERM in
            0) PN1=$N1; PN2=$N3; PN3=$N5; PN4=$N2; PN5=$N4;;
            1) PN1=$N2; PN2=$N4; PN3=$N1; PN4=$N3; PN5=$N5;;
            2) PN1=$N5; PN2=$N3; PN3=$N1; PN4=$N4; PN5=$N2;;
            3) PN1=$N3; PN2=$N5; PN3=$N2; PN4=$N4; PN5=$N1;;
            4) PN1=$N4; PN2=$N1; PN3=$N3; PN4=$N5; PN5=$N2;;
        esac
        PHRASE1=$(build_phrase "$PN1" "$PN2" "$PN3" "$PN4" "$PN5" $VEL_MOD "$OCT" $REST_IDX)
        PHRASE2=$(build_phrase "$PN5" "$PN4" "$PN3" "$PN2" "$PN1" $((VEL_MOD + 5)) "$OCT" $REST_IDX)
        PHRASE3=$(build_phrase "$PN3" "$PN1" "$PN5" "$PN2" "$PN4" $((VEL_MOD - 5)) "$OCT" $REST_IDX)
        PHRASE4=$(build_phrase "$PN4" "$PN2" "$PN5" "$PN1" "$PN3" $VEL_MOD "$OCT" $REST_IDX)
    fi

    REPS=$(( 1 + OVERLAP + (i % 2) ))

    FULL_MELODY=""
    for (( r=0; r<REPS; r++ )); do
        FULL_MELODY="$FULL_MELODY $PHRASE1 R/4 $PHRASE2 R/4 $PHRASE3 R/4 $PHRASE4 R/4"
    done

    log "Instrument $i: patch=$PATCH oct=$OCT vel_mod=$VEL_MOD rest_idx=$REST_IDX reps=$REPS"
    log "  PHRASE1: $PHRASE1"

    echo "Generating: $(patch_name $PATCH)..."
    log_cmd "./target/release/seq --notes \"$FULL_MELODY\" --bpm $( [ $i -eq 0 ] && echo $BPM || echo 0 ) --ch $i --patch $PATCH"

    ./target/release/seq \
        --notes "$FULL_MELODY" \
        --bpm $( [ $i -eq 0 ] && echo $BPM || echo 0 ) \
        --ch $i \
        --patch $PATCH \
        < /dev/null > /tmp/random-seq-inst$i.jsonl

    log "Generated /tmp/random-seq-inst$i.jsonl ($(wc -l < /tmp/random-seq-inst$i.jsonl) lines)"
done

# Generate bass
if [ $HAS_BASS -gt 0 ]; then
    BASS_ROOT=$(digit_to_note $(( D1 % 5 )) | sed 's/4/2/' | sed 's/5/2/')
    BASS_FIFTH=$(digit_to_note $(( (D1 + 3) % 5 )) | sed 's/4/2/' | sed 's/5/2/')
    BASS_PHRASE="$BASS_ROOT/2*75 $BASS_FIFTH/2*70 $BASS_ROOT/2*75 $BASS_FIFTH/4*70 $BASS_ROOT/4*72"

    BASS_REPS=$(( 4 + OVERLAP * 2 ))
    BASS_FULL=""
    for (( r=0; r<BASS_REPS; r++ )); do
        BASS_FULL="$BASS_FULL $BASS_PHRASE"
    done

    log "Bass: root=$BASS_ROOT fifth=$BASS_FIFTH reps=$BASS_REPS"
    echo "Generating: $(patch_name $BASS_PATCH) (bass)..."

    ./target/release/seq \
        --notes "$BASS_FULL" \
        --bpm 0 \
        --ch 7 \
        --patch $BASS_PATCH \
        < /dev/null > /tmp/random-seq-bass.jsonl

    log "Generated /tmp/random-seq-bass.jsonl ($(wc -l < /tmp/random-seq-bass.jsonl) lines)"
fi

# Generate drums
if [ $HAS_DRUMS -gt 0 ]; then
    STEPS=$(( 8 + ((MS / 6000) % 8) ))
    PULSES=$(( 2 + ((MS / 7000) % 5) ))

    log "Drums: steps=$STEPS pulses=$PULSES"
    echo "Generating: Drums..."

    ./target/release/seed $((MS + 3)) | \
        ./target/release/euclid --steps $STEPS --pulses $PULSES --note 36 --ch 9 --vel 90 --repeat 12 \
        > /tmp/random-seq-kick.jsonl

    ./target/release/seed $((MS + 4)) | \
        ./target/release/euclid --steps 16 --pulses $(( 6 + ((MS / 8000) % 6) )) --note 42 --ch 9 --vel 60 --repeat 12 \
        > /tmp/random-seq-hihat.jsonl

    if [ $HAS_DRUMS -eq 2 ]; then
        ./target/release/seed $((MS + 5)) | \
            ./target/release/euclid --steps $STEPS --pulses $(( 1 + (PULSES / 2) )) --note 38 --ch 9 --vel 80 --repeat 12 \
            > /tmp/random-seq-snare.jsonl
    fi

    log "Generated drum tracks"
fi

# Combine all tracks
echo "Combining tracks..."
log "Combining tracks..."

cat /tmp/random-seq-inst*.jsonl \
    $( [ -f /tmp/random-seq-bass.jsonl ] && echo /tmp/random-seq-bass.jsonl ) \
    $( [ -f /tmp/random-seq-kick.jsonl ] && echo /tmp/random-seq-kick.jsonl ) \
    $( [ -f /tmp/random-seq-hihat.jsonl ] && echo /tmp/random-seq-hihat.jsonl ) \
    $( [ -f /tmp/random-seq-snare.jsonl ] && echo /tmp/random-seq-snare.jsonl ) | \
    ./target/release/viz > /tmp/random-seq-full.jsonl

log "Combined into /tmp/random-seq-full.jsonl ($(wc -l < /tmp/random-seq-full.jsonl) lines)"

# Convert to MIDI
echo "Converting to MIDI..."
log "Converting to MIDI..."
cat /tmp/random-seq-full.jsonl | ./target/release/to-midi --out /tmp/random-seq.mid
log "Created /tmp/random-seq.mid"

# Render with FluidSynth
echo "Rendering to WAV..."
log "Rendering with FluidSynth..."
SF2="${HOME}/github/softwarewrighter/midi-cli-rs/soundfonts/GeneralUser_GS.sf2"
fluidsynth -ni -F /tmp/random-seq-raw.wav "$SF2" /tmp/random-seq.mid
log "Created /tmp/random-seq-raw.wav"

# Trim to 20 seconds
log "Trimming to 20 seconds with fade..."
ffmpeg -y -i /tmp/random-seq-raw.wav -t 20 -af "afade=t=out:st=18:d=2" examples/gend-seq.wav 2>/dev/null
log "Created examples/gend-seq.wav"

echo ""
echo "Created: examples/gend-seq.wav (20 seconds)"
echo "Ensemble: $ENSEMBLE_NAME"
echo "Seed: $MS -> digits $LAST5 -> notes $N1 $N2 $N3 $N4 $N5"
if [[ -n "$LOG_FILE" ]]; then
    echo "Log: $LOG_FILE"
fi
echo "Run again for a completely different melody!"
echo ""
echo "Playing..."
afplay examples/gend-seq.wav
