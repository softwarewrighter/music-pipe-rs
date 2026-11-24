#!/usr/bin/env python3
"""Loopable, non-distracting orchestral game music in mood "sets" of phrases.

Each mood set has four separately-composed phrases, each a seamless loop:
    A  establish  - full texture, the shared theme stated softly
    B  bed        - lowest-attention texture, no melody (good to loop x2)
    C  develop    - theme/answer, slightly richer
    D  turnaround - thinner, breathes, leads back to A
Suggested plan: A x1, B x2, C x1, D x1, repeat.  A player may stop at the end
of ANY phrase and jump to the A phrase of any other set.

Compatibility contract (why set-to-set switches are not jarring):
  * every set is centred on D (major / lydian / mixolydian / dorian / minor / phrygian)
  * every phrase ENDS on an open A-sus chord (dominant, no 3rd)
  * every set's A phrase BEGINS on a D chord  -> each switch is V -> I
  * tempos come from one family: 72, 96, 108, 144 BPM
  * one leitmotif, transformed per mode, ties all sets together

Pipeline per layer: seq (notes) | seed N | humanize, extra layers from
seed N | motif | scale; merged with viz, to-midi, fluidsynth, ffmpeg.
Each phrase is rendered once from silence and everything after its end
(release + reverb tail) is added back onto its start, so looping it is
sample-identical to continuous playback (seamless loop).
All seeds fixed -> reproducible.

Public-domain quotations (examples/pd-motifs.json) appear once per set as a
quiet counter-melody, and in short "bridge" one-shots for fast mood changes.

Usage (repo root):  uv venv .venv && .venv/bin/python examples/game-music.py [set ...]
Output: work/game-music/ (override OUT_DIR): per-phrase WAVs, set-plan previews,
catalog.json and index.html.
"""
import array
import json
import os
import subprocess
import sys
import wave
from itertools import combinations
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BIN = ROOT / "target" / "release"
OUT = Path(os.environ.get("OUT_DIR", ROOT / "work" / "game-music")).resolve()
TMP = OUT / "tmp"
SF2 = os.environ.get("SF2", str(Path.home() / "github/softwarewrighter/midi-cli-rs/soundfonts/GeneralUser_GS.sf2"))
SR = 44100
TPQ, BAR, E16 = 480, 1920, 120

# --------------------------------------------------------------------------
# pitch helpers
# --------------------------------------------------------------------------
NAMES = ["C", "C#", "D", "Eb", "E", "F", "F#", "G", "Ab", "A", "Bb", "B"]
PCS = {"C": 0, "C#": 1, "Db": 1, "D": 2, "D#": 3, "Eb": 3, "E": 4, "F": 5, "F#": 6, "Gb": 6,
       "G": 7, "G#": 8, "Ab": 8, "A": 9, "A#": 10, "Bb": 10, "B": 11}
QUAL = {"": [0, 4, 7], "m": [0, 3, 7], "m7": [0, 3, 7, 10], "maj7": [0, 4, 7, 11], "7": [0, 4, 7, 10],
        "sus": [0, 5, 7], "sus2": [0, 2, 7], "5": [0, 7], "add9": [0, 4, 7, 2], "m9": [0, 3, 7, 10, 2],
        "m6": [0, 3, 7, 9], "dim": [0, 3, 6],
        "aug": [0, 4, 8], "m7b5": [0, 3, 6, 10]}
MODES = {"major": [0, 2, 4, 5, 7, 9, 11], "minor": [0, 2, 3, 5, 7, 8, 10], "dorian": [0, 2, 3, 5, 7, 9, 10],
         "phrygian": [0, 1, 3, 5, 7, 8, 10], "lydian": [0, 2, 4, 6, 7, 9, 11],
         "mixolydian": [0, 2, 4, 5, 7, 9, 10]}


def nn(m):
    return f"{NAMES[m % 12]}{m // 12 - 1}"


def chord(sym):
    body, _, bass = sym.partition("/")
    root = body[:2] if len(body) > 1 and body[1] in "#b" else body[:1]
    q = body[len(root):]
    r = PCS[root]
    pcs = [(r + i) % 12 for i in QUAL[q]]
    return {"root": r, "bass": PCS[bass] if bass else r, "pcs": pcs}


def deg(d, mode, tonic):
    i = d - 1
    return tonic + 12 * (i // 7) + MODES[mode][i % 7]


# the shared leitmotif (scale degree, beats) and its answering phrase
THEME = [(1, 2), (5, 2), (4, 1), (3, 1), (2, 2), (3, 3), (1, 5)]
ANSWER = [(3, 2), (4, 1), (5, 1), (6, 2), (5, 2), (4, 1), (3, 1), (2, 2), (5, 4)]


def tune(phrase, mode, tonic, start_bar, aug=1, vel=70):
    tpb = TPQ * aug
    t, ev = start_bar * BAR, []
    for d, beats in phrase:
        ev.append((t, beats * tpb, [deg(d, mode, tonic)], vel))
        t += beats * tpb
    return ev


def voice(pcs, lo, hi, n, prev):
    notes = [m for m in range(lo, hi + 1) if m % 12 in pcs]
    need = min(n, len(set(pcs)))
    best, best_cost = None, None
    for combo in combinations(notes, n):
        if len({m % 12 for m in combo}) < need or combo[-1] - combo[0] > 19:
            continue
        if any(b - a < 2 for a, b in zip(combo, combo[1:])):
            continue
        cost = sum(abs(a - b) for a, b in zip(combo, prev)) if prev else abs(sum(combo) / n - (lo + hi) / 2)
        if best is None or cost < best_cost:
            best, best_cost = combo, cost
    return list(best or notes[:n])


def pad(chords, lo, hi, n, vel, bars=None):
    """Voice-led sustained chords; identical consecutive voicings are tied."""
    ev, prev = [], None
    for i, sym in enumerate(chords):
        if bars is not None and i not in bars:
            prev = None
            continue
        v = voice(chord(sym)["pcs"], lo, hi, n, prev)
        if ev and prev == v and ev[-1][0] + ev[-1][1] == i * BAR:
            s, d, nts, vv = ev[-1]
            ev[-1] = (s, d + BAR, nts, vv)
        else:
            ev.append((i * BAR, BAR, v, vel))
        prev = v
    return ev


def pat(chords, pattern, base, vel=70, bars=None, accent=8, step=E16, drum=False):
    """16th-grid pattern per bar. chars: b bass, r root, f fifth, o octave,
    1-9 chord tones ascending from base, c voiced chord, X/x/g drum hits,
    '-' extends previous, '.' rest. pattern may span several bars (cycled)."""
    p = pattern.replace(" ", "")
    spb = BAR // step
    chunks = [p[i:i + spb] for i in range(0, len(p), spb)]
    ev, prev = [], None
    for bi, sym in enumerate(chords):
        if bars is not None and bi not in bars:
            continue
        c = chord(sym)
        tones = [m for m in range(base, base + 48) if m % 12 in c["pcs"]]
        root = next(m for m in range(base, base + 12) if m % 12 == c["root"])
        bassn = next(m for m in range(base, base + 12) if m % 12 == c["bass"])
        cp = chunks[bi % len(chunks)]
        for i, ch in enumerate(cp):
            if ch in ".-":
                continue
            j = i + 1
            while j < len(cp) and cp[j] == "-":
                j += 1
            v = vel(bi, i) if callable(vel) else vel + (accent if i % 4 == 0 else 0)
            if drum:
                notes, v = [base], {"X": v + 20, "x": v, "g": max(20, v - 30)}[ch]
            elif ch == "b":
                notes = [bassn]
            elif ch == "r":
                notes = [root]
            elif ch == "f":
                notes = [root + 7]
            elif ch == "o":
                notes = [root + 12]
            elif ch == "c":
                prev = voice(c["pcs"], base, base + 19, 3, prev)
                notes = prev
            else:
                notes = [tones[int(ch) - 1]]
            ev.append((bi * BAR + i * step, (j - i) * step, notes, min(127, int(v))))
    return ev


def to_seq(ev):
    ev = sorted(ev)
    merged = []
    for e in ev:  # merge simultaneous starts, truncate overlaps
        if merged and merged[-1][0] == e[0]:
            s, d, n, v = merged[-1]
            merged[-1] = (s, max(d, e[1]), sorted(set(n + e[2])), max(v, e[3]))
        else:
            merged.append(e)
    toks, cur = [], 0
    for k, (s, d, n, v) in enumerate(merged):
        if k + 1 < len(merged):
            d = min(d, merged[k + 1][0] - s)
        if s > cur:
            toks.append(f"R/t{s - cur}")
        names = [nn(m) for m in n]
        toks.append((f"[{','.join(names)}]" if len(names) > 1 else names[0]) + f"/t{d}*{v}")
        cur = s + d
    return " ".join(toks)


# --------------------------------------------------------------------------
# pipeline helpers (all stages from target/release)
# --------------------------------------------------------------------------
def run(cmd, stdin=""):
    r = subprocess.run([str(c) for c in cmd], input=stdin, capture_output=True, text=True)
    if r.returncode != 0:
        sys.exit(f"FAILED: {' '.join(map(str, cmd))[:300]}\n{r.stderr}")
    return r.stdout


def strip(out, keep=("NoteOn", "NoteOff", "ProgramChange")):
    return "".join(l + "\n" for l in out.splitlines() if json.loads(l)["type"] in keep)


def layer(ev, ch, patch, seed, jt=6, jv=6):
    if not ev:
        return ""
    s = run([BIN / "seq", "--notes", to_seq(ev), "--ch", ch, "--bpm", 0] + (["--patch", patch] if patch is not None else []))
    return strip(run([BIN / "humanize", "--jitter-ticks", jt, "--jitter-vel", jv], run([BIN / "seed", seed]) + s))


def motif_events(seed, length, base, n, mode, vel, dur=1.0, rest=0.5):
    """Sparse random-but-seeded notes: seed | motif | scale (repo stages)."""
    m = run([BIN / "motif", "--base", base, "--notes", n, "--rest-prob", rest, "--dur", dur, "--vel", vel],
            run([BIN / "seed", seed]))
    out = run([BIN / "scale", "--root", "D", "--mode", mode], m)
    ev, on = [], {}
    for l in out.splitlines():
        e = json.loads(l)
        if e["type"] == "NoteOn":
            on[e["key"]] = (e["t"], e["vel"])
        elif e["type"] == "NoteOff" and e["key"] in on:
            t, v = on.pop(e["key"])
            if t < length - 240:
                ev.append((t, min(e["t"], length) - t, [e["key"]], v))
    return ev


def tile(jsonl, length, times=3):
    """Repeat one phrase N times (program changes once) for tail-wrap rendering."""
    lines = [json.loads(l) for l in jsonl.splitlines()]
    out = [e for e in lines if e["type"] == "ProgramChange"]
    for k in range(times):
        for e in lines:
            if e["type"] in ("NoteOn", "NoteOff"):
                out.append(dict(e, t=e["t"] + k * length))
    return "".join(json.dumps(e) + "\n" for e in out)


def render_phrase(tag, layers, bpm, bars):
    """Render the phrase once from silence, then wrap everything after the
    phrase end (release + reverb tail) back onto the start. Playing the result
    in a loop is then identical to continuous playback: sample-exact seam."""
    length = bars * BAR
    tempo = json.dumps({"type": "Tempo", "t": 0, "bpm": bpm}) + "\n"
    merged = run([BIN / "viz", "--width", 72], tempo + "".join(layers))
    mid = OUT / f"{tag}.mid"
    run([BIN / "to-midi", "--out", mid], merged)
    raw = TMP / f"{tag}-raw.wav"
    run(["fluidsynth", "-ni", "-g", "0.5", "-r", SR, "-O", "float", "-T", "wav", "-F", raw, SF2, mid])
    n = round(bars * 4 * 60 / bpm * SR)
    pcm = subprocess.run(["ffmpeg", "-loglevel", "error", "-i", str(raw), "-f", "f32le", "-ac", "2", "-"],
                         capture_output=True, check=True).stdout
    a = array.array("f", pcm)
    loop, tail = a[:2 * n], a[2 * n:]
    if len(loop) < 2 * n:
        loop.extend([0.0] * (2 * n - len(loop)))
    for i in range(min(len(tail), 2 * n)):
        loop[i] += tail[i]
    cut = TMP / f"{tag}-loop.wav"
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-f", "f32le", "-ar", str(SR), "-ac", "2", "-i", "-",
                    "-c:a", "pcm_f32le", str(cut)], input=loop.tobytes(), check=True)
    return cut, n


