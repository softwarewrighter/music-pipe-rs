#!/usr/bin/env python3
"""Slide-transition beds: 20-30 s upbeat clips built from 5-second cells.

Made for videos that use 5-second pieces of one clip for title / separator
slides: the first 5 s (0-5), any number of middle windows (n to n+5), and the
last 5 s (L-5 to L) for the closing slide. Every clip is laid out so that each
of those windows works on its own:

    cell 0          motif       a public-domain tune stated plainly, starting
                                on a downbeat at t = 0 (no fade-in, no pickup)
    cells 1..k-2    bridges     short episodes on the same tune: an answer
                                phrase, a modal "shadow" (dorian), a lift to
                                the subdominant (G), a stop-time break, each
                                in a different instrumentation
    cell k-1        denouement  the tune's head, then a cadence; the final D
                                chord is struck 2.5 s before the end and rings

Tempos are chosen so 5 s is a whole number of bars (96 BPM: 2 bars, 144 BPM:
3 bars), so every cell boundary (0, 5, 10, ...) is a bar line and every
window starting there begins on a downbeat. No cell repeats another; the build
report prints the share of unique bars across the whole clip (1.0 = no bar of
any instrument repeats anywhere) and each cell's loudness.

Uses the stages and helpers of examples/game-music.py (seq | seed | humanize,
viz, to-midi, fluidsynth) and the quotations in examples/pd-motifs.json
(from examples/extract-pd-motifs.py). All seeds fixed: reproducible.

Usage (repo root):  .venv/bin/python examples/video-beds.py [clip ...]
Output: work/video-beds/ (override OUT_DIR): <clip>.wav/.mid/.png, catalog.json.
Cut a window:        examples/slice-5s.sh work/video-beds/<clip>.wav 10   (or first / last)
"""
import array
import importlib.util
import json
import os
import subprocess
import sys
import zlib
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.dont_write_bytecode = True     # importing game-music.py should not leave examples/__pycache__
_spec = importlib.util.spec_from_file_location("game_music", HERE / "game-music.py")
gm = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(gm)

ROOT = HERE.parent
BIN = gm.BIN
OUT = Path(os.environ.get("OUT_DIR", ROOT / "work" / "video-beds")).resolve()
TMP = OUT / "tmp"
TPQ, E16, SR = gm.TPQ, gm.E16, gm.SR
CELL = 5.0            # seconds per cell
LUFS, PEAK = -16.0, -1.5   # same loudness as the 10-15 s video clips in work/preview


# --------------------------------------------------------------------------
# event helpers. Events are (tick, dur, [midi], vel); times inside a cell.
# --------------------------------------------------------------------------
def b(beats):
    return round(beats * TPQ)


def Q(mid, part=0, center=72, beat=0.0, vel=84):
    """A public-domain quotation transposed to D (see game-music.py quote())."""
    return gm.quote(mid, 0, beat, part=part, center=center, vel=vel)


def win(ev, b0, b1, at=0.0):
    """Notes starting in beats [b0, b1), moved to start at beat `at`, cut at b1."""
    t0, t1 = b(b0), b(b1)
    return [(t - t0 + b(at), min(d, t1 - t), n, v) for t, d, n, v in ev if t0 <= t < t1]


def tr(ev, s):
    return [(t, d, [k + s for k in n], v) for t, d, n, v in ev]


def vel(ev, dv):
    return [(t, d, n, max(1, min(127, v + dv))) for t, d, n, v in ev]


def sh(ev, beats):
    return [(t + b(beats), d, n, v) for t, d, n, v in ev]


def aug(ev, f):
    return [(round(t * f), round(d * f), n, v) for t, d, n, v in ev]


def stacc(ev, f=0.5):
    return [(t, max(60, round(d * f)), n, v) for t, d, n, v in ev]


def remode(ev, frm="major", to="dorian"):
    """Diatonic mode change around D (major -> dorian lowers the 3rd and 7th)."""
    out = []
    for t, d, n, v in ev:
        ks = []
        for k in n:
            rel = (k - 2) % 12
            if rel in gm.MODES[frm]:
                j = gm.MODES[frm].index(rel)
                k += gm.MODES[to][j] - gm.MODES[frm][j]
            ks.append(k)
        out.append((t, d, ks, v))
    return out


def by_onset(ev):
    g = {}
    for t, d, n, v in ev:
        g.setdefault(t, []).append((d, n, v))
    return g


def mono(ev, high=True):
    """One note per onset (top or bottom): octave-doubled piano line -> wind line."""
    out = []
    for t, xs in sorted(by_onset(ev).items()):
        d, n, v = max(xs, key=lambda x: max(x[1])) if high else min(xs, key=lambda x: min(x[1]))
        out.append((t, d, [max(n) if high else min(n)], v))
    return out


def upper(ev):
    """Everything except the lowest note of each onset (a rag left hand's chords)."""
    out = []
    for t, xs in sorted(by_onset(ev).items()):
        lo = min(k for _, n, _ in xs for k in n)
        for d, n, v in xs:
            ks = [k for k in n if k != lo]
            if ks:
                out.append((t, d, ks, v))
    return out


