# Tailscale VPN + Funnel Setup

Replaces Cloudflare Tunnels with Tailscale for both VPN access and public service exposure via Funnel.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         INTERNET                                 │
├─────────────────────────────────────────────────────────────────┤
│                              │                                   │
│         ┌────────────────────┼────────────────────┐             │
│         │                    │                    │             │
│         ▼                    ▼                    │             │
│   ┌──────────┐        ┌──────────────┐     ┌──────────┐        │
│   │  Your    │        │  Tailscale   │     │  Public  │        │
│   │ Devices  │        │   Funnel     │     │  Users   │        │
│   └────┬─────┘        └──────┬───────┘     └────┬─────┘        │
│        │                     │                  │               │
│        │ Tailscale           │ HTTPS            │               │
│        │ (direct/DERP)       │                  │               │
│        │                     ▼                  │               │
├────────┼──────────────────────────────────────────┼─────────────┤
│        │           TAILSCALE NETWORK              │             │
│        │         (Sydney DERP server)             │             │
├────────┼──────────────────────────────────────────┼─────────────┤
│        │                     │                    │             │
│        ▼                     ▼                    │             │
│   ┌─────────────────────────────────────────────────────┐      │
│   │              HOME NETWORK (Behind CGNAT)             │      │
│   │  ┌────────────────────────────────────────────────┐ │      │
│   │  │           KUBERNETES CLUSTER                   │ │      │
│   │  │                                                │ │      │
│   │  │  ┌──────────────┐    ┌──────────────────────┐ │ │      │
│   │  │  │  Tailscale   │───▶│       Traefik        │◀┼─┼──────┘
│   │  │  │   Operator   │    │   (Ingress + TLS)    │ │ │
│   │  │  │  + Funnel    │    └──────────┬───────────┘ │ │
│   │  │  │  + Subnet    │               │             │ │
│   │  │  │   Router     │               ▼             │ │
│   │  │  └──────────────┘    ┌──────────────────────┐ │ │
│   │  │                      │      Services        │ │ │
│   │  │                      │ Plex, Sonarr, etc.   │ │ │
│   │  │                      └──────────────────────┘ │ │
│   │  └────────────────────────────────────────────────┘ │
│   │                                                      │
│   │  ┌────────────────────────────────────────────────┐ │
│   │  │  Other Home Devices (NAS, printers, IoT)       │ │
│   │  └────────────────────────────────────────────────┘ │
│   └─────────────────────────────────────────────────────┘
└─────────────────────────────────────────────────────────────────┘
```

## What You Get

- **VPN Access**: Connect from anywhere to your entire home network
- **Public Ingress**: Expose services via Tailscale Funnel (no VPS needed)
- **Works Behind CGNAT**: Tailscale handles NAT traversal via DERP relays
- **Sydney DERP**: Low latency for Australian users

## Requirements

- Tailscale account with **Personal Plus** ($48/year) for custom domains
- Or use free tier with `*.ts.net` subdomains only

## Setup Steps

### Step 1: Create Tailscale OAuth Client

1. Go to https://login.tailscale.com/admin/settings/oauth
2. Click "Generate OAuth Client"
3. Set scopes:
   - `devices:read`, `devices:write` - Manage devices
   - `routes:read`, `routes:write` - Subnet router
4. Copy the Client ID and Client Secret

### Step 2: Add Variables to cluster-secrets

Edit `configs/cluster-secrets.sops.yaml` and add:

```yaml
stringData:
  # ... existing secrets ...
  
  # Tailscale OAuth credentials
  TS_OAUTH_CLIENT_ID: "your-oauth-client-id"
  TS_OAUTH_CLIENT_SECRET: "your-oauth-client-secret"
  
  # Your home network CIDR (e.g., 192.168.1.0/24)
  HOME_NETWORK_CIDR: "192.168.1.0/24"
