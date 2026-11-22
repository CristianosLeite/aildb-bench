#!/usr/bin/env python3
"""Make a LanceDB table of the records of a snapshot of aildb.

    lance_make.py SNAPSHOT DIRECTORY

The table "records" in the database at DIRECTORY, which is made anew,
gets a row for each record, in the order of the snapshot: id (the
ordinal), path, start_line, end_line and vector, the binary32 that the
snapshot stores, bit for bit. No index is made, so a search of the table
compares the query with every row. docs/format.md is the layout read
here; the snapshot is taken to be valid ("aildb check").
"""
import shutil
import struct
import sys

import lancedb
import numpy
import pyarrow


def main(argv):
    if len(argv) != 3:
        sys.stderr.write(__doc__.split("\n\n")[1] + "\n")
        return 2
    with open(argv[1], "rb") as f:
        head = f.read(128)
        if head[:8] != b"AILDBIDX":
            sys.stderr.write("lance_make.py: not a snapshot\n")
            return 1
        count, dim = struct.unpack_from("<QQ", head, 24)
        records, strings, strsize, vectors = struct.unpack_from("<QQQQ", head, 40)
        f.seek(records)
        recs = numpy.frombuffer(f.read(24 * count), "<u4").reshape(count, 6)
        text = f.read(strsize)
        f.seek(vectors)
        flat = numpy.frombuffer(f.read(4 * dim * count), "<f4")
    paths = [text[o : o + n].decode() for o, n in recs[:, :2].tolist()]
    table = pyarrow.table(
        {
            "id": pyarrow.array(range(count), pyarrow.uint32()),
            "path": pyarrow.array(paths, pyarrow.string()),
            "start_line": pyarrow.array(recs[:, 4], pyarrow.uint32()),
            "end_line": pyarrow.array(recs[:, 5], pyarrow.uint32()),
            "vector": pyarrow.FixedSizeListArray.from_arrays(pyarrow.array(flat), dim),
        }
    )
    shutil.rmtree(argv[2], ignore_errors=True)
    lancedb.connect(argv[2]).create_table("records", table)
    print("%d rows of %d dimensions, lancedb %s" % (count, dim, lancedb.__version__))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
