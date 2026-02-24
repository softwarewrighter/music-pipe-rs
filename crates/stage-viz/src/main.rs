//! Visualization stage for music-pipe-rs
//!
//! Prints a sparkline-style visualization of notes to stderr,
//! then passes events through to stdout unchanged.

use anyhow::Result;
use clap::Parser;
use music_ir::{read_events_from_stdin, write_events_to_stdout, Event};

/// Visualize notes as a sparkline
#[derive(Parser, Debug)]
#[command(name = "viz")]
#[command(about = "Print sparkline visualization of notes (to stderr)")]
#[command(version)]
struct Args {
    /// Width of the visualization
    #[arg(long, default_value_t = 60)]
    width: usize,

    /// Show piano roll instead of sparkline
    #[arg(long)]
    roll: bool,
}

// Sparkline characters (8 levels)
const SPARKS: [char; 8] = ['▁', '▂', '▃', '▄', '▅', '▆', '▇', '█'];

// Note names
const NOTE_NAMES: [&str; 12] = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"];

fn main() -> Result<()> {
    let args = Args::parse();
    let events = read_events_from_stdin()?;

    // Extract NoteOn events
    let notes: Vec<(u32, u8)> = events
        .iter()
        .filter_map(|e| match e {
            Event::NoteOn { t, key, .. } => Some((*t, *key)),
            _ => None,
        })
        .collect();

    if notes.is_empty() {
        eprintln!("(no notes)");
    } else if args.roll {
        print_piano_roll(&notes);
    } else {
        print_sparkline(&notes, args.width);
    }

    // Pass through all events
    write_events_to_stdout(&events)
}

fn print_sparkline(notes: &[(u32, u8)], width: usize) {
    let keys: Vec<u8> = notes.iter().map(|(_, k)| *k).collect();
    let min_key = *keys.iter().min().unwrap();
    let max_key = *keys.iter().max().unwrap();
    let range = (max_key - min_key).max(1) as f32;

    // Print note range
    let min_name = format!("{}{}", NOTE_NAMES[(min_key % 12) as usize], min_key / 12);
    let max_name = format!("{}{}", NOTE_NAMES[(max_key % 12) as usize], max_key / 12);

    // Build sparkline
    let spark: String = keys
        .iter()
        .take(width)
        .map(|&k| {
            let level = ((k - min_key) as f32 / range * 7.0).round() as usize;
            SPARKS[level.min(7)]
        })
        .collect();

    eprintln!("{} {} {}", min_name, spark, max_name);
}

fn print_piano_roll(notes: &[(u32, u8)]) {
    let keys: Vec<u8> = notes.iter().map(|(_, k)| *k).collect();
    let min_key = *keys.iter().min().unwrap();
    let max_key = *keys.iter().max().unwrap();

    // Build a set of (time_index, key) for quick lookup
    let note_set: std::collections::HashSet<(usize, u8)> = notes
        .iter()
        .enumerate()
        .map(|(i, (_, k))| (i, *k))
        .collect();

    // Print from high to low
    for key in (min_key..=max_key).rev() {
        let name = format!("{:>2}{}", NOTE_NAMES[(key % 12) as usize], key / 12);
        let row: String = (0..notes.len().min(50))
            .map(|i| if note_set.contains(&(i, key)) { '█' } else { '·' })
            .collect();
        eprintln!("{} │{}│", name, row);
    }
}
