//! mid2seq - Extract seq notation from MIDI files
//!
//! Standalone utility for extracting note sequences from MIDI files
//! in the format used by the `seq` stage.
//!
//! Output format: NOTES='C4/t480*96 [D4,F4]/t240*80 R/t120 ...'

use anyhow::{anyhow, Result};
use clap::Parser;
use midly::{MidiMessage, Smf, TrackEventKind};
use std::collections::BTreeMap;
use std::fs;
use std::path::PathBuf;

/// Extract seq notation from MIDI files
#[derive(Parser, Debug)]
#[command(name = "mid2seq")]
#[command(about = "Extract seq notation from MIDI files")]
#[command(version)]
struct Args {
    /// Input MIDI file
    input: PathBuf,

    /// Starting bar (1-indexed)
    #[arg(long, default_value_t = 1)]
    start_bar: u32,

    /// Number of bars to extract (0 = all remaining)
    #[arg(long, default_value_t = 0)]
    bars: u32,

    /// Override BPM (0 = use MIDI tempo)
    #[arg(long, default_value_t = 0)]
    bpm: u32,

    /// Target ticks per quarter note (for scaling)
    #[arg(long, default_value_t = 480)]
    tpq: u32,

    /// Time signature numerator (beats per bar)
    #[arg(long, default_value_t = 4)]
    beats_per_bar: u32,

    /// Track number to extract (0 = merge all tracks)
    #[arg(long, default_value_t = 0)]
    track: usize,

    /// Output as shell variable assignment
    #[arg(long, default_value_t = true)]
    shell: bool,

    /// Minimum gap (ticks) to insert rest
    #[arg(long, default_value_t = 10)]
    min_gap: u32,
}

/// A note event with timing
#[derive(Debug, Clone)]
struct NoteEvent {
    tick: u32,
    key: u8,
    vel: u8,
    duration: u32,
}

/// Convert MIDI note number to note name
fn midi_to_note_name(midi: u8) -> String {
    let note_names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"];
    let octave = (midi / 12) as i32 - 1;
    let note = (midi % 12) as usize;
    format!("{}{}", note_names[note], octave)
}

fn main() -> Result<()> {
    let args = Args::parse();

    // Read MIDI file
    let data = fs::read(&args.input)?;
    let smf = Smf::parse(&data)?;

    // Get ticks per quarter note from MIDI header
    let midi_tpq = match smf.header.timing {
        midly::Timing::Metrical(tpq) => tpq.as_int() as u32,
        _ => return Err(anyhow!("Only metrical timing supported")),
    };

    let scale = args.tpq as f64 / midi_tpq as f64;

    // Calculate tick range based on bars
    let ticks_per_bar = midi_tpq * args.beats_per_bar;
    let start_tick = (args.start_bar - 1) * ticks_per_bar;
    let end_tick = if args.bars > 0 {
        start_tick + args.bars * ticks_per_bar
    } else {
        u32::MAX
    };

    // Collect all note events from tracks
    let mut notes: Vec<NoteEvent> = Vec::new();
    let mut active_notes: BTreeMap<u8, (u32, u8)> = BTreeMap::new(); // key -> (start_tick, vel)

    let tracks_to_process: Vec<usize> = if args.track > 0 {
        vec![args.track - 1]
    } else {
        (0..smf.tracks.len()).collect()
    };

    for track_idx in tracks_to_process {
        if track_idx >= smf.tracks.len() {
            continue;
        }
        let track = &smf.tracks[track_idx];
        let mut tick: u32 = 0;
        active_notes.clear();

        for event in track {
            tick += event.delta.as_int() as u32;

            match event.kind {
                TrackEventKind::Midi { message, .. } => match message {
                    MidiMessage::NoteOn { key, vel } => {
                        let key = key.as_int();
                        let vel = vel.as_int();

                        if vel > 0 {
                            // Note on
                            if tick >= start_tick && tick < end_tick {
                                active_notes.insert(key, (tick, vel));
                            }
                        } else {
                            // Note off (vel=0)
                            if let Some((start, velocity)) = active_notes.remove(&key) {
                                let duration = tick.saturating_sub(start);
                                if start >= start_tick && start < end_tick {
                                    notes.push(NoteEvent {
                                        tick: ((start - start_tick) as f64 * scale).round() as u32,
                                        key,
                                        vel: velocity,
                                        duration: (duration as f64 * scale).round() as u32,
                                    });
                                }
                            }
                        }
                    }
                    MidiMessage::NoteOff { key, .. } => {
                        let key = key.as_int();
                        if let Some((start, velocity)) = active_notes.remove(&key) {
                            let duration = tick.saturating_sub(start);
                            if start >= start_tick && start < end_tick {
                                notes.push(NoteEvent {
                                    tick: ((start - start_tick) as f64 * scale).round() as u32,
                                    key,
                                    vel: velocity,
                                    duration: (duration as f64 * scale).round() as u32,
                                });
                            }
                        }
                    }
                    _ => {}
                },
                _ => {}
            }
        }
    }

    // Sort by tick, then by key
    notes.sort_by(|a, b| a.tick.cmp(&b.tick).then(a.key.cmp(&b.key)));

    if notes.is_empty() {
        eprintln!("No notes found in specified range");
        return Ok(());
    }

    // Group simultaneous notes into chords
    let mut output_parts: Vec<String> = Vec::new();
    let mut last_end_tick: u32 = 0;
    let mut i = 0;

    while i < notes.len() {
        let current_tick = notes[i].tick;

        // Insert rest if there's a gap
        if current_tick > last_end_tick + args.min_gap {
            let gap = current_tick - last_end_tick;
            output_parts.push(format!("R/t{}", gap));
        }

        // Collect all notes at the same tick
        let mut chord_notes: Vec<&NoteEvent> = vec![&notes[i]];
        let mut j = i + 1;
        while j < notes.len() && notes[j].tick == current_tick {
            chord_notes.push(&notes[j]);
            j += 1;
        }

        // Use the shortest duration and average velocity for the chord
        let duration = chord_notes.iter().map(|n| n.duration).min().unwrap_or(480);
        let avg_vel = chord_notes.iter().map(|n| n.vel as u32).sum::<u32>() / chord_notes.len() as u32;

        if chord_notes.len() == 1 {
            // Single note
            let note = chord_notes[0];
            output_parts.push(format!(
                "{}/t{}*{}",
                midi_to_note_name(note.key),
                duration,
                avg_vel
            ));
        } else {
            // Chord
            let note_names: Vec<String> = chord_notes
                .iter()
                .map(|n| midi_to_note_name(n.key))
                .collect();
            output_parts.push(format!(
                "[{}]/t{}*{}",
                note_names.join(","),
                duration,
                avg_vel
            ));
        }

        last_end_tick = current_tick + duration;
        i = j;
    }

    // Output
    let notes_str = output_parts.join(" ");

    if args.shell {
        println!("NOTES='{}'", notes_str);
        eprintln!();
        eprintln!("# {} notes, bars {}-{}",
            notes.len(),
            args.start_bar,
            if args.bars > 0 { args.start_bar + args.bars - 1 } else { 0 }
        );
        if args.bpm > 0 {
            eprintln!("# BPM={}", args.bpm);
        }
    } else {
        println!("{}", notes_str);
    }

    Ok(())
}
