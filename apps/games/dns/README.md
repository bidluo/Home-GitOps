# Game server DNS (Cloudflare)

## Two public paths

| Traffic | Path | DNS in Cloudflare |
|---------|------|-------------------|
| **Panel** (`games.liaw.me`) | Cloudflare Tunnel → `pelican-panel` | Tunnel hostname (automatic when tunnel ingress is configured; zone proxied orange cloud OK) |
| **Game UDP/TCP** (`mc.g.liaw.me`, etc.) | Internet → DO reserved IP → edge relay → home | **A** record, DNS only (grey cloud) |

Tailscale Funnel is deployed but **not** your primary public ingress today — see [cloudflare-tunnel](../../network/cloudflare-tunnel/app/helm-release.yaml). Game traffic cannot use the tunnel (HTTP/S only).

## One-time Cloudflare records

**Games (DO edge)**

| Type | Name | Content | Proxy |
|------|------|---------|--------|
| A | `*.g` | DO reserved IP | **DNS only** (grey cloud) |

Covers `mc.g.liaw.me`, `sotf.g.liaw.me`, etc.

**Panel**

No extra DNS if `games.liaw.me` is already routed by the tunnel config (`games.${PUBLIC_HOSTNAME}` → `pelican-panel`). Cloudflare proxy (orange cloud) is fine for HTTPS.

## Port blocks (relay ↔ Wings)

| Block | Ports |
|-------|-------|
| Well-known | 25565, 19132, 8766, 27016, 9700 |
| Wings range | 20000–20100 (`GAME_PORT_START` / `GAME_PORT_END` in cluster-secrets, optional) |

Open the same on the **DO cloud firewall**.

Pelican node allocation: **20000–20100**. See [wings/README.md](../wings/README.md).

## Spin-up (no per-server DNS or GitOps)

1. Wildcard `*.g` → DO IP (once)
2. Tunnel serves `games.liaw.me` (once, in GitOps)
3. Wings allocation range matches relay
4. Create server in Pelican → use port in range or 25565 for default Minecraft hostname
