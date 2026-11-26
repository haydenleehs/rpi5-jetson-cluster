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
sudo netfilter-persistent save        # "command not found"? sudo apt install -y iptables-persistent (answer Yes to save IPv4 rules)
```

Check:

```bash
sudo iptables -t nat -L POSTROUTING -n -v   # MASQUERADE with out = wlan0 (ts-postrouting is Tailscale's, leave it)
sysctl net.ipv4.ip_forward                  # = 1
```

## 3.3 Jetson — static IP

The Jetson has no cluster IP yet, but you can still reach it **from the Pi over the cable**:

```bash
ssh leecluster@orin-node01.local            # mDNS (works with the Jetson's Ubuntu desktop image)
# or find its IPv6 link-local address:
ping -6 -c 2 ff02::1%eth0                   # the fe80:: address that isn't the Pi's
ssh leecluster@fe80::xxxx:xxxx:xxxx:xxxx%eth0
```

(Or use the Jetson's own keyboard + monitor.)

The Jetson uses **NetworkManager**, not netplan. Find the Ethernet interface name. On the Orin Nano dev kit it's **`enP8p1s0`**. Ignore `wlP1p1s0` (Wi-Fi), `can0`, `l4tbr0`, `usb0/1` and `docker0`.

```bash
ip -br link
sudo nmcli con add type ethernet ifname enP8p1s0 con-name cluster \
  ipv4.method manual ipv4.addresses 10.0.0.11/24 \
  ipv4.gateway 10.0.0.1 ipv4.dns "1.1.1.1 8.8.8.8" ipv6.method disabled
sudo nmcli con up cluster
```

Your SSH session **will freeze or drop** at `nmcli con up` (it disables the IPv6 address you came in on). Wait ~10 s, then reconnect on the new IP:

```bash
ssh leecluster@10.0.0.11
```

If an old *"Wired connection 1"* keeps grabbing the port: `sudo nmcli con delete "Wired connection 1"`.

Turn off the Jetson's Wi-Fi so all traffic goes through the Pi. Do this **after** reconnecting on 10.0.0.11, because your session may be running over Wi-Fi:

```bash
sudo nmcli radio wifi off
```

## 3.4 Both — /etc/hosts

> ⚠️ On the Pi, `/etc/hosts` starts with *"Your system has configured 'manage_etc_hosts' as True"*: cloud-init **rewrites it at every boot**. Disable cloud-init first or your changes vanish.

**Pi:**

```bash
sudo touch /etc/cloud/cloud-init.disabled
sudo sed -i 's/^127.0.1.1/#127.0.1.1/' /etc/hosts
echo -e "10.0.0.1   rpi5-login\n10.0.0.11  orin-node01" | sudo tee -a /etc/hosts
getent hosts orin-node01      # 10.0.0.11  orin-node01
```

**Jetson** (`ssh leecluster@10.0.0.11`):

```bash
sudo sed -i 's/^127.0.1.1/#127.0.1.1/' /etc/hosts
echo -e "10.0.0.1   rpi5-login\n10.0.0.11  orin-node01" | sudo tee -a /etc/hosts
cat /etc/hosts
```

Both should end up with ([`configs/pi5/hosts-cluster`](../../configs/pi5/hosts-cluster)):

```
127.0.0.1   localhost
#127.0.1.1  ...            (commented out, or absent)
10.0.0.1    rpi5-login
10.0.0.11   orin-node01
```

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
