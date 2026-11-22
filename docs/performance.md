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

## What is measured since 2026-11-22

Besides a process a query without a filter, which the first figures were:

- **A filter.** The generator gives every fourth record the language
  `markdown`, and a path is `src/f<n>.aiw`, fifty records a file. `-l
  markdown` takes a quarter of the records, and `-p src/f12` the files
  `f12`, `f120` to `f129` and so on, about one record of eighteen. LanceDB
  gets the same as a filter applied before the search
  (`starts_with(path, ...)`, `language = ...`), and the answers of the two
  engines are compared before they are timed.
- **A process that stays.** `build/bench-stay` opens a snapshot once
  through the library of aildb (`aildb:src/lib/search.aiw`), reads the
  query and runs the search 21 times, each with its results read back;
  `bench/lance_query.py` with `LANCE_STAY=21` does the same with an open
  table. Run alone, bound to the processor, each says the median and the
  95th percentile of a search after the first. Run in 7 rounds under the
  harness, warm and cold, its moments give the time of the opening (from
  the moment before it: the start of the program for aildb, the end of
  the imports for LanceDB) and of the first search, which is the one that
  reads the vectors from the drive when they are not in memory.
- **1,000,000 records**, a snapshot of 3.1 GB.

## Runs

### 2026-11-22, aildb 0.1.0

`make AIL=../ail-packages/build/ail bench PY=~/.cache/aildb-bench/venv/bin/python`
printed [reports/2026-11-22-81ba841.txt](../reports/2026-11-22-81ba841.txt)
on 2026-11-22. Its first lines:

```
aildb-bench: 81ba841
aildb: 467b91bcb6e9070d67b400c00ddbd67366a79ff4 (version 0.1.0), the revision of Ailfile.lock
AIL: ail 0.1.0, revision 9b94a9b, the command that built the programs
LanceDB: lancedb 0.41.0, pyarrow 26.0.1, Python 3.12.13
machine: 12th Gen Intel(R) Core(TM) i7-12700H, 20 processors, 63016 MiB, Linux 7.0.0-44-generic
files: ext4 on /dev/nvme0n1p3
```

The measured processes were bound to processor 2, except in the columns
"every processor". Rounds: 101 warm and 31 cold for aildb, 31 and 15 for
LanceDB, 7 for a process that stays; before every cold round 0 pages of
the files were in memory. **The machine was not left alone**: while the
run went on, which took 73 minutes, other programs were
compiled and tested on it, on other processors. The medians below are
what the report has; a 95th percentile far from its median, as the 556 ms
of a search of aildb in a process at 1,000,000, is to be read with that
in mind, and the run is to be made again on a still machine before a
decision is taken from it.

The tables are made from the report by a program, not typed: times in
milliseconds, the median and then the 95th percentile. The report has
the command of every measurement, the times of the parts, the processor
time and the memory.

### 10,000 records

A process a query, the wall time of the process:

| Search | File cache | aildb | LanceDB, one processor | LanceDB, every processor |
|---|---|---:|---:|---:|
| no filter | warm | 4.439 / 4.560 | 671.398 / 681.139 | 756.197 / 776.579 |
| no filter | cold | 17.899 / 18.797 | 691.221 / 696.842 | 780.102 / 802.343 |
| `-p src/f12` | warm | 0.571 / 0.616 | 672.114 / 679.240 | 761.144 / 776.876 |
| `-p src/f12` | cold | 2.533 / 3.304 | 699.315 / 706.694 | not run |
| `-l markdown` | warm | 2.232 / 2.343 | 672.782 / 687.636 | 756.839 / 783.229 |
| `-l markdown` | cold | 24.217 / 27.283 | 692.866 / 697.386 | not run |

A process that stays, 21 searches without a filter:

| What | File cache | aildb | LanceDB, one processor | LanceDB, every processor |
|---|---|---:|---:|---:|
| a search after the first, in one process | warm | 3.828 / 4.322 | 11.121 / 14.813 | 20.305 / 26.173 |
| opening the snapshot or the table and reading the query | warm | 0.271 / 0.291 | 1.480 / 1.531 | 3.781 / 4.037 |
| opening the snapshot or the table and reading the query | cold | 0.642 / 0.677 | 12.516 / 12.643 | 14.870 / 15.606 |
| the first search | warm | 4.769 / 5.089 | 30.241 / 30.451 | 31.546 / 33.857 |
| the first search | cold | 16.908 / 17.182 | 40.328 / 42.392 | 44.765 / 47.115 |

