# Design Document

## Design Decisions

This document captures key design decisions and their rationale.

---

### Decision 1: JSONL as Intermediate Representation

**Choice**: Use JSON Lines (one JSON object per line) for inter-stage communication.

**Alternatives Considered**:
- Binary protocol (MessagePack, protobuf)
- CSV
- Custom text format

**Rationale**:
- Human-readable for debugging
- Compatible with standard Unix tools (jq, grep, head, tail)
- Self-describing (no schema synchronization needed)
- Trivial to implement with serde_json
- MIDI events are sparse; JSONL overhead is acceptable

**Trade-offs**:
- Slightly verbose (mitigated by low event density in typical MIDI)
- Parse overhead (acceptable for file-based workflows)

---

### Decision 2: Absolute Time in Ticks

**Choice**: Events use absolute time (`t` field) in ticks, not delta time.

**Alternatives Considered**:
- Delta time (time since last event)
- Wall-clock time (seconds/milliseconds)

**Rationale**:
- Easier to reason about when debugging
- Transforms don't need to maintain running totals
- Sorting by `t` restores correct order after any transform
- MIDI file conversion handles delta time conversion

**Trade-offs**:
- Requires sorting after transforms that modify timing
- Slightly larger numbers in JSON

---

### Decision 3: Separate Binary per Stage

**Choice**: Each stage is a separate binary in the workspace.

**Alternatives Considered**:
- Single binary with subcommands (`music-pipe motif | music-pipe transpose`)
- Library-only approach (user writes Rust code)

**Rationale**:
- True Unix philosophy: small tools that do one thing
- Each binary is independently testable
- Can add stages without modifying existing code
- Clearer separation of concerns
- Easier to understand each component

**Trade-offs**:
- Multiple binaries to distribute
- Repeated setup code (mitigated by music-ir library)

---

### Decision 4: Deterministic Randomness with ChaCha8

**Choice**: Use `rand_chacha::ChaCha8Rng` with user-provided seeds.

**Alternatives Considered**:
- System RNG (non-deterministic)
- Other seeded RNGs (Xorshift, PCG)

**Rationale**:
- Reproducible output is essential for music production
- ChaCha8 is cryptographically secure (overkill but proven)
- Same seed produces same output across platforms
- Fast enough for MIDI event volumes

**Trade-offs**:
- Requires users to remember seeds for reproduction
- Slightly more dependencies

---

### Decision 5: Full Buffer Before Output

**Choice**: MVP stages read entire event stream into memory before processing.

**Alternatives Considered**:
- True streaming (process line-by-line)
- Windowed processing (buffer N events)

**Rationale**:
- Simpler implementation for MVP
- MIDI files are small (kilobytes, not gigabytes)
- Some operations (sort, humanize) need full context
- Easy to optimize later without API changes

**Trade-offs**:
- Memory usage scales with event count
- Not suitable for infinite streams (live performance)

---

### Decision 6: midly for MIDI Output

**Choice**: Use the `midly` crate for MIDI file writing.

**Alternatives Considered**:
- `rimd` (older, less maintained)
- `ghakuf` (Japanese documentation)
- Custom MIDI writer

**Rationale**:
- Well-maintained with recent updates
- Good API for both reading and writing
- Handles variable-length quantities correctly
- Zero-copy parsing (though we only need writing)

**Trade-offs**:
- API requires some type conversions (.into())

---

### Decision 7: Event Enum with Tagged Serialization

**Choice**: Single `Event` enum with serde's internally tagged representation.

```rust
#[serde(tag = "type")]
enum Event {
    NoteOn { ... },
    NoteOff { ... },
    ...
}
```

**Alternatives Considered**:
- Externally tagged (`{"NoteOn": {...}}`)
- Adjacently tagged (`{"type": "NoteOn", "data": {...}}`)
- Separate structs per event type

**Rationale**:
- Clean JSON: `{"type":"NoteOn","t":0,...}`
- Easy to grep for specific event types
- Single match handles all events
- Extensible: add new variants without breaking existing stages

**Trade-offs**:
- All event fields must be at same level (no nesting)

---

### Decision 8: No Configuration Files

**Choice**: All configuration via command-line arguments.

**Alternatives Considered**:
- TOML/YAML config files
- Environment variables
- Pipeline definition files

**Rationale**:
- Simple and explicit
- Easy to see full pipeline in shell history
- No hidden state affecting behavior
- Scriptable without config file management

**Trade-offs**:
- Long command lines for complex setups
- Can use shell scripts to save common pipelines

---

## Future Design Considerations

### note_id for Event Pairing

When transforms become more complex (split notes, merge notes), we'll need to track NoteOn/NoteOff pairs:

```rust
NoteOn { t: u32, ch: u8, key: u8, vel: u8, note_id: u64 },
NoteOff { t: u32, ch: u8, key: u8, note_id: u64 },
```

### Scale/Mode System

Future stages will need scale definitions:

```rust
enum Scale {
    Major,
    Minor,
    Dorian,
    // ...
}

struct ScaleContext {
    root: u8,      // Root note (0-11)
    scale: Scale,
}
```

### Control Change Events

For expression, we'll add:

```rust
ControlChange { t: u32, ch: u8, cc: u8, value: u8 },
PitchBend { t: u32, ch: u8, value: i16 },
```

### Streaming Architecture

For live performance, transform to iterator-based processing:

```rust
trait Stage {
    fn process(&mut self, event: Event) -> Vec<Event>;
    fn flush(&mut self) -> Vec<Event>;
}
```
