#!/bin/bash
# scan one provider's prefixes, shard $1 of $2
set -euo pipefail
SHARD="$1"
TOTAL="$2"
PORTS="3000,8000,8080,11434,20128,20137,8316,8317,7863,8321,8003,9129,9127,9123,8188"

python3 shard.py "$TOTAL" "$SHARD" < prefixes.txt > shard_$SHARD.txt
echo "[*] shard $SHARD: $(wc -l < shard_$SHARD.txt) prefixes"
sudo masscan -iL shard_$SHARD.txt -p "$PORTS" --rate 5000 --wait 0 \
  -oJ results_$SHARD.json 2>&1 | tail -2 || true
wc -c results_$SHARD.json 2>/dev/null || echo "no hits"
