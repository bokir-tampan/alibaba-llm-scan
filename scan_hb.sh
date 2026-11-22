#!/bin/bash
# GH Actions: scan huawei+baidu prefixes shard, plus hetzner ip:port list
set -euo pipefail
SHARD="$1"
PORTS="3000,8000,8080,11434,20128,20137,8316,8317,7863,8321,8003,9129,9127,9123,8188"

echo "[*] shard $SHARD: generate prefix slice"
python3 shard.py 20 "$SHARD" < hb_prefixes.txt > shard_$SHARD.txt
wc -l shard_$SHARD.txt

echo "[*] masscan huawei+baidu"
sudo masscan -iL shard_$SHARD.txt -p "$PORTS" --rate 5000 --wait 0 \
  -oJ hb_results_$SHARD.json 2>&1 | tail -2 || true

# hetzner: already ip:port list, scan on shard 0 only (27k hosts, fast)
if [ "$SHARD" = "0" ]; then
  echo "[*] hetzner ip:port list (27k)"
  cp hetzner_targets.txt hetzner_$SHARD.txt
  python3 - <<'EOF'
import urllib.request, json, concurrent.futures as cf
def probe(line):
    ip, port = line.split("\t")
    url = f"http://{ip}:{port}/v1/models"
    try:
        r = urllib.request.urlopen(url, timeout=4)
        b = r.read(400).decode("utf-8","ignore")
        if b.strip().startswith(("{","[")):
            return line, r.status, b[:200]
    except Exception:
        return None
    return None

hits=[]
with open("hetzner_targets.txt") as f:
    lines=[l.strip() for l in f if l.strip()]
with cf.ThreadPoolExecutor(100) as ex:
    for r in ex.map(probe, lines):
        if r: hits.append(r)
with open("hetzner_hits.jsonl","w") as f:
    for h in hits:
        f.write(json.dumps({"ip":h[0].split('\t')[0],"port":h[0].split('\t')[1],"status":h[1],"body":h[2]})+"\n")
print(f"hetzner hits: {len(hits)}")
EOF
fi

echo "[*] sizes"
wc -c hb_results_$SHARD.json 2>/dev/null || echo "no hb results"
ls -la hetzner_hits.jsonl 2>/dev/null || true
