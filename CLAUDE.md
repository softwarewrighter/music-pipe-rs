# Claude Code Instructions

## SoundFont for Audio Rendering

**Always use this soundfont:**
```bash
SF2="${HOME}/github/softwarewrighter/midi-cli-rs/soundfonts/GeneralUser_GS.sf2"
fluidsynth -ni -F output.wav "$SF2" input.mid
```

Do NOT use `/usr/local/share/soundfonts/default.sf2` - it doesn't exist.

## CRITICAL: Python Environment Rules

**NEVER use `pip3 install` directly. NEVER pollute the global Python environment.**

Always use `uv` for Python package management:
```bash
# Create a virtual environment
uv venv .venv

# Activate it
source .venv/bin/activate

# Install packages
uv pip install mido  # or whatever package needed
```

This is non-negotiable. Global Python pollution breaks system tools and causes hard-to-debug issues.

## Demo Pages Workflow

The demo site is at https://softwarewrighter.github.io/music-pipe-rs/

### CRITICAL: Copy-Paste Requirement

**ALL code examples in demo pages MUST be complete and copy-pasteable.**

- NEVER use `...` or ellipses to abbreviate commands
- NEVER omit details for brevity
- The ENTIRE PURPOSE of showing commands is to support copy-paste from web UI to command line
- If a NOTES string is long, include the FULL string - users need working commands, not examples

### File Structure
- `pages/index.html` - The ONLY HTML file for the demo site (deployed to GitHub Pages)
- `pages/*.wav` - Audio files for demos
- `.github/workflows/pages.yml` - Deploys on changes to `pages/**`

### Updating Demo Pages

1. **Edit `pages/index.html` directly** - there is no separate preview/ directory
2. **Update cache-busting timestamp** when changing audio files:
   ```bash
   TS=$(date +%s)000
   sed -i '' "s/\.wav?ts=[0-9]*/\.wav?ts=${TS}/g" pages/index.html
   ```
3. **Copy new WAV files** to pages/:
   ```bash
   cp examples/demo-*.wav pages/
   ```
4. **Commit and push** - deployment triggers automatically on `pages/**` changes

### Cache-Busting Headers
The HTML includes these meta tags to prevent caching:
```html
<meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate">
<meta http-equiv="Pragma" content="no-cache">
<meta http-equiv="Expires" content="0">
```

Audio files use `?ts=<timestamp>` query strings for cache-busting.

### Tab Structure
Each composer has a tab in the HTML. The Wagner tab includes:
- Ride of the Valkyries (authentic melody with `seq` stage)
- Wagner-esque (algorithmic with `motif` stage)

### Common Issues
- **Changes not showing**: Update the `?ts=` timestamp on audio files
- **Wrong file edited**: Only edit `pages/index.html`, not `preview/`
- **Deployment not triggered**: Ensure changes are in `pages/` directory

## Pipeline Stages

### trim
Removes trailing silence from event streams:
```bash
cat events.jsonl | trim --auto              # Auto-detect end + 500ms padding
cat events.jsonl | trim --duration 15       # Force 15 seconds
cat events.jsonl | trim --ticks 7200        # Force specific tick count
```

**Important**: `trim` adjusts the MIDI End event, but FluidSynth ignores it and adds ~40s padding. Use ffmpeg to trim the rendered WAV:
```bash
# In demo scripts, after fluidsynth:
ffmpeg -y -i raw.wav -t 14 -af "afade=t=out:st=12:d=2" output.wav
```

### seq
Explicit note sequences:
```bash
seq --notes "C4/4 D4/8 E4/8 F4/2" --bpm 120 --ch 0 --patch 0
```

### euclid
Euclidean rhythm patterns:
```bash
seed 42 | euclid --steps 16 --pulses 4 --note 36 --ch 9
```

### viz
Merges multiple JSONL streams and displays ASCII visualization:
```bash
cat a.jsonl b.jsonl | viz > combined.jsonl
```
