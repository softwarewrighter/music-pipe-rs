#!/usr/bin/env python3
"""Compose short upbeat pieces (10-15 s) with the music-pipe-rs stages.

Every part is written in `seq` notation and piped through `seed N | humanize`;
extra percussion layers come from `seed N | euclid`. Everything is merged with
`viz`, converted with `to-midi`, rendered with fluidsynth, then trimmed and
loudness-normalized with ffmpeg. All seeds are fixed, so output is
bit-for-bit reproducible.

Set 1 (modern):  neon, disco, pixel, sunburst, skank
Set 2 (ca. 1970 pre-disco / Loft-inspired):  unity, breakit, sunrise, hammond

Requirements: `cargo build --release`, fluidsynth, ffmpeg, and the
GeneralUser GS soundfont (see CLAUDE.md), or set SF2=/path/to/font.sf2.
Only the Python standard library is used.

Usage (from the repo root):
    uv venv .venv
    .venv/bin/python examples/compose-upbeat.py              # all pieces
    .venv/bin/python examples/compose-upbeat.py unity neon   # some pieces

Output goes to work/preview/ (gitignored); override with OUT_DIR=... .
It contains <name>.wav/.mid/.png/.json plus index.html. The all-in-one preview
page is work/index.html; see docs/generated-music.md for serving it with
basic-http-server.
"""
import json
import os
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BIN = ROOT / "target" / "release"
OUT = Path(os.environ.get("OUT_DIR", ROOT / "work" / "preview")).resolve()
TMP = ROOT / "work" / "tmp"
SF2 = os.environ.get(
    "SF2",
    str(Path.home() / "github/softwarewrighter/midi-cli-rs/soundfonts/GeneralUser_GS.sf2"),
)

TPQ = 480
BAR = TPQ * 4
E8, E16, Q, H = 240, 120, 480, 960


# --------------------------------------------------------------------------
# seq-notation helpers
# --------------------------------------------------------------------------
def tok(note, ticks, vel=None):
    """One seq token. note: None (rest), 'C4', or list of notes (chord)."""
    if note is None:
        return f"R/t{ticks}"
    n = f"[{','.join(note)}]" if isinstance(note, (list, tuple)) else note
    return f"{n}/t{ticks}" + (f"*{vel}" if vel else "")


def melody(text, vel=90):
    """'C5/8 D5/16 R/4 ...' with musical durations -> tick tokens (allows *vel)."""
    durs = {"1": 1920, "2": 960, "4": 480, "8": 240, "16": 120, "4.": 720, "8.": 360, "2.": 1440}
    out = []
    for t in text.split():
        v = vel
        if "*" in t:
            t, v = t.split("*")
            v = int(v)
        n, d = t.split("/")
        out.append(tok(None if n == "R" else n, durs[d], None if n == "R" else v))
    return " ".join(out)


def drum_voice(note, patterns, step=E16):
    """patterns: list of per-bar strings; X=accent x=normal g=ghost .=rest."""
    vel = {"X": 112, "x": 92, "g": 55, "o": 75}
    toks = []
    for bar in patterns:
        for c in bar:
            toks.append(tok(note, step, vel[c]) if c in vel else tok(None, step))
    return " ".join(toks)


# --------------------------------------------------------------------------
# pipeline helpers
# --------------------------------------------------------------------------
def run(cmd, stdin=None):
    r = subprocess.run(cmd, input=stdin if stdin is not None else "", capture_output=True, text=True)
    if r.returncode != 0:
        sys.exit(f"FAILED: {' '.join(map(str, cmd))[:300]}\n{r.stderr}")
    return r.stdout


SWING = 0  # ticks to delay off-beat 16ths (set per piece; 0 = straight)


def swing(events, amt=None):
    """Delay every event that falls on an off-beat 16th (t % 240 == 120)."""
    amt = SWING if amt is None else amt
    if not amt:
        return events
    out = []
    for l in events.splitlines():
        e = json.loads(l)
        if e["type"] in ("NoteOn", "NoteOff") and e["t"] % E8 == E16:
            e["t"] += amt
        out.append(json.dumps(e))
    return "\n".join(out) + "\n"


def shift(events, ticks):
    """Move note events later in time (to bring a part in mid-piece)."""
    out = []
    for l in events.splitlines():
        e = json.loads(l)
        if e["type"] in ("NoteOn", "NoteOff"):
            e["t"] += ticks
            out.append(json.dumps(e))
        elif e["type"] == "ProgramChange":
            out.append(json.dumps(e))
    return "\n".join(out) + "\n"


def seq(notes, ch, patch=None, bpm=0):
    cmd = [BIN / "seq", "--notes", notes, "--ch", str(ch), "--bpm", str(bpm)]
    if patch is not None:
        cmd += ["--patch", str(patch)]
    return swing(run(cmd))


def humanize(events, seed, jt=6, jv=8):
    seeded = run([BIN / "seed", str(seed)]) + events
    out = run([BIN / "humanize", "--jitter-ticks", str(jt), "--jitter-vel", str(jv)], seeded)
    # drop the Seed marker line; to-midi doesn't need it
    return "".join(l + "\n" for l in out.splitlines() if '"Seed"' not in l)


def euclid(seed, **kw):
    args = [BIN / "euclid", "--bpm", "0"]
    for k, v in kw.items():
        args += [f"--{k.replace('_', '-')}", str(v)]
    out = run(args, run([BIN / "seed", str(seed)]))
    return swing("".join(l + "\n" for l in out.splitlines() if '"Seed"' not in l))


