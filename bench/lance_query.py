#!/usr/bin/env python3
"""Search a table of lance_make.py as "aildb search" searches a snapshot.

    lance_query.py DIRECTORY QUERY LIMIT

QUERY is a file with the query vector as raw binary32. The LIMIT rows
with the highest cosine similarity are printed, best first, a line of
JSON each as aildb prints them, without score_bits and with the ordinal
as id. LanceDB gives a cosine distance, a binary32; the score is 1 less
that.

On stderr are the lines that bench/run.aiw reads, "@ NAME N" with the
time of CLOCK_MONOTONIC in nanoseconds at a moment, and "= NAME N" with
kibibytes of /proc/self/status at the end:

    entry      the first line of this program: the interpreter has started
    imported   lancedb, pyarrow and numpy are loaded
    opened     the database is connected, the table open, the query read
    searched   the search has run and its rows are an Arrow table
    printed    the lines are written
"""
import time

MARKS = [("entry", time.monotonic_ns())]

import json
import sys

import lancedb
import numpy

MARKS.append(("imported", time.monotonic_ns()))


def main(argv):
    if len(argv) != 4:
        sys.stderr.write(__doc__.split("\n\n")[1] + "\n")
        return 2
    table = lancedb.connect(argv[1]).open_table("records")
    query = numpy.fromfile(argv[2], "<f4")
    MARKS.append(("opened", time.monotonic_ns()))
    rows = (
        table.search(query)
        .metric("cosine")
        .limit(int(argv[3]))
        .select(["id", "path", "start_line", "end_line", "_distance"])
        .to_arrow()
    )
    MARKS.append(("searched", time.monotonic_ns()))
    out = []
    for rank, row in enumerate(rows.to_pylist(), 1):
        out.append(
            json.dumps(
                {
                    "rank": rank,
                    "score": round(1.0 - row["_distance"], 6),
                    "id": row["id"],
                    "path": row["path"],
                    "start_line": row["start_line"],
                    "end_line": row["end_line"],
                },
                separators=(",", ":"),
            )
        )
    sys.stdout.write("".join(line + "\n" for line in out))
    sys.stdout.flush()
    MARKS.append(("printed", time.monotonic_ns()))
    said = ["@ %s %d\n" % mark for mark in MARKS]
    with open("/proc/self/status") as f:
        for line in f:
            name, _, value = line.partition(":")
            if name in ("VmHWM", "RssAnon", "RssFile"):
                said.append("= %s %s\n" % (name, value.split()[0]))
    sys.stderr.write("".join(said))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
