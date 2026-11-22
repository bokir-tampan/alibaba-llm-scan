#!/usr/bin/env python3
"""Split consolidated prefixes into N shards balanced by IP count."""
import ipaddress, sys, json

prefixes = []
for l in open("prefixes.txt"):
    l = l.strip()
    if l:
        prefixes.append(ipaddress.ip_network(l, strict=False))

N = int(sys.argv[1])  # number of shards
idx = int(sys.argv[2])  # this shard index

# sort by size desc, greedy assign to balanced shards
nets = sorted(prefixes, key=lambda n: -n.num_addresses)
shards = [[] for _ in range(N)]
loads = [0] * N
for net in nets:
    # assign to least loaded
    m = min(range(N), key=lambda i: loads[i])
    shards[m].append(net)
    loads[m] += net.num_addresses

for net in shards[idx]:
    print(net)