def render(name, parts, bpm, end_tick, title, meta):
    TMP.mkdir(parents=True, exist_ok=True)
    OUT.mkdir(parents=True, exist_ok=True)
    tempo = json.dumps({"type": "Tempo", "t": 0, "bpm": bpm}) + "\n"
    merged = run([BIN / "viz", "--width", "72"], tempo + "".join(parts))
    mid = TMP / f"{name}.mid"
    run([BIN / "to-midi", "--out", str(mid)], merged)
    raw = TMP / f"{name}-raw.wav"
    run(["fluidsynth", "-ni", "-g", "0.6", "-r", "44100", "-F", str(raw), SF2, str(mid)])
    # length = final downbeat + ring-out, capped at 15s
    secs = min(15.0, end_tick / TPQ * 60 / bpm + 1.9)
    wav = OUT / f"{name}.wav"
    run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(raw), "-t", f"{secs:.2f}",
         "-af", f"loudnorm=I=-15:TP=-1.5:LRA=11,afade=t=out:st={secs - 1.4:.2f}:d=1.4",
         "-ar", "44100", str(wav)])
    run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(wav), "-filter_complex",
         "showwavespic=s=900x110:scale=sqrt:colors=#7dd3fc", "-frames:v", "1", str(OUT / f"{name}.png")])
    (OUT / f"{name}.mid").write_bytes(mid.read_bytes())
    meta.update(name=name, title=title, bpm=bpm, seconds=round(secs, 1))
    (OUT / f"{name}.json").write_text(json.dumps(meta, indent=2))
    print(f"  -> {wav.relative_to(ROOT)} ({secs:.1f}s)")


def chord_track(prog, voicings, ch, patch, rhythm, seed, vel=70):
    """rhythm: list of (ticks, play?) covering one bar; prog: chord per bar
    (or tuple of chords per half bar)."""
    toks = []
    for c in prog:
        halves = c if isinstance(c, tuple) else (c,)
        span = BAR // len(halves)
        for h in halves:
            used = 0
            for ticks, on in rhythm:
                if used >= span:
                    break
                t = min(ticks, span - used)
                toks.append(tok(voicings[h], t, vel) if on else tok(None, t))
                used += t
    return humanize(seq(" ".join(toks), ch, patch), seed)


# --------------------------------------------------------------------------
# 1. Neon Drive — synthpop, A minor, 128 BPM
# --------------------------------------------------------------------------
def neon():
    bpm = 128
    prog = ["Am", "F", "C", "G", "Am", "F", "G", "Am"]
    pad_v = {"Am": ["A3", "C4", "E4"], "F": ["F3", "A3", "C4"], "C": ["G3", "C4", "E4"], "G": ["G3", "B3", "D4"]}
    root = {"Am": "A1", "F": "F1", "C": "C2", "G": "G1"}
    octv = {"Am": "A2", "F": "F2", "C": "C3", "G": "G2"}
    arp = {"Am": ["A4", "C5", "E5", "A5"], "F": ["F4", "A4", "C5", "F5"], "C": ["E4", "G4", "C5", "E5"], "G": ["D4", "G4", "B4", "D5"]}
    body, last = prog[:-1], prog[-1]

    bass = []
    for c in body:
        for i in range(8):
            bass.append(tok(root[c] if i % 2 == 0 else octv[c], E8, 100 if i % 2 == 0 else 85))
    bass.append(tok(root[last], BAR, 110))

    pad = " ".join(tok(pad_v[c], BAR, 62) for c in body) + " " + tok(pad_v[last] + ["A4"], BAR, 80)

    arps = []
    for c in body:
        pat = arp[c] + arp[c][::-1][1:3] + [arp[c][1], arp[c][2]]  # 8 notes up/down
        for i in range(16):
            arps.append(tok(pat[i % 8], E16, 58 if i % 4 else 70))

    lead = melody(
        "R/8 A4/8 C5/8 E5/8 D5/8 C5/8 E5/4 "
        "R/8 A4/8 C5/8 F5/8 E5/8 C5/8 A4/4 "
        "R/8 G4/8 C5/8 E5/8 G5/8 E5/8 D5/4 "
        "D5/4 B4/8 D5/8 G5/4 E5/4 "
        "R/8 A4/8 C5/8 E5/8 A5/4 G5/8 E5/8 "
        "F5/8 E5/8 C5/8 A4/8 C5/4 F5/4 "
        "G5/8 F5/8 E5/8 D5/8 B4/4 D5/4 "
        "A5/1", 96)

    bars = len(body)
    kick = drum_voice("C2", ["X...x...x...x..."] * bars + ["X..............."])
    clap = drum_voice("D#2", ["....x.......x..."] * (bars - 1) + ["....x.......x.gx", "................"])
    hat = drum_voice("F#2", ["..x...x...x....."] * bars + ["................"])
    ohat = drum_voice("A#2", ["..............o."] * bars + ["................"])
    crash = drum_voice("C#3", ["X..............."] + ["................"] * 3 + ["x..............."] + ["................"] * 2 + ["X..............."])

    parts = [
        humanize(seq(" ".join(bass), 1, 38), 11, 3, 6),
        humanize(seq(pad, 2, 89), 12),
        humanize(seq(" ".join(arps), 3, 81), 13, 2, 6),
        humanize(seq(lead, 0, 80), 14),
        seq(kick, 9), seq(clap, 9), seq(hat, 9), seq(ohat, 9), seq(crash, 9),
        euclid(15, steps=16, pulses=9, note=70, ch=9, vel=48, vel_var=10, ghost=0.25, step_ticks=E16, repeat=bars),
    ]
    render("neon-drive", parts, bpm, bars * BAR, "Neon Drive", {
        "style": "Synthpop", "key": "A minor", "seed_note": "Am–F–C–G hook over four-on-the-floor",
        "instruments": "Square lead, saw arpeggio, warm pad, synth bass, drums + euclid shaker"})


