# Wings (manual bootstrap)

Pelican **Wings** runs on the home node with **Docker** — not as a Kubernetes pod.

## Port allocation (match edge relay)

In Pelican **Admin → Nodes → your node → Allocation**:

| Setting | Value |
|---------|-------|
| **Port range start** | `20000` |
| **Port range end** | `20100` |

The [edge relay](../edge-relay/app/relay-script.yaml) forwards **20000–20100** TCP+UDP 1:1 to `${LOCAL_LB_IP}`, plus well-known ports (25565, 19132, 8766, 27016, 9700).

Override range cluster-wide with `GAME_PORT_START` / `GAME_PORT_END` in [cluster-secrets.sops.yaml](../../configs/cluster-secrets.sops.yaml).

**DO firewall** must allow the same ports.

## DNS convention

Use wildcard **`*.g.liaw.me`** → DO IP (see [dns/README.md](../dns/README.md)).

- Default Minecraft on **25565** → players use `mc.g.liaw.me`
- Allocated port **20042** → players use `mc.g.liaw.me:20042` (hostname is cosmetic; port selects the server)

## 1. Install Docker on the home game node (Kairos master)

One-time on the host where game containers run (same node as `${LOCAL_LB_IP}`).

## 2. Install Wings

Follow [Pelican Wings docs](https://pelican.dev/docs/wings/installing):

```bash
curl -L https://github.com/pelican-dev/wings/releases/latest/download/wings_linux_amd64 -o /usr/local/bin/wings
chmod +x /usr/local/bin/wings
```

## 3. Register node in Pelican UI

1. Open `https://games.${PUBLIC_HOSTNAME}` (or `https://games.liaw.me`)
2. Complete panel setup if prompted
3. Admin → Nodes → Create node
4. Set FQDN to the home node LAN IP reachable from the panel pod
5. Set allocation range **20000–20100**
6. Deploy Wings config to `/etc/pelican/config.yml`

## 4. Start Wings

```bash
sudo wings configure --panel-url https://games.${PUBLIC_HOSTNAME} --token <deployment-token>
sudo systemctl enable --now wings
```

## 5. Create servers

Import eggs and create instances. Any port in the allocated range or well-known defaults is already forwarded from DO — no GitOps change per server.