def variety(layers, bars):
    """Share of bars in a phrase that are unique (notes per channel on a 16th grid,
    humanize jitter and velocity ignored). 1.0 = no bar repeats inside the phrase."""
    sig = [set() for _ in range(bars)]
    for l in "".join(layers).splitlines():
        e = json.loads(l)
        if e["type"] == "NoteOn" and e["t"] < bars * BAR:
            t = round(e["t"] / E16) * E16
            if t < bars * BAR:
                sig[t // BAR].add((t % BAR, e["key"], e["ch"]))
    return round(len({frozenset(s) for s in sig}) / bars, 2)


def measure(path):
    r = subprocess.run(["ffmpeg", "-hide_banner", "-i", str(path), "-af", "loudnorm=print_format=json", "-f", "null", "-"],
                       capture_output=True, text=True).stderr
    j = json.loads(r[r.rindex("{"):r.rindex("}") + 1])
    return float(j["input_i"]), float(j["input_tp"])


def seam_check(path):
    """Ratio of the loop-seam sample jump to the 99.9th-pct jump inside the file."""
    with wave.open(str(path)) as w:
        a = array.array("h", w.readframes(w.getnframes()))
    L, R = a[0::2], a[1::2]
    seam = max(abs(L[0] - L[-1]), abs(R[0] - R[-1]))
    d = sorted(abs(L[i + 1] - L[i]) for i in range(0, len(L) - 1, 7))
    return seam / max(1, d[int(len(d) * 0.999)])


# --------------------------------------------------------------------------
# public-domain quotations (examples/pd-motifs.json, from extract-pd-motifs.py)
# Used sparingly: one quote in one phrase of a set, quiet, as a counter-melody.
# --------------------------------------------------------------------------
PD = {m["id"]: m for m in json.loads((Path(__file__).resolve().parent / "pd-motifs.json").read_text())["motifs"]}
QUOTE_LOG = []   # (set, phrase, motif id, clash ratio) for the build report / catalog


def quote(mid, start_bar, beat=0.0, part=0, center=72, stretch=1.0, vel=60, mode_from=None, mode_to=None,
          upto=None, octaves=(0,), hold_last=None, chords=None, tag=None):
    """A public-domain quotation transposed to D (chromatically, or diatonically
    from mode_from to mode_to), starting at start_bar + beat. Optional: only
    notes before beat `upto`, stretch (augmentation), octave doubling, a held
    final note. With chords, the share of strong-beat notes that clash
    (a semitone off the chord, not a chord tone) is logged."""
    m = PD[mid]
    notes = [n for n in m["parts"][part] if upto is None or n[0] < upto]
    o0 = min(n[0] for n in m["parts"][0])
    shift = (2 - m["tonic_pc"]) % 12
    mean = sum(n[2] for n in notes) / len(notes) + shift
    shift += 12 * round((center - mean) / 12)
    ev = []
    for i, (o, d, k) in enumerate(notes):
        k += shift
        if mode_to:
            rel = (k - 2) % 12
            if rel in MODES[mode_from]:
                j = MODES[mode_from].index(rel)
                k += MODES[mode_to][j] - MODES[mode_from][j]
        if hold_last and i == len(notes) - 1:
            d = hold_last
        t = start_bar * BAR + round(beat * TPQ + (o - o0) * TPQ * stretch)
        ev.append((t, max(60, round(d * TPQ * stretch * 0.96)), [k + 12 * x for x in octaves], vel))
    if chords is not None:
        strong = [(t, n[0]) for t, d, n, v in ev if d >= TPQ * 0.9]
        bad = 0
        for t, k in strong:
            pcs = chord(chords[min(len(chords) - 1, t // BAR)])["pcs"]
            if k % 12 not in pcs and any(abs((k - p) % 12) in (1, 11) for p in pcs):
                bad += 1
        QUOTE_LOG.append((tag, mid, round(bad / max(1, len(strong)), 2)))
    return ev


def quote_info(mid, phrase, where):
    m = PD[mid]
    return dict(phrase=phrase, motif=mid, title=m["title"], composer=m["composer"], year=m["year"], where=where,
                source=m["source"])


# --------------------------------------------------------------------------
# set definitions
# --------------------------------------------------------------------------
def x2(seq_):
    return [c for c in seq_ for _ in (0, 1)]


def set_calm():
    """Calm — D major, 72 BPM. Strings, harp, horn & flute, celesta."""
    ch = {
        "A": ["D", "Gmaj7", "Bm7", "Gmaj7", "D", "E/D", "Gmaj7", "Asus"],
        "B": ["D", "E/D", "D", "E/D", "Bm7", "Gmaj7", "Em7", "Asus"],
        "C": ["D", "G", "Em7", "A", "D", "Gmaj7", "Bm7", "Asus"],
        "D": ["D", "D", "Em7", "Gmaj7", "Bm7", "Gmaj7", "Em7", "Asus"],
    }
    harp = {"A": "1-2-3-5-4-3-2-3-" "1-3-5-6-5-3-2---",
            "B": "1---3-5-6---5-3-" "1---2-3-5-------",
            "C": "1-3-5-6-5-3-2---" "1-2-3-5-4-3-2-3-",
            "D": "1---3---5---6---" "1-------5---3---"}
    L = {}
    for k, c in ch.items():
        s = 100 + ord(k)
        lay = [
            layer(pad(c, 57, 76, 4, 52), 2, 49, s),
            layer(pat(c, harp[k], 50, 46, accent=6), 3, 46, s + 1, 4, 6),
            layer(pat(c, "b---------------", 31, 58, accent=0), 4, 43, s + 2),
            layer(pad(c, 64, 79, 2, 30), 6, 89, s + 3),
        ]
        if k == "A":
            lay += [layer(tune(THEME, "major", 62, 0, vel=58), 1, 60, s + 4),
                    layer(pat(c, "........5.......", 74, 40, bars=[4, 6]), 5, 8, s + 5)]
        if k == "B":
            lay += [layer(pat(c, ".......6........", 74, 36, bars=[2, 6]), 5, 8, s + 5)]
        if k == "C":
            lay += [layer(tune(ANSWER, "major", 74, 0, vel=60) + tune(THEME, "major", 74, 4, vel=60), 0, 73, s + 4),
                    layer(pat(c, "2---------------", 55, 40, accent=0), 1, 60, s + 6)]
        if k == "D":  # Celtic colour: 'The Water of Tyne', 6/8 bars stretched to fill 4/4 bars
            lay.append(layer(quote("tyne", 0, 0, center=72, stretch=4 / 3, vel=46, chords=c, tag="calm-D"), 7, 74, s + 7, 4, 6))
        L[k] = lay
    return dict(chords=ch, id="calm", title="Calm", bpm=72, bars=8, mode="D major (lydian colour)", target=-23, L=L,
                intensity=1, valence="positive", energy="low",
                orchestration="Slow strings, harp, contrabass, warm pad; French horn & flute melody; celesta",
                phases=["puzzle: thinking", "RPG: town / inn / menu", "RTS: early base-building",
                        "adventure: safe area / rest", "any: pause / title"],
                desc="Warm, still, open. Harp ripples over sustained strings; the theme appears once, softly, on horn.")


def set_explore():
    """Exploring — D dorian, 96 BPM. Pizzicato, marimba, woodwinds, light percussion."""
    ch = {
        "A": ["Dm7", "G", "Dm7", "G", "Dm7", "G", "C", "Asus"],
        "B": ["Dm7", "Dm7", "G", "G", "Em7", "Em7", "C", "Asus"],
        "C": ["Dm7", "G", "C", "Am", "Dm7", "G", "Dm7", "Asus"],
        "D": ["G", "G", "Em7", "Em7", "C", "C", "Asus", "Asus"],
    }
    L = {}
    for k, c in ch.items():
        s = 200 + ord(k)
        pizz = "1.5.3.5.2.5.3.5." "1.5.3.5.1.3.5.6." if k != "D" else "1.......5.......3.......5......."
        lay = [
            layer(pat(c, pizz, 50, 56), 2, 45, s, 4, 6),
            layer(pat(c, "b.......f.......", 31, 62), 6, 45, s + 1, 4, 6),
            layer(pad(c, 57, 74, 3, 40), 4, 48, s + 2),
        ]
        if k != "D":
            lay.append(layer(pat(c, "..4...5...4...6." "..5...4.....3...", 62, 42), 3, 12, s + 4, 4, 6))
        perc_bars = None if k != "D" else [6, 7]
        lay += [
            layer(pat(["D"] * len(c), "x.gx.g.x.gx.g.g.", 82, 36, drum=True, bars=perc_bars), 9, None, s + 5, 3, 6),
            layer(pat(["D"] * len(c), "x.........x.....", 45, 40, drum=True, bars=None if k in "BC" else [1, 3, 5, 7]), 9, None, s + 6, 3, 6),
        ]
        if k == "A":
            lay.append(layer(tune(THEME, "dorian", 62, 0, vel=62), 0, 71, s + 7))
        if k == "C":
            lay += [layer(tune(ANSWER, "dorian", 62, 0, vel=64), 1, 68, s + 7),
                    layer(tune(THEME, "dorian", 62, 4, vel=60), 0, 71, s + 8),
                    layer(pat(c, "1-2-3-4-5-4-3-2-", 55, 38, accent=4), 5, 46, s + 9, 4, 6)]
        if k == "D":
            lay.append(layer(pat(c, "1-3-5-3-", 55, 36, accent=4), 5, 46, s + 9, 4, 6))
            lay.append(layer(quote("minstrel", 0, 3, center=69, vel=44, mode_from="major", mode_to="dorian",
                                   chords=c, tag="explore-D"), 7, 110, s + 10, 4, 6))
        L[k] = [x for x in lay if x]
    return dict(chords=ch, id="explore", title="Exploring", bpm=96, bars=8, mode="D dorian", target=-21, L=L,
                intensity=2, valence="curious / positive", energy="medium-low",
                orchestration="Pizzicato strings, marimba, string pad, harp; clarinet & oboe melody; shaker + low tom",
                phases=["adventure / RPG: overworld travel", "RTS: scouting, expansion",
                        "FPS: between encounters", "puzzle: active solving", "platformer: calm level"],
                desc="Light, forward-moving, curious. Plucked ostinato and marimba keep a gentle walking pulse.")


def set_sinister():
    """Sinister — D phrygian, 72 BPM. Low drones, low brass, glass, choir, timpani heartbeat."""
    ch = {
        "A": ["Dm", "Eb/D", "Bb/D", "Dm", "Dm", "Eb/D", "Gm/D", "Asus"],
        "B": ["Dm", "Dm", "Eb/D", "Eb/D", "Dm", "Dm", "Eb/D", "Asus"],
        "C": ["Dm", "Bb", "Eb", "Asus", "Dm", "Eb/D", "Bb/D", "Asus"],
        "D": ["Dm", "Dm", "Eb/D", "Eb/D", "Gm/D", "Gm/D", "Eb/D", "Asus"],
    }
    L = {}
    for k, c in ch.items():
        s = 300 + ord(k)
        heart = "b-.b-..........." * 3 + "." * 16
        heart_bars = None if k in "AC" else ([0, 2, 4, 6] if k == "D" else None)
        hv = {"A": 62, "B": 50, "C": 66, "D": 44}[k]
        lay = [
            layer(pat(c, "b---------------", 26, 68, accent=0), 2, 43, s),
            layer(pad(c, 62, 79, 3, 42), 4, 92, s + 1),
            layer(pat(c, heart, 33, hv, accent=6, bars=heart_bars), 6, 47, s + 2, 3, 5),
        ]
        if k in "BCD":
            lay.append(layer(pad(c, 74, 88, 2, 30), 3, 44, s + 3))
            lay.append(layer(pad(c, 50, 64, 2, 36), 8, 99, s + 4))
        if k in "BD":
            lay.append(layer(motif_events(s + 5, 8 * BAR, 74, 32, "phrygian", 34, 1.0, 0.7), 7, 8, s + 5, 10, 8))
        if k == "A":
            lay.append(layer(tune(THEME, "phrygian", 50, 0, vel=70), 0, 57, s + 6))
        if k == "C":
            lay += [layer(pad(c, 57, 72, 3, 50), 5, 53, s + 6),
                    layer(tune(ANSWER, "phrygian", 50, 0, vel=72), 0, 57, s + 7),
                    layer(tune(THEME, "phrygian", 38, 4, vel=74), 1, 58, s + 8),
                    layer(pat(c, "bbbbbbbbbbbbbbbb", 33, lambda b, i: 30 + i * 3, bars=[3, 7]), 6, 47, s + 9, 2, 3)]
        L[k] = lay
    return dict(chords=ch, id="sinister", title="Sinister", bpm=72, bars=8, mode="D phrygian", target=-22, L=L,
                intensity=3, valence="negative", energy="low-medium",
                orchestration="Contrabass drone, bowed-glass & atmosphere pads, tremolo strings, trombone & tuba, choir oohs, timpani heartbeat, celesta (motif|scale)",
                phases=["dungeon / cave", "stealth / infiltration", "RTS: enemy territory, fog of war",
                        "FPS: tension before contact", "horror-lite: something is wrong"],
                desc="Dark and patient. A low drone and soft timpani heartbeat; the theme turns phrygian (flat 2nd) in the low brass.")


# battle patterns: multi-bar so nothing repeats bar-for-bar
OSTINATO = ("1.1.4.1.1.4.3.2." "1.1.4.1.1.4.3.2." "1.1.4.1.1.4.3.2." "1.2.3.4.5.4.3.2."
            "1.1.4.1.1.4.3.2." "1.1.4.1.1.4.5.4." "1.1.4.1.1.4.3.2." "1.1.1.1.4.4.5.5.")
LOW_STRINGS = "b.b.b.b.b.b.b.o." * 3 + "b.b.b.b.b...b.b."
KICK = "X.......x.x....." * 3 + "X.......x.x.x.x."
SNARE = ("....g.g.....x.gg" * 3 + "....g.g.x.x.xxxx" +
         "....g.g.....x.gg" * 3 + "..g.g.g.xgxgxxxx")
# Brass "calls": 1, 2 or 3 hits. Each call gets its own contour (low/high),
# register, spacing and loudness; the lists cycle at different periods so no
# two calls in a row sound alike.
COUNTS = [2, 1, 3, 2, 2, 1, 3, 2, 1]
CONTOURS = {1: ["L", "H", "L"], 2: ["LH", "LL", "HL", "HH"], 3: ["LHL", "LLH", "HHL", "HLH", "LHH"]}
REGISTERS = [52, 57, 47, 62, 55]           # base MIDI note of the low voicing
GAPS = [4, 2, 6, 3, 8, 4]                   # 16ths between hits
VELS = [72, 56, 86, 62, 78, 50, 92]
STARTS = [0, 6, 8, 2, 10, 4, 12]            # 16th position in the bar


def stab_calls(chords, bars, vel_shift=0):
    """Brass stab calls at the given bars, varied in hit count, contour,
    register, rhythm and dynamics. Each call stays inside its bar."""
    ev, seen = [], {1: 0, 2: 0, 3: 0}
    for i, b in enumerate(bars):
        pcs = chord(chords[b])["pcs"]
        reg = REGISTERS[i % len(REGISTERS)]
        low = voice(pcs, reg, reg + 16, 3, None)
        high = voice(pcs, reg + 7, reg + 23, 3, None)
        if high == low:
            high = [m + 12 for m in low]
        n = COUNTS[i % len(COUNTS)]
        shapes = CONTOURS[n]
        shape = shapes[(seen[n] * 3 + seen[n] // len(shapes)) % len(shapes)]
        seen[n] += 1
        g = GAPS[i % len(GAPS)]
        gaps = [g] if n == 2 else ([] if n == 1 else [g, max(2, g // 2) if i % 2 else g + 2])
        gaps = [min(x, 6) for x in gaps] if n == 3 else gaps
        span = sum(gaps) + 3
        start = b * BAR + min(STARTS[i % len(STARTS)], 16 - span) * E16
        v = VELS[i % len(VELS)] + vel_shift
        lean = 8 if i % 3 == 2 else -6   # later hits sometimes lean in, sometimes fall away
        t = start
        for j, c in enumerate(shape):
            dur = (min(gaps[j], 3) if j < len(gaps) else 3) * E16
            ev.append((t, dur, low if c == "L" else high, max(30, min(120, v + j * lean))))
            if j < len(gaps):
                t += gaps[j] * E16
    return ev


def rests(ev, windows):
    """Dramatic stops: drop notes that start inside any (bar, from16, len16)
    window and cut notes that would ring into one."""
    w = [(b * BAR + f * E16, b * BAR + (f + n) * E16) for b, f, n in windows]
    out = []
    for st, d, notes, v in ev:
        if any(a <= st < z for a, z in w):
            continue
        for a, z in w:
            if st < a < st + d:
                d = a - st
        out.append((st, d, notes, v))
    return out


# where the battle rhythm section stops (pads/choir/brass calls keep going)
STOPS = {"A": [(7, 8, 8)], "B": [(5, 12, 4), (11, 8, 8)], "C": [(7, 4, 12), (13, 12, 4)], "D": []}


def set_battle():
    """Battle — D minor, 144 BPM. Spiccato ostinato, brass, choir, timpani, taiko, snare."""
    ch = {
        "A": x2(["Dm", "C", "Bb", "Dm", "Dm", "Bb", "C", "Asus"]),
        "B": x2(["Dm", "Bb", "Dm", "Bb", "Gm", "C", "Dm", "Asus"]),
        "C": x2(["Dm", "Bb", "C", "A", "Dm", "C", "Bb", "Asus"]),
        "D": x2(["Bb", "Gm", "Bb", "Gm", "C", "C", "Asus", "Asus"]),
    }
    L = {}
    for k, c in ch.items():
        s = 400 + ord(k)
        ost_bars = None if k != "D" else list(range(8, 16))
        st = STOPS[k]
        lay = [
            layer(rests(pat(c, OSTINATO, 50, 66, bars=ost_bars), st), 3, 48, s, 3, 6),
            layer(rests(pat(c, LOW_STRINGS, 38, 70, bars=ost_bars), st), 4, 48, s + 1, 3, 6),
            layer(rests(pat(c, KICK, 36, 60, drum=True, bars=ost_bars), st), 9, None, s + 2, 2, 5),
            layer(rests(pat(c, SNARE, 38, 52, drum=True, bars=ost_bars), st), 9, None, s + 3, 2, 6),
            layer(rests(pat(c, "b.......b.b....." "b...............", 33, 70), st), 6, 47, s + 4, 2, 5) if k != "D" else "",
            layer(rests(pat(c, "b..b..b...b..b.." "b..b..b.........", 36, 62, bars=None if k != "D" else [1, 3, 5, 7]), st), 7, 116, s + 5, 3, 6),
            layer(pat(c, "X...............", 49, 70, drum=True, bars=[0, 8]), 9, None, s + 6) if k != "D" else "",
        ]
        if k == "A":  # sparse brass calls of 1-3 hits, varied (not every bar, never the same twice in a row)
            lay.append(layer(stab_calls(c, [0, 2, 3, 5, 7, 8, 10, 11, 13, 14]), 1, 61, s + 7, 3, 4))
        if k == "C":
            lay.append(layer(stab_calls(c, [1, 4, 6, 9, 12, 15], vel_shift=4), 10, 61, s + 12, 3, 4))
        if k == "A":
            lay.append(layer(tune(THEME, "minor", 62, 0, aug=2, vel=82), 0, 60, s + 8))
            lay.append(layer(quote("dies", 8, 0, center=50, stretch=4, vel=60, octaves=(0, -1), chords=c, tag="battle-A"),
                             11, 57, s + 13, 3, 4))
        if k == "B":
            lay.append(layer(pad(c, 45, 60, 2, 58), 2, 57, s + 8))
        if k == "C":
            lay += [layer(pad(c, 57, 74, 3, 62), 5, 52, s + 8),
                    layer(tune(ANSWER, "minor", 62, 0, aug=2, vel=84), 1, 61, s + 9),
                    layer(tune(THEME, "minor", 62, 8, aug=2, vel=84), 0, 60, s + 10),
                    layer(pad(c, 45, 60, 2, 62), 2, 57, s + 11)]
        if k == "D":
            lay += [layer(pad(c, 57, 74, 3, 52, bars=list(range(0, 8))), 8, 44, s + 8),
                    layer(pat(c, "b---------------", 38, 64, accent=0), 4, 48, s + 9),
                    layer(pat(c, "bbbbbbbbbbbbbbbb", 33, lambda b, i: 28 + (b - 12) * 10 + i, bars=[12, 13, 14, 15]), 6, 47, s + 10, 2, 3),
                    layer(pad(c, 57, 72, 3, 48, bars=list(range(8, 16))), 5, 52, s + 11)]
        L[k] = [x for x in lay if x]
    return dict(chords=ch, id="battle", title="Battle", bpm=144, bars=16, mode="D minor", target=-18, L=L,
                intensity=5, valence="negative / heroic", energy="high",
                orchestration="Spiccato strings ostinato, low strings, brass section, horns, trombones, choir aahs, timpani, taiko, bass drum, snare",
                phases=["RTS: armies engaged", "RPG: combat encounter", "FPS: firefight",
                        "action: boss fight", "tower defense: wave in progress"],
                desc="Driving 8th-note string ostinato under brass. The theme is played in long notes so it never competes with gameplay.")


# --------------------------------------------------------------------------
# second wave: six more moods. Each uses its own instruments, groove and
# harmony, and only fragments / inversions / retrogrades of the theme, so
# none of them sounds like a re-orchestration of the first four.
# Most phrases are 12 bars, and accompaniment patterns cycle over 2, 3 or 5
# bars, so bar-for-bar repeats inside a phrase are rare (see "variety").
# --------------------------------------------------------------------------
def inv(phrase, axis=1):
    """Melodic inversion around a scale degree."""
    return [(2 * axis - d, b) for d, b in phrase]


def retro(phrase):
    return list(reversed(phrase))


def swell(chords, bars, lo, hi, n, v0, v1, per_bar=8):
    """Repeated (tremolo-like) chord whose velocity rises across the bar: a crescendo without CC."""
    ev = []
    for b in bars:
        v = voice(chord(chords[b])["pcs"], lo, hi, n, None)
        step = BAR // per_bar
        for i in range(per_bar):
            ev.append((b * BAR + i * step, step, v, int(v0 + (v1 - v0) * i / (per_bar - 1))))
    return ev


def hold(note, bars, vel):
    """One long tied note (pedal) across the whole phrase."""
    return [(0, bars * BAR, [note], vel)]


def set_eerie():
    """Eerie — D lydian / whole-tone colour, 72 BPM, no pulse at all."""
    ch = {
        "A": ["D", "D", "C/D", "C/D", "Bb/D", "Bb/D", "E/D", "E/D", "D", "C/D", "Gm/D", "Asus"],
        "B": ["Dsus2", "C/D", "Dsus2", "Bb/D", "Dsus2", "E/D", "Dsus2", "C/D", "Bb/D", "Bb/D", "E/D", "Asus"],
        "C": ["D", "Bbaug", "Gm/D", "Ab/D", "D", "C/D", "Bbaug", "E/D", "Gm/D", "Ab/D", "Bbaug", "Asus"],
        "D": ["Gm/D", "Gm/D", "Bbaug", "Bbaug", "C/D", "C/D", "Ab/D", "Ab/D", "E/D", "E/D", "Asus", "Asus"],
    }
    bells = {"A": [0, 7], "B": [5], "C": [3, 9], "D": [6]}
    L = {}
    for k, c in ch.items():
        s = 500 + ord(k)
        lay = [
            layer(pad(c, 62, 79, 3, 34), 2, 94, s),                       # halo pad
            layer(hold(26, 12, 44), 4, 43, s + 1),                          # contrabass pedal D1
            layer(motif_events(s + 2, 12 * BAR, 76, 48, "whole-tone" if k == "C" else "lydian", 32, 1.0,
                               0.75 if k != "D" else 0.85), 5, 10, s + 2, 12, 8),   # music box, scattered
            layer(pat(c, "1-------........", 62, 30, bars=bells[k], accent=0), 8, 14, s + 3, 0, 4),  # tubular bell
            layer(pat(c, "........r-------", 26, 40, bars={"A": [2, 5, 9], "B": [3, 10], "C": [1, 4, 7, 10], "D": [8]}[k],
                      accent=0), 6, 0, s + 4, 6, 6),                      # low piano note, off the beat
        ]
        if k in "BC":
            lay.append(layer(pad(c, 81, 93, 2, 26, bars=list(range(2, 12))), 3, 49, s + 5))  # high string harmonics
        if k == "A":
            lay.append(layer(tune(inv(THEME[:5]), "lydian", 74, 2, aug=2, vel=38), 1, 78, s + 6))  # whistle, inverted
        if k == "C":
            lay += [layer(pad(c, 55, 70, 2, 32), 7, 54, s + 7),             # synth voice "ooh"
                    layer(tune(retro(ANSWER[:5]), "lydian", 62, 4, aug=2, vel=36), 1, 78, s + 8)]
        L[k] = [x for x in lay if x]
    return dict(chords=ch, id="eerie", title="Eerie", bpm=72, bars=12, mode="D lydian / whole-tone", target=-24, L=L,
                intensity=2, valence="uneasy / strange", energy="very low",
                orchestration="Halo pad, contrabass pedal, music box (motif|scale), tubular bell, low piano, high string harmonics, whistle, synth voice",
                phases=["abandoned place / ruins", "puzzle: strange room", "RPG: haunted or magical area",
                        "RTS: alien / unknown map region", "after a reveal: something is off"],
                desc="Weightless and strange, with no beat at all. Scattered music-box notes over a held D; chords slide by whole steps and tritones.")


THREAT_OST = ("r..r..r.r..r..r." "r..r..r.r..f..r." "r..r..r.r.r.r.r." "r..r..r.r..r...." "r..r..r.o..f..r.")
THREAT_TOMS = ("X..x..x........." "................" "X..x..x.x..x..x." "................" "x..x..x.........")


def set_threat():
    """Threatening — D phrygian, 108 BPM, 3+3+2 cello/piano ostinato, tom swells."""
    ch = {
        "A": ["Dm", "Dm", "Eb/D", "Dm", "Dm", "Bb/D", "Eb/D", "Eb/D", "Dm", "Gm/D", "Eb/D", "Asus"],
        "B": ["Dm", "Dm", "Dm", "Eb/D", "Dm", "Dm", "Dm", "Eb/D", "Gm/D", "Gm/D", "Eb/D", "Asus"],
        "C": ["Dm", "Eb", "Dm", "Bb", "Dm", "Eb", "Gm", "Asus", "Dm", "Eb", "Bbaug", "Asus"],
        "D": ["Gm/D", "Gm/D", "Eb/D", "Eb/D", "Dm", "Dm", "Bbaug", "Bbaug", "Eb/D", "Eb/D", "Asus", "Asus"],
    }
    L = {}
    for k, c in ch.items():
        s = 600 + ord(k)
        ost_bars = None if k != "D" else [0, 1, 2, 3, 8, 9, 10, 11]
        lay = [
            layer(pat(c, THREAT_OST, 38, 60, bars=ost_bars), 3, 42, s, 3, 7),            # cello 3+3+2
            layer(pat(c, "r.....r.....r..." "r.......r.......", 26, 46, bars=ost_bars), 4, 0, s + 1, 3, 5),  # low piano
            layer(pad(c, 26, 40, 1, 52), 5, 58, s + 2),                                    # tuba root
            layer(pat(["D"] * 12, THREAT_TOMS, 41, 50, drum=True, bars=ost_bars), 9, None, s + 3, 2, 6),
            layer(pat(["D"] * 12, "....x.......x..." "................" "....x.....x.x...", 45, 34, drum=True,
                      bars=ost_bars), 9, None, s + 4, 2, 6),
        ]
        sw = {"A": [3, 7, 10], "B": [7], "C": [3, 7, 11], "D": [5, 9]}[k]
        lay.append(layer(swell(c, sw, 53, 69, 3, 26, 78), 6, 60, s + 5, 2, 3))           # horn crescendo
        if k in "BD":
            lay.append(layer(pad(c, 62, 76, 2, 30), 7, 44, s + 6))                         # tremolo cluster
        if k == "A":
            lay.append(layer(tune(THEME[:3], "phrygian", 50, 8, aug=2, vel=56), 1, 70, s + 7))  # bassoon fragment
        if k == "C":
            lay += [layer(tune(THEME[:4], "phrygian", 38, 1, aug=2, vel=62), 1, 70, s + 7),
                    layer(tune(inv(THEME[:3], 5), "phrygian", 50, 8, aug=2, vel=58), 0, 57, s + 8),
                    layer(pat(c, "bbbbbbbbbbbbbbbb", 33, lambda b, i: 30 + i * 3, bars=[6, 10]), 8, 47, s + 9, 2, 3)]
        L[k] = [x for x in lay if x]
    return dict(chords=ch, id="threat", title="Threatening", bpm=108, bars=12, mode="D phrygian", target=-21, L=L,
                intensity=4, valence="negative", energy="medium",
                orchestration="Cello 3+3+2 ostinato, low piano, tuba, floor & low toms, French horn crescendos, tremolo strings, bassoon & trombone fragments, timpani rolls",
                phases=["RTS: enemy army approaching / under attack warning", "FPS: hunted, enemies near",
                        "RPG: boss lair approach", "puzzle: timer running low", "any: pre-battle"],
                desc="A lopsided 3+3+2 pulse in low cellos and piano, horn swells every few bars. Pressure without melody; it pushes toward battle but never arrives.")


PUZ_VIBES = ("..1...3...2...4." "....3...1...5..." "..2.....4...3..." "1.......3.5.....")
PUZ_BASS = "r.....f.....r..." "r.......o...f..." "r.....r...f....."


def set_puzzle():
    """Puzzling — D lydian, 108 BPM. Vibraphone, kalimba, bass, bassoon, woodblocks."""
    ch = {
        "A": ["Dmaj7", "Dmaj7", "E/D", "E/D", "Dmaj7", "Bm7", "E/D", "C/D", "Dmaj7", "G/D", "Em7", "Asus"],
        "B": ["D", "Em7/D", "A7/C#", "D", "Bm7", "Bm7", "Gmaj7", "Gmaj7", "Dmaj7", "E/D", "Em7", "Asus"],
        "C": ["Dmaj7", "F#m", "Gmaj7", "E/D", "Bm7", "C", "Gmaj7", "Asus", "Dmaj7", "F#m", "Em7", "Asus"],
        "D": ["Gmaj7", "Gmaj7", "E/D", "E/D", "Em7", "Em7", "C/D", "C/D", "Gmaj7", "E/D", "Asus", "Asus"],
    }
    L = {}
    for k, c in ch.items():
        s = 700 + ord(k)
        lay = [
            layer(pat(c, PUZ_VIBES, 62, 44, accent=4, bars=None if k != "B" else list(range(4, 12))), 2, 11, s, 4, 6),
            layer(pat(c, PUZ_BASS, 38, 56, bars=None if k != "D" else [0, 2, 4, 6, 8, 10]), 4, 32, s + 1, 4, 6),
            layer(pad(c, 57, 72, 2, 32), 6, 71, s + 2),                                         # clarinets, soft
            layer(motif_events(s + 3, 12 * BAR, 74, 96, "lydian", 36, 0.5, 0.7 if k != "D" else 0.85), 3, 108, s + 3, 4, 8),
            layer(pat(["D"] * 12, "x.....x...x....." "....x.......x..." "x.......x.x.....", 76, 32, drum=True,
                      bars=None if k in "AC" else [1, 3, 5, 8, 9, 11]), 9, None, s + 4, 3, 6),
            layer(pat(["D"] * 12, "....x.......x...", 77, 28, drum=True, bars=[2, 5, 7, 10]), 9, None, s + 5, 3, 6),
        ]
        if k == "B":  # Bach, Prelude in C (WTC I), bars 1-4, in D on harp: a quiet nod, then the vibes take over
            pre = [e for e in quote("prelude", 0, 0, part=0, center=72, vel=36, chords=c, tag="puzzle-B")
                   + quote("prelude", 0, 0, part=1, center=55, vel=34) if e[0] < 4 * BAR]
            lay.append(layer(pre, 7, 46, s + 9, 3, 5))
        q = {"A": [1, 4, 9], "B": [6], "C": [2, 8, 10], "D": [3, 7]}[k]
        lay.append(layer(pat(c, "1.3.2...........", 50, 46, bars=q, accent=0), 5, 70, s + 6, 3, 6))   # bassoon "hm?"
        if k == "A":
            lay.append(layer(tune(retro(THEME), "lydian", 62, 4, vel=46), 1, 70, s + 7))     # bassoon, theme backwards
        if k == "C":
            lay.append(layer(tune(inv(ANSWER, 5), "lydian", 62, 2, vel=44), 1, 71, s + 7))  # clarinet, answer inverted
            lay.append(layer(pat(c, "...........1....", 86, 34, bars=[0, 4, 8], accent=0), 8, 9, s + 8, 2, 6))  # glock
        L[k] = [x for x in lay if x]
    return dict(chords=ch, id="puzzle", title="Puzzling", bpm=108, bars=12, mode="D lydian", target=-22, L=L,
                intensity=2, valence="curious / playful", energy="medium-low",
                orchestration="Vibraphone, kalimba (motif|scale), acoustic bass, clarinet pad, bassoon, woodblocks, glockenspiel",
                phases=["puzzle: active solving", "adventure: inventory / riddle", "RPG: crafting / shop",
                        "RTS: research / tech tree screen", "any: confusing or tricky section"],
                desc="Light and a little sideways. Off-beat vibraphone, plucked bass and woodblocks; the bassoon asks short questions; lydian chords never quite settle.")


def set_victory():
    """Victory — D major, 96 BPM. Horn & trombone chorale, trumpet theme, timpani, glockenspiel."""
    ch = {
        "A": ["D", "G/D", "D", "A/C#", "Bm", "G", "Em7", "Asus"],
        "B": ["D", "D", "G", "G", "Bm", "Bm", "G", "Asus"],
        "C": ["D", "D", "Em7", "A", "D", "F#m", "G", "Asus"],
        "D": ["G", "G", "Em7", "Em7", "Bm", "Bm", "G", "Asus"],
    }
    L = {}
    for k, c in ch.items():
        s = 800 + ord(k)
        lay = [
            layer(pad(c, 50, 67, 4, 56 if k != "B" else 48), 2, 60, s),                       # horn chorale
            layer(pad(c, 38, 52, 2, 50 if k != "D" else 40), 3, 57, s + 1),                   # trombones
            layer(pat(c, "1.2.3.4.5.4.3.2." "1.3.5.3.2.4.6.4." "1.2.3.5.6.5.3.2.", 62, 38, accent=4,
                      bars=None if k != "D" else [0, 1, 2, 3]), 4, 48, s + 2, 4, 6),          # string 8ths
            layer(pat(c, "b---------------", 26, 56, accent=0), 5, 43, s + 3),
            layer(pat(c, "b.......b.b....." "b...............", 38, 54, bars=None if k != "B" else [0, 4]), 6, 47, s + 4, 2, 5),
        ]
        if k == "A":
            lay += [layer(tune(THEME, "major", 74, 0, aug=2, vel=66), 1, 56, s + 5),                # trumpet theme
                    layer(pat(c, "X...............", 49, 56, drum=True, bars=[0]), 9, None, s + 6),
                    layer(pat(c, "....5.......3...", 86, 36, bars=[1, 5], accent=0), 8, 9, s + 7, 2, 6)]
        if k == "C":
            lay += [layer(quote("hero", 0, 0, center=74, upto=20, vel=60, chords=c, tag="victory-C"), 1, 56, s + 5, 3, 4),
                    layer(tune(inv(ANSWER[:4], 3), "major", 62, 5, vel=46), 7, 60, s + 8),       # horn answer after it
                    layer(pat(c, "....3.......5...", 86, 36, bars=[2, 6], accent=0), 8, 9, s + 7, 2, 6)]
        if k == "D":
            lay.append(layer(pat(c, "1-3-5-6-5-3-2-1-", 50, 40, accent=4, bars=[4, 5, 6, 7]), 7, 46, s + 9, 4, 6))  # harp
        L[k] = [x for x in lay if x]
    return dict(chords=ch, id="victory", title="Victory", bpm=96, bars=8, mode="D major", target=-19, L=L,
                intensity=3, valence="positive / triumphant", energy="medium",
                orchestration="French horn chorale, trombones, trumpet theme, string 8ths, contrabass, timpani, glockenspiel, harp, crash",
                phases=["RTS: mission won / results screen", "RPG: battle won", "puzzle: level solved",
                        "any: achievement, reward, level-up", "FPS: objective captured"],
                desc="Broad and warm rather than loud: a brass chorale with the theme in long trumpet notes. Celebrates without fanfare blasts.")


def set_defeat():
    """Defeat — D minor, 72 BPM. Lament bass, English horn, cello, piano, voices."""
    ch = {
        "A": ["Dm", "Dm/C", "Bb", "Asus", "Gm/Bb", "Dm/A", "Em7b5/G", "Asus"],
        "B": ["Dm", "Dm", "Bb", "Bb", "Gm", "Gm", "Bb", "Asus"],
        "C": ["Dm", "Dm/C", "Bb", "Gm", "Dm", "Em7b5", "Bb", "Asus"],
        "D": ["Gm", "Gm", "Dm", "Dm", "Bb", "Bb", "Em7b5", "Asus"],
    }
    L = {}
    for k, c in ch.items():
        s = 900 + ord(k)
        lay = [
            layer(pat(c, "b---------------", 38, 52, accent=0), 3, 42, s),                    # cello lament bass
            layer(pad(c, 50, 67, 3, 38), 4, 49, s + 1),                                        # low strings
            layer(pat(c, "....5.......3..." "........4...2..." "................", 62, 32, accent=0,
                      bars=None if k != "D" else [1, 3, 5]), 5, 0, s + 2, 6, 5),            # falling piano
        ]
        if k == "A":
            lay.append(layer(tune(THEME, "minor", 62, 1, vel=54), 1, 69, s + 3))               # English horn
        if k == "C":
            lay += [layer(tune(ANSWER[:6], "minor", 62, 0, vel=50), 6, 40, s + 3),           # solo violin
                    layer(tune(inv(THEME[:4], 3), "minor", 62, 4, aug=2, vel=50), 1, 69, s + 4),
                    layer(pad(c, 57, 69, 2, 28), 7, 53, s + 5)]                              # voices, very soft
        if k == "B":
            lay.append(layer(pad(c, 62, 74, 2, 26, bars=[4, 5, 6, 7]), 7, 53, s + 5))
        if k == "D":  # Scottish lament (Niel Gow), first strain, major -> minor, solo violin
            lay.append(layer(quote("gow", 2, 3.5, center=69, upto=8.5, vel=46, mode_from="major", mode_to="minor",
                                   hold_last=2, chords=c, tag="defeat-D"), 6, 40, s + 6, 4, 5))
        L[k] = [x for x in lay if x]
    return dict(chords=ch, id="defeat", title="Defeat", bpm=72, bars=8, mode="D minor (aeolian)", target=-24, L=L,
                intensity=1, valence="negative / sad", energy="low",
                orchestration="Cello lament bass (D-C-Bb-A), slow strings, sparse piano, English horn theme, solo violin, voice oohs",
                phases=["any: game over / mission failed", "RPG: party wiped, story loss", "RTS: base destroyed",
                        "story: grief, farewell", "puzzle: out of moves"],
                desc="Quiet and resigned. A descending lament bass under the theme on English horn; piano notes fall away. Sad, not melodramatic.")


MARCH_SNARE = ("x..gx.g.x.g.x..." "x..gx.g.x.gxx.g." "x..gx.g.x.g.x..." "x.g.x.g.x.g.xxxx")


def set_march():
    """March / Resolve — D mixolydian, 108 BPM. Snare march, tuba, quarter-note strings, horns, fife."""
    ch = {
        "A": ["D", "C", "G/B", "D", "D", "C", "G", "D", "Bm", "C", "G", "Asus"],
        "B": ["D", "D", "C", "C", "D", "D", "G", "G", "D", "C", "G", "Asus"],
        "C": ["D", "C", "Em7", "D", "G", "C", "D", "Asus", "D", "D", "A", "Asus"],
        "D": ["G", "G", "C", "C", "Em7", "Em7", "C", "C", "G", "G", "Asus", "Asus"],
    }
    L = {}
    for k, c in ch.items():
        s = 1000 + ord(k)
        drums_bars = None if k != "D" else [0, 1, 2, 3, 4, 5, 6, 7]
        lay = [
            layer(pat(["D"] * 12, MARCH_SNARE, 38, 40, drum=True, bars=drums_bars), 9, None, s, 3, 6),
            layer(pat(["D"] * 12, "x.......x.......", 35, 50, drum=True, bars=drums_bars), 9, None, s + 1, 2, 4),
            layer(pat(c, "r.......f......." "r.......o.......", 26, 58), 2, 58, s + 2, 3, 5),       # tuba
            layer(pat(c, "c...c...c...c..." "c...c...c.c.c...", 50, 42, accent=6), 3, 48, s + 3, 3, 5),  # string quarters
        ]
        if k == "A":
            lay.append(layer(tune(THEME, "mixolydian", 62, 2, aug=2, vel=62), 1, 60, s + 4))    # horns
        if k == "B":
            lay.append(layer(pad(c, 50, 64, 3, 40), 4, 60, s + 4))                           # horns, held
        if k == "C":
            lay += [layer(tune(ANSWER, "mixolydian", 62, 0, aug=2, vel=60), 1, 60, s + 4),
                    layer(quote("grenadiers", 8, 3, center=81, vel=46, chords=c, tag="march-C"), 5, 72, s + 5, 3, 4),  # fife
                    layer(pat(c, "X...............", 49, 50, drum=True, bars=[0, 8]), 9, None, s + 6)]
        if k == "D":
            lay.append(layer(pad(c, 50, 64, 3, 44, bars=list(range(6, 12))), 4, 60, s + 4))
        L[k] = [x for x in lay if x]
    return dict(chords=ch, id="march", title="March / Resolve", bpm=108, bars=12, mode="D mixolydian", target=-20, L=L,
                intensity=3, valence="determined / heroic", energy="medium",
                orchestration="Field snare & bass drum, tuba, strings on quarter notes, French horns, piccolo (fife), crash",
                phases=["RTS: army mustering / moving out", "RPG: quest accepted, travelling to a goal",
                        "FPS: briefing, regrouping", "strategy: turn planning", "any: determination after a setback"],
                desc="Steady, purposeful quarter-note pulse with a field snare. Mixolydian (flat 7th) keeps it hopeful but earthy, not triumphant.")


# --------------------------------------------------------------------------
# bridges: short one-shot stingers for fast mood changes. The app fades the
# current phrase out at the next bar line (0.5-1 s) while the bridge starts:
# its lead-in is a soft swell (cymbal / snare / timpani roll, harp glissando)
# that covers the fade. At handoff_seconds the app starts the target set's
# phrase A; the bridge's ringing tail overlaps it. Every bridge ends on a
# dominant (A / Asus / A7), which phrase A (starting on D) resolves.
# --------------------------------------------------------------------------
def roll(note, beats, v0, v1, start_beat):
    n = int(beats * 4)
    return [(round(start_beat * TPQ) + i * E16, E16, [note], int(v0 + (v1 - v0) * i / max(1, n - 1))) for i in range(n)]


def bridge_defs():
    out = []
    # 1. battle -> victory: Handel, "See the Conquering Hero Comes", first two bars
    hero = quote("hero", 0, 0, center=74, upto=8, vel=74, octaves=(0, -1))
    c = ["D", "D", "Asus"]
    out.append(dict(id="to-victory", title="Bridge: to Victory", bpm=96, body_bars=3, quote="hero",
                    frm=["battle", "threat", "march"], to=["victory"],
                    desc="Cymbal swell, then the opening of Handel's 'See the Conquering Hero Comes' in trumpets & horns; ends on A-sus.",
                    L=[(roll(51, 2, 18, 66, -2), 9, None, 1, 1, 3),
                       (hero, 1, 56, 2, 3, 3),
                       (pad(c, 50, 67, 4, 54), 2, 60, 3),
                       (pat(c, "b.......b.b....." "b...b...b.b.b.b.", 38, 58, bars=[0, 1]), 6, 47, 4, 2, 4),
                       (pat(c, "b---------------", 26, 56, accent=0), 5, 43, 6)]))

    # 2. battle/threat -> calm/explore: Bach, Passion Chorale, first phrase (SATB, his harmony), then A-sus
    sat = [quote("passion", 0, -1, part=p, center=cc, upto=8, hold_last=2, vel=v)
           for p, cc, v in ((0, 69, 56), (1, 62, 48), (2, 55, 48), (3, 43, 52))]
    out.append(dict(id="release", title="Bridge: release (to calm)", bpm=80, body_bars=3, quote="passion",
                    frm=["battle", "threat", "sinister", "march"], to=["calm", "explore", "puzzle", "eerie"],
                    desc="A timpani roll dying away under the cut, then the first phrase of Bach's Passion Chorale (his own harmony, in D minor) on strings and horn; settles on A-sus.",
                    L=[(roll(38, 2, 70, 16, -3), 6, 47, 11, 1, 2),
                       (sat[0], 1, 60, 12, 2, 3), (sat[0] + sat[1] + sat[2], 2, 49, 13, 2, 3), (sat[3], 3, 42, 14, 2, 3),
                       (pad(["Dm", "Dm", "Asus"], 57, 72, 3, 40, bars=[2]), 4, 49, 15),
                       (pat(["Dm", "Dm", "Asus"], "b---------------", 33, 46, accent=0, bars=[2]), 5, 43, 16)]))

    # 3. any -> defeat/sinister: Dies irae (chant; Berlioz 1830) in low horns & cellos over a held D
    dies = quote("dies", 0, 0, center=50, vel=62, octaves=(0, -1), hold_last=1)
    c = ["Dm", "Dm", "Asus"]
    out.append(dict(id="fall", title="Bridge: fall (to defeat / sinister)", bpm=72, body_bars=3, quote="dies",
                    frm=["battle", "threat", "march", "explore"], to=["defeat", "sinister", "eerie"],
                    desc="A soft cymbal swell, then the Dies irae in low horns and cellos over a held D; ends on A-sus.",
                    L=[(roll(51, 2, 14, 50, -2), 9, None, 21, 1, 3),
                       (dies, 1, 60, 22, 2, 3), ([(t, d, [n[1]], v - 6) for t, d, n, v in dies], 3, 42, 23, 2, 3),
                       (hold(26, 2, 50) + [(2 * BAR, BAR, [33], 48)], 4, 43, 24),
                       (pad(c, 57, 72, 3, 34), 5, 49, 25)]))

    # 4. calm/explore/puzzle -> march/battle/threat: The British Grenadiers on fife over drums
    gren = quote("grenadiers", 0, -1, center=81, vel=62)
    c = ["D", "A", "Asus"]
    out.append(dict(id="call-to-arms", title="Bridge: call to arms (to march / battle)", bpm=108, body_bars=3, quote="grenadiers",
                    frm=["calm", "explore", "puzzle", "victory", "eerie"], to=["march", "battle", "threat"],
                    desc="Snare roll crescendo, then the opening of 'The British Grenadiers' on fife over drums and tuba; ends on A-sus.",
                    L=[(roll(38, 2, 16, 64, -3), 9, None, 31, 1, 3),
                       (gren, 1, 72, 32, 2, 4),
                       (pat(c, "x...g.g.x...x.g." "x...g.g.x.g.xxxx" "X...............", 38, 50, drum=True), 9, None, 33, 2, 5),
                       (pat(c, "r.......f......." "r.......r......." "r---------------", 26, 60), 2, 58, 34, 2, 4),
                       (pad(c, 50, 64, 3, 46), 3, 60, 35)]))

    # 5. any -> puzzle/eerie: Bach, Prelude in C (WTC I) bars 1-3 = I - ii7 - V7 in D, on harp & celesta
    pre = [e for e in quote("prelude", 0, 0, part=0, center=72, vel=46) + quote("prelude", 0, 0, part=1, center=55, vel=44)
           if e[0] < 3 * BAR]
    gl = [(-2 * TPQ + i * E16 // 2, E16, [62 + MODES["major"][i % 7] + 12 * (i // 7)], 24 + i * 2) for i in range(16)]
    out.append(dict(id="riddle", title="Bridge: riddle (to puzzle / eerie)", bpm=96, body_bars=3, quote="prelude",
                    frm=["calm", "explore", "battle", "threat", "march", "victory"], to=["puzzle", "eerie", "explore"],
                    desc="A harp glissando, then the first bars of Bach's C-major Prelude (in D) on harp with celesta; ends on its A7 bar.",
                    L=[(gl, 7, 46, 41, 0, 3), (pre, 7, 46, 42, 2, 4),
                       ([(t, d, n, v - 16) for t, d, n, v in pre if n[0] >= 69], 8, 8, 43, 2, 3),
                       (pad(["D", "Em7/D", "A7/C#"], 57, 72, 3, 28), 3, 49, 44)]))
    return out


def build_bridge(bd):
    """Render a bridge once (not a loop): lead-in + body + 3 s tail, faded and loudness-normalized."""
    tag = bd["id"]
    shift = -min(min(e[0] for e in L[0]) for L in bd["L"] if L[0])
    layers = [layer([(t + shift, d, n, v) for t, d, n, v in ev], ch, patch, seed, *jit) for ev, ch, patch, seed, *jit in bd["L"]]
    tempo = json.dumps({"type": "Tempo", "t": 0, "bpm": bd["bpm"]}) + "\n"
    merged = run([BIN / "viz", "--width", 72], tempo + "".join(x for x in layers if x))
    mid = OUT / f"bridge-{tag}.mid"
    run([BIN / "to-midi", "--out", mid], merged)
    raw = TMP / f"bridge-{tag}-raw.wav"
    run(["fluidsynth", "-ni", "-g", "0.5", "-r", SR, "-O", "float", "-T", "wav", "-F", raw, SF2, mid])
    spt = 60 / bd["bpm"] / TPQ
    lead = shift * spt
    handoff = (shift + bd["body_bars"] * BAR) * spt
    total = handoff + 3.0
    cut = TMP / f"bridge-{tag}-cut.wav"
    run(["ffmpeg", "-y", "-loglevel", "error", "-i", raw, "-t", f"{total:.3f}", "-af",
         f"afade=t=out:st={total - 1.8:.3f}:d=1.8", "-c:a", "pcm_f32le", cut])
    li, tp = measure(cut)
    gain = min(-20.0 - li, -1.0 - tp)
    f = OUT / f"bridge-{tag}.wav"
    run(["ffmpeg", "-y", "-loglevel", "error", "-i", cut, "-af", f"volume={gain:.2f}dB", "-c:a", "pcm_s16le", f])
    run(["sox", f, "-C", "5", f.with_suffix(".ogg")])
    run(["ffmpeg", "-y", "-loglevel", "error", "-i", f, "-filter_complex", "showwavespic=s=1000x90:scale=sqrt:colors=#fbbf24",
         "-frames:v", "1", f.with_suffix(".png")])
    m = PD[bd["quote"]]
    print(f"  bridge {tag:13s} {total:4.1f}s  lead-in {lead:3.1f}s  handoff {handoff:4.1f}s  ({m['composer']}: {m['title'][:44]})")
    return dict(id=tag, title=bd["title"], file=f.name, ogg=f.with_suffix(".ogg").name, midi=mid.name,
                png=f.with_suffix(".png").name, bpm=bd["bpm"], seconds=round(total, 3), lead_in_seconds=round(lead, 3),
                handoff_seconds=round(handoff, 3), from_sets=bd["frm"], to_sets=bd["to"], desc=bd["desc"],
                quote=dict(title=m["title"], composer=m["composer"], year=m["year"], source=m["source"]))


def demo_transition(a, bridge, b, catalog):
    """Audition file: end of set a's phrase C, faded at a bar line 6 bars in, the bridge, then set b's A."""
    sa = next(s for s in catalog["sets"] if s["id"] == a)
    bar = 240 / sa["bpm"]
    cut_at = 6 * bar
    br = next(x for x in catalog["bridges"] if x["id"] == bridge)
    out = OUT / f"demo-{a}-{bridge}-{b}.mp3"
    fc = (f"[0:a]atrim=0:{cut_at + 0.8:.3f},afade=t=out:st={cut_at:.3f}:d=0.8[x];"
          f"[1:a]adelay={int(cut_at * 1000)}|{int(cut_at * 1000)}[y];"
          f"[2:a]adelay={int((cut_at + br['handoff_seconds']) * 1000)}|{int((cut_at + br['handoff_seconds']) * 1000)}[z];"
          "[x][y][z]amix=inputs=3:normalize=0:duration=longest[m]")
    run(["ffmpeg", "-y", "-loglevel", "error", "-i", OUT / f"{a}-C.wav", "-i", OUT / br["file"], "-i", OUT / f"{b}-A.wav",
         "-filter_complex", fc, "-map", "[m]", "-c:a", "libmp3lame", "-q:a", "2", out])
    return dict(file=out.name, a=a, bridge=bridge, b=b, cut_at_seconds=round(cut_at, 2))


QUOTES = {
    "calm": [quote_info("tyne", "D", "recorder, bars 1-4, 6/8 lilt over 4/4")],
    "explore": [quote_info("minstrel", "D", "fiddle, bars 1-4, recast in D dorian")],
    "puzzle": [quote_info("prelude", "B", "harp, bars 1-4 (Bach's harmony, in D)")],
    "battle": [quote_info("dies", "A", "trombones in octaves, one note per bar, bars 9-16")],
    "victory": [quote_info("hero", "C", "trumpet, bars 1-5")],
    "defeat": [quote_info("gow", "D", "solo violin, bars 4-6, recast in D minor")],
    "march": [quote_info("grenadiers", "C", "fife, bars 9-11")],
}


SETS = {"calm": set_calm, "explore": set_explore, "sinister": set_sinister, "battle": set_battle,
        "eerie": set_eerie, "threat": set_threat, "puzzle": set_puzzle, "victory": set_victory,
        "defeat": set_defeat, "march": set_march}
ROLES = {"A": ("establish", 1, "Full texture; theme stated softly. Entry point from any other set (starts on D)."),
         "B": ("bed", 2, "Lowest-attention texture, no melody. Designed to loop."),
         "C": ("develop", 1, "Theme + answer, slightly richer."),
         "D": ("turnaround", 1, "Thinner, breathes; leads back to A or out to another set.")}


# extra renders of the same composition at other tempos (same chords/entry/exit)
TEMPO_VARIANTS = {"calm": [64, 80], "explore": [88, 104], "sinister": [64, 80], "battle": [132, 156],
                  "eerie": [64, 80], "threat": [100, 116], "puzzle": [100, 116], "victory": [88, 104],
                  "defeat": [64, 80], "march": [100, 116]}


def build(set_fn, bpm_override=None):
    n_log = len(QUOTE_LOG)
    spec = set_fn()
    sid, bars = spec["id"], spec["bars"]
    if bpm_override is None:
        for tag, mid, clash in QUOTE_LOG[n_log:]:
            print(f"  quote {mid:10s} in {tag}: {clash:.0%} strong-beat clashes")
    bpm = bpm_override or spec["bpm"]
    pre = sid if bpm_override is None else f"{sid}-{bpm}bpm"
    print(f"== {pre}")
    cuts = {}
    for k, layers in spec["L"].items():
        cuts[k], n = render_phrase(f"{pre}-{k}", layers, bpm, bars)
    # one gain for the whole set (from its A,B,B,C,D plan) -> phrases stay balanced
    plan = TMP / f"{pre}-plan-f.wav"
    lst = TMP / f"{pre}-plan.txt"
    order = [k for k in "ABCD" for _ in range(ROLES[k][1])]
    lst.write_text("".join(f"file '{cuts[k]}'\n" for k in order))
    run(["ffmpeg", "-y", "-loglevel", "error", "-f", "concat", "-safe", "0", "-i", lst, "-c", "copy", plan])
    li, tp = measure(plan)
    gain = min(spec["target"] - li, -1.0 - tp)
    phrases = []
    for k in "ABCD":
        f = OUT / f"{pre}-{k}.wav"
        run(["ffmpeg", "-y", "-loglevel", "error", "-i", cuts[k], "-af", f"volume={gain:.2f}dB", "-c:a", "pcm_s16le", f])
        run(["sox", f, "-C", "5", f.with_suffix(".ogg")])  # Ogg Vorbis q5 (sox/libvorbis)
        role, loops, note = ROLES[k]
        secs = n / SR
        var = variety(spec["L"][k], bars)
        print(f"  {k} {role:10s} {secs:5.1f}s  variety {var:.2f}")
        phrases.append(dict(part=k, role=role, suggested_loops=loops, file=f.name, ogg=f.with_suffix(".ogg").name,
                            midi=f"{pre}-{k}.mid", seconds=round(secs, 3), samples=n, bars=bars, variety=var,
                            chords=spec_chords(spec, k), starts_on=spec_chords(spec, k)[0],
                            ends_on=spec_chords(spec, k)[-1], note=note))
    print(f"  loudness {li:.1f} LUFS -> gain {gain:+.1f} dB (target {spec['target']})")
    if bpm_override:
        return {"bpm": bpm, "phrases": phrases}
    lst.write_text("".join(f"file '{OUT / (sid + '-' + k + '.wav')}'\n" for k in order + ["A"]))
    run(["ffmpeg", "-y", "-loglevel", "error", "-f", "concat", "-safe", "0", "-i", lst, "-c", "copy", OUT / f"{sid}-plan.wav"])
    run(["ffmpeg", "-y", "-loglevel", "error", "-i", OUT / f"{sid}-plan.wav", "-filter_complex",
         "showwavespic=s=1000x90:scale=sqrt:colors=#7dd3fc", "-frames:v", "1", OUT / f"{sid}-plan.png"])
    return {kk: spec[kk] for kk in ("id", "title", "bpm", "mode", "intensity", "valence", "energy",
                                    "orchestration", "phases", "desc")} | {
        "key_center": "D", "loudness_target_lufs": spec["target"], "bars_per_phrase": bars,
        "beat_seconds": round(60 / spec["bpm"], 6), "bar_seconds": round(240 / spec["bpm"], 6),
        "quotes": QUOTES.get(sid, []),
        "plan": order, "plan_preview": f"{sid}-plan.wav", "phrases": phrases,
        "tempo_variants": [build(set_fn, b) for b in TEMPO_VARIANTS.get(sid, [])]}


def spec_chords(spec, k):
    return spec["chords"][k]


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    TMP.mkdir(parents=True, exist_ok=True)
    want = sys.argv[1:] or list(SETS)
    cat_path = OUT / "catalog.json"
    catalog = json.loads(cat_path.read_text()) if cat_path.exists() else {"sets": []}
    by_id = {s["id"]: s for s in catalog["sets"]}
    for w in want:
        build_entry = build(SETS[w])
        by_id[w] = build_entry
    catalog = {
        "version": 1,
        "contract": {
            "key_center": "D",
            "phrase_end_chord": "Asus (A D E) - dominant without a third",
            "set_entry": "every set's phrase A starts on a D chord (major or minor)",
            "tempo_family_bpm": [72, 96, 108, 144],
            "tempo_variants": "each set also lists tempo_variants: the same composition re-rendered from MIDI at another BPM (no time-stretching). Chords, entry and exit are identical, so the switch rule still holds.",
            "switch_rule": "switch only at a phrase boundary; jump to the target set's phrase A",
            "loops": "each phrase WAV is a seamless sample-accurate loop (reverb tail wrapped); an .ogg (Vorbis q5) is written next to every WAV",
        },
        "sets": [by_id[k] for k in SETS if k in by_id] + [s for i, s in by_id.items() if i not in SETS],
    }
    print("== bridges")
    catalog["bridges"] = [build_bridge(b) for b in bridge_defs()]
    catalog["contract"]["fast_switch"] = (
        "To change mood without waiting for the phrase to end: at the next bar line of the current set "
        "(bar_seconds), fade the current phrase out over 0.5-1 s and start a bridge whose from_sets/to_sets fit "
        "at the same moment (its lead-in swell covers the fade). At the bridge's handoff_seconds start the "
        "target set's phrase A at full volume (or with a short 0.3 s fade-in); let the bridge's tail ring under it.")
    have = {s["id"] for s in catalog["sets"]}
    demos = [("battle", "release", "calm"), ("battle", "to-victory", "victory"), ("battle", "fall", "defeat"),
             ("explore", "call-to-arms", "battle"), ("calm", "riddle", "puzzle")]
    catalog["transition_demos"] = [demo_transition(a, br, b, catalog) for a, br, b in demos if a in have and b in have]
    cat_path.write_text(json.dumps(catalog, indent=2))
    write_page(catalog)
    # tour: every set's plan back-to-back (exercises set-to-set transitions)
    lst = TMP / "tour.txt"
    lst.write_text("".join(f"file '{OUT / (s['id'] + '-' + k + '.wav')}'\n" for s in catalog["sets"] for k in "ABCD")
                   + f"file '{OUT / (catalog['sets'][0]['id'] + '-A.wav')}'\n")
    run(["ffmpeg", "-y", "-loglevel", "error", "-f", "concat", "-safe", "0", "-i", lst, "-c:a", "libmp3lame", "-q:a", "2", OUT / "tour.mp3"])


def write_page(catalog):
    ts = int(Path(OUT / "catalog.json").stat().st_mtime)
    cards = []
    for s in catalog["sets"]:
        rows = "".join(f"""
      <div class="ph"><div class="lab"><b>{p['part']}</b> · {p['role']} <span class="dim">× {p['suggested_loops']} · {p['seconds']:.1f}s</span>
        <div class="dim small">{p['note']}<br>chords: {' – '.join(p['chords'])}</div></div>
        <audio controls loop preload="none" src="{p['file']}?ts={ts}"></audio>
        <a class="small" href="{p['file']}" download>wav</a> <a class="small" href="{p['midi']}" download>mid</a></div>""" for p in s["phrases"])
        variants = "".join(f"""
    <div class="var"><span class="small"><b>{v['bpm']} BPM</b> variant</span>""" + "".join(
            f"""<span class="small">{p['part']}</span><audio controls loop preload="none" src="{p['file']}?ts={ts}"></audio>"""
            for p in v["phrases"]) + "</div>" for v in s.get("tempo_variants", []))
        cards.append(f"""
  <section class="card" id="{s['id']}">
    <div class="head"><h2>{s['title']}</h2><span class="tags">{s['mode']} · {s['bpm']} BPM · intensity {s['intensity']}/5 · {s['valence']} · energy {s['energy']}</span></div>
    <p class="dim">{s['desc']}</p>
    <p class="small"><b>Use for:</b> {' · '.join(s['phases'])}<br><b>Orchestration:</b> {s['orchestration']}</p>
    <div class="plan"><span class="small"><b>Full plan preview</b> ({' → '.join(s['plan'])} → A), phrase files concatenated exactly as a player would:</span>
      <img src="{s['plan_preview'].replace('.wav', '.png')}?ts={ts}" alt=""><audio controls preload="none" src="{s['plan_preview']}?ts={ts}"></audio></div>
    {rows}
    {variants}
  </section>""")
    html = f"""<!DOCTYPE html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate">
<title>Game music sets — preview</title>
<style>
 :root {{ color-scheme: dark; --bg:#0f1117; --card:#181b24; --line:#2a2f3d; --fg:#e7e9ee; --dim:#9aa3b5; --acc:#7dd3fc; }}
 body {{ margin:0; font:15px/1.5 system-ui,-apple-system,sans-serif; background:var(--bg); color:var(--fg); }}
 main {{ max-width:1020px; margin:0 auto; padding:28px 20px 60px; }}
 h1 {{ font-size:22px; margin:0 0 6px; }} h2 {{ font-size:19px; margin:0; }}
 .dim {{ color:var(--dim); }} .small {{ font-size:13px; }} a {{ color:var(--acc); }}
 .card {{ background:var(--card); border:1px solid var(--line); border-radius:12px; padding:18px 20px; margin:18px 0; }}
 .head {{ display:flex; gap:12px; align-items:baseline; flex-wrap:wrap; }} .tags {{ color:var(--acc); font-size:13px; }}
 .plan {{ background:#11141b; border-radius:8px; padding:10px 12px; margin:8px 0 12px; }}
 .plan img {{ width:100%; height:56px; object-fit:fill; display:block; margin:6px 0; opacity:.85; }}
 .var {{ display:grid; grid-template-columns: 110px repeat(4, 16px 1fr); gap:6px; align-items:center; border-top:1px dashed var(--line); padding:6px 0; }}
 .ph {{ display:grid; grid-template-columns: 1fr 320px auto auto; gap:10px; align-items:center; border-top:1px solid var(--line); padding:8px 0; }}
 audio {{ width:100%; }} code {{ background:#11141b; border:1px solid var(--line); border-radius:5px; padding:1px 5px; font-size:12.5px; }}
 ul {{ margin:6px 0; padding-left:20px; }}
</style></head><body><main>
<h1>Game background music — mood sets (preview)</h1>
<p class="dim">Each mood is a <b>set</b> of four separate phrase files (A establish, B bed, C develop, D turnaround). Each phrase file is a seamless loop. Suggested plan: A×1 → B×2 → C×1 → D×1 → repeat. The player may stop after <i>any</i> phrase and go to the <b>A</b> phrase of another set.</p>
<p class="small"><b>Why switches don't jar:</b></p>
<ul class="small dim">
<li>Every set is centred on D.</li>
<li>Every phrase ends on an open A-sus chord, and every set's A begins on D, so each switch moves from that A-sus chord back home to D.</li>
<li>Tempos come from one family (72 / 96 / 108 / 144 BPM).</li>
<li>One theme is reworked in each set's mode.</li>
<li>Machine-readable catalog: <a href="catalog.json">catalog.json</a></li>
</ul>
<div class="card"><b>Tour</b> <span class="dim small">— every set's A B C D in a row, then back to the first set's A. Use it to judge set-to-set transitions.</span>
<audio controls preload="none" src="tour.mp3?ts={ts}"></audio></div>
<p class="small dim">Note: the browser's &lt;audio loop&gt; may leave a tiny gap at the loop point. The WAV files themselves are sample-accurate loops.</p>
{''.join(cards)}
</main></body></html>"""
    (OUT / "index.html").write_text(html)


if __name__ == "__main__":
    # record chord charts for the catalog before building
    main()
