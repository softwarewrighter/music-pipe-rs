//! Seed stage for music-pipe-rs
//!
//! Establishes a single random seed for the entire pipeline.
//! All downstream stages use this seed for deterministic randomness.

use anyhow::Result;
use clap::Parser;
use music_ir::{write_events_to_stdout, Event};
use std::time::{SystemTime, UNIX_EPOCH};

/// Establish a random seed for the pipeline.
///
/// Run this as the first stage to set a seed that all other stages will use.
/// If no seed is provided, a random seed is generated and printed to stderr.
///
/// Examples:
///   seed              # auto-generate seed, print to stderr
///   seed 12345        # use specific seed for reproducibility
///   seed 12345 | motif --notes 16 | humanize | to-midi --out out.mid
#[derive(Parser, Debug)]
#[command(name = "seed")]
#[command(about = "Set the random seed for the entire pipeline")]
#[command(version)]
struct Args {
    /// Random seed value.
    /// If omitted, generates from system time and prints to stderr.
    seed: Option<u64>,
}

fn main() -> Result<()> {
    let args = Args::parse();

    // Determine the seed
    let seed = args.seed.unwrap_or_else(|| {
        let auto_seed = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .map(|d| d.as_nanos() as u64)
            .unwrap_or(42);
        eprintln!("seed: {}", auto_seed);
        auto_seed
    });

    // Just emit the Seed event - this stage is always first in the pipeline
    let events = vec![Event::Seed { seed }];

    write_events_to_stdout(&events)
}
