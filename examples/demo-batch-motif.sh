#!/bin/bash
# =============================================================================
# Batch Motif Generator - Creates multiple documented music examples
# =============================================================================
#
# Generates multiple unique motif compositions with documentation.
# Each WAV file gets a corresponding TXT file documenting the seed
# and all derived parameters for reproducibility.
#
# Output directory: examples/batch-YYYYMMDD-HHMMSS/
#   - *.wav files are gitignored
#   - *.txt files are tracked (contain reproduction info)
#
# Options:
#   -n, --count NUM   Number of examples to generate (default: 5)
#   -d, --delay MS    Delay between examples in ms (default: 100)
#   -o, --output DIR  Custom output directory
#   -h, --help        Show this help
#
# To recreate a WAV from its TXT:
#   ./examples/demo-random-motif.sh -s <SEED_FROM_TXT>
#

set -e
cd "$(dirname "$0")/.."

# Default options
COUNT=5
DELAY_MS=100
CUSTOM_OUTPUT=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--count)
            COUNT="$2"
            shift 2
            ;;
        -d|--delay)
            DELAY_MS="$2"
            shift 2
            ;;
        -o|--output)
            CUSTOM_OUTPUT="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [-n|--count NUM] [-d|--delay MS] [-o|--output DIR]"
            echo ""
            echo "Options:"
            echo "  -n, --count NUM   Number of examples to generate (default: 5)"
            echo "  -d, --delay MS    Delay between examples in ms (default: 100)"
            echo "  -o, --output DIR  Custom output directory"
            echo "  -h, --help        Show this help"
            echo ""
            echo "Output: examples/batch-YYYYMMDD-HHMMSS/"
            echo "  - *.wav files are gitignored"
            echo "  - *.txt files document seeds for reproducibility"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Create timestamped output directory
if [[ -n "$CUSTOM_OUTPUT" ]]; then
    OUTPUT_DIR="$CUSTOM_OUTPUT"
else
    TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    OUTPUT_DIR="examples/batch-$TIMESTAMP"
fi

mkdir -p "$OUTPUT_DIR"

# Create .gitignore in the output directory to ignore WAV files
cat > "$OUTPUT_DIR/.gitignore" << 'EOF'
# WAV files are generated and should not be tracked
*.wav

# TXT files document the seeds and should be tracked
!*.txt
EOF

echo "=== Batch Motif Generator ==="
echo "Output: $OUTPUT_DIR"
echo "Count: $COUNT examples"
echo ""

# Arrays for lookups (same as demo-random-motif.sh)
ROOTS=("C" "C#" "D" "D#" "E" "F" "F#" "G" "G#" "A" "A#" "B")
MODES=("major" "minor" "dorian" "phrygian" "lydian" "mixolydian" "pentatonic" "blues")
DURS=("0.25" "0.5" "0.75" "1.0")
REST_PROBS=("0.0" "0.1" "0.2" "0.3")
CHORD_PROBS=("0.0" "0.15" "0.25" "0.4")
SWINGS=("0.0" "0.2" "0.33")

# Ensemble names
get_ensemble_name() {
    case $1 in
        0)  echo "String Quartet";;
        1)  echo "Jazz Trio";;
        2)  echo "Rock Band";;
        3)  echo "Brass Quintet";;
        4)  echo "Big Band";;
        5)  echo "Woodwind Quintet";;
        6)  echo "Piano Trio";;
        7)  echo "Synth Pop";;
        8)  echo "Folk Ensemble";;
        9)  echo "Organ Trio";;
        10) echo "Chamber Orchestra";;
        11) echo "Latin Jazz";;
        12) echo "Rockabilly";;
    esac
}

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

# Get ensemble patches
get_ensemble_patches() {
    case $1 in
        0)  echo "40 40 41 42";;
        1)  echo "0 0 0";;
        2)  echo "27 29 29";;
        3)  echo "56 56 60 57 58";;
        4)  echo "65 66 66 56 56 57";;
        5)  echo "73 68 71 70 60";;
        6)  echo "0 40 42";;
        7)  echo "80 81 88 89";;
        8)  echo "25 105 40 22";;
        9)  echo "16 16 26";;
        10) echo "48 48 40 42 73";;
        11) echo "0 56 65";;
        12) echo "0 27 25";;
    esac
}

