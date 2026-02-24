//! music-pipe - Unix-style pipeline for generative MIDI music
//!
//! This is the main entry point that provides help and documentation
//! for all pipeline stages.

use clap::{Parser, Subcommand};

/// Unix-style pipeline for generative MIDI music.
///
/// Pipeline pattern: seed [N] | [generator] | [transforms...] | to-midi --out file.mid
///
/// # Quick Start
///
/// Generate a melody:
///   seed 12345 | motif --notes 16 | humanize | to-midi --out melody.mid
///
/// Or with auto-seed:
///   seed | motif --notes 16 | humanize | to-midi --out melody.mid
///
/// # AI Agent Usage
///
/// Each stage has detailed --help. Start with:
///   seed --help
///   motif --help
///   humanize --help
///
/// See docs/usage.md for comprehensive recipes and examples.
#[derive(Parser)]
#[command(name = "music-pipe")]
#[command(version)]
#[command(about = "Unix-style pipeline for generative MIDI music")]
#[command(long_about = LONG_HELP)]
#[command(after_help = EXAMPLES)]
struct Cli {
    #[command(subcommand)]
    command: Option<Commands>,
}

#[derive(Subcommand)]
enum Commands {
    /// Set random seed for the entire pipeline
    ///
    /// Always use as first stage. All downstream stages use this seed.
    ///
    /// Examples:
    ///   seed              # auto-generate, print to stderr
    ///   seed 12345        # explicit seed for reproducibility
    #[command(name = "seed")]
    Seed {
        #[arg(long, short = 'H')]
        full_help: bool,
    },

    /// Generate melodic patterns (uses pipeline seed)
    ///
    /// Examples:
    ///   seed 12345 | motif --notes 16 --complexity 5
    ///   seed | motif --base 72 --notes 20 --bpm 140
    #[command(name = "motif")]
    Motif {
        #[arg(long, short = 'H')]
        full_help: bool,
    },

    /// Generate Euclidean rhythms for drums/percussion
    ///
    /// Distributes N pulses evenly across K steps.
    ///
    /// Examples:
    ///   seed | euclid --steps 16 --pulses 4 --note 36  # kick
    ///   seed | euclid --steps 8 --pulses 3             # tresillo
    #[command(name = "euclid")]
    Euclid {
        #[arg(long, short = 'H')]
        full_help: bool,
    },

    /// Shift all notes by N semitones
    ///
    /// Examples:
    ///   transpose --semitones 7   # up a fifth
    ///   transpose --semitones -12 # down an octave
    #[command(name = "transpose")]
    Transpose {
        #[arg(long, short = 'H')]
        full_help: bool,
    },

    /// Constrain notes to a musical scale
    ///
    /// Snaps notes to nearest degree of the target scale.
    ///
    /// Examples:
    ///   scale --root C --mode major
    ///   scale --root A --mode pentatonic-minor
    #[command(name = "scale")]
    Scale {
        #[arg(long, short = 'H')]
        full_help: bool,
    },

    /// Add human-like timing and velocity variation (uses pipeline seed)
    ///
    /// Examples:
    ///   seed 12345 | motif | humanize --jitter-ticks 8
    #[command(name = "humanize")]
    Humanize {
        #[arg(long, short = 'H')]
        full_help: bool,
    },

    /// Show sparkline/piano roll visualization
    ///
    /// Examples:
    ///   seed | motif | viz | to-midi --out out.mid
    ///   seed | motif | viz --roll | to-midi --out out.mid
    #[command(name = "viz")]
    Viz {
        #[arg(long, short = 'H')]
        full_help: bool,
    },

    /// Convert JSONL events to MIDI file
    ///
    /// Examples:
    ///   to-midi --out output.mid
    #[command(name = "to-midi")]
    ToMidi {
        #[arg(long, short = 'H')]
        full_help: bool,
    },

    /// Show quick reference for all stages
    #[command(name = "reference")]
    Reference,

    /// Show video intro/outro recipes
    #[command(name = "recipes")]
    Recipes,
}

const LONG_HELP: &str = r#"
music-pipe-rs generates MIDI music using composable Unix-style pipelines.

ARCHITECTURE:
  Each stage reads JSONL events from stdin, transforms them, and writes
  to stdout. Chain stages with pipes. Final stage writes .mid file.

