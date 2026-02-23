# Implementation Plan

## Overview

This document tracks the implementation tasks for music-pipe-rs MVP.

## Phase 1: Foundation (MVP)

### 1.1 Project Setup

- [x] Initialize Cargo workspace
- [x] Create crates directory structure
- [x] Add root Cargo.toml with workspace members
- [x] Create .gitignore for Rust project
- [x] Initial commit with documentation

### 1.2 music-ir Crate

- [x] Create music-ir/Cargo.toml
- [x] Define Event enum with serde serialization
- [x] Implement read_events_from_stdin()
- [x] Implement write_events_to_stdout()
- [x] Add unit tests for serialization roundtrip
- [x] Add doc comments

### 1.3 stage-motif

- [x] Create stage-motif/Cargo.toml with [[bin]] section
- [x] Implement CLI args (base, ch, tpq, bpm)
- [x] Generate simple arpeggio motif
- [x] Output JSONL to stdout
- [x] Add --help documentation
- [x] Test: verify valid JSONL output

### 1.4 stage-transpose

- [x] Create stage-transpose/Cargo.toml
- [x] Implement CLI args (semitones)
- [x] Read events from stdin
- [x] Apply transposition with clamping (0-127)
- [x] Write events to stdout
- [x] Test: transpose up/down, edge cases

### 1.5 stage-humanize

- [x] Create stage-humanize/Cargo.toml
- [x] Implement CLI args (seed, jitter-ticks, jitter-vel)
- [x] Initialize ChaCha8Rng from seed
- [x] Apply timing jitter to NoteOn/NoteOff
- [x] Apply velocity jitter to NoteOn
- [x] Sort events by time after modification
- [x] Test: determinism with same seed

### 1.6 stage-to-midi

- [x] Create stage-to-midi/Cargo.toml
- [x] Implement CLI args (out, tpq)
- [x] Read events from stdin
- [x] Build midly SMF structure
- [x] Convert absolute time to delta time
- [x] Handle Tempo events (microseconds per quarter)
- [x] Write .mid file
- [x] Test: output plays in DAW

### 1.7 Integration

- [x] Create examples/demo.sh with full pipeline
- [x] End-to-end test: motif | transpose | humanize | to-midi
- [x] Verify output.mid in MIDI player/DAW
- [x] Document pipeline usage in README

### 1.8 Quality

- [x] All crates pass `cargo test`
- [x] All crates pass `cargo clippy -- -D warnings`
- [x] All code formatted with `cargo fmt`
- [x] All docs pass markdown-checker

## Phase 2: Extended Stages (Post-MVP)

### 2.1 stage-euclid

- [ ] Euclidean rhythm generator
- [ ] Parameters: steps, pulses, rotation
- [ ] Output pattern of NoteOn/NoteOff events

### 2.2 stage-scale

- [ ] Lock pitches to scale/mode
- [ ] Parameters: root, scale name
- [ ] Round notes to nearest scale degree

### 2.3 stage-quantize

- [ ] Grid quantization
- [ ] Parameters: grid division, swing amount
- [ ] Snap note times to grid

### 2.4 stage-arpeggio

- [ ] Arpeggiator patterns
- [ ] Parameters: pattern type, rate
- [ ] Transform chord to arpeggiated notes

### 2.5 stage-chord

- [ ] Generate chords from root notes
- [ ] Parameters: chord type (major, minor, 7th, etc.)
- [ ] Output multiple notes per input

## Phase 3: Advanced Features (Future)

### 3.1 Live Output

- [ ] Real-time MIDI port output
- [ ] MIDI clock sync
- [ ] Streaming event processing

### 3.2 Generative Engines

- [ ] Markov chain generator
- [ ] L-system composer
- [ ] Cellular automata rhythms

### 3.3 note_id System

- [ ] Add note_id to events
- [ ] Track NoteOn/NoteOff pairs
- [ ] Enable advanced transforms (split, merge)

## Dependencies by Phase

### Phase 1 (MVP)
```toml
[dependencies]
clap = { version = "4", features = ["derive"] }
serde = { version = "1", features = ["derive"] }
serde_json = "1"
anyhow = "1"
rand = "0.8"
rand_chacha = "0.3"
midly = "0.5"
```

### Phase 2
```toml
# No additional dependencies expected
```

### Phase 3
```toml
midir = "0.9"  # For live MIDI output
```

## Milestones

| Milestone | Description | Target |
|-----------|-------------|--------|
| M1 | Project structure and music-ir | Day 1 |
| M2 | All four MVP stages working | Day 2-3 |
| M3 | End-to-end pipeline produces valid MIDI | Day 3 |
| M4 | Documentation and quality checks | Day 4 |
| MVP | First usable release | Day 4 |

## Notes

- Start with simplest implementation; optimize later
- Test each stage in isolation before integration
- Keep stages focused: one transformation per stage
- Document CLI help text thoroughly