# Generate examples
for (( i=1; i<=COUNT; i++ )); do
    # Get current milliseconds since epoch
    SEED=$(python3 -c "import time; print(int(time.time() * 1000))")

    # Derive the same values as demo-random-motif.sh
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
    ENSEMBLE_IDX=$(( (SEED / 9000) % 13 ))
    SIMILARITY=$(( (SEED / 12000) % 4 ))
    OVERLAP=$(( (SEED / 13000) % 4 ))

    ROOT="${ROOTS[$ROOT_IDX]}"
    MODE="${MODES[$MODE_IDX]}"
    DUR="${DURS[$DUR_IDX]}"
    REST_PROB="${REST_PROBS[$REST_PROB_IDX]}"
    CHORD_PROB="${CHORD_PROBS[$CHORD_PROB_IDX]}"
    SWING="${SWINGS[$SWING_IDX]}"
    ENSEMBLE_NAME=$(get_ensemble_name $ENSEMBLE_IDX)
    PATCHES=$(get_ensemble_patches $ENSEMBLE_IDX)

    # Create output filenames
    WAV_FILE="$OUTPUT_DIR/motif-$SEED.wav"
    TXT_FILE="$OUTPUT_DIR/motif-$SEED.txt"

    echo "[$i/$COUNT] Generating: $ENSEMBLE_NAME (seed: $SEED)"

    # Write documentation file FIRST (before generation)
    cat > "$TXT_FILE" << EOF
# Motif Generation Parameters
# Generated: $(date -Iseconds)
# Recreate with: ./examples/demo-random-motif.sh -s $SEED

SEED=$SEED

# Musical Parameters
BPM=$BPM
ROOT=$ROOT
MODE=$MODE
BASE_NOTE=$BASE_NOTE
COMPLEXITY=$COMPLEXITY
NUM_NOTES=$NUM_NOTES
VELOCITY=$VELOCITY
DURATION=$DUR
REST_PROB=$REST_PROB
CHORD_PROB=$CHORD_PROB
SWING=$SWING

# Ensemble
ENSEMBLE_NAME="$ENSEMBLE_NAME"
ENSEMBLE_IDX=$ENSEMBLE_IDX
PATCHES=($PATCHES)

# Variation Controls
SIMILARITY=$SIMILARITY  # 0=varied, 3=similar
OVERLAP=$OVERLAP        # 0=sparse, 3=dense

# Instruments
EOF

    # Add instrument details
    read -ra PATCH_ARRAY <<< "$PATCHES"
    for (( j=0; j<${#PATCH_ARRAY[@]}; j++ )); do
        echo "CH$j=$(patch_name ${PATCH_ARRAY[$j]}) (patch ${PATCH_ARRAY[$j]})" >> "$TXT_FILE"
    done

    # Run the actual generator (suppress most output)
    ./examples/demo-random-motif.sh -s "$SEED" > /dev/null 2>&1

    # Move the output to our batch directory
    mv examples/gend-motif.wav "$WAV_FILE"

    echo "  -> $WAV_FILE"
    echo "  -> $TXT_FILE"

    # Delay before next generation to ensure unique seed
    if [[ $i -lt $COUNT ]]; then
        sleep "0.$DELAY_MS"
    fi
done

echo ""
echo "=== Batch Complete ==="
echo "Generated $COUNT examples in $OUTPUT_DIR"
echo ""
echo "TXT files document all parameters for reproduction."
echo "To recreate any WAV: ./examples/demo-random-motif.sh -s <SEED>"
echo ""

# List the generated files
echo "Generated files:"
ls -la "$OUTPUT_DIR"/*.txt 2>/dev/null | awk '{print "  " $NF}'
