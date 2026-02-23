//! music-pipe - Unix-style pipeline for generative MIDI music
//!
//! This is the main entry point that provides help and documentation
//! for all pipeline stages.

use clap::{Parser, Subcommand};

/// Unix-style pipeline for generative MIDI music.
///
/// Pipeline pattern: [generator] | [transforms...] | to-midi --out file.mid
///
/// # Quick Start
///
/// Generate a melody:
///   music-pipe motif --base 60 --bpm 120 --repeat 4 | music-pipe to-midi --out melody.mid
///
/// Or use stage binaries directly:
///   motif --base 60 | transpose --semitones 7 | humanize | to-midi --out melody.mid
///
/// # AI Agent Usage
///
/// Each stage has detailed --help. Start with:
///   music-pipe --help          # This overview
///   music-pipe motif --help    # Generator help
///   music-pipe euclid --help   # Rhythm generator help
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
    /// Generate melodic patterns (arpeggio, scale, chord)
    ///
    /// Creates JSONL events for melodic content.
    ///
    /// Examples:
    ///   music-pipe motif --base 60 --pattern arpeggio --repeat 4
    ///   music-pipe motif --base 72 --bpm 140 --pattern scale
    #[command(name = "motif")]
    Motif {
        /// Show all options
        #[arg(long, short = 'H')]
        full_help: bool,
    },

    /// Generate Euclidean rhythms for drums/percussion
    ///
    /// Distributes N pulses evenly across K steps.
    /// Perfect for drum patterns.
    ///
    /// Examples:
    ///   music-pipe euclid --steps 16 --pulses 4 --note 36  # kick
    ///   music-pipe euclid --steps 8 --pulses 3             # tresillo
    #[command(name = "euclid")]
    Euclid {
        #[arg(long, short = 'H')]
        full_help: bool,
    },

    /// Shift all notes by N semitones
    ///
    /// Examples:
    ///   music-pipe transpose --semitones 7   # up a fifth
    ///   music-pipe transpose --semitones -12 # down an octave
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
    ///   music-pipe scale --root C --mode major
    ///   music-pipe scale --root A --mode pentatonic-minor
    #[command(name = "scale")]
    Scale {
        #[arg(long, short = 'H')]
        full_help: bool,
    },

    /// Add human-like timing and velocity variation
    ///
    /// Uses deterministic RNG for reproducible output.
    ///
    /// Examples:
    ///   music-pipe humanize --seed 42 --jitter-ticks 8
    #[command(name = "humanize")]
    Humanize {
        #[arg(long, short = 'H')]
        full_help: bool,
    },

    /// Convert JSONL events to MIDI file
    ///
    /// Examples:
    ///   music-pipe to-midi --out output.mid
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
  Generators (create events):
    motif     - Melodic patterns (arpeggio, scale, chord)
    euclid    - Euclidean rhythms (drums, percussion)

  Transforms (modify events):
    transpose - Shift pitch by semitones
    scale     - Constrain to musical scale
    humanize  - Add timing/velocity variation

  Output:
    to-midi   - Write MIDI file

PIPELINE PATTERN:
  [generator] | [transform...] | to-midi --out file.mid

AI AGENT USAGE:
  1. Run: music-pipe --help (this help)
  2. Run: music-pipe <stage> --help for stage details
  3. Run: music-pipe reference for quick parameter reference
  4. Run: music-pipe recipes for video intro/outro examples
  5. See: docs/usage.md for comprehensive documentation
"#;

const EXAMPLES: &str = r#"
EXAMPLES:
  # Simple melody
  motif --base 60 --bpm 120 --repeat 4 | to-midi --out melody.mid

  # Melody in C major with humanization
  motif --base 60 --repeat 8 | scale --root C --mode major | humanize | to-midi --out out.mid

  # Drum pattern (kick + hihat)
  { euclid --steps 16 --pulses 4 --note 36;
    euclid --steps 16 --pulses 8 --note 42 --vel 60 --bpm 0; } | to-midi --out drums.mid

  # Video intro (5 seconds)
  motif --base 72 --bpm 130 --repeat 6 | scale --root G --mode major | humanize --seed 42 | to-midi --out intro.mid

MORE INFO:
  music-pipe reference    Quick parameter reference
  music-pipe recipes      Video intro/outro recipes
  See docs/usage.md       Full documentation
"#;

const REFERENCE: &str = r#"
QUICK REFERENCE
===============

GENERATORS
----------
motif --base <NOTE> --bpm <BPM> --pattern <TYPE> --repeat <N> --ch <CH> --vel <VEL>
  --base     MIDI note (60=middle C)        [default: 60]
  --bpm      Tempo                          [default: 120]
  --pattern  arpeggio|scale|chord           [default: arpeggio]
  --repeat   Repetitions                    [default: 1]
  --ch       MIDI channel (0-15)            [default: 0]
  --vel      Velocity (1-127)               [default: 96]

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

humanize --seed <N> --jitter-ticks <N> --jitter-vel <N>
  --seed     Random seed (reproducible)     [default: 42]
  --jitter-ticks  Timing variation (+/-)    [default: 8]
  --jitter-vel    Velocity variation (+/-)  [default: 10]

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
  5 seconds = 10 quarter notes = motif --repeat 10 (at 4 notes/pattern = ~2.5 patterns)
"#;

const RECIPES: &str = r#"
VIDEO INTRO/OUTRO RECIPES
=========================

BRIGHT INTRO (5 sec)
--------------------
motif --base 72 --bpm 130 --pattern arpeggio --repeat 6 --vel 100 \
  | scale --root C --mode major \
  | humanize --seed 42 --jitter-ticks 6 \
  | to-midi --out bright-intro.mid