def fold(ev, lo, hi):
    """Move notes by octaves into [lo, hi]."""
    def f(k):
        while k > hi:
            k -= 12
        while k < lo:
            k += 12
        return k
    return [(t, d, [f(k) for k in n], v) for t, d, n, v in ev]


def midi(name):
    i = 2 if len(name) > 2 and name[1] in "#b" else 1
    return (int(name[i:]) + 1) * 12 + gm.PCS[name[:i]]


def notes(text, at=0.0, v=80):
    """'A4/.25 [D4,F#4]/2 R/1' with durations in beats."""
    ev, t = [], at
    for tok in text.split():
        nm, d = tok.split("/")
        if nm != "R":
            ev.append((b(t), round(b(float(d)) * 0.96), [midi(x) for x in nm.strip("[]").split(",")], v))
        t += float(d)
    return ev


def ctr(sym, s):
    """Transpose a chord symbol by s semitones."""
    def one(x):
        r = x[:2] if len(x) > 1 and x[1] in "#b" else x[:1]
        return gm.NAMES[(gm.PCS[r] + s) % 12] + x[len(r):]
    main, _, bass = sym.partition("/")
    return one(main) + ("/" + one(bass) if bass else "")


def comp(chords, unit, pattern, base, v=60, at=0.0, accent=6):
    """game-music pat() with one chord per `unit` beats; the pattern (16ths) runs on across chords."""
    steps, p, ev = int(unit * 4), pattern.replace(" ", ""), []
    for i, c in enumerate(chords):
        chunk = "".join(p[(i * steps + j) % len(p)] for j in range(steps))
        ev += [(t + b(at + i * unit), d, n, vv) for t, d, n, vv in gm.pat([c], chunk, base, v, accent=accent)]
    return ev


def pad(chords, unit, lo, hi, n, v, at=0.0):
    """Voice-led sustained chords, one per `unit` beats; repeated voicings are tied."""
    ev, prev = [], None
    for i, s in enumerate(chords):
        vo = gm.voice(gm.chord(s)["pcs"], lo, hi, n, prev)
        t = b(at + i * unit)
        if ev and prev == vo and ev[-1][0] + ev[-1][1] == t:
            ev[-1] = (ev[-1][0], ev[-1][1] + b(unit), vo, v)
        else:
            ev.append((t, b(unit), vo, v))
        prev = vo
    return ev


def ring(sym, at, end, lo, hi, n, v):
    return pad([sym], end - at, lo, hi, n, v, at)


def drums(beats, parts, v=64, at=0.0):
    """parts: [(GM drum note, 16th pattern of X / x / g / .)], patterns cycle."""
    ev = []
    for note, p in parts:
        p = p.replace(" ", "")
        for i in range(int(beats * 4)):
            c = p[i % len(p)]
            if c not in ".-":
                ev.append((b(at) + i * E16, E16, [note], min(127, {"X": v + 20, "x": v, "g": max(18, v - 28)}[c])))
    return ev


def hit(note, at, v, beats=1.0):
    return [(b(at), b(beats), [note], v)]


def fill(at, beats, v0, v1, note=38):
    n = int(beats * 4)
    return [(b(at) + i * E16, E16, [note], int(v0 + (v1 - v0) * i / max(1, n - 1))) for i in range(n)]


KICK, SIDE, SNARE, CLAP, HAT, PHAT, OHAT, CRASH, RIDE, TAMB, LTOM, MTOM, SHAKER = 36, 37, 38, 39, 42, 44, 46, 49, 51, 54, 45, 47, 70


def cell(role, label, chords, unit, mel=None, **parts):
    return dict(role=role, label=label, chords=chords, unit=unit, mel=mel, parts=parts)


