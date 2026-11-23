#!/bin/bash
# scan batch $1 of $2 on curated ports (258), 20k IP each
set -euo pipefail
SHARD="$1"; TOTAL="$2"
split -n l/$TOTAL -d fullport_ips.txt fp_ 2>/dev/null
F=$(ls fp_* | sed -n "$(( SHARD + 1 ))p")
echo "[*] batch $SHARD: $(wc -l < $F) IPs x 258 ports"
PORTS=$(cat ports.txt)
sudo masscan -iL "$F" -p"$PORTS" --rate 15000 --wait 0 --max-retries 1 \
  -oJ batch_$SHARD.json 2>&1 | tail -1 || true
echo "[*] done: $(grep -c '"ip"' batch_$SHARD.json 2>/dev/null || echo 0) hits"
