//! Motif generator stage for music-pipe-rs
//!
//! Generates simple musical motifs and outputs them as JSONL events.

use anyhow::Result;
use clap::Parser;
use music_ir::{write_events_to_stdout, Event};

/// Generate musical motifs
#[derive(Parser, Debug)]
#[command(name = "motif")]
#[command(about = "Generate musical motifs as JSONL events")]
#[command(version)]
struct Args {
    /// Base MIDI note number (60 = middle C)
    #[arg(long, default_value_t = 60)]
    base: u8,

    /// MIDI channel (0-15)
    #[arg(long, default_value_t = 0)]
    ch: u8,

    /// Ticks per quarter note
    #[arg(long, default_value_t = 480)]
    tpq: u32,

    /// Tempo in beats per minute
    #[arg(long, default_value_t = 120)]
    bpm: u32,

    /// Velocity (1-127)
    #[arg(long, default_value_t = 96)]
    vel: u8,

    /// Pattern type: arpeggio, scale, or chord
    #[arg(long, default_value = "arpeggio")]
    pattern: String,

    /// Number of repetitions
    #[arg(long, default_value_t = 1)]
    repeat: u32,
}

fn main() -> Result<()> {
    let args = Args::parse();

    let mut events = Vec::new();

    // Emit tempo event at start
    events.push(Event::Tempo {
        t: 0,
        bpm: args.bpm,
    });

    // Generate the pattern
    let notes = match args.pattern.as_str() {
        "arpeggio" => generate_arpeggio(args.base),
        "scale" => generate_scale(args.base),
        "chord" => generate_chord(args.base),
        _ => generate_arpeggio(args.base),
    };

    // Note duration: eighth note = tpq / 2
    let dur = args.tpq / 2;
    let _pattern_length = notes.len() as u32 * dur;

    let mut t = 0u32;
    for _ in 0..args.repeat {
        for &key in &notes {
            // Clamp key to valid MIDI range
            let key = key.clamp(0, 127);

            events.push(Event::NoteOn {
                t,
                ch: args.ch,
                key,
                vel: args.vel,
            });
            events.push(Event::NoteOff {
                t: t + dur,
                ch: args.ch,
                key,
            });
            t += dur;
        }
    }

    // End marker
    events.push(Event::End { t });

    write_events_to_stdout(&events)
}

/// Generate an arpeggio pattern (root, 3rd, 5th, octave)
fn generate_arpeggio(base: u8) -> Vec<u8> {
    vec![base, base + 4, base + 7, base + 12]
}

/// Generate a major scale pattern
fn generate_scale(base: u8) -> Vec<u8> {
    // Major scale intervals: W W H W W W H
    vec![
        base,
        base + 2,
        base + 4,
        base + 5,
        base + 7,
        base + 9,
        base + 11,
        base + 12,
    ]
}

/// Generate a chord (all notes at once, then release)
fn generate_chord(base: u8) -> Vec<u8> {
    // For chord, we return single notes but they'll be played sequentially
    // A true chord stage would need different logic
    vec![base, base + 4, base + 7]
}
