# Implementation Plan

## Overview

This document tracks the implementation tasks for music-pipe-rs MVP.

## Phase 1: Foundation (MVP)

### 1.1 Project Setup

- [ ] Initialize Cargo workspace
- [ ] Create crates directory structure
- [ ] Add root Cargo.toml with workspace members
- [ ] Create .gitignore for Rust project
- [ ] Initial commit with documentation

### 1.2 music-ir Crate

- [ ] Create music-ir/Cargo.toml
- [ ] Define Event enum with serde serialization
- [ ] Implement read_events_from_stdin()
- [ ] Implement write_events_to_stdout()
- [ ] Add unit tests for serialization roundtrip
- [ ] Add doc comments

### 1.3 stage-motif

- [ ] Create stage-motif/Cargo.toml with [[bin]] section
- [ ] Implement CLI args (base, ch, tpq, bpm)
- [ ] Generate simple arpeggio motif
- [ ] Output JSONL to stdout
- [ ] Add --help documentation
- [ ] Test: verify valid JSONL output

### 1.4 stage-transpose

- [ ] Create stage-transpose/Cargo.toml
- [ ] Implement CLI args (semitones)
- [ ] Read events from stdin
- [ ] Apply transposition with clamping (0-127)
- [ ] Write events to stdout
- [ ] Test: transpose up/down, edge cases

### 1.5 stage-humanize

- [ ] Create stage-humanize/Cargo.toml
- [ ] Implement CLI args (seed, jitter-ticks, jitter-vel)
- [ ] Initialize ChaCha8Rng from seed
- [ ] Apply timing jitter to NoteOn/NoteOff
- [ ] Apply velocity jitter to NoteOn
- [ ] Sort events by time after modification
- [ ] Test: determinism with same seed

### 1.6 stage-to-midi

- [ ] Create stage-to-midi/Cargo.toml
- [ ] Implement CLI args (out, tpq)
- [ ] Read events from stdin
- [ ] Build midly SMF structure
- [ ] Convert absolute time to delta time
- [ ] Handle Tempo events (microseconds per quarter)
- [ ] Write .mid file
- [ ] Test: output plays in DAW

### 1.7 Integration

- [ ] Create examples/demo.sh with full pipeline
- [ ] End-to-end test: motif | transpose | humanize | to-midi
- [ ] Verify output.mid in MIDI player/DAW
- [ ] Document pipeline usage in README

### 1.8 Quality

- [ ] All crates pass `cargo test`
- [ ] All crates pass `cargo clippy -- -D warnings`
- [ ] All code formatted with `cargo fmt`
- [ ] All docs pass markdown-checker

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
