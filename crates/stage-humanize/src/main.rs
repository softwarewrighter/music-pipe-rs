//! Humanize stage for music-pipe-rs
//!
//! Adds timing and velocity variation to make sequences sound more human.
//! Uses deterministic random number generation for reproducible results.

use anyhow::Result;
use clap::Parser;
use music_ir::{read_events_from_stdin, sort_events_by_time, write_events_to_stdout, Event};
use rand::{Rng, SeedableRng};
use rand_chacha::ChaCha8Rng;

/// Add human-like variation to timing and velocity
#[derive(Parser, Debug)]
#[command(name = "humanize")]
#[command(about = "Add timing and velocity variation")]
#[command(version)]
struct Args {
    /// Random seed for reproducible results
    #[arg(long, default_value_t = 42)]
    seed: u64,

    /// Maximum timing jitter in ticks (+/-)
    #[arg(long, default_value_t = 8)]
    jitter_ticks: i32,

    /// Maximum velocity jitter (+/-)
    #[arg(long, default_value_t = 10)]
    jitter_vel: i16,
}

fn main() -> Result<()> {
    let args = Args::parse();
    let mut rng = ChaCha8Rng::seed_from_u64(args.seed);
    let mut events = read_events_from_stdin()?;

    for event in &mut events {
        match event {
            Event::NoteOn { t, vel, .. } => {
                // Apply timing jitter
                let dt = rng.gen_range(-args.jitter_ticks..=args.jitter_ticks);
                *t = apply_time_jitter(*t, dt);

                // Apply velocity jitter
                let dv = rng.gen_range(-args.jitter_vel..=args.jitter_vel);
                *vel = apply_velocity_jitter(*vel, dv);
            }
            Event::NoteOff { t, .. } => {
                // Apply timing jitter to note off as well
                let dt = rng.gen_range(-args.jitter_ticks..=args.jitter_ticks);
                *t = apply_time_jitter(*t, dt);
            }
            _ => {}
        }
    }

    // Re-sort events since timing may have changed order
    sort_events_by_time(&mut events);

    write_events_to_stdout(&events)
}

/// Apply timing jitter, clamping to minimum of 0
fn apply_time_jitter(t: u32, delta: i32) -> u32 {
    let new_t = t as i64 + delta as i64;
    new_t.max(0) as u32
}

/// Apply velocity jitter, clamping to valid range (1-127)
fn apply_velocity_jitter(vel: u8, delta: i16) -> u8 {
    let new_vel = vel as i16 + delta;
    new_vel.clamp(1, 127) as u8
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_time_jitter_positive() {
        assert_eq!(apply_time_jitter(100, 10), 110);
    }

    #[test]
    fn test_time_jitter_negative() {
        assert_eq!(apply_time_jitter(100, -10), 90);
    }

    #[test]
    fn test_time_jitter_clamp_zero() {
        assert_eq!(apply_time_jitter(5, -10), 0);
    }

    #[test]
    fn test_velocity_jitter_positive() {
        assert_eq!(apply_velocity_jitter(100, 10), 110);
    }

    #[test]
    fn test_velocity_jitter_clamp_high() {
        assert_eq!(apply_velocity_jitter(120, 20), 127);
    }

    #[test]
    fn test_velocity_jitter_clamp_low() {
        assert_eq!(apply_velocity_jitter(10, -20), 1);
    }

    #[test]
    fn test_deterministic_rng() {
        let mut rng1 = ChaCha8Rng::seed_from_u64(42);
        let mut rng2 = ChaCha8Rng::seed_from_u64(42);

        let v1: i32 = rng1.gen_range(-10..=10);
        let v2: i32 = rng2.gen_range(-10..=10);

        assert_eq!(v1, v2);
    }
}
