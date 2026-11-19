# Part 4 · Stage 6 — NFS shared `/clusterfs`

The Pi exports `/clusterfs` and the Jetson mounts it at the same path, so job scripts, inputs and outputs are visible on both.

## 6.1 Pi — NFS server

```bash
sudo mkdir -p /clusterfs
sudo chown leecluster:leecluster /clusterfs
sudo cp ~/rpi5-jetson-cluster/configs/pi5/exports /etc/exports
# contains: /clusterfs 10.0.0.0/24(rw,sync,no_subtree_check)
sudo exportfs -ra
sudo exportfs -v                              # confirm it's exported
```

## 6.2 Jetson — mount

```bash
sudo mkdir -p /clusterfs
echo '10.0.0.1:/clusterfs /clusterfs nfs defaults,_netdev 0 0' | sudo tee -a /etc/fstab
sudo systemctl daemon-reload
sudo mount -a
df -h /clusterfs                              # 10.0.0.1:/clusterfs
```

## 6.3 Test

```bash
# Pi
echo "hello from $(hostname)" > /clusterfs/test.txt
ssh orin-node01 cat /clusterfs/test.txt
srun touch /clusterfs/from-jetson && ls -l /clusterfs/from-jetson   # owned by leecluster
```

> The Pi's microSD is slow. If jobs write a lot of output, move `/clusterfs` to a USB SSD on the Pi.

Next: [Stage 7 — Workloads](../part4-storage-workloads/stage7-workloads.md)
