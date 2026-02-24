//! MIDI output stage for music-pipe-rs
//!
//! Converts JSONL events to a standard MIDI file.

use anyhow::{Context, Result};
use clap::Parser;
use midly::{Format, Header, MetaMessage, MidiMessage, Smf, Timing, TrackEvent, TrackEventKind};
use music_ir::{read_events_from_stdin, sort_events_by_time, Event};
use std::fs;
use std::path::PathBuf;

/// Convert JSONL events to MIDI file
#[derive(Parser, Debug)]
#[command(name = "to-midi")]
#[command(about = "Convert JSONL events to a MIDI file")]
#[command(version)]
struct Args {
    /// Output MIDI file path
    #[arg(long)]
    out: PathBuf,

    /// Ticks per quarter note
    #[arg(long, default_value_t = 480)]
    tpq: u16,
}

fn main() -> Result<()> {
    let args = Args::parse();
    let mut events = read_events_from_stdin()?;

    // Ensure events are sorted by time
    sort_events_by_time(&mut events);

    // Build MIDI file
    let header = Header::new(Format::SingleTrack, Timing::Metrical(args.tpq.into()));
    let mut track: Vec<TrackEvent> = Vec::new();

    let mut last_t: u32 = 0;

    for event in events {
        let t = event.time();
        let delta = t.saturating_sub(last_t);
        last_t = t;

        let kind = match event {
            Event::Seed { .. } => {
                // Skip Seed events; they're pipeline metadata, not MIDI
                continue;
            }
            Event::Tempo { bpm, .. } => {
                let mpqn = bpm_to_microseconds_per_quarter(bpm);
                TrackEventKind::Meta(MetaMessage::Tempo(mpqn.into()))
            }
            Event::ProgramChange { ch, program, .. } => TrackEventKind::Midi {
                channel: ch.into(),
                message: MidiMessage::ProgramChange {
                    program: program.into(),
                },
            },
            Event::NoteOn { ch, key, vel, .. } => TrackEventKind::Midi {
                channel: ch.into(),
                message: MidiMessage::NoteOn {
                    key: key.into(),
                    vel: vel.into(),
                },
            },
            Event::NoteOff { ch, key, .. } => TrackEventKind::Midi {
                channel: ch.into(),
                message: MidiMessage::NoteOff {
                    key: key.into(),
                    vel: 64.into(), // Standard release velocity
                },
            },
            Event::End { .. } => {
                // Skip End events; we'll add EndOfTrack at the end
                continue;
            }
        };

        track.push(TrackEvent {
            delta: delta.into(),
            kind,
        });
    }

    // Add EndOfTrack marker
    track.push(TrackEvent {
        delta: 0.into(),
        kind: TrackEventKind::Meta(MetaMessage::EndOfTrack),
    });

    // Create SMF and write to file
    let smf = Smf {
        header,
        tracks: vec![track],
    };

    let mut buffer = Vec::new();
    smf.write(&mut buffer)
        .map_err(|e| anyhow::anyhow!("failed to encode MIDI: {e}"))?;

    fs::write(&args.out, buffer).with_context(|| format!("failed to write {:?}", args.out))?;

    eprintln!("Wrote MIDI file: {:?}", args.out);
    Ok(())
}

/// Convert BPM to microseconds per quarter note
fn bpm_to_microseconds_per_quarter(bpm: u32) -> u32 {
    // 60,000,000 microseconds per minute / beats per minute
    60_000_000 / bpm.max(1)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_bpm_conversion() {
        // 120 BPM = 500,000 microseconds per quarter note
        assert_eq!(bpm_to_microseconds_per_quarter(120), 500_000);

        // 60 BPM = 1,000,000 microseconds per quarter note
        assert_eq!(bpm_to_microseconds_per_quarter(60), 1_000_000);

        // 240 BPM = 250,000 microseconds per quarter note
        assert_eq!(bpm_to_microseconds_per_quarter(240), 250_000);
    }

    #[test]
    fn test_bpm_zero_protection() {
        // Should not panic or divide by zero
        let result = bpm_to_microseconds_per_quarter(0);
        assert_eq!(result, 60_000_000);
    }
}
