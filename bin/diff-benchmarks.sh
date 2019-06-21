#!/bin/bash

before="$1"
after="$2"

parse() {
    sed -n \
        -e 's/ *\t */\t/g' \
        -e '/^Benchmark/p' |
        column -s'	' --json \
               --table-columns name,count,time,rate \
               --table-name "results" |
        jq '.results[] | {name: .name, time: (.time | rtrimstr(" ns/op") | tonumber)}'
}

benchcmp "$1" "$2"

echo ""
echo "Result:"

{
    parse < "$1"
    parse < "$2"
} | jq -e -r -s 'group_by(.name)[] | {name: .[0].name, speedup: (.[1].time / .[0].time)} | select(.speedup < 0.90) | "\(.name)\t\(.speedup)x"'

if [[ $? -ne 4 ]]; then
    echo ""
    echo "FAIL"
    exit 1
else
    echo "PASS"
fi