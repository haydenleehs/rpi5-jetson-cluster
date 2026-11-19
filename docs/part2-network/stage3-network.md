# Part 2 · Stage 3 — Cluster network (login node shares internet)

```
internet ── wlan0 [rpi5-login] eth0 10.0.0.1 ── cable ── 10.0.0.11 [orin-node01]
```

> Before starting: the Pi's Wi-Fi must work (Stage 1.5). Unplug the laptop cable from the Pi and connect **Pi `eth0` ↔ Jetson Ethernet**. SSH to the Pi over Wi-Fi or Tailscale from now on.

## 3.1 Pi — static IP on eth0

```bash
sudo cp ~/rpi5-jetson-cluster/configs/pi5/60-cluster.yaml /etc/netplan/
```

It contains ([`configs/pi5/60-cluster.yaml`](../../configs/pi5/60-cluster.yaml)):

```yaml
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: false
      dhcp6: false
      addresses: [10.0.0.1/24]
```

Netplan merges files in order, so this overrides the `eth0: dhcp4: true` in `50-cloud-init.yaml`.

```bash
sudo chmod 600 /etc/netplan/60-cluster.yaml
sudo netplan try
ip -br addr show eth0       # 10.0.0.1/24
```

## 3.2 Pi — share internet (NAT)

```bash
echo 'net.ipv4.ip_forward=1' | sudo tee /etc/sysctl.d/99-forward.conf
sudo sysctl --system

sudo iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE
sudo iptables -A FORWARD -i eth0 -o wlan0 -j ACCEPT
sudo iptables -A FORWARD -i wlan0 -o eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo netfilter-persistent save
```

## 3.3 Jetson — static IP

The Jetson uses **NetworkManager**, not netplan. Find the Ethernet interface name first (often `enP8p1s0`, not `eth0`):

```bash
ip -br link
sudo nmcli con add type ethernet ifname <IFACE> con-name cluster \
  ipv4.method manual ipv4.addresses 10.0.0.11/24 \
  ipv4.gateway 10.0.0.1 ipv4.dns "1.1.1.1 8.8.8.8" ipv6.method disabled
sudo nmcli con up cluster
```

If an old *"Wired connection 1"* keeps grabbing the port: `sudo nmcli con delete "Wired connection 1"`.

Turn off the Jetson's Wi-Fi so all traffic goes through the Pi:

```bash
sudo nmcli radio wifi off
```

## 3.4 Both — /etc/hosts

Add to `/etc/hosts` on **both** nodes ([`configs/pi5/hosts-cluster`](../../configs/pi5/hosts-cluster)):

```
10.0.0.1   rpi5-login
10.0.0.11  orin-node01
```

Also **comment out the `127.0.1.1 <hostname>` line** on each node, so the node's own name resolves to its cluster IP.

## 3.5 Test

```bash
# on the Jetson
ping -c 3 rpi5-login
ping -c 3 8.8.8.8         # internet via the Pi
ping -c 3 google.com

# on the Pi
ping -c 3 orin-node01
```

## 3.6 Optional — reach the Jetson from your laptop

**Jump host** (no setup):

```powershell
ssh -J leecluster@rpi5-login leecluster@orin-node01
```

On the laptop, `orin-node01` isn't known; use `10.0.0.11` if the name fails.

**Or a Tailscale subnet route** (laptop reaches all of `10.0.0.0/24` directly):

```bash
sudo tailscale up --ssh --advertise-routes=10.0.0.0/24
```

Then approve the route in the admin console (Pi → ⋯ → Edit route settings).

Next: [Stage 4 — SSH keys & users](../part2-network/stage4-ssh-users.md)
