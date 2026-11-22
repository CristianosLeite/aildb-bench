#!/usr/bin/env python3
"""Compare what "aildb search" and lance_query.py printed for one query.

    lance_same.py AILDB_OUTPUT LANCE_OUTPUT

Says whether the two have the same records in the same order, by path
and lines, and the largest difference between two scores of a rank,
taken from score_bits on the side of aildb. The status is 0 if the
records are the same and no score differs by more than 1e-5, the
tolerance of docs/format.md for an engine that computes in binary32.
"""
import json
import struct
import sys


def main(argv):
    if len(argv) != 3:
        sys.stderr.write(__doc__.split("\n\n")[1] + "\n")
        return 2
    ours = [json.loads(line) for line in open(argv[1])][1:]
    theirs = [json.loads(line) for line in open(argv[2])]
    where = lambda r: (r["path"], r["start_line"], r["end_line"])
    same = [where(r) for r in ours] == [where(r) for r in theirs]
    worst = 0.0
    for a, b in zip(ours, theirs):
        exact = struct.unpack(">d", bytes.fromhex(a["score_bits"]))[0]
        worst = max(worst, abs(exact - b["score"]))
    print(
        "%d and %d results, %s; largest difference of a score: %.1e"
        % (len(ours), len(theirs), "the same records in the same order" if same else "NOT the same records", worst)
    )
    return 0 if same and worst <= 1e-5 else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
