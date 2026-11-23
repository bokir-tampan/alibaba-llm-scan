#!/bin/bash
# full-port scan (1-10000) on confirmed-live IPs, shard $1 of $2
set -euo pipefail
SHARD="$1"
TOTAL="$2"

split -n l/$TOTAL -d fullport_ips.txt fp_ 2>/dev/null || split -n l/$TOTAL fullport_ips.txt fp_
F=$(ls fp_* | sed -n "$(( SHARD + 1 ))p")
echo "[*] shard $SHARD: $(wc -l < $F) IPs, full port 1-10000"

sudo masscan -iL "$F" -p1-10000 --rate 50000 --wait 0 \
  -oJ fp_results_$SHARD.json 2>&1 | tail -2 || true
wc -c fp_results_$SHARD.json 2>/dev/null || echo "no hits"
