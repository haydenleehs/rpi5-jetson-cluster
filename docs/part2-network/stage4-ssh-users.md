# Part 2 · Stage 4 — SSH keys & matching users

## 4.1 Passwordless SSH (Pi → Jetson)

```bash
# on the Pi
ssh-keygen -t ed25519          # press Enter for all prompts
ssh-copy-id orin-node01
ssh orin-node01 hostname       # should print orin-node01 with no password
```

## 4.2 UIDs must match

```bash
id;          ssh orin-node01 id           # both: uid=1000(leecluster) gid=1000(leecluster)
id slurm;    ssh orin-node01 id slurm     # same uid on both (Ubuntu uses a fixed one)
id munge;    ssh orin-node01 id munge     # can differ; key ownership is set by name
```

If `leecluster` has a different UID on one node, fix it before going on, because Slurm and NFS both depend on it.

## 4.3 Time sync

MUNGE rejects credentials if clocks drift. Both nodes have internet now, so `systemd-timesyncd` handles it:

```bash
timedatectl                    # "System clock synchronized: yes"
ssh orin-node01 timedatectl
```

Next: [Part 3 — Slurm](../part3-slurm/README.md)