```

Then encrypt:

```bash
sops -e -i configs/cluster-secrets.sops.yaml
```

### Step 3: Deploy

```bash
git add .
git commit -m "Add Tailscale operator with Funnel for public ingress"
git push
```

Watch deployment:

```bash
kubectl get pods -n network -w
kubectl get ingress -n network
```

### Step 4: Approve Subnet Routes

1. Go to https://login.tailscale.com/admin/machines
2. Find "home-k8s-router"
3. Click three dots → "Edit route settings"
4. Enable your home network subnet

### Step 5: Configure Custom Domains (Personal Plus)

After deployment, get your Funnel hostname:

```bash
kubectl get ingress -n network traefik-funnel -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
# Example output: traefik-funnel.tail1234.ts.net
```

Add CNAME records in your DNS provider:

```
yourdomain.com        CNAME  traefik-funnel.tail1234.ts.net
*.yourdomain.com      CNAME  traefik-funnel.tail1234.ts.net
```

Your existing Traefik ingress rules will work as-is - Traefik handles routing by hostname.

### Step 6: Test

**VPN Access:**
```bash
# Install Tailscale on your device
# Sign in with same account
tailscale status

# Access home network
ping 192.168.1.1
ssh user@192.168.1.50
```

**Public Access:**
```bash
curl https://yourdomain.com
curl https://plex.yourdomain.com
```

## How It Works

1. **Public traffic** → Tailscale Funnel → Traefik → Services
2. **VPN traffic** → Tailscale (direct or DERP) → Subnet Router → Home Network
3. **Traefik** handles hostname-based routing and TLS for internal services
4. **Funnel** handles TLS for the public endpoint

## Files

| File | Purpose |
|------|---------|
| `helm-release.yaml` | Tailscale operator deployment |
| `connector.yaml` | Subnet router for home network VPN access |
| `ingress-class.yaml` | Tailscale ingress class for Funnel |
| `funnel-ingress.yaml` | Exposes Traefik via Funnel for public access |

## Migration Checklist

After verifying Tailscale is working:

- [ ] Operator pod running: `kubectl get pods -n network -l app.kubernetes.io/name=tailscale-operator`
- [ ] Subnet router approved in Tailscale admin
- [ ] VPN access works from your devices
- [ ] Funnel ingress has hostname: `kubectl get ingress -n network traefik-funnel`
- [ ] DNS CNAME records added
- [ ] Public services accessible via custom domains
- [ ] Plex streaming works

## Removing Cloudflare Tunnel

Once everything is verified:

1. Update `apps/network/kustomization.yaml`:
   ```yaml
   resources:
   - namespace.yaml
   - tailscale
   # Remove these:
   # - cloudflare-tunnel
   # - pangolin
   # - wireguard  # Optional - keep as backup if desired
   ```

2. Delete old directories:
   ```bash
   rm -rf apps/network/cloudflare-tunnel
   rm -rf apps/network/pangolin
   ```

3. Clean up charts (optional):
   ```bash
   # Remove from charts/kustomization.yaml: cloudflare.yaml, fossorial.yaml
   rm charts/cloudflare.yaml charts/fossorial.yaml
   ```

4. Commit and push

## Troubleshooting

### Operator not starting

```bash
kubectl logs -n network -l app.kubernetes.io/name=tailscale-operator
```

Check OAuth credentials are correct in cluster-secrets.

### Funnel not working

1. Verify ingress exists: `kubectl get ingress -n network`
2. Check Tailscale admin for the funnel device
3. Ensure Funnel is enabled in Tailscale admin: https://login.tailscale.com/admin/dns

### Custom domains not working

1. Verify CNAME records: `dig yourdomain.com CNAME`
2. Ensure you have Personal Plus plan
3. Check Tailscale admin → DNS → Enable HTTPS certificates

### Slow streaming (Plex)

Tailscale should use direct connections when possible. Check:
```bash
tailscale status  # Look for "direct" vs "relay"
```

If always relay, check firewall allows UDP on random high ports.
