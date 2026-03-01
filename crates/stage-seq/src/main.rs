//! Sequence stage for music-pipe-rs
//!
//! Accepts explicit note sequences using musical notation.
//!
//! Notation format:
//!   NOTE[ACCIDENTAL]OCTAVE[/DURATION][*VELOCITY]
//!   [NOTE,NOTE,...][/DURATION][*VELOCITY]  - chord (simultaneous notes)
//!
//! Duration formats:
//!   /N     - traditional: 1=whole, 2=half, 4=quarter, 8=eighth, 16, 32, 64, 128
//!   /tN    - tick-based: exact number of ticks (at 480 tpq, 480t = 1 beat)
//!   /bN.N  - beat-based: decimal beats (e.g., /b0.31 = 0.31 beats)
//!
//! Examples:
//!   D5         - D5 quarter note (default duration)
//!   C#5/8      - C# eighth note
//!   Bb3/2      - Bb half note
//!   D5/1*127   - D5 whole note, velocity 127
//!   R/4        - Quarter rest
//!   R/t120     - Rest for 120 ticks (= /16 at 480 tpq)
//!   R/b0.31    - Rest for 0.31 beats
//!   G#4/t149*73  - G#4 for 149 ticks, velocity 73
//!   [C4,E4,G4]/4     - C major chord, quarter note
//!   [G#3,C4,D#4]/8*80 - Ab major chord, eighth note, velocity 80

use anyhow::{anyhow, Result};
use clap::Parser;
use music_ir::{read_events_from_stdin, write_events_to_stdout, Event};

/// Explicit note sequence input
#[derive(Parser, Debug)]
#[command(name = "seq")]
#[command(about = "Input explicit note sequences")]
#[command(version)]
struct Args {
    /// Note sequence (space-separated)
    /// Format: NOTE[#/b]OCTAVE[/DURATION][*VEL] or R/DURATION for rests
    /// Duration: 1=whole, 2=half, 4=quarter, 8=eighth, 16=sixteenth, 32=32nd
    /// Example: "D5/2 C#5/16 D5/16 R/8 A4/4"
    #[arg(long, required = true)]
    notes: String,

    /// MIDI channel (0-15)
    #[arg(long, default_value_t = 0)]
    ch: u8,

    /// MIDI program/patch (0-127). 19=Church Organ
    #[arg(long)]
    patch: Option<u8>,

    /// Ticks per quarter note
    #[arg(long, default_value_t = 480)]
    tpq: u32,

    /// Tempo in beats per minute
    #[arg(long, default_value_t = 120)]
    bpm: u32,

    /// Default velocity (1-127)
    #[arg(long, default_value_t = 96)]
    vel: u8,
}

/// Parsed note from notation
#[derive(Debug)]
struct ParsedNote {
    /// MIDI note number (0-127), None for rest
    midi_note: Option<u8>,
    /// Duration in ticks
    duration_ticks: u32,
    /// Velocity (1-127)
    velocity: u8,
}

/// Parsed chord (multiple simultaneous notes)
#[derive(Debug)]
struct ParsedChord {
    /// MIDI note numbers
    midi_notes: Vec<u8>,
    /// Duration in ticks (same for all notes)
    duration_ticks: u32,
    /// Velocity (same for all notes)
    velocity: u8,
}

/// Parse note name to semitone offset (C=0, D=2, E=4, F=5, G=7, A=9, B=11)
fn note_to_semitone(note: char) -> Result<i32> {
    match note.to_ascii_uppercase() {
        'C' => Ok(0),
        'D' => Ok(2),
        'E' => Ok(4),
        'F' => Ok(5),
        'G' => Ok(7),
        'A' => Ok(9),
        'B' => Ok(11),
        _ => Err(anyhow!("Invalid note: {}", note)),
    }
}

/// Parse duration denominator to ticks (based on quarter note = tpq)
fn duration_to_ticks(denom: u32, tpq: u32) -> u32 {
    // 1=whole=4*tpq, 2=half=2*tpq, 4=quarter=tpq, 8=eighth=tpq/2, etc.
    (4 * tpq) / denom
}

