#!/usr/bin/env python3
import asyncio, aiohttp, json, sys, re, os

TARGETS=sys.argv[1] if len(sys.argv)>1 else "/tmp/probe_targets.txt"
OUT=sys.argv[2] if len(sys.argv)>2 else "/root/recon-alibaba/probe_hits.jsonl"
CONC=int(os.environ.get("CONC","200"))
TIMEOUT=float(os.environ.get("TO","2.5"))

MODELMARK=re.compile(r'("object"\s*:\s*"list"|"data"\s*:\s*\[|"models"\s*:\s*\[|owned_by|"id"\s*:\s*"[^"]*(gpt|qwen|claude|deepseek|llama|glm|minimax|kimi))', re.I)

written=0
fout=open(OUT,"a")
q=None

async def worker(session):
    global written
    while True:
        item=await q.get()
        if item is None: q.task_done(); break
        host,port=item
        try:
            async with session.get(f"http://{host}:{port}/v1/models", timeout=aiohttp.ClientTimeout(total=TIMEOUT)) as r:
                if r.status in (200,401,403):
                    body=(await r.text(errors="ignore"))[:4000]
                    if MODELMARK.search(body):
                        rec={"ip":host,"port":int(port),"status":r.status,"body":body[:1500],"locked":r.status in (401,403)}
                        fout.write(json.dumps(rec)+"\n"); fout.flush(); written+=1
        except Exception:
            pass
        q.task_done()

async def main():
    global q
    lines=[l.strip() for l in open(TARGETS) if l.strip()]
    q=asyncio.Queue(maxsize=CONC*4)
    print(f"[*] {len(lines)} targets CONC={CONC} TO={TIMEOUT}", flush=True)
    conn=aiohttp.TCPConnector(limit=CONC, ttl_dns_cache=300, force_close=True)
    async with aiohttp.ClientSession(connector=conn, headers={"User-Agent":"Mozilla/5.0"}) as s:
        workers=[asyncio.create_task(worker(s)) for _ in range(CONC)]
        for i,l in enumerate(lines):
            try: host,port=l.split(":")
            except: continue
            await q.put((host,port))
            if (i+1)%20000==0: print(f"[*] fed {i+1}/{len(lines)} written={written}", flush=True)
        for _ in workers: await q.put(None)
        await asyncio.gather(*workers)
    print(f"[+] DONE written={written}", flush=True)

asyncio.run(main())