STAGES:
  Seed (always first):
    seed      - Set random seed for pipeline (auto if omitted)

  Generators (create events):
    motif     - Melodic patterns (uses pipeline seed)
    euclid    - Euclidean rhythms (drums, percussion)

  Transforms (modify events):
    transpose - Shift pitch by semitones
    scale     - Constrain to musical scale
    humanize  - Add timing/velocity variation (uses pipeline seed)
    viz       - Show sparkline/piano roll visualization

  Output:
    to-midi   - Write MIDI file

PIPELINE PATTERN:
  seed [N] | [generator] | [transform...] | to-midi --out file.mid

AI AGENT USAGE:
  1. Run: seed --help, motif --help, etc.
  2. Run: music-pipe reference for quick parameter reference
  3. Run: music-pipe recipes for video intro/outro examples
  4. See: docs/usage.md for comprehensive documentation
"#;

const EXAMPLES: &str = r#"
EXAMPLES:
  # Auto-seed melody (different each run)
  seed | motif --notes 16 --bpm 120 | humanize | to-midi --out melody.mid

  # Reproducible melody (same seed = same output)
  seed 12345 | motif --notes 16 --repeat 2 | to-midi --out melody.mid

  # Melody in C major with visualization
  seed 12345 | motif --notes 20 --complexity 5 | viz | scale --root C --mode major | humanize | to-midi --out out.mid

  # Drum pattern (kick + hihat)
  seed 12345 | { euclid --steps 16 --pulses 4 --note 36;
    euclid --steps 16 --pulses 8 --note 42 --vel 60 --bpm 0; } | humanize | to-midi --out drums.mid

  # Video intro (5 seconds)
  seed 42 | motif --base 72 --bpm 130 --notes 16 --complexity 6 | scale --root G --mode major | humanize | to-midi --out intro.mid

MORE INFO:
  music-pipe reference    Quick parameter reference
  music-pipe recipes      Video intro/outro recipes
  See docs/usage.md       Full documentation
"#;

const REFERENCE: &str = r#"
QUICK REFERENCE
===============

SEED (always first)
-------------------
seed [SEED]
  [SEED]     Optional seed value (auto-generates if omitted, prints to stderr)

GENERATORS
----------
motif --notes <N> --complexity <1-10> --base <NOTE> --bpm <BPM> --repeat <N>
  --notes      Number of notes to generate    [default: 8]
  --complexity Melodic complexity (1-10)      [default: 5]
  --base       MIDI note (60=middle C)        [default: 60]
  --bpm        Tempo                          [default: 120]
  --repeat     Repetitions                    [default: 1]
  --ch         MIDI channel (0-15)            [default: 0]
  --vel        Velocity (1-127)               [default: 96]

euclid --steps <N> --pulses <N> --note <NOTE> --repeat <N> --ch <CH> --bpm <BPM>
  --steps    Steps in pattern               [default: 16]
  --pulses   Hits to distribute             [default: 5]
  --note     MIDI note (36=kick)            [default: 36]
  --ch       MIDI channel (9=drums)         [default: 9]
  --bpm      Tempo (0=no tempo event)       [default: 120]
  --repeat   Repetitions                    [default: 1]
  --rotation Shift pattern start            [default: 0]

TRANSFORMS
----------
transpose --semitones <N>
  --semitones  Semitones (+/-)              [required]

