//! Transpose stage for music-pipe-rs
//!
//! Shifts all notes up or down by a specified number of semitones.

use anyhow::Result;
use clap::Parser;
use music_ir::{read_events_from_stdin, write_events_to_stdout, Event};

/// Transpose notes by semitones
#[derive(Parser, Debug)]
#[command(name = "transpose")]
#[command(about = "Transpose notes by N semitones")]
#[command(version)]
struct Args {
    /// Number of semitones to transpose (can be negative)
    #[arg(long)]
    semitones: i16,
}

fn main() -> Result<()> {
    let args = Args::parse();
    let mut events = read_events_from_stdin()?;

    for event in &mut events {
        match event {
            Event::NoteOn { key, .. } | Event::NoteOff { key, .. } => {
                *key = transpose_key(*key, args.semitones);
            }
            _ => {}
        }
    }

    write_events_to_stdout(&events)
}

/// Transpose a MIDI key by semitones, clamping to valid range (0-127)
fn transpose_key(key: u8, semitones: i16) -> u8 {
    let new_key = key as i16 + semitones;
    new_key.clamp(0, 127) as u8
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_transpose_up() {
        assert_eq!(transpose_key(60, 7), 67);
    }

    #[test]
    fn test_transpose_down() {
        assert_eq!(transpose_key(60, -12), 48);
    }

    #[test]
    fn test_transpose_clamp_high() {
        assert_eq!(transpose_key(120, 20), 127);
    }

    #[test]
    fn test_transpose_clamp_low() {
        assert_eq!(transpose_key(10, -20), 0);
    }
}
