//! Euclidean rhythm generator for music-pipe-rs
//!
//! Generates rhythms using the Euclidean algorithm, which distributes
//! N pulses as evenly as possible across K steps. This produces many
//! traditional world music rhythms.
//!
//! Examples:
//! - E(3,8) = [x . . x . . x .] - Cuban tresillo
//! - E(5,8) = [x . x x . x x .] - Cuban cinquillo
//! - E(7,16) = [x . x . x . x . x . x . x . x .] - Brazilian samba

use anyhow::Result;
use clap::Parser;
use music_ir::{write_events_to_stdout, Event};

/// Generate Euclidean rhythms
#[derive(Parser, Debug)]
#[command(name = "euclid")]
#[command(about = "Generate Euclidean rhythms as JSONL events")]
#[command(version)]
struct Args {
    /// Number of steps in the pattern
    #[arg(long, default_value_t = 16)]
    steps: u32,

    /// Number of pulses (hits) to distribute
    #[arg(long, default_value_t = 5)]
    pulses: u32,

    /// Rotation offset (shifts pattern start)
    #[arg(long, default_value_t = 0)]
    rotation: i32,

    /// MIDI note number for hits
    #[arg(long, default_value_t = 36)]
    note: u8,

    /// MIDI channel (0-15)
    #[arg(long, default_value_t = 9)]
    ch: u8,

    /// Velocity (1-127)
    #[arg(long, default_value_t = 100)]
    vel: u8,

    /// Ticks per step
    #[arg(long, default_value_t = 120)]
    step_ticks: u32,

    /// Note duration in ticks (0 = half of step_ticks)
    #[arg(long, default_value_t = 0)]
    duration: u32,

    /// Tempo in BPM (0 = don't emit tempo event)
    #[arg(long, default_value_t = 120)]
    bpm: u32,

    /// Number of pattern repetitions
    #[arg(long, default_value_t = 1)]
    repeat: u32,
}

fn main() -> Result<()> {
    let args = Args::parse();

    // Generate the Euclidean pattern
    let pattern = euclidean_rhythm(args.steps as usize, args.pulses as usize);

    // Apply rotation
    let pattern = rotate_pattern(&pattern, args.rotation);

    // Calculate note duration
    let duration = if args.duration == 0 {
        args.step_ticks / 2
    } else {
        args.duration
    };

    let mut events = Vec::new();

    // Emit tempo if specified
    if args.bpm > 0 {
        events.push(Event::Tempo {
            t: 0,
            bpm: args.bpm,
        });
    }

    // Generate events for each repetition
    let pattern_length = args.steps * args.step_ticks;

    for rep in 0..args.repeat {
        let base_t = rep * pattern_length;

        for (step, &hit) in pattern.iter().enumerate() {
            if hit {
                let t = base_t + (step as u32) * args.step_ticks;

                events.push(Event::NoteOn {
                    t,
                    ch: args.ch,
                    key: args.note,
                    vel: args.vel,
                });

                events.push(Event::NoteOff {
                    t: t + duration,
                    ch: args.ch,
                    key: args.note,
                });
            }
        }
    }

    // End marker
    let end_t = args.repeat * pattern_length;
    events.push(Event::End { t: end_t });

    write_events_to_stdout(&events)
}

/// Generate a Euclidean rhythm using Bjorklund's algorithm.
///
/// Distributes `pulses` hits as evenly as possible across `steps` positions.
/// The pattern always starts with a hit on the first step.
///
/// Returns a vector of booleans where `true` indicates a hit.
fn euclidean_rhythm(steps: usize, pulses: usize) -> Vec<bool> {
    if steps == 0 {
        return vec![];
    }

    if pulses == 0 {
        return vec![false; steps];
    }

    if pulses >= steps {
        return vec![true; steps];
    }

    // Calculate positions using the slope approach
    // For k pulses in n steps, place hits at floor(i * n / k) for i in 0..k
    let mut pattern = vec![false; steps];

    for i in 0..pulses {
        let pos = (i * steps) / pulses;
        pattern[pos] = true;
    }

    pattern
}