# --------------------------------------------------------------------------
# 2. Disco Strut — disco-funk, E dorian, 118 BPM
# --------------------------------------------------------------------------
def disco():
    bpm = 118
    prog = ["Em7", "A7", "Em7", "A7", "Cmaj7", "D", "Em9"]
    gtr_v = {"Em7": ["E4", "G4", "B4", "D5"], "A7": ["E4", "G4", "C#5", "A4"], "Cmaj7": ["E4", "G4", "B4", "C5"], "D": ["D4", "F#4", "A4", "D5"]}
    lo = {"Em7": "E2", "A7": "A1", "Cmaj7": "C2", "D": "D2", "Em9": "E1"}
    hi = {"Em7": "E3", "A7": "A2", "Cmaj7": "C3", "D": "D3"}
    body = prog[:-1]

    # syncopated octave bass with a pickup on the last 16ths
    bass = []
    for i, c in enumerate(body):
        nxt = prog[i + 1]
        l, h = lo[c], hi[c]
        bass += [tok(l, E8, 105), tok(h, E8, 90), tok(None, E16), tok(l, E16, 95), tok(h, E8, 90),
                 tok(l, E8, 105), tok(h, E8, 90), tok(l, E16, 90), tok(h, E16, 85), tok(lo[nxt] if nxt != "Em9" else "B1", E8, 95)]
    bass.append(tok("E1", BAR, 112))

    # chicken-scratch 16ths: accent offbeats, ghost the rest
    scratch = "gxgXgxgx" * 2
    gtr = []
    for c in body:
        for s in scratch:
            gtr.append(tok(gtr_v[c], E16 // 2, {"g": 40, "x": 68, "X": 84}[s]))
            gtr.append(tok(None, E16 // 2))
    gtr.append(tok(["E4", "G4", "B4", "D5", "F#5"], BAR, 90))

    strings = melody(
        "B4/2 D5/2 C#5/2 E5/2 B4/2 D5/2 C#5/2 E5/2 "
        "E5/4. G5/8 B5/2 F#5/8 G5/8 A5/8 B5/8 D6/8 E6/8 F#6/8 A6/8 "
        "B5/1", 78)

    brass = melody(
        "R/2 R/4 R/8 B4/8 R/2 R/4 R/8 C#5/8 "
        "R/2 R/4 R/8 B4/8 R/2 R/8 A4/8 C#5/8 E5/8 "
        "R/4 G5/8 R/8 R/8 G5/8 R/4 R/4 A5/8 R/8 F#5/8 G5/8 A5/8 D5/8 "
        "E5/2 R/2", 96)

    bars = len(body)
    kick = drum_voice("C2", ["X...x...X...x..."] * bars + ["X..............."])
    snare = drum_voice("D2", ["....X.......X..."] * (bars - 1) + ["....X.......X.xx", "................"])
    hat = drum_voice("F#2", ["xgx.xgx.xgx.xgx."] * bars + ["................"])
    ohat = drum_voice("A#2", ["...o...o...o...o"] * bars + ["................"])
    crash = drum_voice("C#3", ["X..............."] + ["................"] * 3 + ["X..............."] + ["................"] + ["X..............."])

    parts = [
        humanize(seq(" ".join(bass), 1, 36), 21, 4, 8),
        humanize(seq(" ".join(gtr), 2, 28), 22, 3, 8),
        humanize(seq(strings, 3, 48), 23),
        humanize(seq(brass, 4, 61), 24, 4, 6),
        seq(kick, 9), seq(snare, 9), seq(hat, 9), seq(ohat, 9), seq(crash, 9),
        euclid(25, steps=16, pulses=7, rotation=2, note=54, ch=9, vel=55, vel_var=12, step_ticks=E16, repeat=bars),
    ]
    render("disco-strut", parts, bpm, bars * BAR, "Disco Strut", {
        "style": "Disco-funk", "key": "E dorian",
        "seed_note": "Em7–A7 vamp lifting to Cmaj7–D, string run into the last hit",
        "instruments": "Slap bass, muted chicken-scratch guitar, string section, brass stabs, drums + euclid tambourine"})


# --------------------------------------------------------------------------
# 3. Pixel Quest — chiptune, C major, 150 BPM
# --------------------------------------------------------------------------
def pixel():
    bpm = 150
    prog = ["C", "G", "Am", "F", "C", "G", "F", "G", "C"]
    tones = {"C": ["C4", "E4", "G4", "C5"], "G": ["B3", "D4", "G4", "B4"], "Am": ["A3", "C4", "E4", "A4"], "F": ["A3", "C4", "F4", "A4"]}
    root = {"C": "C2", "G": "G1", "Am": "A1", "F": "F1"}
    body = prog[:-1]

    arps = []
    for c in body:
        for i in range(16):
            arps.append(tok(tones[c][[0, 1, 2, 3, 2, 1][i % 6]], E16, 52 if i % 4 else 64))
    arps.append(tok(tones["C"], BAR, 70))

    bass = []
    for c in body:
        r = root[c]
        o = r[:-1] + str(int(r[-1]) + 1)
        bass += [tok(r, E8, 100), tok(o, E8, 85)] * 4
    bass.append(tok("C2", BAR, 110))

    lead = melody(
        "C5/8 E5/8 G5/8 C6/8 B5/8 G5/8 E5/4 "
        "D5/8 G5/8 B5/8 D6/4 B5/8 G5/4 "
        "C6/4 B5/8 A5/8 E5/4 A5/4 "
        "F5/8 G5/8 A5/8 C6/8 A5/4 F5/4 "
        "E5/8 G5/8 C6/8 E6/8 D6/8 C6/8 G5/4 "
        "B5/8 D6/8 G6/4 F6/8 D6/8 B5/4 "
        "A5/8 C6/8 F6/4 E6/8 C6/8 A5/4 "
        "G5/16 A5/16 B5/16 C6/16 D6/16 E6/16 F6/16 G6/16 D6/8 B5/8 G5/4 "
        "C6/1", 100)
    harmony = melody(  # thirds below the lead in the second half
        "R/1 R/1 R/1 R/1 "
        "C5/8 E5/8 G5/8 C6/8 B5/8 A5/8 E5/4 "
        "G5/8 B5/8 D6/4 D6/8 B5/8 G5/4 "
        "F5/8 A5/8 C6/4 C6/8 A5/8 F5/4 "
        "R/2 B5/8 G5/8 D5/4 "
        "E5/1", 70)

    bars = len(body)
    kick = drum_voice("C2", ["X.....x.X......."] * bars + ["X..............."])
    snare = drum_voice("E2", ["....X.......X..."] * (bars - 1) + ["....X...X.X.XXXX", "................"])
    hat = drum_voice("F#2", ["x.x.x.x.x.x.x.x."] * bars + ["................"])
    crash = drum_voice("C#3", ["X..............."] + ["................"] * 3 + ["X..............."] + ["................"] * 3 + ["X..............."])

    parts = [
        humanize(seq(" ".join(arps), 1, 81), 31, 0, 4),
        humanize(seq(" ".join(bass), 2, 38), 32, 0, 4),
        humanize(seq(lead, 0, 80), 33, 0, 4),
        humanize(seq(harmony, 3, 80), 34, 0, 4),
        seq(kick, 9), seq(snare, 9), seq(hat, 9), seq(crash, 9),
    ]
    render("pixel-quest", parts, bpm, bars * BAR, "Pixel Quest", {
        "style": "Chiptune / arcade", "key": "C major",
        "seed_note": "Heroic square-wave hook, harmony joins halfway, 16th-note run into the cadence",
        "instruments": "Square lead + harmony, saw arpeggio, synth bass, tight drums"})


# --------------------------------------------------------------------------
# 4. Sunburst — pop-rock, D major, 140 BPM
# --------------------------------------------------------------------------
def sunburst():
    bpm = 140
    prog = ["D", "A", "Bm", "G", "D", "A", ("G", "A"), "D"]
    power = {"D": ["D3", "A3", "D4"], "A": ["A2", "E3", "A3"], "Bm": ["B2", "F#3", "B3"], "G": ["G2", "D3", "G3"]}
    keys_v = {"D": ["F#4", "A4", "D5"], "A": ["E4", "A4", "C#5"], "Bm": ["F#4", "B4", "D5"], "G": ["G4", "B4", "D5"]}
    root = {"D": "D2", "A": "A1", "Bm": "B1", "G": "G1"}
    body = prog[:-1]

    # final chord: render alone, then shift it to the last bar
    final = [json.loads(l) for l in humanize(seq(tok(power["D"] + ["F#4"], BAR, 105), 2), 41).splitlines()]
    gtr = chord_track(body, power, 2, 29, [(E8, True)] * 8, 41, 80)
    for e in final:
        if e["type"] in ("NoteOn", "NoteOff"):
            e["t"] += len(body) * BAR
            gtr += json.dumps(e) + "\n"

    piano = chord_track(body + ["D"], keys_v, 3, 0, [(Q, True), (E8, False), (E8, True), (Q, True), (Q, True)], 42, 66)

    bass = []
    for c in body:
        for h in (c if isinstance(c, tuple) else (c,)):
            n = 8 // (2 if isinstance(c, tuple) else 1)
            bass += [tok(root[h], E8, 100 if i % 2 == 0 else 88) for i in range(n)]
    bass.append(tok("D2", BAR, 112))

    lead = melody(
        "F#5/4 E5/8 D5/8 E5/4 F#5/4 "
        "E5/4 C#5/8 A4/8 C#5/4 E5/4 "
        "D5/8 F#5/8 B5/4 A5/8 F#5/8 D5/4 "
        "G5/4 F#5/8 E5/8 D5/4 B4/4 "
        "A5/4 F#5/8 A5/8 D6/4 A5/4 "
        "C#6/8 B5/8 A5/8 E5/8 A5/2 "
        "G5/8 F#5/8 E5/8 G5/8 F#5/8 E5/8 C#5/8 E5/8 "
        "D5/1", 98)

    bars = len(body)
    kick = drum_voice("C2", ["X.....x.X.x....."] * bars + ["X..............."])
    snare = drum_voice("D2", ["....X.......X..."] * (bars - 1) + ["....X.......XxXX", "................"])
    hat = drum_voice("F#2", ["x.g.x.g.x.g.x.g."] * bars + ["................"])
    crash = drum_voice("C#3", ["X..............."] + ["................"] * 3 + ["X..............."] + ["................"] * 2 + ["X..............."])

    parts = [
        gtr,
        piano,
        humanize(seq(" ".join(bass), 1, 34), 43, 4, 6),
        humanize(seq(lead, 0, 30), 44),
        seq(kick, 9), seq(snare, 9), seq(hat, 9), seq(crash, 9),
    ]
    render("sunburst", parts, bpm, bars * BAR, "Sunburst", {
        "style": "Pop-rock", "key": "D major",
        "seed_note": "I–V–vi–IV with driving eighth-note power chords",
        "instruments": "Distortion lead guitar, overdriven rhythm guitar, piano, pick bass, rock kit"})


# --------------------------------------------------------------------------
# 5. Island Skank — ska, F major, 152 BPM
# --------------------------------------------------------------------------
def skank():
    bpm = 152
    prog = ["F", "Dm", "Bb", "C", "F", "Dm", "Bb", "C7", "F"]
    chop = {"F": ["F4", "A4", "C5"], "Dm": ["F4", "A4", "D5"], "Bb": ["F4", "Bb4", "D5"], "C": ["E4", "G4", "C5"], "C7": ["E4", "Bb4", "C5"]}
    walk = {"F": "F2 A2 C3 E3", "Dm": "D2 F2 A2 C#3", "Bb": "Bb1 D2 F2 B1", "C": "C2 E2 G2 E2", "C7": "C2 E2 G2 Bb2"}
    body = prog[:-1]

    gtr = chord_track(body, chop, 2, 27, [(E8, False), (E8, True)] * 4, 51, 82)
    organ = chord_track(body, {k: [n.replace("4", "3").replace("5", "4") for n in v] for k, v in chop.items()},
                        3, 17, [(E16, False), (E16, False), (E16, True), (E16, True)] * 4, 52, 55)
    bass = []
    for c in body:
        bass += [tok(n, Q, 100 if i == 0 else 88) for i, n in enumerate(walk[c].split())]
    bass.append(tok("F2", BAR, 112))

    tune = (
        "R/8 C5/8 F5/8 A5/8 G5/8 F5/8 C5/4 "
        "R/8 D5/8 F5/8 A5/8 G5/4 F5/4 "
        "R/8 D5/8 F5/8 Bb5/8 A5/8 G5/8 F5/4 "
        "G5/4 E5/8 C5/8 E5/4 G5/4 "
        "A5/8 A5/8 R/8 A5/8 G5/8 F5/8 C6/4 "
        "A5/4 F5/8 D5/8 F5/4 A5/4 "
        "Bb5/8 A5/8 G5/8 F5/8 D5/4 F5/4 "
        "E5/8 F5/8 G5/8 A5/8 Bb5/4 G5/4 "
        "F5/2. R/4")
    # alto sax an octave below the trumpet
    sax_toks = []
    for t in tune.split():
        n, d = t.split("/")
        if n != "R":
            n = n[:-1] + str(int(n[-1]) - 1)
        sax_toks.append(f"{n}/{d}")
    trumpet = melody(tune, 100)
    sax = melody(" ".join(sax_toks), 84)
    trombone = melody("R/1 R/1 R/1 R/1 F3/4. F3/8 R/2 D3/4. D3/8 R/2 Bb2/4. Bb2/8 R/2 C3/4 E3/4 G3/4 Bb3/4 A3/2. R/4", 88)

    bars = len(body)
    kick = drum_voice("C2", ["X.......x......."] * bars + ["X..............."])
    snare = drum_voice("D2", ["....X.......X..."] * (bars - 1) + ["....X...X.X.XXXX", "................"])
    rim = drum_voice("C#2", ["..x...x...x...x."] * bars + ["................"])
    hat = drum_voice("F#2", ["xgxgxgxgxgxgxgxg"] * bars + ["................"])
    crash = drum_voice("C#3", ["X..............."] + ["................"] * 3 + ["X..............."] + ["................"] * 3 + ["X..............."])

    parts = [
        gtr, organ,
        humanize(seq(" ".join(bass), 1, 33), 53, 4, 6),
        humanize(seq(trumpet, 0, 56), 54),
        humanize(seq(sax, 4, 65), 55),
        humanize(seq(trombone, 5, 57), 56),
        seq(kick, 9), seq(snare, 9), seq(rim, 9), seq(hat, 9), seq(crash, 9),
    ]
    render("island-skank", parts, bpm, bars * BAR, "Island Skank", {
        "style": "Ska", "key": "F major",
        "seed_note": "Offbeat guitar + organ bubble, walking bass, horn section melody",
        "instruments": "Trumpet + alto sax in octaves, trombone, clean guitar chops, percussive organ, finger bass, drums"})


# ==========================================================================
# Set 2 — ca. 1970 pre-disco / Loft-inspired (original material, period feel)
# ==========================================================================
def octave(text, n):
    """Shift every note in a melody() string by n octaves."""
    out = []
    for t in text.split():
        name, d = t.split("/")
        if name != "R":
            name = name[:-1] + str(int(name[-1]) + n)
        out.append(f"{name}/{d}")
    return " ".join(out)


def bass_line(prog, patterns, notes, vel=96):
    """patterns: {'full': '...', 'half': '...'} with {r},{f},{s},{o},... slots;
    notes: chord -> dict of slot notes. A tuple in prog = two half-bar chords."""
    out = []
    for c in prog:
        if isinstance(c, tuple):
            out += [patterns["half"].format(**notes[h]) for h in c]
        else:
            out.append(patterns["full"].format(**notes[c]))
    return melody(" ".join(out), vel)


def hit(chord, ch, patch, at, vel, seed, ticks=BAR):
    """A single final chord placed at tick `at`."""
    return shift(humanize(seq(tok(chord, ticks, vel), ch, patch), seed, 4, 4), at)


# --------------------------------------------------------------------------
# 6. Unity Train — early Philly soul, G major, 112 BPM
#    (orchestral strings, horn punches, Rhodes, busy melodic bass, 4-on-floor)
# --------------------------------------------------------------------------
def unity():
    global SWING
    SWING = 0
    bpm = 112
    body = ["Gmaj7", "Em7", "Cmaj7", "D7", "Gmaj7", ("Cmaj7", "D7")]
    end = len(body) * BAR
    rh = {"Gmaj7": ["F#3", "B3", "D4"], "Em7": ["G3", "B3", "D4"], "Cmaj7": ["G3", "B3", "E4"], "D7": ["F#3", "C4", "E4"]}
    hn = {"Gmaj7": ["D4", "G4", "B4"], "Em7": ["E4", "G4", "B4"], "Cmaj7": ["E4", "G4", "C5"], "D7": ["D4", "F#4", "C5"]}
    pad = {"Gmaj7": ["B4", "D5", "F#5"], "Em7": ["B4", "D5", "G5"], "Cmaj7": ["B4", "E5", "G5"], "D7": ["A4", "C5", "F#5"]}
    bn = {"Gmaj7": dict(r="G1", f="D2", o="G2"), "Em7": dict(r="E1", f="B1", o="E2"),
          "Cmaj7": dict(r="C2", f="G2", o="C3"), "D7": dict(r="D2", f="A2", o="D3")}

    bass = bass_line(body, {"full": "{r}/8 R/16 {r}/16 {f}/8 {o}/8 {r}/8. {r}/16 {f}/8 {o}/8",
                            "half": "{r}/8 R/16 {r}/16 {f}/8 {o}/8"}, bn, 98)
    bass = humanize(seq(bass, 1, 33), 61, 4, 6) + hit(["G1"], 1, None, end, 110, 61)

    rhodes = chord_track(body, rh, 2, 4, [(E8, True), (E8, False), (E16, False), (E16, True), (E8, False)] * 2, 62, 72) \
        + hit(["G3", "B3", "D4", "E4"], 2, None, end, 85, 62)
    horns = chord_track(body, hn, 3, 61, [(Q, False), (E8, False), (E8, True), (Q, False), (E8, False), (E8, True)], 63, 92) \
        + hit(["D4", "G4", "B4", "E5"], 3, None, end, 105, 63, Q)
    strings_pad = chord_track(body, pad, 4, 49, [(BAR, True)], 64, 52)
    gtr = []  # clean "chank" guitar on 2 and 4, plus 16th ghost scratch
    for c in body:
        for h in (c if isinstance(c, tuple) else (c,)):
            span = BAR // (2 if isinstance(c, tuple) else 1)
            for i in range(span // E16):
                on = (i % 8 == 4)
                gtr.append(tok([n.replace("3", "4") for n in rh[h]], E16, 80 if on else 34))
    gtr = humanize(seq(" ".join(gtr), 5, 27), 65, 3, 6)

    tune = ("B5/2. A5/8 B5/8 D6/4 B5/4 G5/4 E5/4 E5/2 G5/4 B5/4 A5/2. F#5/8 A5/8 "
            "D6/2. E6/8 D6/8 C6/8 B5/8 A5/8 G5/8 F#5/8 G5/8 A5/8 C6/8 B5/1")
    violins = humanize(seq(melody(tune, 92), 0, 48), 66)
    vibes = humanize(seq(melody(octave(tune, -1), 70), 6, 11), 67)

    n = len(body)
    kick = drum_voice("C2", ["x...x...x...x..."] * n + ["X..............."])
    snare = drum_voice("D2", ["....X.......X..."] * (n - 1) + ["....X.......X.gx", "................"])
    hat = drum_voice("F#2", ["xg.gxg.gxg.gxg.g"] * n + ["................"])
    ohat = drum_voice("A#2", ["..o...o...o...o."] * n + ["................"])
    tamb = drum_voice("F#3", ["....x.......x..."] * n + ["x..............."])
    crash = drum_voice("C#3", ["X..............."] + ["................"] * 3 + ["x..............."] + ["................"] + ["X..............."])

    parts = [bass, rhodes, horns, strings_pad, gtr, violins, vibes,
             seq(kick, 9), seq(snare, 9), seq(hat, 9), seq(ohat, 9), seq(tamb, 9), seq(crash, 9),
             euclid(68, steps=16, pulses=5, rotation=3, note=63, ch=9, vel=60, vel_var=12, step_ticks=E16, repeat=n),
             euclid(69, steps=16, pulses=3, rotation=6, note=64, ch=9, vel=62, vel_var=10, step_ticks=E16, repeat=n)]
    render("unity-train", parts, bpm, end, "Unity Train", {
        "set": "1970", "style": "Early Philly soul", "key": "G major",
        "seed_note": "Orchestral, joyful: soaring violins over a four-on-the-floor lift with a melodic, bouncing bass",
        "influence": "the orchestral soul and early Philly sound (Curtis Mayfield, the O'Jays, MFSB)",
        "instruments": "Violins + vibraphone, string pad, brass punches, Rhodes, clean guitar chank, finger bass, drums + tambourine + euclid congas"})


# --------------------------------------------------------------------------
# 7. Break It Down — deep funk, E dorian, 100 BPM, swung 16ths
#    (one-chord vamp, horn riff, scratch guitar, drum break before the hit)
# --------------------------------------------------------------------------
def breakit():
    global SWING
    SWING = 22
    bpm = 100
    body = ["E9", "E9", "E9", "A9", "BREAK"]
    end = len(body) * BAR
    gv = {"E9": ["G#3", "D4", "F#4", "B4"], "A9": ["C#4", "G4", "B4", "E5"]}
    bn = {"E9": dict(r="E2", m="G2", p="A2", f="B2", s="D3", o="E3"),
          "A9": dict(r="A1", m="C2", p="D2", f="E2", s="G2", o="A2")}
    pat = "{r}/8 R/16 {r}/16 R/8 {m}/16 {p}/16 R/16 {f}/16 R/8 {s}/16 {o}/16 {s}/16 {f}/16"
    bass = " ".join(pat.format(**bn[c]) for c in body[:-1]) + " R/2 R/4 R/16 B1/16 D2/16 D#2/16"
    bass = humanize(seq(melody(bass, 100), 1, 33), 71, 3, 6) + hit(["E1"], 1, None, end, 115, 71, Q)

    scratch = ".x.xX..x.x.X..x."
    g = []
    for c in body[:-1]:
        for s in scratch:
            g += [tok(gv[c], 90, 82 if s == "X" else 62) if s != "." else tok(None, 90), tok(None, 30)]
    g.append(tok(None, BAR))
    gtr = humanize(seq(" ".join(g), 2, 28), 72, 3, 8) + hit(gv["E9"], 2, None, end, 95, 72, Q)

    organ = humanize(seq(" ".join(tok(["E3", "G#3", "D4"] if c == "E9" else ["A3", "C#4", "G4"], BAR, 50)
                                  for c in body[:-1]) + " " + tok(None, BAR), 3, 16), 73) \
        + hit(["E3", "G#3", "D4", "F#4"], 3, None, end, 70, 73)

    riff = ("R/2 B4/16 D5/16 R/8 E5/8 R/8 "
            "R/2 G5/8 F#5/16 E5/16 D5/8 B4/8 "
            "R/2 B4/16 D5/16 R/8 E5/8 R/8 "
            "R/2 C#5/16 E5/16 R/8 G5/8 F#5/8 "
            "R/1 E5/4 R/2.")
    trumpet = humanize(seq(melody(riff, 100), 0, 56), 74, 4, 6)
    tenor = humanize(seq(melody(octave(riff, -1), 96), 4, 66), 75, 4, 6)

    kick = drum_voice("C2", ["X.x...x...x..x.."] * 4 + ["X.x...x..Xx..x..", "X..............."])
    snare = drum_voice("D2", ["....X..g.g.gX..g"] * 4 + ["....X..g.gXg.X.X", "................"])
    hat = drum_voice("F#2", ["xgxgxgxgxgxgxgxg"] * 3 + ["xgxgxgxgxgxgxgog", "xgxgxgxgxgxgxgxg", "................"])
    crash = drum_voice("C#3", ["X..............."] + ["................"] * 4 + ["X..............."])

    parts = [bass, gtr, organ, trumpet, tenor,
             seq(kick, 9), seq(snare, 9), seq(hat, 9), seq(crash, 9),
             euclid(76, steps=16, pulses=6, rotation=1, note=63, ch=9, vel=58, vel_var=12, ghost=0.3, step_ticks=E16, repeat=4)]
    render("break-it-down", parts, bpm, end, "Break It Down", {
        "set": "1970", "style": "Deep funk", "key": "E dorian",
        "seed_note": "One-chord E9 vamp, tight horn riff, swung 16ths, a bar of bare drum break before the final hit",
        "influence": "early-'70s deep funk (the J.B.'s, Little Sister) and the extended breaks DJs looped",
        "instruments": "Trumpet + tenor sax unison riff, muted scratch guitar, organ, finger bass, drums + euclid conga"})


# --------------------------------------------------------------------------
# 8. Sunrise Drums — Afro-Latin percussion groove, A dorian, 118 BPM
#    (percussion intro, bass + piano montuno enter, tenor sax & flute melody)
# --------------------------------------------------------------------------
def sunrise():
    global SWING
    SWING = 10
    bpm = 118
    body = ["Am7", "D9", "Am7", "D9", "Am7", "D9"]
    n = len(body)
    end = n * BAR
    bn = {"Am7": dict(r="A1", f="E2", s="G2", o="A2"), "D9": dict(r="D2", f="A2", s="C3", o="D3")}
    bass = bass_line(body[1:], {"full": "{r}/8. {r}/16 R/8 {f}/8 {s}/8 {o}/8 {s}/8 {f}/8"}, bn, 100)
    bass = shift(humanize(seq(bass, 1, 33), 81, 4, 6), BAR) + hit(["A1"], 1, None, end, 112, 81)

    pv = {"Am7": ["G4", "C5", "E5"], "D9": ["F#4", "C5", "E5"]}
    piano = shift(chord_track(body[1:], pv, 2, 0, [(E8, True), (E8, False), (E8, True), (E8, True),
                                                    (E8, False), (E8, True), (E8, False), (E8, True)], 82, 74), BAR) \
        + hit(["A3", "G4", "B4", "C5", "E5"], 2, None, end, 92, 82)

    tune = ("R/1 R/1 "
            "E5/4 R/8 G5/8 A5/8 G5/8 E5/4 "
            "F#5/8 E5/8 D5/8 F#5/8 A5/4 R/4 "
            "C6/4. B5/8 A5/8 G5/8 E5/4 "
            "D5/8 E5/8 F#5/8 A5/8 B5/8 A5/8 F#5/8 E5/8 "
            "A5/1")
    sax = humanize(seq(melody(octave(tune, -1), 100), 0, 66), 83)
    flute_line = " ".join(["R/1"] * 4) + " C6/4. B5/8 A5/8 G5/8 E5/4 D5/8 E5/8 F#5/8 A5/8 B5/8 A5/8 F#5/8 E5/8 A5/1"
    flute = humanize(seq(melody(flute_line, 76), 3, 73), 84)

    perc = [
        drum_voice("D4", ["..g...g...g....."] * n + ["................"]),      # mute hi conga
        drum_voice("D#4", ["............x.x."] * n + ["................"]),     # open hi conga
        drum_voice("E4", ["......x........x"] * n + ["X..............."]),     # low conga
        drum_voice("D#5", ["x..x..x...x.x..."] * n + ["................"]),     # 3-2 son clave
        drum_voice("A#4", ["xgggxgggxgggxggg"] * n + ["................"]),     # maracas
        drum_voice("C2", ["X.....x.X......."] * n + ["X..............."]),     # soft kick
        drum_voice("F#2", ["..g...g...g...g."] * n + ["................"]),     # hat
        drum_voice("C#3", ["................"] * n + ["X..............."]),     # crash at the end
    ]
    parts = [bass, piano, sax, flute] + [humanize(seq(p, 9), 85 + i, 4, 8) for i, p in enumerate(perc)] + [
        euclid(91, steps=16, pulses=7, rotation=1, note=60, ch=9, vel=62, vel_var=14, ghost=0.3, step_ticks=E16, repeat=n),  # hi bongo
        euclid(92, steps=16, pulses=3, rotation=5, note=61, ch=9, vel=70, vel_var=10, step_ticks=E16, repeat=n),              # low bongo
        euclid(93, steps=12, pulses=5, rotation=0, note=67, ch=9, vel=58, vel_var=10, step_ticks=160, repeat=n),              # agogo (6/8 feel)
        euclid(94, steps=16, pulses=4, rotation=2, note=68, ch=9, vel=55, vel_var=8, step_ticks=E16, repeat=n),               # low agogo
    ]
    render("sunrise-drums", parts, bpm, end, "Sunrise Drums", {
        "set": "1970", "style": "Afro-Latin percussion groove", "key": "A dorian",
        "seed_note": "Opens on percussion alone, then bass and piano montuno lock in, and tenor sax (later joined by flute) sings over it",
        "influence": "the percussion records central to the Loft (Olatunji, Candido, Manu Dibango)",
        "instruments": "Tenor sax, flute, piano montuno, finger bass, congas, son clave, maracas + euclid bongos & agogo (one in a 12-step cross-rhythm)"})


# --------------------------------------------------------------------------
# 9. Hammond Glide — organ jazz-rock, D dorian, 112 BPM
#    (hypnotic ii–V vamp, drawbar organ lead, Rhodes comping, ride cymbal)
# --------------------------------------------------------------------------
def hammond():
    global SWING
    SWING = 14
    bpm = 112
    body = ["Dm9", "G13", "Dm9", "G13", "Bbmaj7", ("C", "A7")]
    end = len(body) * BAR
    bn = {"Dm9": dict(r="D2", f="A2", s="C3", o="D3"), "G13": dict(r="G1", f="D2", s="F2", o="G2"),
          "Bbmaj7": dict(r="Bb1", f="F2", s="A2", o="Bb2"), "C": dict(r="C2", f="G2"), "A7": dict(r="A1", f="E2")}
    bass = bass_line(body, {"full": "{r}/8. {r}/16 R/8 {f}/8 {s}/8 {o}/8 {f}/8 {s}/8",
                            "half": "{r}/8. {r}/16 R/8 {f}/8"}, bn, 98)
    bass = humanize(seq(bass, 1, 33), 101, 4, 6) + hit(["D2"], 1, None, end, 110, 101)

    ev = {"Dm9": ["F4", "A4", "C5", "E5"], "G13": ["F4", "B4", "E5"], "Bbmaj7": ["F4", "A4", "D5"],
          "C": ["E4", "G4", "C5"], "A7": ["E4", "G4", "C#5"]}
    rhodes = chord_track(body, ev, 2, 4, [(E8, False), (E8, True), (E8, False), (E8, False), (E8, False), (E8, True),
                                          (E8, False), (E16, False), (E16, True)], 102, 70) \
        + hit(["D4", "F4", "A4", "C5", "E5"], 2, None, end, 82, 102)

    tune = ("A4/8 C5/8 D5/8 F5/8 E5/8 D5/8 C5/4 "
            "B4/8 D5/8 E5/8 G5/8 F5/4 E5/4 "
            "A5/4 G5/8 F5/8 E5/8 D5/8 F5/4 "
            "E5/8 D5/8 B4/8 G4/8 A4/2 "
            "D5/8 F5/8 A5/8 Bb5/4. A5/8 F5/8 "
            "G5/8 E5/8 C5/8 E5/8 C#5/8 E5/8 G5/8 Bb5/8 "
            "A5/1")
    organ = humanize(seq(melody(tune, 100), 0, 16), 103)
    organ_low = humanize(seq(melody(octave(tune, -1), 70), 3, 17), 104)  # percussive organ an octave down

    n = len(body)
    kick = drum_voice("C2", ["X..x..x...x....."] * n + ["X..............."])
    snare = drum_voice("D2", ["....X..g..g.X..g"] * (n - 1) + ["....X..g..g.X.XX", "................"])
    ride = drum_voice("D#3", ["x.g.x.g.x.g.x.g."] * n + ["................"])
    pedal = drum_voice("G#2", ["....x.......x..."] * n + ["................"])
    crash = drum_voice("C#3", ["X..............."] + ["................"] * 3 + ["X..............."] + ["................"] + ["X..............."])

    parts = [bass, rhodes, organ, organ_low,
             seq(kick, 9), seq(snare, 9), seq(ride, 9), seq(pedal, 9), seq(crash, 9),
             euclid(105, steps=16, pulses=5, rotation=2, note=63, ch=9, vel=60, vel_var=12, step_ticks=E16, repeat=n),
             euclid(106, steps=16, pulses=3, rotation=0, note=64, ch=9, vel=64, vel_var=10, step_ticks=E16, repeat=n)]
    render("hammond-glide", parts, bpm, end, "Hammond Glide", {
        "set": "1970", "style": "Organ jazz-rock", "key": "D dorian",
        "seed_note": "Hypnotic Dm9–G13 vamp, drawbar organ melody doubled by percussive organ, lifting through Bbmaj7 and A7 back home",
        "influence": "the rhythmic jazz-rock the Loft also played (Brian Auger & The Trinity, Traffic, Babe Ruth)",
        "instruments": "Drawbar organ lead + percussive organ, Rhodes comping, finger bass, ride-cymbal kit + euclid congas"})


PIECES = {"neon": neon, "disco": disco, "pixel": pixel, "sunburst": sunburst, "skank": skank,
          "unity": unity, "breakit": breakit, "sunrise": sunrise, "hammond": hammond}

if __name__ == "__main__":
    want = sys.argv[1:] or list(PIECES)
    OUT.mkdir(parents=True, exist_ok=True)
    page = Path(__file__).with_name("compose-upbeat-preview.html")
    (OUT / "index.html").write_text(page.read_text())
    for w in want:
        print(f"== {w}")
        SWING = 0
        PIECES[w]()
