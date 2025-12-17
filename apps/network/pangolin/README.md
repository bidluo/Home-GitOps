# Pangolin Remote Access Setup (via Cloudflare Tunnel)

This directory contains the configuration for Pangolin, an identity-based remote access platform that provides VPN-like access to your home network from behind CGNAT.

## Architecture Overview

```
┌─────────────────────┐
│  Client (Phone/PC)  │
│    Olm Client       │
└──────────┬──────────┘
           │
           │ HTTPS/UDP via Cloudflare
           │
┌──────────▼──────────┐
│  Cloudflare Tunnel  │
│   (CF Zero Trust)   │
└──────────┬──────────┘
           │
           │ Outbound connection from home
           │
┌──────────▼──────────────────┐
│   Home Cluster (CGNAT)      │
│  ┌────────────────────────┐ │
│  │ cloudflared Pod        │ │
│  └───────────┬────────────┘ │
│              │               │
│  ┌───────────▼────────────┐ │
│  │  Pangolin + Gerbil     │ │
│  │  (WireGuard Hub)       │ │
│  └───────────┬────────────┘ │
│              │               │
│     ┌────────┴────────┐     │
│     │                 │     │
│ ┌───▼───┐      ┌─────▼───┐ │
│ │  NAS  │      │K8s Svcs │ │
│ └───────┘      └─────────┘ │
│                             │
│  SSH Hosts, IoT, etc.       │
└─────────────────────────────┘
```

**Key Advantage**: No VPS required! Everything runs in your home cluster, leveraging Cloudflare Tunnel's UDP support.

## Components

- **Pangolin**: Web dashboard and control plane (runs in cluster)
- **Gerbil**: WireGuard tunnel manager (runs in cluster)
- **Cloudflare Tunnel**: Exposes Pangolin dashboard (HTTPS) and WireGuard (UDP)
- **Olm**: Client application for end users (installed on phones/laptops)

## Deployment Steps

### Step 1: Configure Secrets

Edit [`apps/network/pangolin/app/pangolin-secrets.sops.yaml`](apps/network/pangolin/app/pangolin-secrets.sops.yaml):

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: pangolin-secrets
  namespace: network
type: Opaque
stringData:
  PANGOLIN_DOMAIN: "vpn.yourdomain.com"
  PANGOLIN_ADMIN_EMAIL: "admin@yourdomain.com"
  PANGOLIN_ADMIN_PASSWORD: "your-strong-password-here"
```

**Important**: Replace:
- `vpn.yourdomain.com` with your actual domain (must match CF Tunnel hostname)
- `admin@yourdomain.com` with your email
- `your-strong-password-here` with a strong password

Encrypt the file:

```bash
cd apps/network/pangolin/app
sops -e -i pangolin-secrets.sops.yaml
```

### Step 2: Configure DNS

In Cloudflare DNS, you should already have your tunnel CNAME. The Cloudflare Tunnel will handle routing to Pangolin automatically via the updated configuration.

Verify your existing DNS setup:
```
CNAME  vpn.yourdomain.com  -> <your-tunnel-id>.cfargotunnel.com
CNAME  vpn-wg.yourdomain.com  -> <your-tunnel-id>.cfargotunnel.com
```

If these don't exist, Cloudflare Zero Trust will create them automatically when you add the hostnames to your tunnel.

### Step 3: Deploy Pangolin

Commit and push the changes:

```bash
git add apps/network/pangolin/
git add apps/network/cloudflare-tunnel/
git commit -m "Add Pangolin deployment via Cloudflare Tunnel"
git push
```

Flux will automatically:
1. Deploy Pangolin to your cluster
2. Update the Cloudflare Tunnel configuration
3. Expose Pangolin dashboard at `vpn.yourdomain.com`
4. Expose WireGuard at `vpn-wg.yourdomain.com:51820`

### Step 4: Monitor Deployment

Watch the deployment:

```bash
# Watch Flux reconciliation
kubectl get kustomization -n flux-system pangolin -w

# Check Pangolin pod
kubectl get pods -n network -l app.kubernetes.io/name=pangolin

# View logs
kubectl logs -n network -l app.kubernetes.io/name=pangolin -f
```

Wait for pod to be `Running` and healthy.

### Step 5: Access Pangolin Dashboard

1. Navigate to `https://vpn.yourdomain.com`
2. Login with admin credentials from secrets
3. Complete initial setup wizard if prompted

### Step 6: Configure Resources

In the Pangolin dashboard:

#### Create Private Resources (for VPN access)

Navigate to **Resources** → **Private Resources** → **Add Resource**

