#!/bin/sh
# usage: bench/bench.sh [PYTHON]
# The measurements of docs/performance.md: top-10 at 10,000, 100,000 and
# 1,000,000 vectors of 768 dimensions, aildb and the Python binding of
# LanceDB on the same stored values and the same query: a process a
# query, with and without a filter, and a process that keeps the
# snapshot or the table open and searches it again and again. It is run by "make bench",
# which builds the programs first; PYTHON is an interpreter that has the
# package lancedb (default python3). Everything is written below
# build/bench/, and the report, which is also printed, to
# build/bench/report.txt.
#
# The report starts with what made it: the revision of this repository,
# the revision of aildb that Ailfile.lock names, the version of AIL and
# the revision of the checkout its command is in (AILREV names it for an
# AIL that is installed), the machine, and before each measurement the
# command that was run.
#
# The environment variables say how much is run: CPU the processor the
# measured processes are bound to (2), WARM and COLD the rounds with the
# file cache as it is and with the files put out of it (101 and 31), and
# LWARM and LCOLD the same for LanceDB, whose rounds take longer (31 and
# 15), SIZES the numbers of records ("10000 100000 1000000"), STAY the
# searches of a process that stays (21) and SROUNDS the rounds of such a
# process, warm and cold (7).
set -eu
cd "$(dirname "$0")/.."
py=${1:-python3}
cpu=${CPU:-2}
warm=${WARM:-101}
cold=${COLD:-31}
lwarm=${LWARM:-31}
lcold=${LCOLD:-15}
sizes=${SIZES:-"10000 100000 1000000"}
stay=${STAY:-21}
srounds=${SROUNDS:-7}
b=build
d=build/bench
mkdir -p $d
run=$b/bench-run
ail=${AIL:-ail}

# the revision of AIL: of the checkout the command is in, if it is in one
ailrev=${AILREV:-}
if [ -z "$ailrev" ]; then
    cmd=$(command -v "$ail" 2> /dev/null) && root=$(dirname "$(dirname "$(readlink -f "$cmd")")") &&
        [ -f "$root/Ailfile" ] && ailrev=$(git -C "$root" rev-parse --short HEAD 2> /dev/null)$(git -C "$root" diff --quiet 2> /dev/null || echo ' with changes')
fi

# a measurement: its title, then the command, which is printed and run
go() {
    echo; echo "### $1"
    shift
    echo "\$ $*"
    "$@"
}
# the same for a command whose stdout is results, which are not shown
quiet() {
    echo; echo "### $1"
    shift
    echo "\$ $*"
    "$@" > /dev/null
}

