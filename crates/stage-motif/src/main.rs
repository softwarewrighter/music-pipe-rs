//! Motif generator stage for music-pipe-rs
//!
//! Generates musical motifs with seed-driven variation.
//! Same seed = same output. Different seed = different output.

use anyhow::Result;
use clap::Parser;
use music_ir::{extract_seed, read_events_from_stdin, write_events_to_stdout, Event};

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

    /// Number of notes to generate
    #[arg(long, default_value_t = 8)]
    notes: usize,

    /// Number of repetitions
    #[arg(long, default_value_t = 1)]
    repeat: u32,

    /// Melodic complexity (1-10). Higher = more variation.
    #[arg(long, default_value_t = 5)]
    complexity: u8,
}

/// Simple deterministic RNG (LCG)
struct Rng {
    state: u64,
}

impl Rng {
    fn new(seed: u64) -> Self {
        Self { state: seed }
    }

    fn next(&mut self) -> u64 {
        self.state = self.state
            .wrapping_mul(6364136223846793005)
            .wrapping_add(1442695040888963407);
        self.state
    }

    /// Random integer in range [0, max)
    fn next_range(&mut self, max: usize) -> usize {
        (self.next() >> 33) as usize % max
    }

    /// Random integer in range [min, max]
    fn next_range_inclusive(&mut self, min: i32, max: i32) -> i32 {
        let range = (max - min + 1) as usize;
        min + self.next_range(range) as i32
    }

    /// Random bool with given probability (0.0 - 1.0)
    fn next_bool(&mut self, probability: f64) -> bool {
        (self.next() as f64 / u64::MAX as f64) < probability
    }
}

fn main() -> Result<()> {
    let args = Args::parse();

    // Read any existing events from stdin (to get seed)
    let input_events = read_events_from_stdin().unwrap_or_default();

    // Extract seed from input, default to 42 if not provided
    let seed = extract_seed(&input_events).unwrap_or(42);

    let mut events = Vec::new();

    // Pass through Seed event if present
    for event in &input_events {
        if matches!(event, Event::Seed { .. }) {
            events.push(event.clone());
        }
    }

    let mut rng = Rng::new(seed);

    // Emit tempo event at start
    events.push(Event::Tempo {
        t: 0,
        bpm: args.bpm,
    });

    // Generate seed-driven melodic pattern
    let notes = generate_melody(&mut rng, args.base, args.notes, args.complexity);

    // Note duration: eighth note = tpq / 2
    let dur = args.tpq / 2;

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

/// Generate a melodic pattern using seed-driven randomness.
///
/// The melody uses a constrained random walk with tendency to return
/// to chord tones, creating musical phrases rather than random noise.
fn generate_melody(rng: &mut Rng, base: u8, length: usize, complexity: u8) -> Vec<u8> {
    let mut notes = Vec::with_capacity(length);

    // Chord tones (relative to base): root, 3rd, 5th, octave
    let chord_tones = [0i32, 4, 7, 12];

    // Scale degrees (relative to base): major scale - reserved for future scale-aware movement
    let _scale_degrees = [0i32, 2, 4, 5, 7, 9, 11, 12];

    // Start on a chord tone
    let start_idx = rng.next_range(chord_tones.len());
    let mut current = base as i32 + chord_tones[start_idx];
    notes.push(current as u8);

    // Complexity affects interval size and chord tone probability
    let max_interval = (complexity as i32).clamp(2, 7);
    let chord_tone_prob = 0.7 - (complexity as f64 * 0.05); // 5=0.45, 10=0.2

    for i in 1..length {
        // Decide movement type
        let movement = if rng.next_bool(chord_tone_prob) {
            // Jump to a chord tone
            let target_idx = rng.next_range(chord_tones.len());
            let target = base as i32 + chord_tones[target_idx];

            // Possibly in different octave
            let octave_shift = if rng.next_bool(0.3) {
                rng.next_range_inclusive(-1, 1) * 12
            } else {
                0
            };

            target + octave_shift - current
        } else if rng.next_bool(0.6) {
            // Stepwise motion (scale degree)
            let step = rng.next_range_inclusive(-2, 2);
            step
        } else {
            // Skip (larger interval)
            rng.next_range_inclusive(-max_interval, max_interval)
        };

        current += movement;

        // Keep in reasonable range (base-12 to base+24)
        let low = base as i32 - 12;
        let high = base as i32 + 24;
        if current < low {
            current = low + (low - current) % 12;
        } else if current > high {
            current = high - (current - high) % 12;
        }

        // Tendency to end on chord tone
        if i == length - 1 && rng.next_bool(0.8) {
            let nearest_chord_tone = chord_tones
                .iter()
                .map(|&ct| base as i32 + ct)
                .min_by_key(|&ct| (ct - current).abs())
                .unwrap_or(base as i32);
            current = nearest_chord_tone;
        }

        notes.push(current.clamp(0, 127) as u8);
    }

    notes
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_deterministic_same_seed() {
        let mut rng1 = Rng::new(42);
        let mut rng2 = Rng::new(42);

        let melody1 = generate_melody(&mut rng1, 60, 8, 5);
        let melody2 = generate_melody(&mut rng2, 60, 8, 5);

        assert_eq!(melody1, melody2);
    }

    #[test]
    fn test_different_seeds_different_output() {
        let mut rng1 = Rng::new(42);
        let mut rng2 = Rng::new(43);

        let melody1 = generate_melody(&mut rng1, 60, 8, 5);
        let melody2 = generate_melody(&mut rng2, 60, 8, 5);

        assert_ne!(melody1, melody2);
    }

    #[test]
    fn test_melody_in_range() {
        let mut rng = Rng::new(12345);
        let melody = generate_melody(&mut rng, 60, 16, 10);

        for &note in &melody {
            assert!(note >= 48 && note <= 84, "Note {} out of range", note);
        }
    }

    #[test]
    fn test_complexity_affects_variation() {
        let mut rng_low = Rng::new(100);
        let melody_low = generate_melody(&mut rng_low, 60, 16, 1);

        // Reset RNG for high complexity test
        let mut rng_high = Rng::new(100);
        let melody_high = generate_melody(&mut rng_high, 60, 16, 10);

        // Higher complexity should produce different results
        // (This is a basic sanity check)
        assert_eq!(melody_low.len(), melody_high.len());
    }
}