/// Parse duration string to ticks, supporting multiple formats:
/// - "4" -> traditional denominator (quarter note)
/// - "t120" -> 120 ticks directly
/// - "b0.31" -> 0.31 beats
fn parse_duration_str(dur_str: &str, tpq: u32) -> Result<u32> {
    let dur_str = dur_str.trim();

    if dur_str.starts_with('t') || dur_str.starts_with('T') {
        // Tick-based: /t120
        let ticks: u32 = dur_str[1..]
            .parse()
            .map_err(|_| anyhow!("Invalid tick duration: {}", dur_str))?;
        Ok(ticks)
    } else if dur_str.starts_with('b') || dur_str.starts_with('B') {
        // Beat-based: /b0.31
        let beats: f64 = dur_str[1..]
            .parse()
            .map_err(|_| anyhow!("Invalid beat duration: {}", dur_str))?;
        Ok((beats * tpq as f64).round() as u32)
    } else {
        // Traditional denominator: /4, /8, /16
        let denom: u32 = dur_str
            .parse()
            .map_err(|_| anyhow!("Invalid duration: {}", dur_str))?;
        Ok(duration_to_ticks(denom, tpq))
    }
}

/// Parse a single note token
fn parse_note(token: &str, tpq: u32, default_vel: u8) -> Result<ParsedNote> {
    let token = token.trim();
    if token.is_empty() {
        return Err(anyhow!("Empty token"));
    }

    // Check for rest
    if token.starts_with('R') || token.starts_with('r') {
        let duration = if let Some(slash_pos) = token.find('/') {
            let dur_str = token[slash_pos + 1..]
                .split('*')
                .next()
                .unwrap();
            parse_duration_str(dur_str, tpq)?
        } else {
            tpq // default quarter note
        };

        return Ok(ParsedNote {
            midi_note: None,
            duration_ticks: duration,
            velocity: 0,
        });
    }

    // Parse note: NOTE[#/b]OCTAVE[/DURATION][*VELOCITY]
    let mut chars = token.chars().peekable();

    // Note letter (A-G)
    let note_char = chars.next().ok_or_else(|| anyhow!("Missing note"))?;
    let semitone = note_to_semitone(note_char)?;

    // Optional accidental
    let accidental = match chars.peek() {
        Some('#') => {
            chars.next();
            1
        }
        Some('b') => {
            chars.next();
            -1
        }
        _ => 0,
    };

    // Octave number
    let octave_char = chars.next().ok_or_else(|| anyhow!("Missing octave in: {}", token))?;
    let octave: i32 = octave_char
        .to_digit(10)
        .ok_or_else(|| anyhow!("Invalid octave in: {}", token))? as i32;

    // Calculate MIDI note: C4 = 60
    let midi_note = ((octave + 1) * 12 + semitone + accidental) as u8;

    // Remaining string for duration and velocity
    let remaining: String = chars.collect();

    // Parse duration
    let duration_ticks = if let Some(slash_pos) = remaining.find('/') {
        let dur_str = &remaining[slash_pos + 1..];
        let denom_str = dur_str.split('*').next().unwrap();
        parse_duration_str(denom_str, tpq)?
    } else {
        tpq // default quarter note
    };

    // Parse velocity
    let velocity = if let Some(star_pos) = remaining.find('*') {
        remaining[star_pos + 1..]
            .parse()
            .map_err(|_| anyhow!("Invalid velocity in: {}", token))?
    } else {
        default_vel
    };

    Ok(ParsedNote {
        midi_note: Some(midi_note),
        duration_ticks,
        velocity,
    })
}

/// Parse a single note name (without duration/velocity) to MIDI number
fn parse_note_name(s: &str) -> Result<u8> {
    let s = s.trim();
    if s.is_empty() {
        return Err(anyhow!("Empty note name"));
    }

    let mut chars = s.chars().peekable();

    // Note letter
    let note_char = chars.next().ok_or_else(|| anyhow!("Missing note"))?;
    let semitone = note_to_semitone(note_char)?;

    // Optional accidental
    let accidental = match chars.peek() {
        Some('#') => { chars.next(); 1 }
        Some('b') => { chars.next(); -1 }
        _ => 0,
    };

    // Octave
    let octave_char = chars.next().ok_or_else(|| anyhow!("Missing octave in: {}", s))?;
    let octave: i32 = octave_char
        .to_digit(10)
        .ok_or_else(|| anyhow!("Invalid octave in: {}", s))? as i32;

    Ok(((octave + 1) * 12 + semitone + accidental) as u8)
}

