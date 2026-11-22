import ipaddress, sys
N = int(sys.argv[1]); idx = int(sys.argv[2])
nets = sorted([ipaddress.ip_network(l.strip(), strict=False) for l in sys.stdin if l.strip()], key=lambda n:-n.num_addresses)
shards=[[] for _ in range(N)]; loads=[0]*N
for n in nets:
    m=min(range(N), key=lambda i: loads[i]); shards[m].append(n); loads[m]+=n.num_addresses
for n in shards[idx]: print(n)