# --------------------------------------------------------------------------
# clips
# --------------------------------------------------------------------------
def clip_sonata():
    """Mozart K. 545, 144 BPM: 3 bars per cell."""
    rh, lh = Q("k545", 0, center=76), Q("k545", 1, center=62)
    groove = [(KICK, "X.......x......."), (HAT, "..g...g...g...g."), (SHAKER, "g.g.g.g.g.g.g.g.")]
    c = []
    ch = ["D", "A7", "G/D"]
    c.append(cell("motif", "Mozart's opening on piano, Alberti left hand, pizzicato bass", ch, 4, win(rh, 0, 12),
                  rh=win(rh, 0, 12), lh=vel(win(lh, 0, 12), -20), pz=comp(ch, 4, "r.......f.......", 38, 58),
                  dr=drums(12, groove, 58)))
    ch = ["G/D", "D", "A7"]
    run = notes("A4/.25 C#5/.25 E5/.25 G5/.25 A5/.25 G5/.25 E5/.25 C#5/.25 A4/.25 C#5/.25 E5/.25 G5/.25 A5/1", 8, 74)
    fl = win(rh, 8, 16) + run
    c.append(cell("bridge", "Answer: bars 3-4 on flute, then a rising A7 turn; strings and Alberti piano", ch, 4, fl,
                  fl=vel(fl, -4), lh=vel(win(lh, 8, 16) + comp(["A7"], 4, "1.3.2.3.1.3.2.3.", 57, 64, at=8), -22),
                  vn=pad(ch, 4, 55, 72, 3, 42), pz=comp(ch, 4, "r...f...r...f...", 38, 54),
                  dr=drums(12, [(KICK, "X.......x......."), (SNARE, "....g.......g..."), (HAT, "g.g.g.g.g.g.g.g.")], 56)
                  + fill(11, 1, 30, 62)))
    ch = ["Dm", "Am7", "G/D"]
    c.append(cell("bridge", "Shadow: the opening in D dorian on clarinet, lighter beat", ch, 4, remode(win(rh, 0, 12)),
                  cl=vel(remode(win(rh, 0, 12)), -2), lh=vel(remode(win(lh, 0, 12)), -24),
                  vn=pad(ch, 4, 50, 65, 3, 36), bs=comp(ch, 4, "r---------------", 38, 50, accent=0),
                  dr=drums(12, [(KICK, "x..............."), (SHAKER, "g.x.g.x.g.x.g.x."), (SIDE, "........g.......")], 52)))
    ch = ["G", "D7", "C/G"]
    c.append(cell("bridge", "Lift: the opening in G on violins with flute an octave up, full beat", ch, 4, tr(win(rh, 0, 12), -7),
                  vn=vel(tr(win(rh, 0, 12), -7), -2), fl=vel(tr(win(rh, 0, 12), 5), -26), lh=vel(tr(win(lh, 0, 12), -7), -20),
                  pz=comp(ch, 4, "r...f...r...f...", 38, 60),
                  dr=hit(CRASH, 0, 76) + drums(12, [(KICK, "X...x...X...x..."), (SNARE, "....x.......x..."), (HAT, "g.x.g.x.g.x.g.x.")], 60)))
    ch = ["D", "A7", "D"]
    end = 12
    c.append(cell("denouement", "The opening once more, landing on D at 2.5 s before the end; full chord rings out", ch, 4,
                  win(rh, 0, 6), rh=win(rh, 0, 6) + [(b(6), b(6), [74, 78], 80)],
                  lh=vel(win(lh, 0, 6), -20) + ring("D", 6, end, 50, 66, 3, 64),
                  vn=ring("D", 6, end, 55, 74, 4, 58), pz=comp(["D", "A7"], 4, "r.......r.......", 38, 56) + hit(38, 6, 74, 6),
                  dr=drums(6, groove, 56) + hit(CRASH, 6, 70) + hit(KICK, 6, 80)))
    return dict(id="sonata-sprint", title="Sonata Sprint", bpm=144, bpc=3, quote="k545",
                style="Chamber pop", instruments="Piano, flute, clarinet, strings, pizzicato bass, light kit + shaker",
                desc="Mozart's 'Sonata facile' opening at a brisk 144 BPM with a light beat.",
                inst=dict(rh=(0, 0), lh=(1, 0), fl=(2, 73), vn=(3, 48), pz=(4, 45), bs=(5, 32), cl=(6, 71), dr=(9, None)),
                cells=c)


def clip_maple():
    """Joplin, Maple Leaf Rag A strain, 96 BPM: 2 bars (4 rag bars of 2/4) per cell."""
    rh, lh = Q("maple", 0, center=74, beat=0.25), Q("maple", 1, center=48, beat=0.25)
    rag = [(KICK, "X.......x......."), (SNARE, "....x.......x..."), (HAT, "g.x.g.x.g.x.g.x.")]
    ch = ["D", "A7", "D", "A7"]
    c = [cell("motif", "Joplin's A strain on honky-tonk piano, both hands as written; rag kit", ch, 2,
              rh=win(rh, 0, 8), lh=vel(win(lh, 0, 8), -8), dr=drums(8, rag, 56))]
    s1 = win(rh, 8, 16)
    c.append(cell("bridge", "Answer: second half of the strain on clarinet, banjo chords, tuba bass", ch, 2,
                  cl=fold(mono(s1, high=False), 62, 86), bj=vel(upper(win(lh, 8, 16)), -12),
                  tu=vel(mono(win(lh, 8, 16), high=False), 4),
                  dr=drums(8, [(KICK, "X.......x......."), (SNARE, "....x.......x..."), (RIDE, "x.g.x.g.x.g.x.g.")], 54)))
    c.append(cell("bridge", "Break: stop-time piano, then the strain's second phrase on xylophone with the band back in", ch, 2,
                  rh=win(rh, 0, 4), bj=ring("D", 0, 0.5, 55, 67, 3, 70) + ring("A7", 2, 2.5, 55, 69, 3, 70),
                  tu=notes("D2/.5 R/1.5 A1/.5", 0, 78) + vel(mono(win(lh, 4, 8, at=4), high=False), 4),
                  xy=fold(mono(win(rh, 4, 8, at=4), high=True), 72, 96), lh=vel(win(lh, 4, 8, at=4), -14),
                  dr=hit(KICK, 0, 70) + hit(CRASH, 0, 56) + hit(KICK, 2, 66) + fill(3, 1, 30, 70)
                  + drums(4, rag, 56, at=4)))
    c.append(cell("bridge", "Lift: second half of the strain in G on muted trumpet over the piano left hand", [ctr(x, 5) for x in ch], 2,
                  tp=fold(mono(tr(s1, 5), high=False), 60, 82), lh=vel(tr(win(lh, 8, 16), 5), -10),
                  cl=vel(fold(mono(tr(s1, 5), high=False), 48, 70), -30),
                  dr=hit(CRASH, 0, 74) + drums(8, [(KICK, "X...x...X...x..."), (SNARE, "....x.......x.g."), (HAT, "g.x.g.x.g.x.g.x.")], 58)))
    c.append(cell("denouement", "Opening bar, then a rag cadence on D struck 2.5 s before the end", ["D", "A7", "D", "D"], 2,
                  rh=win(rh, 0, 4) + [(b(4), b(4), [62, 66, 69, 74], 82)], lh=ring("D", 4, 8, 38, 57, 3, 74),
                  tu=vel(mono(win(lh, 0, 4), high=False), 4) + hit(38, 4, 80, 4),
                  bj=vel(upper(win(lh, 0, 4)), -12) + ring("D", 4, 4.5, 55, 67, 3, 66),
                  dr=drums(4, [(KICK, "X.......x......."), (SIDE, "....x.......x..."), (RIDE, "x.g.x.g.x.g.x.g.")], 56)
                  + hit(CRASH, 4, 66) + hit(KICK, 4, 76)))
    return dict(id="maple-strut", title="Maple Strut", bpm=96, bpc=2, quote="maple",
                style="Ragtime", instruments="Honky-tonk piano, clarinet, banjo, tuba, muted trumpet, xylophone, rag kit",
                desc="Joplin's Maple Leaf Rag (1899), A strain, moved to D: piano rag with a small band.",
                inst=dict(rh=(0, 3), lh=(1, 3), bj=(2, 105), tu=(3, 58), cl=(4, 71), tp=(5, 59), xy=(6, 13), dr=(9, None)),
                cells=c)


