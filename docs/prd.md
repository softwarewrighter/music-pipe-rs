# Product Requirements Document (PRD)

## Overview

**Project**: music-pipe-rs
**Version**: 0.1.0 (MVP)
**Status**: Planning

## Vision

A Unix-style pipeline engine for generative MIDI composition. Small, composable command-line tools that read JSONL event streams, transform them, and produce standard MIDI output.

## Problem Statement

Most generative music tools are:
- Monolithic (single applications with closed workflows)
- Black-box AI/ML systems (non-deterministic, non-explainable)
- Sample-based (licensing concerns for commercial use)
- DAW-centric (require expensive software)

Musicians and developers need:
- Composable tools that can be chained together
- Deterministic, reproducible output (--seed support)
- Algorithmic composition (copyright-safe, no sample licensing)
- CLI-first workflows that integrate with existing tools

## Target Users

1. **Electronic Musicians** - Looking for generative tools that produce MIDI for their DAW
2. **Creative Coders** - Want programmable music generation
3. **Live Performers** - Need reproducible, deterministic sequences
4. **Music Researchers** - Exploring algorithmic composition techniques

## Core Requirements

### MVP (Phase 1)

1. **JSONL Event Stream Format**
   - Standard intermediate representation
   - Human-readable and debuggable
   - Compatible with jq, grep, awk for inspection
   - Events: NoteOn, NoteOff, Tempo, End

2. **Stage: motif**
   - Generate simple musical motifs
   - Configurable base note, channel, BPM
   - Deterministic output

3. **Stage: transpose**
   - Shift all notes by N semitones
   - Handle MIDI range limits (0-127)

4. **Stage: humanize**
   - Add timing and velocity variation
   - Deterministic via --seed parameter
   - Configurable jitter amounts

5. **Stage: to-midi**
   - Convert JSONL stream to standard MIDI file
   - Configurable ticks-per-quarter-note
   - Produce valid .mid files playable in any DAW

6. **Pipeline Composability**
   - Each stage reads stdin, writes stdout
   - Stages can be combined with Unix pipes
   - Example: `motif | transpose | humanize | to-midi`

### Phase 2 (Post-MVP)

1. **Stage: euclid** - Euclidean rhythm generator
2. **Stage: scale-lock** - Constrain pitches to a scale/mode
3. **Stage: quantize** - Grid quantization with swing
4. **Stage: arpeggio** - Arpeggiator patterns
5. **Stage: chord** - Chord generation from root notes

### Phase 3 (Future)

1. **Live MIDI output** - Real-time streaming to MIDI ports
2. **MIDI clock sync** - Synchronize with external gear
3. **Grammar-based generation** - L-systems, Markov chains
4. **Visualization** - DAG composition model viewer

## Non-Goals (MVP)

- Audio synthesis (this is MIDI-only)
- GUI interface
- DAW plugin format (VST/AU)
- Real-time input processing
- ML/AI-based generation

## Technical Constraints

- Written in Rust (performance, safety)
- Single workspace with multiple binary crates
- No external runtime dependencies (self-contained binaries)
- Cross-platform (macOS, Linux, Windows)

## Success Criteria (MVP)

1. Can generate a valid MIDI file with the full pipeline
2. Output is deterministic with same --seed
3. Each stage works independently and composes correctly
4. Documentation enables new users to build custom pipelines
5. Code passes all quality checks (tests, clippy, fmt)

## Dependencies

- `clap` - CLI argument parsing
- `serde`, `serde_json` - JSONL serialization
- `anyhow` - Error handling
- `rand`, `rand_chacha` - Deterministic randomness
- `midly` - MIDI file writing

## Risks

| Risk | Mitigation |
|------|------------|
| Event ordering after transforms | Sort by timestamp after each stage |
| NoteOn/NoteOff pairing breaks | Add note_id field in Phase 2 |
| JSONL verbosity for large files | Acceptable for MIDI densities; binary format later if needed |
| Humanize causes negative timestamps | Clamp to 0 minimum |

## References

- [midly crate](https://crates.io/crates/midly) - MIDI file handling
- [Euclidean rhythms](https://en.wikipedia.org/wiki/Euclidean_rhythm) - Future rhythm generation
- [Opusmodus](https://opusmodus.com/) - Inspiration for compositional DSL
