# Part 2 — Connect the nodes

Cable the Pi's `eth0` to the Jetson, give both static IPs on a private `10.0.0.0/24` network, have the Pi share its Wi-Fi internet, and set up passwordless SSH.

```
internet ── wlan0 [rpi5-login] eth0 10.0.0.1 ── cable ── 10.0.0.11 [orin-node01]
```

| Stage | Guide | Time |
|---|---|---|
| 3 | [Cluster network](stage3-network.md): static IPs, NAT, `/etc/hosts` | 30 min |
| 4 | [SSH keys & users](stage4-ssh-users.md): passwordless SSH, matching UIDs, time sync | 10 min |

## ✅ Checkpoint: before Part 3

- [ ] Pi: `ip -br addr show eth0` → `10.0.0.1/24`
- [ ] Jetson: `ping -c 3 google.com` works (internet through the Pi)
- [ ] Pi: `ssh orin-node01 hostname` → `orin-node01`, **no password asked**
- [ ] `id` matches on both nodes (`uid=1000(leecluster)`)
- [ ] `timedatectl` → *System clock synchronized: yes* on both

Start: [Stage 3 — Cluster network](stage3-network.md)
