# music-pipe-rs Development Plan

## Future Enhancements

### Duration Control Stage (`trim`)

**Problem**: When combining multiple MIDI event streams, the `viz` stage uses the maximum `End` time from all inputs. This creates trailing silence when percussion patterns (euclid) extend beyond melodic content.

**Example**: Valkyries demo has ~13s of musical content but generates a 52s WAV because euclid percussion patterns have a longer End time.

**Proposed Solution**: Add a `trim` stage with options:

```bash
# Trim silence from end (auto-detect last NoteOff + padding)
cat events.jsonl | trim --auto

# Force specific duration in seconds
cat events.jsonl | trim --duration 15

# Force specific duration in ticks
cat events.jsonl | trim --ticks 7200

# Use minimum End time from inputs (vs maximum)
cat a.jsonl b.jsonl | viz --end-mode min
```

**Implementation Notes**:
- `trim --auto`: Find last NoteOff event, add configurable padding (default 500ms), set End time
- `trim --duration`: Convert seconds to ticks using BPM from Tempo event (or assume 120 BPM)
- `--end-mode min` in viz: Alternative approach - use smallest End time when merging

**Status**: IMPLEMENTED in `crates/stage-trim/`

**Note**: The trim stage correctly adjusts the End event time in JSONL/MIDI, but FluidSynth adds reverb/decay padding (~40s) after the last note regardless of track duration. The musical content is correctly trimmed - only the rendered WAV has silent padding.

---

### Other Ideas

- [ ] `normalize` stage - boost MIDI velocities to use full 0-127 range
- [ ] `fade` stage - apply velocity fade in/out
- [ ] `transpose` stage - shift all notes by semitones
- [ ] `quantize` stage - snap notes to grid
- [ ] Web-based pipeline builder UI