**Example: Full Home Network Access**
```
Name: Home Network
Type: Network Range
CIDR: 192.168.1.0/24
Ports: *
Protocol: TCP/UDP
Description: Full access to home LAN
```

**Example: NAS Access**
```
Name: NAS
Type: Host
IP: 192.168.1.50
Ports: 22,445,2049 (SSH, SMB, NFS)
Protocol: TCP
Description: Main NAS server
```

See [`RESOURCE_CONFIG_GUIDE.md`](RESOURCE_CONFIG_GUIDE.md) for more examples.

### Step 7: Create Client

In Pangolin dashboard:

1. Navigate to **Clients**
2. Click **Add Client**
3. Configure:
   - Name: `david-laptop` (or your device name)
   - Allowed Resources: Select resources this client can access
4. Click **Create**
5. **Download** or copy the Olm configuration

### Step 8: Install Olm Client

**macOS:**
```bash
brew install fosrl/tap/olm
# Configure with credentials from dashboard
olm configure --credential <credential-string>
```

**Linux:**
```bash
wget https://github.com/fosrl/pangolin/releases/latest/download/olm-linux-amd64
chmod +x olm-linux-amd64
sudo mv olm-linux-amd64 /usr/local/bin/olm
olm configure --credential <credential-string>
```

**Windows:**
Download from GitHub releases and run installer.

**Mobile (iOS/Android):**
Install Olm from App Store / Play Store, scan QR code from dashboard.

### Step 9: Connect and Test

```bash
# Start VPN connection
olm connect

# Check status
olm status

# Test access to home resources
ping 192.168.1.1  # Your router
ssh user@192.168.1.50  # SSH to NAS
```

You should now have full access to your home network!

## Configuration Details

### Cloudflare Tunnel Ingress

The following entries were added to your CF Tunnel configuration:

```yaml
# Pangolin HTTPS dashboard
- hostname: "vpn.${PUBLIC_HOSTNAME}"
  service: http://pangolin.network.svc.cluster.local:80

# Pangolin WireGuard (UDP)
- hostname: "vpn-wg.${PUBLIC_HOSTNAME}"
  service: udp://pangolin-wireguard.network.svc.cluster.local:51820
```

### Storage

Pangolin uses a 10Gi PVC (`pangolin-data`) for:
- SQLite database (default)
- WireGuard configurations
- Application data

Storage class: `longhorn-backup` (with backups enabled)

### Security Context

Pangolin requires elevated privileges for WireGuard:
- `NET_ADMIN` capability
- `SYS_MODULE` capability
- Sysctl modifications for IP forwarding

The pod runs on master nodes for better network access.

## Resource Examples

### Common Private Resources

#### SSH Access to All Devices
```
Type: Network Range
CIDR: 192.168.1.0/24
Port: 22
```

#### Kubernetes Services
```
Type: Network Range
CIDR: 10.43.0.0/16  (your service CIDR)
Ports: *
```

#### Smart Home / IoT
```
Type: Host
IP: 192.168.1.30  (Home Assistant)
Port: 8123
```

See [`RESOURCE_CONFIG_GUIDE.md`](RESOURCE_CONFIG_GUIDE.md) for comprehensive examples.

## Maintenance

### Update Pangolin

Update the image tag in [`apps/network/pangolin/app/helm-release.yaml`](apps/network/pangolin/app/helm-release.yaml):

```yaml
image:
  repository: ghcr.io/fosrl/pangolin
  tag: v1.2.3  # Update to specific version
```

Commit and push - Flux will handle the update.

### View Logs

```bash
# Pangolin logs
kubectl logs -n network -l app.kubernetes.io/name=pangolin -f

# Cloudflare Tunnel logs (to verify routing)
kubectl logs -n network -l app=cloudflare-tunnel -f
```

### Backup

Pangolin data is stored in the `pangolin-data` PVC which uses Longhorn with backup enabled. Regular snapshots are taken automatically.

Manual backup:
```bash
kubectl exec -n network deployment/pangolin -- tar czf - /data > pangolin-backup.tar.gz
```

## Troubleshooting

### Pangolin Pod Not Starting

```bash
# Check pod status
kubectl describe pod -n network -l app.kubernetes.io/name=pangolin

# Common issues:
# - NET_ADMIN capability not granted
# - PVC not bound
# - Secrets not properly encrypted/deployed
```

### Can't Access Dashboard

1. Verify Cloudflare Tunnel is running:
   ```bash
   kubectl get pods -n network -l app=cloudflare-tunnel
   ```

2. Check CF Tunnel logs:
   ```bash
   kubectl logs -n network -l app=cloudflare-tunnel
   ```