scale --root <NOTE> --mode <SCALE> --snap <DIR>
  --root     Root note (C, C#, D, ...)      [default: C]
  --mode     major|minor|dorian|pentatonic|blues|...  [default: major]
  --snap     nearest|up|down                [default: nearest]

humanize --jitter-ticks <N> --jitter-vel <N>
  --jitter-ticks  Timing variation (+/-)    [default: 8]
  --jitter-vel    Velocity variation (+/-)  [default: 10]

viz [--roll] [--width <N>]
  --roll     Show piano roll instead of sparkline
  --width    Sparkline width                [default: 60]

OUTPUT
------
to-midi --out <PATH>
  --out      Output file path               [required]
  --tpq      Ticks per quarter note         [default: 480]

MIDI NOTES
----------
C3=48  D3=50  E3=52  F3=53  G3=55  A3=57  B3=59
C4=60  D4=62  E4=64  F4=65  G4=67  A4=69  B4=71
C5=72  D5=74  E5=76  F5=77  G5=79  A5=81  B5=83

Drums: Kick=36, Snare=38, HiHat=42, OpenHat=46, Crash=49

TIMING
------
At 120 BPM with TPQ=480:
  Quarter note = 480 ticks = 0.5 sec
  Eighth note  = 240 ticks = 0.25 sec
  5 seconds = 10 quarter notes
"#;

const RECIPES: &str = r#"
VIDEO INTRO/OUTRO RECIPES
=========================

BRIGHT INTRO (5 sec)
--------------------
seed 42 | motif --base 72 --bpm 130 --notes 16 --complexity 6 --repeat 2 --vel 100 \
  | scale --root C --mode major \
  | humanize --jitter-ticks 6 \
  | to-midi --out bright-intro.mid

CALM INTRO (8 sec)
------------------
seed 55 | motif --base 60 --bpm 90 --notes 20 --complexity 4 --repeat 2 --vel 80 \
  | scale --root G --mode major \
  | humanize --jitter-ticks 10 \
  | to-midi --out calm-intro.mid

DRAMATIC INTRO (6 sec)
----------------------
seed 77 | motif --base 48 --bpm 100 --notes 16 --complexity 5 --repeat 2 --vel 90 \
  | scale --root D --mode harmonic-minor \
  | humanize --jitter-ticks 8 \
  | to-midi --out dramatic-intro.mid

TECH/ELECTRONIC INTRO (6 sec)
-----------------------------
seed 64 | {
  motif --base 60 --bpm 128 --notes 16 --complexity 7 --repeat 2 --ch 0;
  euclid --steps 16 --pulses 4 --note 36 --ch 1 --bpm 0 --repeat 4;
  euclid --steps 16 --pulses 8 --note 42 --ch 9 --bpm 0 --repeat 4 --vel 45;
} | scale --root C --mode pentatonic-minor | humanize | to-midi --out tech-intro.mid

MELLOW OUTRO (12 sec)
---------------------
seed 33 | motif --base 60 --bpm 70 --notes 24 --complexity 3 --repeat 2 --vel 70 \
  | scale --root A --mode minor \
  | humanize --jitter-ticks 15 \
  | to-midi --out mellow-outro.mid

UPBEAT OUTRO WITH DRUMS (10 sec)
--------------------------------
SEED=88
# Create parts
seed $SEED | motif --base 67 --bpm 120 --notes 20 --complexity 5 --repeat 2 --ch 0 > /tmp/mel.jsonl
seed $SEED | { euclid --steps 16 --pulses 4 --note 36 --ch 9 --bpm 0 --repeat 5;
  euclid --steps 16 --pulses 8 --note 42 --ch 9 --vel 50 --bpm 0 --repeat 5; } > /tmp/drm.jsonl
# Combine
cat /tmp/mel.jsonl /tmp/drm.jsonl | scale --root G --mode major | humanize | to-midi --out upbeat-outro.mid

PLAYBACK
--------
# Convert to WAV with FluidSynth
fluidsynth -ni -F output.wav /path/to/soundfont.sf2 input.mid

# Play on macOS
afplay output.wav
"#;

fn main() {
    let cli = Cli::parse();

    match cli.command {
        Some(Commands::Reference) => {
            println!("{REFERENCE}");
        }
        Some(Commands::Recipes) => {
            println!("{RECIPES}");
        }
        Some(Commands::Seed { full_help }) => {
            if full_help {
                run_stage("seed", &["--help"]);
            } else {
                println!("seed - Set random seed for pipeline\n");
                println!("Run 'seed --help' for details\n");
                println!("Usage:");
                println!("  seed              # auto-generate (prints to stderr)");
                println!("  seed 12345        # explicit seed for reproducibility");
            }
        }
        Some(Commands::Motif { full_help }) => {
            if full_help {
                run_stage("motif", &["--help"]);
            } else {
                println!("motif - Generate melodic patterns (uses pipeline seed)\n");
                println!("Run 'motif --help' for all options\n");
                println!("Quick usage:");
                println!("  seed 12345 | motif --notes 16 --complexity 5\n");
                println!("Key options:");
                println!("  --notes <N>       Number of notes to generate");
                println!("  --complexity <N>  Melodic complexity (1-10)");
                println!("  --base <NOTE>     Base MIDI note (60=middle C)");
                println!("  --bpm <BPM>       Tempo in beats per minute");
            }
        }
        Some(Commands::Euclid { full_help }) => {
            if full_help {
                run_stage("euclid", &["--help"]);
            } else {
                println!("euclid - Generate Euclidean rhythms\n");
                println!("Run 'euclid --help' for all options\n");
                println!("Quick usage:");
                println!("  seed | euclid --steps 16 --pulses 4 --note 36\n");
                println!("Key options:");
                println!("  --steps <N>    Steps in pattern");
                println!("  --pulses <N>   Hits to distribute");
                println!("  --note <NOTE>  MIDI note (36=kick, 38=snare, 42=hihat)");
            }
        }
        Some(Commands::Transpose { full_help }) => {
            if full_help {
                run_stage("transpose", &["--help"]);
            } else {
                println!("transpose - Shift notes by semitones\n");
                println!("Usage:");
                println!("  transpose --semitones 7   # up a fifth");
                println!("  transpose --semitones -12 # down an octave");
            }
        }
        Some(Commands::Scale { full_help }) => {
            if full_help {
                run_stage("scale", &["--help"]);
            } else {
                println!("scale - Constrain to musical scale\n");
                println!("Run 'scale --help' for all options\n");
                println!("Quick usage:");
                println!("  scale --root C --mode major\n");
                println!("Modes: major, minor, dorian, phrygian, lydian, mixolydian,");
                println!("       pentatonic, pentatonic-minor, blues, harmonic-minor");
            }
        }
        Some(Commands::Humanize { full_help }) => {
            if full_help {
                run_stage("humanize", &["--help"]);
            } else {
                println!("humanize - Add timing/velocity variation (uses pipeline seed)\n");
                println!("Run 'humanize --help' for all options\n");
                println!("Usage:");
                println!("  seed 12345 | motif | humanize --jitter-ticks 8");
            }
        }
        Some(Commands::Viz { full_help }) => {
            if full_help {
                run_stage("viz", &["--help"]);
            } else {
                println!("viz - Show sparkline/piano roll visualization\n");
                println!("Run 'viz --help' for all options\n");
                println!("Usage:");
                println!("  seed | motif | viz | to-midi --out out.mid");
                println!("  seed | motif | viz --roll > /dev/null  # piano roll only");
            }
        }
        Some(Commands::ToMidi { full_help }) => {
            if full_help {
                run_stage("to-midi", &["--help"]);
            } else {
                println!("to-midi - Write MIDI file\n");
                println!("Usage:");
                println!("  to-midi --out output.mid");
            }
        }
        None => {
            println!("music-pipe - Unix-style pipeline for generative MIDI music\n");
            println!("USAGE:");
            println!("  seed [N] | [generator] | [transforms] | to-midi --out file.mid\n");
            println!("COMMANDS:");
            println!("  seed       Set random seed (always first)");
            println!("  motif      Generate melodic patterns");
            println!("  euclid     Generate Euclidean rhythms");
            println!("  transpose  Shift notes by semitones");
            println!("  scale      Constrain to musical scale");
            println!("  humanize   Add timing/velocity variation");
            println!("  viz        Show sparkline/piano roll");
            println!("  to-midi    Write MIDI file");
            println!("  reference  Quick parameter reference");
            println!("  recipes    Video intro/outro recipes");
            println!();
            println!("QUICK START:");
            println!("  seed 12345 | motif --notes 16 | humanize | to-midi --out melody.mid\n");
            println!("MORE HELP:");
            println!("  music-pipe --help         Full overview");
            println!("  music-pipe <stage> -H     Stage details");
            println!("  music-pipe reference      Quick reference");
        }
    }
}

fn run_stage(name: &str, args: &[&str]) {
    use std::process::Command;

    let exe_dir = std::env::current_exe()
        .ok()
        .and_then(|p| p.parent().map(|p| p.to_path_buf()));

    let stage_path = exe_dir
        .map(|d| d.join(name))
        .filter(|p| p.exists())
        .unwrap_or_else(|| std::path::PathBuf::from(name));

    match Command::new(&stage_path).args(args).status() {
        Ok(_) => {}
        Err(e) => {
            eprintln!("Failed to run {}: {}", name, e);
            eprintln!("Make sure the stage binary is in your PATH or same directory.");
        }
    }
}
