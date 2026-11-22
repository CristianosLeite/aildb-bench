# aildb-bench is a package of AIL (Ailfile), built and tested by the
# command ail: "ail build" compiles the engine and the programs of the
# measurements into build/, and "ail test" runs the tests. AIL names the
# command, if it is not on PATH:
#   make AIL=../ail/build/ail
AIL ?= ail
all:
	$(AIL) build

test:
	$(AIL) test $(T)
	$(AIL) fmt --check

# The measurements (docs/performance.md), against the Python binding of
# LanceDB. PY is a Python that has the package lancedb.
PY ?= python3
bench:
	$(AIL) build
	AIL=$(AIL) bench/bench.sh $(PY)

clean:
	$(AIL) clean

.PHONY: all test bench clean
