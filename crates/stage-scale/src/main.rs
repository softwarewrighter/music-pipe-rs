//! Scale constraint stage for music-pipe-rs
//!
//! Snaps note pitches to the nearest degree of a specified scale.
//! Useful for ensuring melodic content stays in key.

use anyhow::{anyhow, Result};
use clap::{Parser, ValueEnum};
use music_ir::{read_events_from_stdin, write_events_to_stdout, Event};

/// Constrain pitches to a scale
#[derive(Parser, Debug)]
#[command(name = "scale")]
#[command(about = "Snap notes to a musical scale")]
#[command(version)]
struct Args {
    /// Root note (C, C#, D, D#, E, F, F#, G, G#, A, A#, B)
    #[arg(long, default_value = "C")]
    root: String,

    /// Scale/mode type
    #[arg(long, value_enum, default_value = "major")]
    mode: ScaleMode,

    /// Snap direction: nearest, up, or down
    #[arg(long, value_enum, default_value = "nearest")]
    snap: SnapDirection,
}

#[derive(Debug, Clone, Copy, ValueEnum)]
enum ScaleMode {
    Major,
    Minor,
    Dorian,
    Phrygian,
    Lydian,
    Mixolydian,
    Locrian,
    HarmonicMinor,
    MelodicMinor,
    Pentatonic,
    PentatonicMinor,
    Blues,
    Chromatic,
    WholeTone,
}

#[derive(Debug, Clone, Copy, ValueEnum)]
enum SnapDirection {
    /// Snap to nearest scale degree
    Nearest,
    /// Snap up to next scale degree
    Up,
    /// Snap down to previous scale degree
    Down,
}

fn main() -> Result<()> {
    let args = Args::parse();

    let root = parse_root(&args.root)?;
    let intervals = get_scale_intervals(args.mode);

    let mut events = read_events_from_stdin()?;

    for event in &mut events {
        match event {
            Event::NoteOn { key, .. } | Event::NoteOff { key, .. } => {
                *key = snap_to_scale(*key, root, &intervals, args.snap);
            }
            _ => {}
        }
    }

    write_events_to_stdout(&events)
}

/// Parse a root note name to a pitch class (0-11)
fn parse_root(s: &str) -> Result<u8> {
    match s.to_uppercase().as_str() {
        "C" => Ok(0),
        "C#" | "DB" => Ok(1),
        "D" => Ok(2),
        "D#" | "EB" => Ok(3),
        "E" => Ok(4),
        "F" => Ok(5),
        "F#" | "GB" => Ok(6),
        "G" => Ok(7),
        "G#" | "AB" => Ok(8),
        "A" => Ok(9),
        "A#" | "BB" => Ok(10),
        "B" => Ok(11),
        _ => Err(anyhow!("invalid root note: {}", s)),
    }
}

