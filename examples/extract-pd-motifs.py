#!/usr/bin/env python3
"""Extract short public-domain quotations from music21's bundled corpus into
examples/pd-motifs.json, which examples/game-music.py reads (so the generator
itself needs no third-party packages).

All sources are compositions from before 1900 (or traditional) in editions
shipped with music21. Notes are stored as [onset_beats, dur_beats, midi] in the
original key; the generator transposes them.

Usage (repo root):  uv pip install --python .venv/bin/python music21
                    .venv/bin/python examples/extract-pd-motifs.py
"""
import json
from pathlib import Path

from music21 import corpus

OUT = Path(__file__).resolve().parent / "pd-motifs.json"

SPECS = [
    # id, corpus path, opus title (or None), parts, measures, tonic, mode, metadata
    ("grenadiers", "miscFolk/americanfifeopus.abc", "British Grenadiers", [0], (0, 4), "D", "major",
     dict(title="The British Grenadiers", composer="traditional (English)", year="c. 1700s",
          source="music21 corpus: American fife tunes (miscFolk/americanfifeopus.abc)")),
    ("minstrel", "miscFolk/americanfifeopus.abc", "Minstrel Boy", [0], (0, 4), "G", "major",
     dict(title="The Minstrel Boy", composer="traditional Irish air (The Moreen), words Thomas Moore", year="1813",
          source="music21 corpus: American fife tunes (miscFolk/americanfifeopus.abc)")),
    ("tyne", "miscFolk/northumbrianminstrelsyopus.abc", "Water of Tyne", [0], (0, 4), "D", "major",
     dict(title="The Water of Tyne", composer="traditional (Northumbrian)", year="pub. 1882",
          source="music21 corpus: Northumbrian Minstrelsy (miscFolk/northumbrianminstrelsyopus.abc)")),
    ("hero", "airdsAirs/book3.abc", "Conquering Hero", [0], (0, 4), "G", "major",
     dict(title="See the Conquering Hero Comes (Judas Maccabaeus)", composer="G. F. Handel", year="1747",
          source="music21 corpus: Aird's Airs book 3 (airdsAirs/book3.abc)")),
    ("gow", "airdsAirs/book3.abc", "Neil Gows Lamentation", [0], (0, 2), "D", "major",
     dict(title="Lamentation for Abercairney", composer="Niel Gow", year="c. 1790",
          source="music21 corpus: Aird's Airs book 3 (airdsAirs/book3.abc)")),
    ("passion", "bach/bwv244.62.mxl", None, [0, 1, 2, 3], (0, 2), "A", "minor",
     dict(title="Passion Chorale 'Wenn ich einmal soll scheiden' (St Matthew Passion)", composer="J. S. Bach",
          year="1727", source="music21 corpus: bach/bwv244.62.mxl (SATB)")),
    ("prelude", "bach/bwv846.mxl", None, None, (1, 4), "C", "major",
     dict(title="Prelude in C major, WTC I", composer="J. S. Bach", year="1722",
          source="music21 corpus: bach/bwv846.mxl")),
]

# Not in the corpus: the Dies irae sequence (13th-century chant, first phrase),
# as quoted by Berlioz (Symphonie fantastique, 1830) and Liszt (Totentanz).
DIES_IRAE = dict(id="dies", title="Dies irae (first phrase)", composer="plainchant; quoted by Berlioz 1830",
                 year="13th c.", source="chant, written out by hand: F E F D E C D D", tonic="D", mode="dorian",
                 meter="free", parts=[[[0, 1, 65], [1, 1, 64], [2, 1, 65], [3, 1, 62], [4, 1, 64], [5, 1, 60],
                                       [6, 1, 62], [7, 1, 62]]])

PCS = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}


def pick(path, title):
    s = corpus.parse(path)
    if title is None:
        return s
    return next(sc for sc in s.scores if sc.metadata.title and title.lower() in sc.metadata.title.lower())


def notes_of(stream, first_offset):
    out = []
    for n in stream.flatten().notes:
        if n.duration.isGrace or n.quarterLength <= 0:
            continue
        on = round(float(n.offset) - first_offset, 4)
        for p in (n.pitches if n.isChord else [n.pitch]):
            out.append([on, round(float(n.quarterLength), 4), p.midi])
    return out


def main():
    motifs = []
    for mid, path, title, parts, (m0, m1), tonic, mode, meta in SPECS:
        s = pick(path, title)
        srcparts = s.parts if parts is None else [s.parts[i] for i in parts] if s.parts else [s]
        sel = [p.measures(m0, m1) for p in srcparts]
        start = min(float(x.offset) for p in sel for x in p.flatten().notesAndRests)
        ts = s.recurse().getElementsByClass("TimeSignature").first()
        motifs.append(dict(id=mid, **meta, tonic=tonic, tonic_pc=PCS[tonic], mode=mode,
                           meter=ts.ratioString if ts else "4/4", measures=f"{m0}-{m1}",
                           parts=[notes_of(p, start) for p in sel]))
        print(f"{mid:11s} {len(motifs[-1]['parts'])} part(s), {sum(len(p) for p in motifs[-1]['parts'])} notes  {meta['title']}")
    DIES_IRAE["tonic_pc"] = 2
    motifs.append(DIES_IRAE)
    OUT.write_text(json.dumps({"note": "Public-domain quotations; see examples/extract-pd-motifs.py", "motifs": motifs},
                              indent=1))
    print("wrote", OUT)


if __name__ == "__main__":
    main()
