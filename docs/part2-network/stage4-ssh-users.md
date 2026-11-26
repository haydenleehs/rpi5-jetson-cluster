# Part 2 · Stage 4 — SSH keys & matching users

## 4.1 Passwordless SSH (Pi → Jetson)

```bash
# on the Pi
ssh-keygen -t ed25519          # press Enter 3x: default file, empty passphrase (twice)
ssh-copy-id orin-node01
ssh orin-node01 hostname       # should print orin-node01 with no password
```

*"Could not resolve hostname orin-node01"* → do Stage 3.4 (`/etc/hosts`) on the Pi first.

### Optional: passwordless sudo on the Jetson

`ssh -t orin-node01 'sudo …'` asks for the **sudo** password every time (each `ssh -t` is a new terminal). For a home lab you can turn that off:

```bash
ssh -t orin-node01 "echo 'leecluster ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/leecluster && sudo chmod 440 /etc/sudoers.d/leecluster"
ssh orin-node01 sudo whoami    # root, no prompt
```

Trade-off: anyone who gets into `leecluster` on the Jetson is effectively root.

> `sudo` over SSH always needs **`ssh -t`**. Without it: *"sudo: a terminal is required to read the password"*.

## 4.2 UIDs must match

```bash
id;          ssh orin-node01 id           # both: uid=1000(leecluster) gid=1000(leecluster)
id slurm;    ssh orin-node01 id slurm     # same uid on both (Ubuntu uses a fixed one)
id munge;    ssh orin-node01 id munge     # can differ; key ownership is set by name
```

If `leecluster` has a different UID on one node (e.g. the Jetson shows `uid=2002`), fix it before going on, because Slurm and NFS both depend on it. Follow [Stage 2.0b](../part1-setup/stage2-jetson.md#20b-rename-the-user-to-leecluster-with-uid-1000) (temp admin with UID 1500, then `groupmod -g 1000` / `usermod -u 1000`).

A sign you missed this: `munge -n | ssh orin-node01 unmunge` in Stage 5 shows `UID: ??? (1000)`.

## 4.3 Time sync

MUNGE rejects credentials if clocks drift. Both nodes have internet now, so `systemd-timesyncd` handles it:

```bash
timedatectl                    # "System clock synchronized: yes"
ssh orin-node01 timedatectl
```

Next: [Part 3 — Slurm](../part3-slurm/README.md)