def clip_soldiers():
    """Soldier's Joy (fiddle reel), 96 BPM: 2 bars per cell, chords per beat."""
    sj = Q("soldiers", 0, center=70, beat=-0.5)     # pickup falls before 0 and is dropped
    S0 = ["D", "D", "D", "D", "D", "D", "Em", "A7"]
    S1 = ["D", "D", "D", "D", "D", "A7", "D", "D"]
    reel = [(KICK, "X.......x......."), (SNARE, "....g.......g..."), (TAMB, "g.x.g.x.")]
    bod = [(LTOM, "x..gx.g.x..gx.g."), (KICK, "X..............."), (TAMB, "..g...g...g...g.")]
    boom = lambda ch, v=52: comp(ch, 1, "b.c.", 48, v)
    bass = lambda ch, v=70: comp(ch, 1, "r...f...", 38, v)
    roll = lambda ch, v=50: comp(ch, 1, "3214", 55, v)
    c = [cell("motif", "The reel's first strain on fiddle, boom-chuck guitar and bass", S0, 1, win(sj, 0, 8),
              fd=win(sj, 0, 8), gt=boom(S0), bs=bass(S0), dr=drums(8, reel, 58))]
    c.append(cell("bridge", "Answer: second strain on tin whistle, banjo rolls, accordion, bodhran", S1, 1, win(sj, 8, 16),
                  wh=vel(win(sj, 8, 16), -4), bj=roll(S1), bs=bass(S1, 64), ac=pad(S1, 1, 55, 69, 3, 34),
                  dr=drums(8, bod, 56)))
    c.append(cell("bridge", "Break: fiddle call, bodhran fill, whistle answer over fiddle chops", S0, 1,
                  fd=win(sj, 0, 2) + vel(comp(S0[4:], 1, "..c.", 60, 44, at=4), 0), wh=win(sj, 4, 8, at=4), bs=bass(S0, 62),
                  dr=drums(2, bod, 56) + fill(2, 2, 34, 76, LTOM) + hit(CRASH, 4, 52) + drums(4, bod, 58, at=4)))
    D0 = ["Dm", "Dm", "Dm", "Dm", "Dm", "Dm", "Em", "Am7"]
    c.append(cell("bridge", "Shadow: the first strain in D dorian on fiddle with accordion and guitar", D0, 1, remode(win(sj, 0, 8)),
                  fd=remode(win(sj, 0, 8)), ac=pad(D0, 1, 55, 69, 3, 40), gt=boom(D0, 48), bs=bass(D0, 62),
                  dr=drums(8, [(LTOM, "x...x..gx...x.g."), (TAMB, "g.x.g.x.")], 52)))
    G1 = [ctr(x, 5) for x in S1]
    c.append(cell("bridge", "Lift: second strain in G, fiddle and whistle together, banjo, full kit", G1, 1, tr(win(sj, 8, 16), 5),
                  fd=tr(win(sj, 8, 16), 5), wh=vel(tr(win(sj, 8, 16), 5), -14), bj=roll(G1, 46), gt=boom(G1, 50), bs=bass(G1),
                  dr=hit(CRASH, 0, 72) + drums(8, [(KICK, "X...x...X...x..."), (SNARE, "....x.......x..."), (TAMB, "g.x.g.x.")], 58)))
    den = ["D", "D", "D", "A7", "D", "D", "D", "D"]
    c.append(cell("denouement", "Opening bar, then the tune's own cadence; D lands 2.5 s before the end", den, 1,
                  win(sj, 0, 2) + win(sj, 12, 14, at=2),
                  fd=win(sj, 0, 2) + win(sj, 12, 14, at=2) + [(b(4), b(4), [62, 74], 86)],
                  gt=boom(den[:4]) + ring("D", 4, 8, 50, 67, 4, 60), bs=bass(den[:4]) + hit(38, 4, 80, 4),
                  ac=ring("D", 4, 8, 57, 69, 3, 40),
                  dr=drums(3, reel, 58) + fill(3, 1, 36, 72, LTOM) + hit(CRASH, 4, 66) + hit(KICK, 4, 78)))
    return dict(id="soldiers-reel", title="Soldier's Reel", bpm=96, bpc=2, quote="soldiers",
                style="Celtic / bluegrass reel", instruments="Fiddle, tin whistle, banjo, steel guitar, accordion, bass, bodhran, kit",
                desc="'Soldier's Joy' (trad., pub. 1883) as a bright fiddle band.",
                inst=dict(fd=(0, 110), wh=(1, 78), bj=(2, 105), gt=(3, 25), bs=(4, 32), ac=(5, 21), dr=(9, None)),
                cells=c)