/// Rotate a pattern by the given offset.
///
/// Positive rotation shifts hits to the right (later in time).
/// Negative rotation shifts hits to the left (earlier in time).
fn rotate_pattern(pattern: &[bool], rotation: i32) -> Vec<bool> {
    if pattern.is_empty() {
        return vec![];
    }

    let len = pattern.len() as i32;
    let effective_rotation = ((rotation % len) + len) % len;

    let mut rotated = vec![false; pattern.len()];
    for (i, &hit) in pattern.iter().enumerate() {
        let new_pos = ((i as i32 + effective_rotation) % len) as usize;
        rotated[new_pos] = hit;
    }

    rotated
}

/// Format a pattern as a string for display (e.g., "x . x . x . . .")
#[allow(dead_code)]
fn format_pattern(pattern: &[bool]) -> String {
    pattern
        .iter()
        .map(|&hit| if hit { "x" } else { "." })
        .collect::<Vec<_>>()
        .join(" ")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_euclidean_3_8() {
        // E(3,8) = Cuban tresillo: x . . x . . x .
        let pattern = euclidean_rhythm(8, 3);
        assert_eq!(pattern.len(), 8);
        assert_eq!(pattern.iter().filter(|&&x| x).count(), 3);

        // Verify it's a valid distribution (no two hits adjacent would be suboptimal)
        let formatted = format_pattern(&pattern);
        // Should be "x . . x . . x ." or a rotation of it
        assert!(
            formatted == "x . . x . . x ."
                || formatted == "x . x . . x . ."
                || formatted == "x . . x . x . ."
        );
    }

    #[test]
    fn test_euclidean_5_8() {
        // E(5,8) = Cuban cinquillo
        let pattern = euclidean_rhythm(8, 5);
        assert_eq!(pattern.len(), 8);
        assert_eq!(pattern.iter().filter(|&&x| x).count(), 5);
    }

    #[test]
    fn test_euclidean_4_16() {
        // E(4,16) = standard 4-on-the-floor
        let pattern = euclidean_rhythm(16, 4);
        assert_eq!(pattern.len(), 16);
        assert_eq!(pattern.iter().filter(|&&x| x).count(), 4);

        // Should be evenly spaced: every 4th step
        assert!(pattern[0]);
        assert!(pattern[4]);
        assert!(pattern[8]);
        assert!(pattern[12]);
    }

    #[test]
    fn test_euclidean_0_pulses() {
        let pattern = euclidean_rhythm(8, 0);
        assert_eq!(pattern.len(), 8);
        assert!(pattern.iter().all(|&x| !x));
    }

    #[test]
    fn test_euclidean_full_pulses() {
        let pattern = euclidean_rhythm(8, 8);
        assert_eq!(pattern.len(), 8);
        assert!(pattern.iter().all(|&x| x));
    }

    #[test]
    fn test_euclidean_more_pulses_than_steps() {
        let pattern = euclidean_rhythm(4, 10);
        assert_eq!(pattern.len(), 4);
        assert!(pattern.iter().all(|&x| x));
    }

    #[test]
    fn test_rotation_zero() {
        let pattern = vec![true, false, false, true];
        let rotated = rotate_pattern(&pattern, 0);
        assert_eq!(rotated, pattern);
    }

    #[test]
    fn test_rotation_positive() {
        let pattern = vec![true, false, false, false];
        let rotated = rotate_pattern(&pattern, 1);
        assert_eq!(rotated, vec![false, true, false, false]);
    }

    #[test]
    fn test_rotation_negative() {
        let pattern = vec![true, false, false, false];
        let rotated = rotate_pattern(&pattern, -1);
        assert_eq!(rotated, vec![false, false, false, true]);
    }

    #[test]
    fn test_rotation_wrap() {
        let pattern = vec![true, false, false, false];
        let rotated = rotate_pattern(&pattern, 4);
        assert_eq!(rotated, pattern); // Full rotation = no change
    }
}
