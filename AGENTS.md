# AGENTS.md

This file provides guidance to AI coding agents when working with code in this repository.

## What this is

The measurements of aildb (https://github.com/CristianosLeite/aildb), a vector search engine written in AIL (https://github.com/CristianosLeite/ail). The programs were `bench/` of aildb and left it on 2026-11-22 (user, 2026-11-22), as the benchmarks of AIL are in ail-bench. The `AGENTS.md` of aildb and its `docs/` describe the engine, and its knowledge base (`.agents/knowledge/testing/measurement.md` there) has the decisions about how a query is measured; read them before changing a measurement. This repository has no knowledge base of its own yet: a decision taken here is written in `docs/performance.md` or in this file.

## State

The repository was made on 2026-11-22 by the agent, on the user's machine, and is not published: it has no remote, and one is the user's to create. The figures of the first measurements, of 2026-11-21 at the revision `4a21a3e` of aildb, are in `docs/performance.md` of aildb, made by the programs as they were there.

## How it is built

- It is a package of AIL: `Ailfile` names what is built and the dependency `aildb`, by its address and a version, and `Ailfile.lock` has the revision of that version. `ail build` fetches it into `deps/`, which git ignores.
- `src/aildb.aiw` compiles `aildb:src/main.aiw` with `aildb:src/hook.aiw`, the hooks that do nothing: `build/aildb`, the engine that is measured. `src/times.aiw` compiles the same commands with `bench/hook.aiw`: `build/aildb-times`, which writes the four moments of a search (`hookmark`) and the memory of the process to stderr.
- The programs of `bench/` use the libraries of the engine through `use "aildb:src/lib/<name>.aiw"`, and the tests start programs with `aildb:tests/lib/cmd.aiw`, which finds them in `build/`.
- `make test` is `ail test` and `ail fmt --check`: `tests/bench_stat.aiw` (the percentile and the median) and `tests/bench_tools.aiw` (the generator, the scan, the engine with times and the harness) and `tests/bench_stay.aiw` (the process that stays prints what `search` prints, with the filters).
- `bench/stay.aiw`, `build/bench-stay`, searches a snapshot it keeps open through `aildb:src/lib/search.aiw`; `bench/lance_query.py` does the same with a table when `LANCE_STAY` is a number above 1. `bench/bench.sh` measures, at each size, a process a query with and without a filter (a prefix and a language, which the generator gives every fourth record), and the process that stays alone and in rounds, warm and cold.
- `make bench PY=<python with lancedb>` runs `bench/bench.sh`; the report, `build/bench/report.txt`, starts with the revisions of this repository, of aildb and of AIL, and has the command of each measurement before its figures.

## Rules

The rules are those of aildb and of the AIL repository.

- All repository text is in English, even when the conversation is in another language.
- AIL sources have the extension `.aiw` and are indented with one tab for each block; `ail fmt` sets it.
- A commit message is `type: subject` (`feat`, `fix`, `test` or `docs`, no scope, lower case, no full stop) and a prose body wrapped at about 70 columns: the problem, what changed and why, how it was verified. No trailers or attribution lines.
- A figure in a document is one that a command of this repository printed; say with which command, on which day, on which hardware and against which revisions of aildb, of this repository and of AIL. Do not edit a figure by hand or carry one over from a run that was not made.
- Nothing of aildb or of AIL is copied here.
