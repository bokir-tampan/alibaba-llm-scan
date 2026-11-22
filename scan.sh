#!/bin/bash
# GH Actions scan job: scan shard $1 of the CIDR list on the given ports, upload hits
set -euo pipefail

SHARD_IDX="$1"
PREFIXES="prefixes.txt"
PORTS="6007,7000,7001,8002,8003,8009,8081,8082,8083,8088,8100,8118,8188,8191,8288,8388,8488,8588,8688,9002,9003,9091,9092,9099,9119,9123,9127,9129,11400,11433,11435,11436,11500,11501,18081,19121,20129,20138,30000,31000,45000,49153"

echo "[*] shard $SHARD_IDX: generating prefix list"
python3 shard.py 40 "$SHARD_IDX" > shard_$SHARD_IDX.txt
wc -l shard_$SHARD_IDX.txt

echo "[*] masscan"
sudo masscan -iL shard_$SHARD_IDX.txt -p "$PORTS" --rate 5000 --wait 0 \
  -oJ results_$SHARD_IDX.json 2>&1 | tail -3

echo "[*] result size:"
wc -c results_$SHARD_IDX.json || true
ls -la results_$SHARD_IDX.json 2>/dev/null || echo "no hits file"

# upload artifact is handled by actions/upload-artifact
