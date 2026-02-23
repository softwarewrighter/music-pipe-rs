# music-pipe-rs

A Unix-style pipeline engine for generative MIDI composition.

## Overview

music-pipe-rs provides small, composable command-line tools that transform MIDI events through Unix pipes. Each stage reads JSONL events from stdin, transforms them, and writes JSONL to stdout. The final stage converts to standard MIDI files.

```bash
motif --base 60 --bpm 120 \
  | transpose --semitones 7 \
  | humanize --seed 42 \
  | to-midi --out output.mid
```

## Features

- **Composable**: Chain stages with Unix pipes
- **Deterministic**: Seeded randomness for reproducible output
- **Debuggable**: JSONL format works with jq, grep, head
- **DAW-Compatible**: Outputs standard MIDI files
- **Copyright-Safe**: Algorithmic composition, no sample licensing

## Installation

```bash
# Clone the repository
git clone https://github.com/softwarewrighter/music-pipe-rs.git
cd music-pipe-rs

# Build all stages
cargo build --release

# Binaries are in target/release/
```

## Usage

### Generate a Simple Melody

```bash
./target/release/motif --base 60 --bpm 120 \
  | ./target/release/transpose --semitones 7 \
  | ./target/release/humanize --seed 123 \
  | ./target/release/to-midi --out melody.mid
```

### Inspect the Event Stream

```bash
# See raw JSONL events
./target/release/motif --base 60 | head

# Filter specific events
./target/release/motif --base 60 | grep NoteOn

# Pretty-print with jq
./target/release/motif --base 60 | jq .
```

### Available Stages

| Stage | Description |
|-------|-------------|
| `motif` | Generate simple musical motifs |
| `transpose` | Shift notes by N semitones |
| `humanize` | Add timing and velocity variation |
| `to-midi` | Convert JSONL stream to .mid file |

## Documentation

- [Product Requirements](docs/prd.md) - Vision and requirements
- [Architecture](docs/architecture.md) - System design and data flow
- [Design Decisions](docs/design.md) - Technical choices and rationale
- [Implementation Plan](docs/plan.md) - Task breakdown and milestones
- [Status](docs/status.md) - Current progress

### Development

- [AI Agent Instructions](docs/ai_agent_instructions.md) - Guidelines for AI coding agents
- [Development Process](docs/process.md) - Workflow and quality standards
- [Tools](docs/tools.md) - Recommended development tools

## Event Format

Stages communicate via JSONL (JSON Lines). Each event is a single JSON object:

```json
{"type":"Tempo","t":0,"bpm":120}
{"type":"NoteOn","t":0,"ch":0,"key":60,"vel":96}
{"type":"NoteOff","t":240,"ch":0,"key":60}
{"type":"End","t":480}
```

## Project Structure

```
music-pipe-rs/
|-- Cargo.toml              # Workspace root
|-- crates/
|   |-- music-ir/           # Shared event types
|   |-- stage-motif/        # Motif generator
|   |-- stage-transpose/    # Pitch transposition
|   |-- stage-humanize/     # Timing/velocity jitter
|   +-- stage-to-midi/      # MIDI file output
+-- docs/                   # Documentation
```

## Requirements

- Rust 1.70+ (2021 edition)
- No external runtime dependencies

## License

MIT

## Contributing

Contributions welcome. Please follow the [development process](docs/process.md).
