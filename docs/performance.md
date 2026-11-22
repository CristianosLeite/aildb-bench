# Performance

How a query of aildb is measured, and the figures of each run with the
revisions that made them.

## Where the first figures are

The first measurements, top-10 at 10,000 and 100,000 vectors of 768
dimensions against the Python binding of LanceDB, were made on
2026-11-21 with these programs as they were in `bench/` of aildb, at its
revision `4a21a3e`. Their method, figures and what was decided from them
are in [docs/performance.md of aildb](https://github.com/CristianosLeite/aildb/blob/main/docs/performance.md),
which is not repeated here: the boundaries of each time, what cold means
and how it is verified, how mapped pages count in the peak resident
memory, the inputs, and the comparison with LanceDB.

## What a report says of itself

`make bench` writes `build/bench/report.txt`. Since the programs are
here, its first lines name what made it:

- `aildb-bench`: the revision of this repository, and whether the files
  had changes;
- `aildb`: the revision and the version that `Ailfile.lock` has, which is
  the source `build/aildb` and `build/aildb-times` are compiled from;
- `AIL`: the version of the command and the revision of the checkout it
  is in (`AILREV=` names it for an AIL that is installed);
- the versions of LanceDB, pyarrow and Python, the machine, and the
  filesystem and device of the files.

Each measurement has the command that was run before its figures. A
figure that is written into this document is copied from a report, with
those lines.

## Runs

None yet with the programs in this repository.