def clip_ode():
    """Beethoven, Ode to Joy, 96 BPM: half a phrase per cell, synth-pop / arcade."""
    ode = Q("ode", 0, center=76)
    A, Bc = ["D", "G", "A7", "D"], ["Bm", "A", "D", "A"]
    four = [(KICK, "X...x...x...x..."), (CLAP, "....x.......x..."), (HAT, "g.x.g.x.g.x.g.x.")]
    arp = lambda ch, v=46: comp(ch, 2, "12343212", 62, v)
    bass = lambda ch, v=72: comp(ch, 2, "r.r.o.r.", 38, v)
    c = [cell("motif", "The theme's first bar pair on square lead, synth bass and warm pad, four-on-the-floor", A, 2, win(ode, 0, 8),
              ld=win(ode, 0, 8), bs=bass(A), pd=pad(A, 2, 57, 72, 3, 36),
              dr=drums(8, [(KICK, "X...x...x...x..."), (HAT, "g.x.g.x.g.x.g.x.")], 60))]
    c.append(cell("bridge", "Answer: the half cadence on glockenspiel and synth brass, arpeggiator, claps", Bc, 2, win(ode, 8, 16),
                  gl=vel(win(ode, 8, 16), -6), br=vel(tr(win(ode, 8, 16), -12), -14), ar=arp(Bc), bs=bass(Bc),
                  dr=drums(8, four, 58)))
    Dd = ["Dm", "Dm", "Dm", "Am"]
    c.append(cell("bridge", "Shadow: the theme in D dorian, half-time beat, held bass", Dd, 2, remode(win(ode, 0, 8)),
                  ld=vel(remode(win(ode, 0, 8)), -8), ar=arp(Dd, 40), bs=comp(Dd, 2, "r-------", 38, 66, accent=0),
                  pd=pad(Dd, 2, 55, 70, 3, 40),
                  dr=drums(8, [(KICK, "X.........x....."), (SNARE, "........x......."), (HAT, "x.x.x.x.x.x.x.x.")], 54)))
    G = [ctr(x, 5) for x in A]
    c.append(cell("bridge", "Lift: the second phrase in G, lead and brass in octaves, crash", G, 2, tr(win(ode, 16, 24), 5),
                  ld=tr(win(ode, 16, 24), 5), br=vel(tr(win(ode, 16, 24), -7), -10), ar=arp(G), bs=bass(G),
                  dr=hit(CRASH, 0, 74) + drums(8, four + [(OHAT, "..g...g...g...g.")], 60)))
    den = ["Bm", "A", "A7", "D", "D", "D", "D", "D"]
    last = aug(win(ode, 24, 32), 0.5)
    last = last[:-1] + [(last[-1][0], b(8) - last[-1][0], last[-1][2], last[-1][3])]
    c.append(cell("denouement", "The closing bar in double time, landing on D 3 s before the end", den, 1, last,
                  ld=last, gl=vel(last, -10), bs=comp(den[:3], 1, "r.r.", 38, 70) + hit(38, 3, 80, 5),
                  pd=ring("D", 3, 8, 57, 74, 4, 50),
                  dr=drums(3, [(KICK, "X..."), (HAT, "g.x.")], 60) + hit(CRASH, 3, 70) + hit(KICK, 3, 80)))
    return dict(id="ode-arcade", title="Ode Arcade", bpm=96, bpc=2, quote="ode",
                style="Synth-pop / arcade", instruments="Square lead, saw arpeggio, synth bass, warm pad, glockenspiel, synth brass, drum machine",
                desc="Beethoven's 'Ode to Joy' (1824) as bright synth-pop.",
                inst=dict(ld=(0, 80), ar=(1, 81), bs=(2, 38), pd=(3, 89), gl=(4, 9), br=(5, 62), dr=(9, None)),
                cells=c)


