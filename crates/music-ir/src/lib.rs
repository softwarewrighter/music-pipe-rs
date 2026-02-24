//! Music IR - Intermediate Representation for music-pipe-rs
//!
//! This crate provides the shared event types and JSONL I/O functions
//! used by all pipeline stages.

use anyhow::{Context, Result};
use serde::{Deserialize, Serialize};
use std::io::{self, BufRead, Write};

/// A musical event in the pipeline.
///
/// Events use absolute time in ticks, making them easy to sort and debug.
/// The `type` field in JSON is used for tagged serialization.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
#[serde(tag = "type")]
pub enum Event {
    /// Random seed for the pipeline.
    /// Emitted once at the start; all stages use this seed for determinism.
    Seed {
        /// The seed value
        seed: u64,
    },
    /// A note begins playing
    NoteOn {
        /// Absolute time in ticks
        t: u32,
        /// MIDI channel (0-15)
        ch: u8,
        /// MIDI note number (0-127)
        key: u8,
        /// Velocity (1-127)
        vel: u8,
    },
    /// A note stops playing
    NoteOff {
        /// Absolute time in ticks
        t: u32,
        /// MIDI channel (0-15)
        ch: u8,
        /// MIDI note number (0-127)
        key: u8,
    },
    /// Tempo change
    Tempo {
        /// Absolute time in ticks
        t: u32,
        /// Beats per minute
        bpm: u32,
    },
    /// End of sequence marker
    End {
        /// Absolute time in ticks
        t: u32,
    },
}

impl Event {
    /// Get the timestamp of this event (Seed has no time, returns 0)
    pub fn time(&self) -> u32 {
        match self {
            Event::Seed { .. } => 0,
            Event::NoteOn { t, .. } => *t,
            Event::NoteOff { t, .. } => *t,
            Event::Tempo { t, .. } => *t,
            Event::End { t } => *t,
        }
    }

    /// Set the timestamp of this event (no-op for Seed)
    pub fn set_time(&mut self, new_t: u32) {
        match self {
            Event::Seed { .. } => {}
            Event::NoteOn { t, .. } => *t = new_t,
            Event::NoteOff { t, .. } => *t = new_t,
            Event::Tempo { t, .. } => *t = new_t,
            Event::End { t } => *t = new_t,
        }
    }
}

/// Extract the seed value from events, if present.
pub fn extract_seed(events: &[Event]) -> Option<u64> {
    events.iter().find_map(|e| match e {
        Event::Seed { seed } => Some(*seed),
        _ => None,
    })
}

/// Read all events from stdin as JSONL (one JSON object per line).
///
/// # Errors
///
/// Returns an error if stdin cannot be read or if any line contains invalid JSON.
pub fn read_events_from_stdin() -> Result<Vec<Event>> {
    let stdin = io::stdin();
    let mut events = Vec::new();

    for (i, line) in stdin.lock().lines().enumerate() {
        let line = line.context("failed to read from stdin")?;
        if line.trim().is_empty() {
            continue;
        }
        let event: Event = serde_json::from_str(&line)
            .with_context(|| format!("invalid JSON on line {}", i + 1))?;
        events.push(event);
    }

    Ok(events)
}

/// Write events to stdout as JSONL (one JSON object per line).
///
/// # Errors
///
/// Returns an error if writing to stdout fails.
pub fn write_events_to_stdout(events: &[Event]) -> Result<()> {
    let stdout = io::stdout();
    let mut writer = io::BufWriter::new(stdout.lock());

    for event in events {
        serde_json::to_writer(&mut writer, event)?;
        writer.write_all(b"\n")?;
    }

    writer.flush()?;
    Ok(())
}

/// Sort events by time, maintaining stability for events at the same time.
pub fn sort_events_by_time(events: &mut [Event]) {
    events.sort_by_key(|e| e.time());
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_event_serialization_roundtrip() {
        let events = vec![
            Event::Tempo { t: 0, bpm: 120 },
            Event::NoteOn {
                t: 0,
                ch: 0,
                key: 60,
                vel: 96,
            },
            Event::NoteOff {
                t: 240,
                ch: 0,
                key: 60,
            },
            Event::End { t: 240 },
        ];

        for event in &events {
            let json = serde_json::to_string(event).unwrap();
            let parsed: Event = serde_json::from_str(&json).unwrap();
            assert_eq!(event, &parsed);
        }
    }

    #[test]
    fn test_event_time_accessor() {
        let event = Event::NoteOn {
            t: 100,
            ch: 0,
            key: 60,
            vel: 96,
        };
        assert_eq!(event.time(), 100);
    }

    #[test]
    fn test_sort_events_by_time() {
        let mut events = vec![
            Event::NoteOff {
                t: 240,
                ch: 0,
                key: 60,
            },
            Event::NoteOn {
                t: 0,
                ch: 0,
                key: 60,
                vel: 96,
            },
            Event::Tempo { t: 0, bpm: 120 },
        ];

        sort_events_by_time(&mut events);

        assert_eq!(events[0].time(), 0);
        assert_eq!(events[1].time(), 0);
        assert_eq!(events[2].time(), 240);
    }
}
