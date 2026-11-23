#!/bin/bash
# tencent targets → llm_hunt, shard $1 of 20
set -euo pipefail
SHARD="$1"
split -n l/20 -d tencent_targets.txt tc_part_ 2>/dev/null || split -n l/20 tencent_targets.txt tc_part_
F=$(ls tc_part_* | sed -n "$(( $SHARD + 1 ))p")
echo "[*] shard $SHARD: $(wc -l < $F) targets"
python3 llm_hunt.py --file "$F" --workers 60 --farm --output "tc_hits_$SHARD.jsonl" 2>&1 | tail -3
wc -l "tc_hits_$SHARD.jsonl" || true
