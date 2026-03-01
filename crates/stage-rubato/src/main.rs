//! Rubato stage for music-pipe-rs
//!
//! Adds tempo variation (rubato) to make sequences sound more human.
//! Inserts Tempo events throughout the piece with slight BPM variations,
//! simulating the natural push-and-pull of human performance.

use anyhow::Result;
use clap::Parser;
use music_ir::{extract_seed, read_events_from_stdin, sort_events_by_time, write_events_to_stdout, Event};
use rand::{Rng, SeedableRng};
use rand_chacha::ChaCha8Rng;

/// Add tempo variation (rubato) to a sequence
#[derive(Parser, Debug)]
#[command(name = "rubato")]
#[command(about = "Add tempo variation for human-like expression")]
#[command(version)]
struct Args {
    /// Base tempo in BPM (will vary around this)
    #[arg(long, default_value_t = 100)]
    bpm: u32,

    /// Maximum tempo variation as percentage (e.g., 5 = ±5%)
    #[arg(long, default_value_t = 5)]
    variance: u32,

    /// Ticks per tempo change (how often to insert tempo events)
    /// Default 240 = every half beat at 480 tpq
    #[arg(long, default_value_t = 240)]
    interval: u32,

    /// Style of rubato: "random", "ragtime", "waltz"
    #[arg(long, default_value = "ragtime")]
    style: String,
}

fn main() -> Result<()> {
    let args = Args::parse();
    let mut events = read_events_from_stdin()?;

    // Use pipeline seed if present, otherwise default to 42
    let seed = extract_seed(&events).unwrap_or(42);
    let mut rng = ChaCha8Rng::seed_from_u64(seed);

    // Find the end time
    let end_time = events.iter()
        .filter_map(|e| match e {
            Event::End { t } => Some(*t),
            _ => None,
        })
        .max()
        .unwrap_or(0);

    // Remove existing tempo events (we'll insert our own)
    events.retain(|e| !matches!(e, Event::Tempo { .. }));

    // Insert tempo events at regular intervals
    let mut t = 0u32;
    let base_bpm = args.bpm as f64;
    let variance_pct = args.variance as f64 / 100.0;

    while t <= end_time {
        let tempo_variation = match args.style.as_str() {
            "ragtime" => {
                // Ragtime: slight acceleration into syncopated figures,
                // ritardando at phrase endings (every ~8 beats = 3840 ticks)
                let phrase_pos = (t % 3840) as f64 / 3840.0;
                let phrase_shape = if phrase_pos < 0.8 {
                    // Slightly push forward through phrase
                    0.02 * (phrase_pos * 2.0).sin()
                } else {
                    // Slow down at phrase end
                    -0.03 * ((phrase_pos - 0.8) * 5.0)
                };

                // Add random micro-variation
                let random_var: f64 = rng.gen_range(-variance_pct..=variance_pct);
                phrase_shape + random_var * 0.5
            }
            "waltz" => {
                // Waltz: slight emphasis on beat 1, lightness on 2-3
                let beat_pos = (t % 1440) as f64 / 1440.0; // 3 beats
                let waltz_shape = 0.02 * (beat_pos * 2.0 * std::f64::consts::PI).cos();
                let random_var: f64 = rng.gen_range(-variance_pct..=variance_pct);
                waltz_shape + random_var * 0.3
            }
            _ => {
                // Random: just random variation
                rng.gen_range(-variance_pct..=variance_pct)
            }
        };

        let bpm = (base_bpm * (1.0 + tempo_variation)).round() as u32;
        let bpm = bpm.clamp(60, 200); // Keep within reasonable range

        events.push(Event::Tempo { t, bpm });
        t += args.interval;
    }

    // Re-sort events
    sort_events_by_time(&mut events);

    write_events_to_stdout(&events)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_tempo_clamping() {
        // Just a basic sanity test
        let bpm = 100u32;
        let clamped = bpm.clamp(60, 200);
        assert_eq!(clamped, 100);
    }
}