report() {
    echo "# The measurements of aildb, $(date -u +%Y-%m-%d)"
    echo "aildb-bench: $(git rev-parse --short HEAD 2> /dev/null || echo unknown)$([ -z "$(git status --porcelain 2> /dev/null)" ] || echo ' with changes')"
    echo "aildb: $(awk '$1=="aildb" {print $3 " (version " $2 ")"}' Ailfile.lock), the revision of Ailfile.lock"
    echo "AIL: $($ail version 2> /dev/null || echo unknown), revision ${ailrev:-unknown}, the command that built the programs"
    echo "LanceDB: $($py -c 'import lancedb, pyarrow, sys; print("lancedb", lancedb.__version__ + ", pyarrow", pyarrow.__version__ + ", Python", sys.version.split()[0])')"
    echo "machine: $(sed -n 's/^model name[^:]*: //p' /proc/cpuinfo | head -n 1), $(nproc) processors, $(awk '/MemTotal/ {printf "%d MiB", $2/1024}' /proc/meminfo), Linux $(uname -r)"
    echo "files: $(df -T $d | awk 'NR==2 {print $2 " on " $1}')"
    for n in $sizes; do
        echo
        echo "## $n records of 768 dimensions"
        $b/bench-gen $n 768 $d/v$n.bin $d/m$n.tsv $d/q$n.bin
        $b/aildb build -o $d/s$n.idx -v $d/v$n.bin -m $d/m$n.tsv -d 768 -i random
        $b/aildb check $d/s$n.idx > /dev/null
        $py bench/lance_make.py $d/s$n.idx $d/l$n
        sync
        echo "the snapshot: $(stat -c %s $d/s$n.idx) bytes"
        echo "the table of LanceDB: $(find $d/l$n -type f -printf '%s\n' | awk '{s+=$1} END {print s " bytes in " NR " files"}')"
        $b/aildb search $d/s$n.idx -k 10 -q $d/q$n.bin > $d/a$n.out
        $py bench/lance_query.py $d/l$n $d/q$n.bin 10 > $d/l$n.out 2> /dev/null
        # nothing is timed unless the two engines give the same answer
        same=$($py bench/lance_same.py $d/a$n.out $d/l$n.out) || { echo "aildb and LanceDB: $same"; exit 1; }
        echo "aildb and LanceDB: $same"
        for how in m p r; do
            $b/bench-scan $d/s$n.idx $d/q$n.bin $how 2> /dev/null | cksum
        done | sort -u | awk 'END {print "the three ways of bench-scan: " (NR==1 ? "the same results" : "DIFFERENT results")}'
        aildb="search $d/s$n.idx -k 10 -q $d/q$n.bin"
        lance="bench/lance_query.py $d/l$n $d/q$n.bin 10"
        go "aildb, warm" $run $warm $cpu - $b/aildb $aildb
        go "aildb with the times of its parts, warm" $run $warm $cpu - $b/aildb-times $aildb
        go "aildb, cold" $run $cold $cpu $d/s$n.idx $b/aildb $aildb
        go "aildb with the times of its parts, cold" $run $cold $cpu $d/s$n.idx $b/aildb-times $aildb
        go "LanceDB on one processor, warm" $run $lwarm $cpu - $py $lance
        go "LanceDB on one processor, cold" $run $lcold $cpu $d/l$n $py $lance
        go "LanceDB on every processor, warm" $run $lwarm - - $py $lance
        go "LanceDB on every processor, cold" $run $lcold - $d/l$n $py $lance
        for how in m p r; do
            go "bench-scan $how, warm" $run $warm $cpu - $b/bench-scan $d/s$n.idx $d/q$n.bin $how
            go "bench-scan $how, cold" $run $cold $cpu $d/s$n.idx $b/bench-scan $d/s$n.idx $d/q$n.bin $how
        done
        # A filter: the prefix takes the files f12, f120 to f129 and so
        # on, about one record of eighteen, and the language one of four.
        # The answers are compared first, as without a filter.
        for f in "src/f12 -" "- markdown"; do
            set -- $f
            opts=
            [ "$1" = - ] || opts="-p $1"
            [ "$2" = - ] || opts="$opts -l $2"
            echo; echo "## $n records, the filter $opts"
            $b/aildb search $d/s$n.idx -k 10 -q $d/q$n.bin $opts > $d/af$n.out
            $py bench/lance_query.py $d/l$n $d/q$n.bin 10 $1 $2 > $d/lf$n.out 2> /dev/null
            same=$($py bench/lance_same.py $d/af$n.out $d/lf$n.out) || { echo "aildb and LanceDB: $same"; exit 1; }
            echo "aildb and LanceDB: $same"
            go "aildb, warm" $run $warm $cpu - $b/aildb $aildb $opts
            go "aildb, cold" $run $cold $cpu $d/s$n.idx $b/aildb $aildb $opts
            go "LanceDB on one processor, warm" $run $lwarm $cpu - $py $lance $1 $2
            go "LanceDB on one processor, cold" $run $lcold $cpu $d/l$n $py $lance $1 $2
            go "LanceDB on every processor, warm" $run $lwarm - - $py $lance $1 $2
        done
        # A process that stays: the snapshot or the table is opened once
        # and searched $stay times. Run alone, bound to the processor, it
        # says the median of a search after the first; under the harness
        # its parts are the time to "opened", to the first search and to
        # the last.
        echo; echo "## $n records, a process that stays, $stay searches"
        $b/bench-stay $d/s$n.idx $d/q$n.bin 10 1 2> /dev/null | cmp -s - $d/a$n.tail ||
            { tail -n +2 $d/a$n.out > $d/a$n.tail; $b/bench-stay $d/s$n.idx $d/q$n.bin 10 1 2> /dev/null | cmp - $d/a$n.tail; }
        echo "bench-stay and aildb search: the same results"
        quiet "aildb, one process, warm" taskset -c $cpu $b/bench-stay $d/s$n.idx $d/q$n.bin 10 $stay
        go "aildb, rounds of such a process, warm" $run $srounds $cpu - $b/bench-stay $d/s$n.idx $d/q$n.bin 10 $stay
        go "aildb, rounds of such a process, cold" $run $srounds $cpu $d/s$n.idx $b/bench-stay $d/s$n.idx $d/q$n.bin 10 $stay
        quiet "LanceDB on one processor, one process, warm" env LANCE_STAY=$stay taskset -c $cpu $py $lance
        go "LanceDB on one processor, rounds of such a process, warm" env LANCE_STAY=$stay $run $srounds $cpu - $py $lance
        go "LanceDB on one processor, rounds of such a process, cold" env LANCE_STAY=$stay $run $srounds $cpu $d/l$n $py $lance
        quiet "LanceDB on every processor, one process, warm" env LANCE_STAY=$stay $py $lance
        go "LanceDB on every processor, rounds of such a process, warm" env LANCE_STAY=$stay $run $srounds - - $py $lance
        go "LanceDB on every processor, rounds of such a process, cold" env LANCE_STAY=$stay $run $srounds - $d/l$n $py $lance
    done
}
# the status of the measurements, not that of tee: a step that fails
# ends the left side at once, which then leaves no file
rm -f $d/complete
{ report 2>&1; : > $d/complete; } | tee $d/report.txt
[ -f $d/complete ]