def clip_prelude():
    """Bach, Prelude in C (WTC I) in D, 96 BPM: 2 prelude bars per cell; downtempo beat."""
    pr, pl = Q("prelude", 0, center=72, beat=0.5), Q("prelude", 1, center=52, beat=0.5)
    lofi = [(KICK, "X.....x...X....."), (SNARE, "....x.......x..."), (HAT, "g.g.g.g.g.g.g.g.")]
    S0, S1 = ["D", "Em7/D"], ["A7/C#", "D"]
    c = [cell("motif", "Bach's first two bars on electric piano, as written, over a downtempo beat", S0, 4,
              rh=win(pr, 0, 8), lh=win(pl, 0, 8), bs=comp(S0, 4, "r.......r...r...", 38, 66), dr=drums(8, lofi, 56))]
    c.append(cell("bridge", "Answer: bars 3-4 on harp, vibraphone line above, strings", S1, 4, notes("G5/2 E5/2 F#5/4", 0, 70),
                  hp=win(pr, 8, 16), lh=vel(win(pl, 8, 16), -10), vb=notes("G5/2 E5/2 F#5/4", 0, 70),
                  st=pad(S1, 4, 55, 72, 3, 40), bs=comp(S1, 4, "r.......r...r...", 38, 62), dr=drums(8, lofi, 54)))
    D0 = ["Dm", "Em7/D"]
    c.append(cell("bridge", "Shadow: bars 1-2 in D dorian on vibraphone, cello, beat drops to hats", D0, 4, notes("D3/4 E3/4", 0, 60),
                  vb=vel(remode(win(pr, 0, 8)), -8), lh=vel(remode(win(pl, 0, 8)), -14), ce=notes("D3/4 E3/4", 0, 62),
                  dr=drums(8, [(KICK, "x..............."), (HAT, "g.x.g.x.g.x.g.x.")], 50)))
    G1 = [ctr(x, 5) for x in S1]
    c.append(cell("bridge", "Lift: bars 3-4 in G on piano and harp, cello melody, full beat and crash", G1, 4, notes("A3/2 C4/2 B3/4", 0, 70),
                  rh=tr(win(pr, 8, 16), 5), hp=vel(tr(win(pr, 8, 16), -7), -16), lh=vel(tr(win(pl, 8, 16), 5), -8),
                  ce=notes("A3/2 C4/2 B3/4", 0, 70), st=pad(G1, 4, 55, 72, 3, 44), bs=comp(G1, 4, "r.......r...r...", 38, 66),
                  dr=hit(CRASH, 0, 66) + drums(8, lofi + [(SHAKER, "g.x.g.x.")], 56)))
    c.append(cell("denouement", "Bar 1, then a full D chord struck 2.5 s before the end", ["D", "D"], 4, None,
                  rh=win(pr, 0, 4) + [(b(4), b(4), [69, 74, 78], 76)], lh=win(pl, 0, 4) + ring("D", 4, 8, 50, 62, 2, 66),
                  st=ring("D", 4, 8, 55, 74, 4, 50), bs=hit(38, 0, 66, 2) + hit(38, 4, 76, 4),
                  dr=drums(4, lofi, 54) + hit(CRASH, 4, 60) + hit(KICK, 4, 72)))
    return dict(id="prelude-pulse", title="Prelude Pulse", bpm=96, bpc=2, quote="prelude",
                style="Downtempo / neo-classical", instruments="Electric piano, harp, vibraphone, strings, cello, synth bass, downtempo kit",
                desc="Bach's C-major Prelude (in D) as steady 16th-note arpeggios over a downtempo beat.",
                inst=dict(rh=(0, 4), lh=(1, 4), st=(2, 49), bs=(3, 39), vb=(4, 11), hp=(5, 46), ce=(6, 42), dr=(9, None)),
                cells=c)


