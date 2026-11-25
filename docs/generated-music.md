# Generated music: video clips, game music, slide beds

Three Python scripts in `examples/` drive the pipeline stages to make finished
audio. They only use the Python standard library plus the stages in
`target/release`, fluidsynth, ffmpeg and sox. All seeds are fixed, so every
run reproduces the same files. Scripts are checked in; rendered audio is not
(everything goes to `work/`, which is gitignored except the preview page).

## Setup

```bash
cargo build --release
uv venv .venv
```

Tools: `fluidsynth`, `ffmpeg`, `sox` (game music Ogg files), and the soundfont
`~/github/softwarewrighter/midi-cli-rs/soundfonts/GeneralUser_GS.sf2`
(override with `SF2=/path/to/font.sf2`).

## 1. Upbeat video clips (10-15 s, one-shot)

```bash
.venv/bin/python examples/compose-upbeat.py
```

Nine pieces: five modern (neon-drive, disco-strut, pixel-quest, sunburst,
island-skank) and four ca. 1970 pre-disco / Loft-inspired (unity-train,
break-it-down, sunrise-drums, hammond-glide). Output: `work/preview/<name>.wav`
`.mid` `.png` `.json`, about -15 LUFS.

## 2. Game background music (loopable mood sets)

```bash
.venv/bin/python examples/game-music.py
```

Ten mood sets (calm, explore, sinister, battle, eerie, threat, puzzle, victory,
defeat, march). Each set has four separately composed phrases, each a
sample-exact seamless loop: A establish, B bed, C develop, D turnaround
(suggested plan A, B x2, C, D). Every set also has two tempo variants.

Compatibility contract, so switching sets is never jarring:

- every set is centred on D
- every phrase ends on an open A-sus chord; every set's A begins on D (V to I)
- tempos come from one family (72 / 96 / 108 / 144 BPM)
- one shared leitmotif, transformed per mode

Public-domain quotations (one per set, quiet, as a counter-melody) come from
`examples/pd-motifs.json`. **Bridges** are one-shot stingers for fast mood
changes: fade the current phrase at the next bar line (`bar_seconds`), start
the bridge, and start the target set's A at the bridge's `handoff_seconds`.

Output: `work/game-music/` with per-phrase `.wav` `.ogg` `.mid`, bridges,
transition demos, `tour.mp3` and `catalog.json` (sets, phrases, tempo variants,
quotes, bridges, contract) for the game to pick from.

## 3. Slide-transition beds (20-30 s, 5-second cells)

```bash
.venv/bin/python examples/video-beds.py
```

For videos that take 5-second windows of one clip for title and separator
slides: 0-5 for the opening, any n to n+5 for separators, L-5 to L for the
closing slide. Each clip is a run of 5-second cells:

| cell | role | content |
|---|---|---|
| first | motif | a public-domain tune stated plainly, downbeat at t = 0 |
| middle | bridges | answer phrase, dorian "shadow", lift to G, stop-time break; all different |
| last | denouement | the tune's head, final D chord struck 2.5 s before the end |

- 5 s is a whole number of bars (96 BPM: 2 bars, 144 BPM: 3 bars), so every
  cell start is a downbeat; at 96 BPM, 2.5-s steps are bar lines too.
- No bar repeats anywhere in a clip (the build prints `unique bars 1.00`).
- Every cell is levelled to the same loudness (-16 LUFS overall, true peak
  -1.5 dB), so any window can be used on its own.

Clips: sonata-sprint (Mozart K. 545), maple-strut (Joplin, Maple Leaf Rag),
soldiers-reel (Soldier's Joy), ode-arcade (Beethoven, Ode to Joy),
prelude-pulse (Bach, Prelude in C), minstrel-road (The Minstrel Boy).
Output: `work/video-beds/<clip>.wav` `.mid` `.png` and `catalog.json` (cell
start/end, role, description and loudness per cell).

Cut one window (8 ms edge fades; middle windows also get a 0.4 s fade-out):

```bash
examples/slice-5s.sh work/video-beds/soldiers-reel.wav first
examples/slice-5s.sh work/video-beds/soldiers-reel.wav 10
examples/slice-5s.sh work/video-beds/soldiers-reel.wav last
```

## Public-domain quotations

`examples/extract-pd-motifs.py` writes `examples/pd-motifs.json` from the
music21 corpus (only needed to change the quotations):

```bash
uv pip install --python .venv/bin/python music21
.venv/bin/python examples/extract-pd-motifs.py
```

All sources are pre-1900 or traditional: Bach (Passion Chorale, Prelude in C),
Handel (See the Conquering Hero Comes), Mozart (K. 545), Joplin (Maple Leaf
Rag), Niel Gow, and traditional tunes (The British Grenadiers, The Minstrel
Boy, The Water of Tyne, Soldier's Joy). The Dies irae (chant) and the Ode to
Joy theme are not in the corpus and are written out by hand in the script.

## Preview page

`work/index.html` shows everything on one page: table of contents, video
clips, slide beds (click a cell to hear its 5-second window), game sets with
quotes, transition demos and bridges. Serve `work/` with
[basic-http-server](https://crates.io/crates/basic-http-server), which supports
HTTP range requests (needed for audio seeking). It binds one address, so run
it on IPv4 and IPv6 for `localhost` to work everywhere:

```bash
cargo install basic-http-server
basic-http-server -a 127.0.0.1:9431 work &
basic-http-server -a "[::1]:9431" work &
open http://localhost:9431/
```
