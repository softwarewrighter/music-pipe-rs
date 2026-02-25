//! Trim stage for music-pipe-rs
//!
//! Removes trailing silence by adjusting the End event time.
//!
//! Modes:
//! - `--auto`: Find last NoteOff, add padding (default)
//! - `--duration <secs>`: Force specific duration in seconds
//! - `--ticks <t>`: Force specific duration in ticks

use anyhow::Result;
use clap::Parser;
use music_ir::{read_events_from_stdin, write_events_to_stdout, Event};

/// Trim trailing silence from event streams
#[derive(Parser, Debug)]
#[command(name = "trim")]
#[command(about = "Trim trailing silence from event streams")]
#[command(version)]
struct Args {
    /// Auto-detect end time from last NoteOff + padding
    #[arg(long, default_value_t = true)]
    auto: bool,

    /// Force specific duration in seconds
    #[arg(long, conflicts_with = "ticks")]
    duration: Option<f64>,

    /// Force specific duration in ticks
    #[arg(long, conflicts_with = "duration")]
    ticks: Option<u32>,

    /// Padding in milliseconds after last NoteOff (for --auto mode)
    #[arg(long, default_value_t = 500)]
    padding_ms: u32,

    /// Ticks per quarter note (for duration calculation)
    #[arg(long, default_value_t = 480)]
    tpq: u32,
}

fn main() -> Result<()> {
    let args = Args::parse();

    let events = read_events_from_stdin()?;

    if events.is_empty() {
        return Ok(());
    }

    // Extract BPM from Tempo event (default 120 if not found)
    let bpm = events
        .iter()
        .find_map(|e| match e {
            Event::Tempo { bpm, .. } => Some(*bpm),
            _ => None,
        })
        .unwrap_or(120);

    // Calculate new end time
    let new_end_ticks = if let Some(duration_secs) = args.duration {
        // Convert seconds to ticks: ticks = seconds * (bpm/60) * tpq
        let ticks_per_second = (bpm as f64 / 60.0) * args.tpq as f64;
        (duration_secs * ticks_per_second) as u32
    } else if let Some(ticks) = args.ticks {
        ticks
    } else {
        // Auto mode: find last NoteOff and add padding
        let last_note_off = events
            .iter()
            .filter_map(|e| match e {
                Event::NoteOff { t, .. } => Some(*t),
                _ => None,
            })
            .max()
            .unwrap_or(0);

        // Convert padding_ms to ticks
        let ticks_per_ms = (bpm as f64 / 60.0) * args.tpq as f64 / 1000.0;
        let padding_ticks = (args.padding_ms as f64 * ticks_per_ms) as u32;

        last_note_off + padding_ticks
    };

    // Filter events: keep all events before new_end_ticks, update End event
    let mut output_events: Vec<Event> = Vec::new();
    let mut has_end = false;

    for event in events.iter() {
        match event {
            Event::End { .. } => {
                has_end = true;
                // Will add corrected End event at the end
            }
            _ => {
                // Keep events that start before the new end time
                if event.time() <= new_end_ticks {
                    let mut e = event.clone();

                    // For NoteOff events, clamp to new_end_ticks if needed
                    if let Event::NoteOff { t, .. } = &mut e {
                        if *t > new_end_ticks {
                            *t = new_end_ticks;
                        }
                    }

                    output_events.push(e);
                }
            }
        }
    }

    // Add End event at new position
    if has_end || !output_events.is_empty() {
        output_events.push(Event::End { t: new_end_ticks });
    }

    write_events_to_stdout(&output_events)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn make_events() -> Vec<Event> {
        vec![
            Event::Tempo { t: 0, bpm: 120 },
            Event::NoteOn { t: 0, ch: 0, key: 60, vel: 96 },
            Event::NoteOff { t: 480, ch: 0, key: 60 },
            Event::NoteOn { t: 480, ch: 0, key: 62, vel: 96 },
            Event::NoteOff { t: 960, ch: 0, key: 62 },
            Event::End { t: 5000 }, // Much later than content
        ]
    }

    #[test]
    fn test_find_last_noteoff() {
        let events = make_events();
        let last = events
            .iter()
            .filter_map(|e| match e {
                Event::NoteOff { t, .. } => Some(*t),
                _ => None,
            })
            .max();
        assert_eq!(last, Some(960));
    }
}