def clip_minstrel():
    """The Minstrel Boy, 96 BPM: half the tune per cell, Celtic band."""
    mb = Q("minstrel", 0, center=76, beat=-1)
    S0, S1 = ["D", "G", "D", "D"], ["Bm7", "D", "A", "D"]
    bod = [(LTOM, "x..gx.g.x..gx.g."), (KICK, "X.......x......."), (TAMB, "..g...g...g...g.")]
    pick = lambda ch, v=52: comp(ch, 2, "b.3.2.3.", 48, v)
    harp = lambda ch, v=48: comp(ch, 2, "1.2.3.4.", 55, v)
    c = [cell("motif", "The air's first phrase on tin whistle, picked guitar, strings, bodhran", S0, 2, win(mb, 0, 8),
              wh=win(mb, 0, 8), gt=pick(S0), st=pad(S0, 2, 55, 69, 3, 34), ce=comp(S0, 2, "r-------", 38, 56, accent=0),
              dr=drums(8, bod, 54))]
    c.append(cell("bridge", "Answer: second phrase on oboe over harp arpeggios and cello", S1, 2, win(mb, 8, 16),
                  ob=win(mb, 8, 16), hp=harp(S1), ce=comp(S1, 2, "r...f...", 38, 58),
                  dr=drums(8, [(LTOM, "x...x..gx...x.g."), (TAMB, "..g...g.")], 50)))
    G = [ctr(x, 5) for x in S0]
    c.append(cell("bridge", "Lift: the first phrase in G on strings with flute above, harp, crash", G, 2, tr(win(mb, 0, 8), -7),
                  st=vel(tr(win(mb, 0, 8), -7), -4), fl=vel(tr(win(mb, 0, 8), 5), -28), hp=harp(G, 46), gt=pick(G, 46),
                  ce=comp(G, 2, "r...f...", 38, 60), dr=hit(CRASH, 0, 64) + drums(8, bod, 56)))
    den = ["D", "A", "D", "D"]
    m = win(mb, 10, 14)
    c.append(cell("denouement", "The air's last line, ending on D 2.5 s before the end", den, 2, m,
                  wh=m + [(b(4), b(4), [74], 80)], gt=pick(den[:2]) + ring("D", 4, 8, 50, 66, 4, 56),
                  st=ring("D", 4, 8, 55, 74, 4, 44), ce=comp(den[:2], 2, "r...f...", 38, 56) + hit(38, 4, 70, 4),
                  hp=notes("D4/.25 F#4/.25 A4/.25 D5/.25 F#5/2", 4, 50),
                  dr=drums(4, bod, 52) + hit(CRASH, 4, 56)))
    return dict(id="minstrel-road", title="Minstrel Road", bpm=96, bpc=2, quote="minstrel",
                style="Celtic", instruments="Tin whistle, oboe, flute, harp, nylon guitar, strings, cello, bodhran",
                desc="'The Minstrel Boy' (Irish air, 1813) as a warm, walking Celtic band piece.",
                inst=dict(wh=(0, 78), hp=(1, 46), st=(2, 48), ce=(3, 42), gt=(4, 24), fl=(5, 73), ob=(6, 68), dr=(9, None)),
                cells=c)


CLIPS = {"sonata": clip_sonata, "maple": clip_maple, "soldiers": clip_soldiers, "ode": clip_ode,
         "prelude": clip_prelude, "minstrel": clip_minstrel}