/// Parse a chord token: [C4,E4,G4]/4*80
fn parse_chord(token: &str, tpq: u32, default_vel: u8) -> Result<ParsedChord> {
    let token = token.trim();

    // Find the closing bracket
    let close_bracket = token.find(']')
        .ok_or_else(|| anyhow!("Missing ] in chord: {}", token))?;

    // Extract note names (between [ and ])
    let notes_str = &token[1..close_bracket];
    let mut midi_notes = Vec::new();

    for note_name in notes_str.split(',') {
        midi_notes.push(parse_note_name(note_name)?);
    }

    if midi_notes.is_empty() {
        return Err(anyhow!("Empty chord: {}", token));
    }

    // Parse duration and velocity from remainder
    let remainder = &token[close_bracket + 1..];

    let duration_ticks = if let Some(slash_pos) = remainder.find('/') {
        let dur_str = &remainder[slash_pos + 1..];
        let denom_str = dur_str.split('*').next().unwrap();
        parse_duration_str(denom_str, tpq)?
    } else {
        tpq // default quarter note
    };

    let velocity = if let Some(star_pos) = remainder.find('*') {
        remainder[star_pos + 1..]
            .parse()
            .map_err(|_| anyhow!("Invalid velocity in chord: {}", token))?
    } else {
        default_vel
    };

    Ok(ParsedChord {
        midi_notes,
        duration_ticks,
        velocity,
    })
}

fn main() -> Result<()> {
    let args = Args::parse();

    // Read any existing events from stdin (passthrough)
    let input_events = read_events_from_stdin().unwrap_or_default();

    let mut events = Vec::new();

    // Pass through existing events
    for event in &input_events {
        events.push(event.clone());
    }

    // Emit tempo event at start (skip if bpm is 0)
    if args.bpm > 0 {
        events.push(Event::Tempo {
            t: 0,
            bpm: args.bpm,
        });
    }

    // Emit program change if specified
    if let Some(program) = args.patch {
        events.push(Event::ProgramChange {
            t: 0,
            ch: args.ch,
            program,
        });
    }

    // Parse and emit notes
    let mut t = 0u32;
    for token in args.notes.split_whitespace() {
        // Check if this is a chord (starts with [)
        if token.starts_with('[') {
            let chord = parse_chord(token, args.tpq, args.vel)?;

            // All notes in chord start at same time
            for &midi_note in &chord.midi_notes {
                events.push(Event::NoteOn {
                    t,
                    ch: args.ch,
                    key: midi_note,
                    vel: chord.velocity,
                });
                events.push(Event::NoteOff {
                    t: t + chord.duration_ticks,
                    ch: args.ch,
                    key: midi_note,
                });
            }

            t += chord.duration_ticks;
        } else {
            let parsed = parse_note(token, args.tpq, args.vel)?;

            if let Some(midi_note) = parsed.midi_note {
                events.push(Event::NoteOn {
                    t,
                    ch: args.ch,
                    key: midi_note,
                    vel: parsed.velocity,
                });
                events.push(Event::NoteOff {
                    t: t + parsed.duration_ticks,
                    ch: args.ch,
                    key: midi_note,
                });
            }
            // Rests just advance time without notes

            t += parsed.duration_ticks;
        }
    }

    // End marker
    events.push(Event::End { t });

    write_events_to_stdout(&events)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_simple_note() {
        let note = parse_note("C4", 480, 96).unwrap();
        assert_eq!(note.midi_note, Some(60)); // C4 = 60
        assert_eq!(note.duration_ticks, 480); // quarter note
        assert_eq!(note.velocity, 96);
    }

    #[test]
    fn test_parse_note_with_duration() {
        let note = parse_note("D5/8", 480, 96).unwrap();
        assert_eq!(note.midi_note, Some(74)); // D5 = 74
        assert_eq!(note.duration_ticks, 240); // eighth note
    }

    #[test]
    fn test_parse_sharp() {
        let note = parse_note("C#4", 480, 96).unwrap();
        assert_eq!(note.midi_note, Some(61)); // C#4 = 61
    }

    #[test]
    fn test_parse_flat() {
        let note = parse_note("Bb3", 480, 96).unwrap();
        assert_eq!(note.midi_note, Some(58)); // Bb3 = 58
    }

    #[test]
    fn test_parse_rest() {
        let note = parse_note("R/4", 480, 96).unwrap();
        assert_eq!(note.midi_note, None);
        assert_eq!(note.duration_ticks, 480);
    }

    #[test]
    fn test_parse_velocity() {
        let note = parse_note("D5/4*127", 480, 96).unwrap();
        assert_eq!(note.midi_note, Some(74));
        assert_eq!(note.velocity, 127);
    }

    #[test]
    fn test_parse_whole_note() {
        let note = parse_note("D5/1", 480, 96).unwrap();
        assert_eq!(note.duration_ticks, 1920); // 4 * 480
    }

    #[test]
    fn test_parse_sixteenth() {
        let note = parse_note("D5/16", 480, 96).unwrap();
        assert_eq!(note.duration_ticks, 120); // 480/4
    }
}
