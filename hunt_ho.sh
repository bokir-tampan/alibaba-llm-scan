#!/bin/bash
# hetzner + other-prov ip:port list → llm_hunt directly (no masscan needed)
set -euo pipefail
echo "[*] hunt $1 targets from ip:port list"
split -n l/4 -d ho_targets.txt ho_part_ 2>/dev/null || split -n l/4 ho_targets.txt ho_part_
F=$(ls ho_part_* | sed -n "$(( $1 + 1 ))p")
echo "[*] using $F: $(wc -l < $F) targets"
python3 llm_hunt.py --file "$F" --workers 60 --farm --output "ho_hits_$1.jsonl" 2>&1 | tail -4
wc -l "ho_hits_$1.jsonl" || true