### 100,000 records

A process a query, the wall time of the process:

| Search | File cache | aildb | LanceDB, one processor | LanceDB, every processor |
|---|---|---:|---:|---:|
| no filter | warm | 43.535 / 44.531 | 937.970 / 951.829 | 952.076 / 971.298 |
| no filter | cold | 192.207 / 197.967 | 1001.590 / 1012.716 | 1087.401 / 1125.030 |
| `-p src/f12` | warm | 4.831 / 6.827 | 954.178 / 966.692 | 950.516 / 985.142 |
| `-p src/f12` | cold | 14.458 / 15.316 | 1018.171 / 1039.100 | not run |
| `-l markdown` | warm | 25.778 / 28.544 | 981.118 / 1036.018 | 1004.528 / 1030.399 |
| `-l markdown` | cold | 245.772 / 262.422 | 1049.985 / 1060.218 | not run |

A process that stays, 21 searches without a filter:

| What | File cache | aildb | LanceDB, one processor | LanceDB, every processor |
|---|---|---:|---:|---:|
| a search after the first, in one process | warm | 38.974 / 39.644 | 258.455 / 265.733 | 204.552 / 211.200 |
| opening the snapshot or the table and reading the query | warm | 2.267 / 2.332 | 1.416 / 1.480 | 3.684 / 4.748 |
| opening the snapshot or the table and reading the query | cold | 3.041 / 6.701 | 12.354 / 12.396 | 15.091 / 15.454 |
| the first search | warm | 48.735 / 50.149 | 307.863 / 309.477 | 225.175 / 233.413 |
| the first search | cold | 189.530 / 294.013 | 357.362 / 360.218 | 347.934 / 355.433 |

### 1,000,000 records

A process a query, the wall time of the process:

| Search | File cache | aildb | LanceDB, one processor | LanceDB, every processor |
|---|---|---:|---:|---:|
| no filter | warm | 430.147 / 434.274 | 3494.234 / 3511.044 | 2851.687 / 2895.669 |
| no filter | cold | 2227.195 / 2244.413 | 3876.774 / 3912.447 | 3893.166 / 3956.530 |
| `-p src/f12` | warm | 48.447 / 66.566 | 3516.439 / 3542.183 | 2820.162 / 2843.392 |
| `-p src/f12` | cold | 147.930 / 151.624 | 3883.767 / 3894.606 | not run |
| `-l markdown` | warm | 242.725 / 245.430 | 3720.827 / 3920.656 | 3133.899 / 3181.074 |
| `-l markdown` | cold | 2467.151 / 2546.237 | 4360.963 / 4408.521 | not run |

A process that stays, 21 searches without a filter:

| What | File cache | aildb | LanceDB, one processor | LanceDB, every processor |
|---|---|---:|---:|---:|
| a search after the first, in one process | warm | 382.645 / 556.068 | 2863.495 / 2886.149 | 2103.162 / 2120.864 |
| opening the snapshot or the table and reading the query | warm | 22.816 / 23.624 | 1.442 / 1.513 | 3.953 / 4.631 |
| opening the snapshot or the table and reading the query | cold | 26.201 / 36.833 | 12.368 / 12.477 | 14.733 / 15.540 |
| the first search | warm | 449.566 / 452.432 | 2857.490 / 2894.460 | 2105.911 / 2126.609 |
| the first search | cold | 2226.024 / 2249.676 | 3224.948 / 3243.421 | 3143.944 / 3164.780 |

What the figures say, and no more than that:

- For aildb a search in a process that stays takes about the time of a
  process a query, less its start: 38.974 against 43.535 ms at 100,000
  and 382.645 against 430.147 ms at 1,000,000. The scan is the cost, and
  keeping the snapshot open saves the opening, 2.3 and 22.8 ms warm.
- For LanceDB most of a process a query is the start of the interpreter
  and its libraries: at 10,000 records 671 ms a process against 11 ms a
  search in a process that stays.
- A filter makes a search of aildb shorter by about the share of the
  records it leaves out, warm; cold, the language filter was not faster
  than no filter (245.772 against 192.207 ms at 100,000), which was not
  looked into.
- At 1,000,000 records a search of aildb is 430 ms warm and 2.2 s cold, a
  process a query.

No target of latency is set and nothing was decided from this run (the
user, 2026-11-22: measure only). Whether a scan on several threads or an
approximate index is to be tried is open, in the TODO of aildb.