/// Get the semitone intervals for a scale mode
fn get_scale_intervals(mode: ScaleMode) -> Vec<u8> {
    match mode {
        // Major modes
        ScaleMode::Major => vec![0, 2, 4, 5, 7, 9, 11], // Ionian
        ScaleMode::Dorian => vec![0, 2, 3, 5, 7, 9, 10],
        ScaleMode::Phrygian => vec![0, 1, 3, 5, 7, 8, 10],
        ScaleMode::Lydian => vec![0, 2, 4, 6, 7, 9, 11],
        ScaleMode::Mixolydian => vec![0, 2, 4, 5, 7, 9, 10],
        ScaleMode::Minor => vec![0, 2, 3, 5, 7, 8, 10], // Aeolian
        ScaleMode::Locrian => vec![0, 1, 3, 5, 6, 8, 10],

        // Other scales
        ScaleMode::HarmonicMinor => vec![0, 2, 3, 5, 7, 8, 11],
        ScaleMode::MelodicMinor => vec![0, 2, 3, 5, 7, 9, 11],
        ScaleMode::Pentatonic => vec![0, 2, 4, 7, 9], // Major pentatonic
        ScaleMode::PentatonicMinor => vec![0, 3, 5, 7, 10], // Minor pentatonic
        ScaleMode::Blues => vec![0, 3, 5, 6, 7, 10],
        ScaleMode::Chromatic => vec![0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
        ScaleMode::WholeTone => vec![0, 2, 4, 6, 8, 10],
    }
}

/// Snap a MIDI note to the nearest scale degree
fn snap_to_scale(key: u8, root: u8, intervals: &[u8], direction: SnapDirection) -> u8 {
    if intervals.is_empty() || intervals.len() == 12 {
        return key; // Chromatic or empty = no change
    }

    let pitch_class = (key + 12 - root) % 12;
    let octave = key / 12;

    // Find the snapped pitch class
    let snapped_pc = match direction {
        SnapDirection::Nearest => snap_nearest(pitch_class, intervals),
        SnapDirection::Up => snap_up(pitch_class, intervals),
        SnapDirection::Down => snap_down(pitch_class, intervals),
    };

    // Reconstruct the MIDI note
    let mut result = octave * 12 + root + snapped_pc;

    // Handle octave wrapping
    if snapped_pc < pitch_class && matches!(direction, SnapDirection::Up) {
        result += 12;
    } else if snapped_pc > pitch_class && matches!(direction, SnapDirection::Down) {
        result = result.saturating_sub(12);
    }

    result.clamp(0, 127)
}

/// Snap to the nearest interval in the scale
fn snap_nearest(pc: u8, intervals: &[u8]) -> u8 {
    let mut best = intervals[0];
    let mut best_dist = distance(pc, best);

    for &interval in intervals.iter().skip(1) {
        let dist = distance(pc, interval);
        if dist < best_dist {
            best = interval;
            best_dist = dist;
        }
    }

    best
}

/// Snap up to the next scale degree
fn snap_up(pc: u8, intervals: &[u8]) -> u8 {
    for &interval in intervals {
        if interval >= pc {
            return interval;
        }
    }
    // Wrap to first interval (in next octave, handled by caller)
    intervals[0]
}

/// Snap down to the previous scale degree
fn snap_down(pc: u8, intervals: &[u8]) -> u8 {
    for &interval in intervals.iter().rev() {
        if interval <= pc {
            return interval;
        }
    }
    // Wrap to last interval (in previous octave, handled by caller)
    *intervals.last().unwrap_or(&0)
}

/// Calculate circular distance between two pitch classes
fn distance(a: u8, b: u8) -> u8 {
    let diff = a.abs_diff(b);
    diff.min(12 - diff)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_root() {
        assert_eq!(parse_root("C").unwrap(), 0);
        assert_eq!(parse_root("c").unwrap(), 0);
        assert_eq!(parse_root("C#").unwrap(), 1);
        assert_eq!(parse_root("Db").unwrap(), 1);
        assert_eq!(parse_root("G").unwrap(), 7);
        assert_eq!(parse_root("B").unwrap(), 11);
    }

    #[test]
    fn test_major_scale_intervals() {
        let intervals = get_scale_intervals(ScaleMode::Major);
        assert_eq!(intervals, vec![0, 2, 4, 5, 7, 9, 11]);
    }

    #[test]
    fn test_snap_nearest_in_scale() {
        let intervals = vec![0, 2, 4, 5, 7, 9, 11]; // C major
                                                    // C (0) -> C
        assert_eq!(snap_nearest(0, &intervals), 0);
        // D (2) -> D
        assert_eq!(snap_nearest(2, &intervals), 2);
    }

    #[test]
    fn test_snap_nearest_out_of_scale() {
        let intervals = vec![0, 2, 4, 5, 7, 9, 11]; // C major
                                                    // C# (1) -> C (0) or D (2), nearest is either (equidistant, picks first)
        let result = snap_nearest(1, &intervals);
        assert!(result == 0 || result == 2);

        // F# (6) -> G (7) (distance 1) vs F (5) (distance 1)
        let result = snap_nearest(6, &intervals);
        assert!(result == 5 || result == 7);
    }

    #[test]
    fn test_snap_up() {
        let intervals = vec![0, 2, 4, 5, 7, 9, 11]; // C major
        assert_eq!(snap_up(0, &intervals), 0); // C -> C
        assert_eq!(snap_up(1, &intervals), 2); // C# -> D
        assert_eq!(snap_up(3, &intervals), 4); // D# -> E
        assert_eq!(snap_up(6, &intervals), 7); // F# -> G
    }

    #[test]
    fn test_snap_down() {
        let intervals = vec![0, 2, 4, 5, 7, 9, 11]; // C major
        assert_eq!(snap_down(0, &intervals), 0); // C -> C
        assert_eq!(snap_down(1, &intervals), 0); // C# -> C
        assert_eq!(snap_down(3, &intervals), 2); // D# -> D
        assert_eq!(snap_down(6, &intervals), 5); // F# -> F
    }

    #[test]
    fn test_snap_to_scale_c_major() {
        let intervals = vec![0, 2, 4, 5, 7, 9, 11];
        let root = 0; // C

        // Middle C (60) stays as C
        assert_eq!(
            snap_to_scale(60, root, &intervals, SnapDirection::Nearest),
            60
        );

        // C# (61) snaps to C (60) or D (62)
        let result = snap_to_scale(61, root, &intervals, SnapDirection::Nearest);
        assert!(result == 60 || result == 62);

        // C# (61) snaps up to D (62)
        assert_eq!(snap_to_scale(61, root, &intervals, SnapDirection::Up), 62);

        // C# (61) snaps down to C (60)
        assert_eq!(snap_to_scale(61, root, &intervals, SnapDirection::Down), 60);
    }

    #[test]
    fn test_snap_to_scale_g_major() {
        let intervals = vec![0, 2, 4, 5, 7, 9, 11];
        let root = 7; // G

        // G (67) stays as G
        assert_eq!(
            snap_to_scale(67, root, &intervals, SnapDirection::Nearest),
            67
        );

        // G# (68) in G major should snap to G (67) or A (69)
        let result = snap_to_scale(68, root, &intervals, SnapDirection::Nearest);
        assert!(result == 67 || result == 69);
    }

    #[test]
    fn test_pentatonic() {
        let intervals = vec![0, 2, 4, 7, 9]; // Major pentatonic
        let root = 0; // C

        // E (64) is in scale
        assert_eq!(
            snap_to_scale(64, root, &intervals, SnapDirection::Nearest),
            64
        );

        // F (65) not in pentatonic, snaps to E (64) or G (67)
        let result = snap_to_scale(65, root, &intervals, SnapDirection::Nearest);
        assert!(result == 64 || result == 67);
    }

    #[test]
    fn test_distance() {
        assert_eq!(distance(0, 0), 0);
        assert_eq!(distance(0, 1), 1);
        assert_eq!(distance(0, 6), 6);
        assert_eq!(distance(0, 7), 5); // Wraps around
        assert_eq!(distance(0, 11), 1); // Wraps around
        assert_eq!(distance(11, 0), 1);
    }
}
