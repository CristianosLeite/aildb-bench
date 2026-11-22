#!/usr/bin/env python3
"""Search a table of lance_make.py as "aildb search" searches a snapshot.

    lance_query.py DIRECTORY QUERY LIMIT [PREFIX [LANGUAGE]]

QUERY is a file with the query vector as raw binary32. The LIMIT rows
with the highest cosine similarity are printed, best first, a line of
JSON each as aildb prints them, without score_bits and with the ordinal
as id. LanceDB gives a cosine distance, a binary32; the score is 1 less
that. PREFIX and LANGUAGE are the filters of "aildb search -p" and
"-l", "-" for none: only rows whose path starts with PREFIX and whose
language is LANGUAGE are compared with the query, the filter applied
before the search, so that the rows are the best of those that pass.

With the environment variable LANCE_STAY set to a number above 1, the search
is run that many times in this process, the table open, and the lines
on stderr have "first" and "last" in place of "searched" and "printed",
as bench/stay.aiw has them, followed by the median and the 95th
percentile of a search after the first.

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
import os
import sys

import lancedb
import numpy

MARKS.append(("imported", time.monotonic_ns()))


def main(argv):
    if not 4 <= len(argv) <= 6:
        sys.stderr.write(__doc__.split("\n\n")[1] + "\n")
        return 2
    quote = lambda text: "'" + text.replace("'", "''") + "'"
    where = []
    if len(argv) > 4 and argv[4] != "-":
        where.append("starts_with(path, %s)" % quote(argv[4]))
    if len(argv) > 5 and argv[5] != "-":
        where.append("language = %s" % quote(argv[5]))
    stay = int(os.environ.get("LANCE_STAY", "1"))
    table = lancedb.connect(argv[1]).open_table("records")
    query = numpy.fromfile(argv[2], "<f4")
    MARKS.append(("opened", time.monotonic_ns()))

    def search():
        found = table.search(query).metric("cosine").limit(int(argv[3]))
        if where:
            found = found.where(" AND ".join(where), prefilter=True)
        return found.select(["id", "path", "start_line", "end_line", "_distance"]).to_arrow()

    rows = search()
    MARKS.append(("first" if stay > 1 else "searched", time.monotonic_ns()))
    took = []
    for _ in range(stay - 1):
        before = time.monotonic_ns()
        search()
        took.append(time.monotonic_ns() - before)
    if stay > 1:
        MARKS.append(("last", time.monotonic_ns()))
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
    if stay == 1:
        MARKS.append(("printed", time.monotonic_ns()))
    said = ["@ %s %d\n" % mark for mark in MARKS]
    with open("/proc/self/status") as f:
        for line in f:
            name, _, value = line.partition(":")
            if name in ("VmHWM", "RssAnon", "RssFile"):
                said.append("= %s %s\n" % (name, value.split()[0]))
    if took:
        # the median and the percentile as bench/stat.aiw has them
        took.sort()
        n = len(took)
        median = took[n // 2] if n % 2 else (took[n // 2 - 1] + took[n // 2]) // 2
        p95 = took[(95 * n + 99) // 100 - 1]
        said.append("searches after the first: %d\n" % n)
        said.append("milliseconds      median      95th percentile\n")
        said.append("a search          %.3f       %.3f\n" % (median / 1e6, p95 / 1e6))
    sys.stderr.write("".join(said))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
