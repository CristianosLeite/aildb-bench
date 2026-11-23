# aildb-bench

The measurements of [aildb](https://github.com/CristianosLeite/aildb), a local, file-based vector search engine written in [AIL](https://github.com/CristianosLeite/ail): how long a query takes and how much memory it needs, against the Python binding of [LanceDB](https://lancedb.com) on the same stored vectors and the same query. The programs were in `bench/` of aildb until its version 0.1.0 and are here since 2026-11-22, as the benchmarks of AIL are in ail-bench.

The engine that is measured is the package aildb at the version of `Ailfile`, whose revision is in `Ailfile.lock`; nothing of it is copied here. `build/aildb` is compiled from its sources with the hooks it is shipped with, and for `v0.1.0`, compiled by AIL 0.1.0, it was byte for byte the executable of the archive that `make dist` of aildb makes. Since 2026-11-22 the package is 0.1.1 and measures aildb 0.1.1 with AIL 0.1.1.

[docs/performance.md](docs/performance.md) says how a query is measured and has the figures of each run, with the revisions and the commands that made them.

## Requirements

x86-64 Linux and AIL, whose command `ail` builds and tests a package (`make AIL=../ail/build/ail` names the command of a checkout that is not installed). The first build fetches aildb into `deps/` with git. `make bench` needs a Python with the package `lancedb`.

## Commands

```
make                         # build/: aildb, aildb-times, bench-run, bench-gen, bench-scan, bench-stay
make test                    # the tests of the harness and of the programs, and the indentation
make bench PY=/path/to/python   # the measurements; the report is build/bench/report.txt
```

| Program | Source | What it is |
|---|---|---|
| `build/aildb` | `src/aildb.aiw` | the engine as it is shipped |
| `build/aildb-times` | `src/times.aiw` | the same commands with the hooks of `bench/hook.aiw`, which say on stderr when each part of a search was done |
| `build/bench-run` | `bench/run.aiw`, `bench/stat.aiw` | the harness: rounds of a command, the median and the 95th percentile of the wall and CPU time and of the peak resident memory |
| `build/bench-gen` | `bench/gen.aiw` | the inputs, the same bytes every run |
| `build/bench-scan` | `bench/scan.aiw` | the scan of a snapshot read in three ways: a mapping, a mapping that is populated, and reads |
| `build/bench-stay` | `bench/stay.aiw` | a process that opens a snapshot once and searches it again and again, with the library of aildb |

`bench/bench.sh` is what `make bench` runs, and `bench/lance_make.py`, `lance_query.py` and `lance_same.py` make the table of LanceDB from a snapshot, search it, once or again and again in one process (`LANCE_STAY`), with the filters of `search`, and compare the answers of the two engines.

To measure another version of aildb, `ail update aildb` moves the dependency to its latest tag, and `ail add --path ../aildb` names a checkout in its place.

## License

Apache License 2.0, the file `LICENSE`, as aildb.