# --------------------------------------------------------------------------
# build
# --------------------------------------------------------------------------
def clash(mel, chords, unit):
    """Share of melody notes of a beat or longer that sit a semitone off the chord."""
    long = [(t, n[0]) for t, d, n, v in mel if d >= TPQ * 0.9]
    bad = 0
    for t, k in long:
        pcs = gm.chord(chords[min(len(chords) - 1, int(t // b(unit)))])["pcs"]
        if k % 12 not in pcs and any((k - p) % 12 in (1, 11) for p in pcs):
            bad += 1
    return round(bad / max(1, len(long)), 2)


def bar_variety(merged, bars):
    sig = [set() for _ in range(bars)]
    for l in merged.splitlines():
        e = json.loads(l)
        if e["type"] == "NoteOn":
            t = round(e["t"] / E16) * E16
            if t < bars * gm.BAR:
                sig[t // gm.BAR].add((t % gm.BAR, e["key"], e["ch"]))
    return round(len({frozenset(s) for s in sig}) / bars, 2)


def loud(path, ss=None, t=None):
    pre = (["-ss", str(ss), "-t", str(t)] if ss is not None else [])
    r = subprocess.run(["ffmpeg", "-hide_banner"] + pre + ["-i", str(path), "-af", "loudnorm=print_format=json", "-f", "null", "-"],
                       capture_output=True, text=True).stderr
    j = json.loads(r[r.rindex("{"):r.rindex("}") + 1])
    return float(j["input_i"]), float(j["input_tp"])


def level_cells(path, n, cap=6.0, ramp=0.04):
    """Each cell is used on its own, so give every 5-s cell the same loudness:
    a per-cell gain (at most +-cap dB), with 40 ms ramps at the cell boundaries."""
    lis = [loud(path, i * CELL, CELL)[0] for i in range(n)]
    mean = sum(lis) / n
    lin = [10 ** (max(-cap, min(cap, mean - li)) / 20) for li in lis]
    pcm = subprocess.run(["ffmpeg", "-loglevel", "error", "-i", str(path), "-f", "f32le", "-ac", "2", "-"],
                         capture_output=True, check=True).stdout
    a = array.array("f", pcm)
    cs, r = round(CELL * SR), round(ramp * SR)
    for f in range(len(a) // 2):
        i = min(n - 1, f // cs)
        g = lin[i]
        off = f - i * cs
        if i > 0 and off < r:          # ramp from the previous cell's gain
            x = (off + r) / (2 * r)
            g = lin[i - 1] * (1 - x) + lin[i] * x
        elif i < n - 1 and cs - off <= r:
            x = (r - (cs - off)) / (2 * r)
            g = lin[i] * (1 - x) + lin[i + 1] * x
        a[2 * f] *= g
        a[2 * f + 1] *= g
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-f", "f32le", "-ar", str(SR), "-ac", "2", "-i", "-",
                    "-c:a", "pcm_f32le", str(path)], input=a.tobytes(), check=True)


def build(clip):
    cid, bpm, bpc, cells = clip["id"], clip["bpm"], clip["bpc"], clip["cells"]
    assert abs(bpc * 4 * 60 / bpm - CELL) < 1e-9, "a cell must be exactly 5 s of whole bars"
    ct, n = bpc * gm.BAR, len(cells)
    L = n * CELL
    per = {k: [] for k in clip["inst"]}
    for i, c in enumerate(cells):
        for k, ev in c["parts"].items():
            for t, d, ns, v in ev:
                if 0 <= t < ct:
                    per[k].append((t + i * ct, d if i == n - 1 else min(d, ct - t), ns, v))
    layers = []
    for k, ev in per.items():
        ch, patch = clip["inst"][k]
        seed = zlib.crc32(f"{cid}:{k}".encode()) % 100000
        layers.append(gm.layer(sorted(ev), ch, patch, seed, *((3, 8) if ch == 9 else (6, 6))))
    tempo = json.dumps({"type": "Tempo", "t": 0, "bpm": bpm}) + "\n"
    merged = gm.run([BIN / "viz", "--width", 72], tempo + "".join(x for x in layers if x))
    mid = OUT / f"{cid}.mid"
    gm.run([BIN / "to-midi", "--out", mid], merged)
    raw, cut, wav = TMP / f"{cid}-raw.wav", TMP / f"{cid}-cut.wav", OUT / f"{cid}.wav"
    gm.run(["fluidsynth", "-ni", "-g", "0.5", "-r", SR, "-O", "float", "-T", "wav", "-F", raw, gm.SF2, mid])
    gm.run(["ffmpeg", "-y", "-loglevel", "error", "-i", raw, "-t", f"{L:.3f}", "-af",
            f"afade=t=in:d=0.004,afade=t=out:st={L - 1.6:.3f}:d=1.6", "-c:a", "pcm_f32le", cut])
    level_cells(cut, n)
    li, tp = loud(cut)
    gain = min(LUFS - li, PEAK - tp)
    gm.run(["ffmpeg", "-y", "-loglevel", "error", "-i", cut, "-af", f"volume={gain:.2f}dB", "-c:a", "pcm_s16le", wav])
    marks = ",".join(f"drawbox=x={round(1000 * i / n) - 1}:y=0:w=2:h=110:color=white@0.35:t=fill" for i in range(1, n))
    gm.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav, "-filter_complex",
            f"showwavespic=s=1000x110:scale=sqrt:colors=#a78bfa,{marks}", "-frames:v", "1", wav.with_suffix(".png")])
    var = bar_variety(merged, n * bpc)
    m = gm.PD[clip["quote"]]
    print(f"== {cid}: {L:.0f}s, {n} cells, {bpm} BPM, unique bars {var:.2f}  ({m['composer']}: {m['title'][:40]})")
    out_cells = []
    for i, c in enumerate(cells):
        ci, _ = loud(wav, i * CELL, CELL)
        cl = clash(c["mel"], c["chords"], c["unit"]) if c["mel"] else None
        print(f"   {i * CELL:4.0f}-{(i + 1) * CELL:2.0f}s {c['role']:10s} {ci:6.1f} LUFS  clash {cl if cl is not None else '-'}  {c['label'][:58]}")
        out_cells.append(dict(index=i, start=i * CELL, end=(i + 1) * CELL, role=c["role"], label=c["label"],
                              chords=c["chords"], lufs=round(ci, 1)))
    return dict(id=cid, title=clip["title"], style=clip["style"], instruments=clip["instruments"], desc=clip["desc"],
                bpm=bpm, bars_per_cell=bpc, seconds=L, cell_seconds=CELL, cells=out_cells, unique_bars=var,
                file=wav.name, midi=mid.name, png=wav.with_suffix(".png").name,
                quote=dict(title=m["title"], composer=m["composer"], year=m["year"], source=m["source"]))


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    TMP.mkdir(parents=True, exist_ok=True)
    gm.OUT, gm.TMP = OUT, TMP
    names = sys.argv[1:] or list(CLIPS)
    cat_path = OUT / "catalog.json"
    old = {c["id"]: c for c in json.loads(cat_path.read_text())["clips"]} if cat_path.exists() else {}
    for name in names:
        info = build(CLIPS[name]())
        old[info["id"]] = info
    order = [CLIPS[k]()["id"] for k in CLIPS]
    cat = dict(
        note="Slide-transition beds. Every clip is a whole number of 5-second cells; each cell starts on a downbeat. "
             "Use 0-5 for an opening slide, any n-to-n+5 for separators (n = a cell start gives a complete musical "
             "phrase; no cell repeats another), and L-5 to L for the closing slide (ends on the home chord).",
        loudness=dict(integrated_lufs=LUFS, true_peak_db=PEAK),
        slice_command="examples/slice-5s.sh <clip>.wav <start-seconds | first | last> [out.wav]",
        clips=[old[i] for i in order if i in old])
    cat_path.write_text(json.dumps(cat, indent=1))
    print("wrote", cat_path)


if __name__ == "__main__":
    main()
