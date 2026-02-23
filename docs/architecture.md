# Architecture

## Overview

music-pipe-rs is a Cargo workspace containing multiple binary crates that communicate via JSONL (JSON Lines) streams. Each binary is a pipeline stage that reads events from stdin, transforms them, and writes events to stdout.

```
+----------+     +------------+     +-----------+     +----------+
|  motif   | --> | transpose  | --> | humanize  | --> | to-midi  |
+----------+     +------------+     +-----------+     +----------+
     |                |                   |                |
     v                v                   v                v
  Generate         Transform          Transform         Output
   JSONL            JSONL              JSONL            .mid
```

## Workspace Structure

```
music-pipe-rs/
|-- Cargo.toml              # Workspace root
|-- README.md
|-- docs/
|   |-- architecture.md     # This file
|   |-- prd.md              # Requirements
|   |-- design.md           # Design decisions
|   |-- plan.md             # Implementation plan
|   +-- status.md           # Current status
|-- crates/
|   |-- music-ir/           # Shared types library
|   |   |-- Cargo.toml
|   |   +-- src/
|   |       +-- lib.rs
|   |-- stage-motif/        # Motif generator
|   |   |-- Cargo.toml
|   |   +-- src/
|   |       +-- main.rs
|   |-- stage-transpose/    # Pitch transposition
|   |   |-- Cargo.toml
|   |   +-- src/
|   |       +-- main.rs
|   |-- stage-humanize/     # Timing/velocity variation
|   |   |-- Cargo.toml
|   |   +-- src/
|   |       +-- main.rs
|   +-- stage-to-midi/      # MIDI file output
|       |-- Cargo.toml
|       +-- src/
|           +-- main.rs
+-- examples/
    +-- demo.sh             # Example pipeline
```

## Data Flow

### Event Types (music-ir)

All stages communicate using these event types:

```rust
enum Event {
    NoteOn { t: u32, ch: u8, key: u8, vel: u8 },
    NoteOff { t: u32, ch: u8, key: u8 },
    Tempo { t: u32, bpm: u32 },
    End { t: u32 },
}
```

Fields:
- `t` - Absolute time in ticks
- `ch` - MIDI channel (0-15)
- `key` - MIDI note number (0-127)
- `vel` - Velocity (1-127)
- `bpm` - Beats per minute

### JSONL Format

Each event is a single JSON object on its own line:

```json
{"type":"Tempo","t":0,"bpm":120}
{"type":"NoteOn","t":0,"ch":0,"key":60,"vel":96}
{"type":"NoteOff","t":240,"ch":0,"key":60}
{"type":"NoteOn","t":240,"ch":0,"key":64,"vel":96}
{"type":"NoteOff","t":480,"ch":0,"key":64}
{"type":"End","t":480}
```

### Pipeline Execution

```bash
motif --base 60 --bpm 120 \
  | transpose --semitones 7 \
  | humanize --seed 42 --jitter-ticks 8 \
  | to-midi --out output.mid
```

## Crate Dependencies

```
music-ir (library)
    ^
    |
    +-- stage-motif
    +-- stage-transpose
    +-- stage-humanize
    +-- stage-to-midi
```

### External Dependencies

| Crate | Purpose | Used By |
|-------|---------|---------|
| serde | Serialization traits | music-ir |
| serde_json | JSON parsing/writing | music-ir |
| anyhow | Error handling | all |
| clap | CLI argument parsing | all stages |
| rand | Random number generation | stage-humanize |
| rand_chacha | Deterministic RNG | stage-humanize |
| midly | MIDI file writing | stage-to-midi |

## Design Principles

1. **Composability** - Each stage is a complete program that can be used independently
2. **Debuggability** - JSONL format allows inspection with jq, grep, head, etc.
3. **Determinism** - All randomness uses seeded RNG for reproducibility
4. **Simplicity** - MVP reads full stream into memory; streaming can be added later
5. **Unix Philosophy** - Do one thing well; combine tools for complex behavior

## Extension Points

### Adding New Stages

1. Create new crate in `crates/stage-<name>/`
2. Depend on `music-ir` for event types
3. Implement: read stdin -> transform -> write stdout
4. Add to workspace members in root `Cargo.toml`

### Adding New Event Types

1. Add variant to `Event` enum in `music-ir`
2. Handle in relevant stages (others can pass through unchanged)
3. Update `to-midi` to convert new events appropriately

### Future Architecture (Post-MVP)

- **note_id field** - Track NoteOn/NoteOff pairs through transforms
- **Streaming transforms** - Process events without full buffering
- **Binary format option** - For large compositions
- **Live output** - Direct MIDI port output instead of file