CALM INTRO (8 sec)
------------------
motif --base 60 --bpm 90 --pattern arpeggio --repeat 6 --vel 80 \
  | scale --root G --mode major \
  | humanize --seed 55 --jitter-ticks 10 \
  | to-midi --out calm-intro.mid

DRAMATIC INTRO (6 sec)
----------------------
motif --base 48 --bpm 100 --pattern scale --repeat 4 --vel 90 \
  | scale --root D --mode harmonic-minor \
  | humanize --seed 77 \
  | to-midi --out dramatic-intro.mid

TECH/ELECTRONIC INTRO (6 sec)
-----------------------------
{
  motif --base 60 --bpm 128 --pattern arpeggio --repeat 8 --ch 0;
  euclid --steps 16 --pulses 4 --note 36 --ch 1 --bpm 0 --repeat 4;
  euclid --steps 16 --pulses 8 --note 42 --ch 9 --bpm 0 --repeat 4 --vel 45;
} | scale --root C --mode pentatonic-minor | humanize --seed 64 | to-midi --out tech-intro.mid

MELLOW OUTRO (12 sec)
---------------------
motif --base 60 --bpm 70 --pattern arpeggio --repeat 8 --vel 70 \
  | scale --root A --mode minor \
  | humanize --seed 33 --jitter-ticks 15 \
  | to-midi --out mellow-outro.mid

UPBEAT OUTRO WITH DRUMS (10 sec)
--------------------------------
# Create parts
motif --base 67 --bpm 120 --pattern arpeggio --repeat 10 --ch 0 > /tmp/mel.jsonl
{ euclid --steps 16 --pulses 4 --note 36 --ch 9 --bpm 0 --repeat 5;
  euclid --steps 16 --pulses 8 --note 42 --ch 9 --vel 50 --bpm 0 --repeat 5; } > /tmp/drm.jsonl
# Combine
cat /tmp/mel.jsonl /tmp/drm.jsonl | scale --root G --mode major | humanize | to-midi --out upbeat-outro.mid

PLAYBACK
--------
# With FluidSynth
fluidsynth -a coreaudio -ni /path/to/soundfont.sf2 output.mid

# Convert to WAV
fluidsynth -F output.wav -ni soundfont.sf2 input.mid
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
        Some(Commands::Motif { full_help }) => {
            if full_help {
                run_stage("motif", &["--help"]);
            } else {
                println!("motif - Generate melodic patterns\n");
                println!("Run 'motif --help' for all options, or 'music-pipe motif -H'\n");
                println!("Quick usage:");
                println!("  motif --base 60 --bpm 120 --pattern arpeggio --repeat 4\n");
                println!("Key options:");
                println!("  --base <NOTE>     Base MIDI note (60=middle C)");
                println!("  --bpm <BPM>       Tempo in beats per minute");
                println!("  --pattern <TYPE>  arpeggio|scale|chord");
                println!("  --repeat <N>      Number of repetitions");
            }
        }
        Some(Commands::Euclid { full_help }) => {
            if full_help {
                run_stage("euclid", &["--help"]);
            } else {
                println!("euclid - Generate Euclidean rhythms\n");
                println!("Run 'euclid --help' for all options, or 'music-pipe euclid -H'\n");
                println!("Quick usage:");
                println!("  euclid --steps 16 --pulses 4 --note 36  # kick drum\n");
                println!("Key options:");
                println!("  --steps <N>    Steps in pattern");
                println!("  --pulses <N>   Hits to distribute");
                println!("  --note <NOTE>  MIDI note (36=kick, 38=snare, 42=hihat)");
                println!("  --repeat <N>   Repetitions");
            }
        }
        Some(Commands::Transpose { full_help }) => {
            if full_help {
                run_stage("transpose", &["--help"]);
            } else {
                println!("transpose - Shift notes by semitones\n");
                println!("Run 'transpose --help' for all options\n");
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
                println!("Run 'scale --help' for all options, or 'music-pipe scale -H'\n");
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
                println!("humanize - Add timing/velocity variation\n");
                println!("Run 'humanize --help' for all options\n");
                println!("Usage:");
                println!("  humanize --seed 42 --jitter-ticks 8 --jitter-vel 10");
            }
        }
        Some(Commands::ToMidi { full_help }) => {
            if full_help {
                run_stage("to-midi", &["--help"]);
            } else {
                println!("to-midi - Write MIDI file\n");
                println!("Run 'to-midi --help' for all options\n");
                println!("Usage:");
                println!("  to-midi --out output.mid");
            }
        }
        None => {
            // Print default help
            println!("music-pipe - Unix-style pipeline for generative MIDI music\n");
            println!("USAGE:");
            println!("  music-pipe <COMMAND> [OPTIONS]\n");
            println!("COMMANDS:");
            println!("  motif      Generate melodic patterns");
            println!("  euclid     Generate Euclidean rhythms");
            println!("  transpose  Shift notes by semitones");
            println!("  scale      Constrain to musical scale");
            println!("  humanize   Add timing/velocity variation");
            println!("  to-midi    Write MIDI file");
            println!("  reference  Quick parameter reference");
            println!("  recipes    Video intro/outro recipes");
            println!();
            println!("PIPELINE PATTERN:");
            println!("  motif | transpose | scale | humanize | to-midi --out file.mid\n");
            println!("QUICK START:");
            println!(
                "  music-pipe motif --base 60 --repeat 4 | music-pipe to-midi --out test.mid\n"
            );
            println!("MORE HELP:");
            println!("  music-pipe --help         Full overview");
            println!("  music-pipe <stage> -H     Stage details");
            println!("  music-pipe reference      Quick reference");
            println!("  music-pipe recipes        Video intro/outro examples");
        }
    }
}

fn run_stage(name: &str, args: &[&str]) {
    use std::process::Command;

    // Try to find the stage binary
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
