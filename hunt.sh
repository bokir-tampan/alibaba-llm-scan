#!/bin/bash
# GH Actions hunt job: split targets, run llm_hunt.py on each shard
set -euo pipefail
SHARD="$1"
TOTAL="$2"

pip install --quiet requests 2>/dev/null || true

echo "[*] shard $SHARD/$TOTAL"
split -n l/$TOTAL -d targets.txt shard_ 2>/dev/null
# split produces shard_00, shard_01...; pick ours
F=$(printf "shard_%02d" "$SHARD")
[ -f "$F" ] || F=$(ls shard_* | sed -n "$((SHARD+1))p")

echo "[*] using $F, $(wc -l < $F) targets"
python3 llm_hunt.py --file "$F" --workers 60 --output "hits_$SHARD.jsonl" 2>&1 | tail -5
wc -l "hits_$SHARD.jsonl" || true