3. Verify DNS resolves to CF Tunnel:
   ```bash
   dig vpn.yourdomain.com
   ```

### Olm Client Can't Connect

1. **Check WireGuard endpoint in client config**:
   - Should be `vpn-wg.yourdomain.com:51820`
   
2. **Verify UDP tunnel is working**:
   - Check CF Tunnel supports UDP (should be automatic as of July 2025)
   - Review CF Tunnel logs for UDP traffic

3. **Test connectivity**:
   ```bash
   # From client machine
   nc -zvu vpn-wg.yourdomain.com 51820
   ```

4. **Check Pangolin logs**:
   ```bash
   kubectl logs -n network -l app.kubernetes.io/name=pangolin | grep -i wireguard
   ```

### UDP Not Working

According to [Cloudflare's July 2025 changelog](https://developers.cloudflare.com/changelog/2025-07-15-udp-improvements/), UDP support is built-in. If issues persist:

1. Verify `cloudflared` version in tunnel pod:
   ```bash
   kubectl exec -n network deployment/cloudflare-tunnel -- cloudflared --version
   ```
   
2. Ensure version is 2024.7.0 or later

3. Check tunnel configuration syntax:
   ```bash
   kubectl describe helmrelease -n flux-system cloudflare-tunnel
   ```

### Slow VPN Performance

1. **Check CF Tunnel metrics** in Cloudflare Zero Trust dashboard
2. **Review Pangolin resource usage**:
   ```bash
   kubectl top pod -n network -l app.kubernetes.io/name=pangolin
   ```
3. **Consider resource limits** in helm-release.yaml

## Comparison: Pangolin vs WireGuard-Easy

Your existing WireGuard setup provides basic VPN access. Pangolin adds:

| Feature | WireGuard-Easy | Pangolin |
|---------|----------------|----------|
| VPN Access | ✅ | ✅ |
| Web Dashboard | ✅ Basic | ✅ Advanced |
| Identity/SSO | ❌ | ✅ |
| Granular ACL | ❌ | ✅ Per-resource |
| Zero Trust | ❌ | ✅ |
| Public Resources | ❌ | ✅ Reverse proxy |
| Multi-Site | ❌ | ✅ |

You can run both simultaneously and migrate clients gradually.

## Security Considerations

1. **Strong Admin Password**: Use a password manager
2. **Enable MFA**: In Pangolin user settings after first login
3. **Least Privilege**: Don't give all clients access to all resources
4. **Monitor Logs**: Regular review of access patterns
5. **Update Regularly**: Keep Pangolin image updated
6. **Network Segmentation**: Consider VLANs for different resource types

## Cost Analysis

### Current Setup
- Cloudflare Tunnel: $0 (free tier)
- WireGuard-Easy: $0 (self-hosted)

### With Pangolin
- Cloudflare Tunnel: $0 (free tier, now includes UDP)
- Pangolin: $0 (self-hosted)
- **Total additional cost: $0** ✨

No VPS needed thanks to CF Tunnel's UDP support!

## Future Enhancements

### Option 1: Keep Both Access Methods

- **Cloudflare Tunnel**: Public-facing web services (current setup)
- **Pangolin**: VPN access to private resources (new)

This is the safest approach - add capabilities without removing existing functionality.

### Option 2: Consolidate on Pangolin

Migrate all public services from CF Tunnel to Pangolin's public resources:
- Single platform for all external access
- Unified access control and logging
- Identity-aware for all services

Trade-off: Lose CF's DDoS protection on public services.

## Additional Resources

- [Pangolin Documentation](https://docs.pangolin.net)
- [Pangolin GitHub](https://github.com/fosrl/pangolin)
- [Cloudflare Tunnel UDP Support](https://developers.cloudflare.com/changelog/2025-07-15-udp-improvements/)
- [Resource Configuration Guide](RESOURCE_CONFIG_GUIDE.md)

## Quick Reference

### Key URLs
- **Dashboard**: https://vpn.yourdomain.com
- **WireGuard Endpoint**: vpn-wg.yourdomain.com:51820

### Key Commands
```bash
# Deploy/Update
git commit -am "Update Pangolin" && git push

# Check status
kubectl get pods -n network -l app.kubernetes.io/name=pangolin

# View logs
kubectl logs -n network -l app.kubernetes.io/name=pangolin -f

# Client commands
olm connect
olm status
olm disconnect
```

### Support

If you encounter issues:
1. Check logs: Pangolin pod and CF Tunnel
2. Review Pangolin dashboard events
3. Verify Cloudflare Zero Trust tunnel status
4. Consult [Pangolin GitHub Issues](https://github.com/fosrl/pangolin/issues)
