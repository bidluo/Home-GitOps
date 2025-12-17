# Pangolin Quick Start Guide

Get Pangolin running in 10 minutes.

## Prerequisites

- Home Kubernetes cluster (✅ you have this)
- Cloudflare Tunnel configured (✅ you have this)
- Domain name (✅ you have this)
- SOPS configured for secrets (✅ you have this)

## Step-by-Step Setup

### 1. Configure Secrets (2 minutes)

```bash
cd apps/network/pangolin/app
```

Edit `pangolin-secrets.sops.yaml`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: pangolin-secrets
  namespace: network
type: Opaque
stringData:
  PANGOLIN_DOMAIN: "vpn.yourdomain.com"  # ← Change this
  PANGOLIN_ADMIN_EMAIL: "admin@yourdomain.com"  # ← Change this
  PANGOLIN_ADMIN_PASSWORD: "SuperStrongPassword123!"  # ← Change this
```

Encrypt and commit:

```bash
sops -e -i pangolin-secrets.sops.yaml
cd ../../../../
git add apps/network/pangolin/
git add apps/network/cloudflare-tunnel/
git commit -m "Add Pangolin VPN access platform"
git push
```

### 2. Wait for Deployment (3-5 minutes)

```bash
# Watch Flux deploy Pangolin
watch kubectl get pods -n network

# Wait until pangolin pod shows "Running"
# Also verify cloudflare-tunnel pod restarts with new config
```

### 3. Access Dashboard (1 minute)

Open browser to: `https://vpn.yourdomain.com`

Login with:
- Email: (from secrets)
- Password: (from secrets)

### 4. Create First Resource (2 minutes)

In Pangolin dashboard:

1. Click **Resources** → **Private Resources** → **Add Resource**

2. Create "Home Network" resource:
   ```
   Name: Home Network
   Type: Network Range
   CIDR: 192.168.1.0/24
   Ports: *
   Protocol: TCP/UDP
   ```

3. Click **Save**

This gives VPN access to your entire home network!

### 5. Create Client (2 minutes)

1. Click **Clients** → **Add Client**

2. Configure:
   ```
   Name: My Laptop
   Allowed Resources: [x] Home Network
   ```

3. Click **Create**

4. **Download** the configuration or copy the credential string

### 6. Install Olm Client (Device-dependent)

**macOS:**
```bash
brew install fosrl/tap/olm
olm configure --credential <paste-credential-from-dashboard>
```

**Linux:**
```bash
wget https://github.com/fosrl/pangolin/releases/latest/download/olm-linux-amd64
chmod +x olm-linux-amd64
sudo mv olm-linux-amd64 /usr/local/bin/olm
olm configure --credential <paste-credential-from-dashboard>
```

**Windows:** Download installer from GitHub releases

**Mobile:** Install Olm app, scan QR code from dashboard

### 7. Connect! (30 seconds)

```bash
olm connect
```

Test it:
```bash
# Ping your router
ping 192.168.1.1

# SSH to a machine
ssh user@192.168.1.50

# Access your NAS
open smb://192.168.1.50  # macOS
# Or browse to \\192.168.1.50 on Windows
```

🎉 **You're done!** You now have secure VPN access to your home network from anywhere.

## What Just Happened?

```
Your Phone/Laptop
       ↓
   (Olm Client)
       ↓
  WireGuard Tunnel
       ↓
 Cloudflare Tunnel (UDP)
       ↓
   Your Home Cluster
       ↓
    Pangolin
       ↓
   Home Network
  (NAS, SSH, etc.)
```

Cloudflare Tunnel handles the UDP transport, so no VPS needed!

## Next Steps

### Add More Specific Resources

Instead of full network access, create targeted resources:

**NAS Only:**
```
Name: NAS
Type: Host
IP: 192.168.1.50
Ports: 22,445,2049
```

**SSH Only:**
```
Name: SSH Access
Type: Network Range
CIDR: 192.168.1.0/24
Port: 22
```

**Kubernetes API:**
```
Name: K8s API
Type: Host
IP: 192.168.1.100
Port: 6443
```

See [RESOURCE_CONFIG_GUIDE.md](RESOURCE_CONFIG_GUIDE.md) for 20+ examples.

### Create Additional Clients

Create separate clients for:
- Work laptop
- Personal laptop
- Phone
- Tablet
- Family members (with restricted access)

Each client can have different resource permissions!

### Enable MFA

In Pangolin dashboard:
1. Click your profile
2. Go to **Security**
3. Enable **Multi-Factor Authentication**

### Add SSO/OIDC (Optional)

Integrate with your Authentik instance:
1. Create OIDC provider in Authentik
2. Configure in Pangolin dashboard under **Settings** → **Authentication**

## Common Commands

```bash
# Connect VPN
olm connect

# Check status
olm status

# Disconnect
olm disconnect

# List available resources
olm resources

# View logs
olm logs

# Update client
brew upgrade olm  # macOS
# or download latest from GitHub
```

## Troubleshooting

### "Can't reach vpn.yourdomain.com"

```bash
# Check DNS
dig vpn.yourdomain.com

# Check Pangolin pod
kubectl get pods -n network -l app.kubernetes.io/name=pangolin

# Check logs
kubectl logs -n network -l app.kubernetes.io/name=pangolin
```

### "Olm can't connect"

```bash
# Verify WireGuard endpoint
nc -zvu vpn-wg.yourdomain.com 51820

# Check client has resource permissions in dashboard

# Review Pangolin WireGuard logs
kubectl logs -n network -l app.kubernetes.io/name=pangolin | grep -i wireguard
```

### "Connected but can't access resources"

1. Verify client has permission to access resource in dashboard
2. Check resource configuration (correct IPs/ports)
3. Test from Pangolin pod:
   ```bash
   kubectl exec -n network deployment/pangolin -- ping 192.168.1.1
   ```

## Daily Usage

### Morning Routine
```bash
olm connect
# Now work as if you're at home!
```

### Evening
```bash
olm disconnect
# Or leave connected, it's secure!
```

### On Mobile
- Open Olm app
- Toggle VPN on
- Access home resources via apps

## Pro Tips

1. **Always Connected**: Olm is lightweight - you can leave it connected all day
2. **Split Tunneling**: Configure which traffic goes through VPN in Olm settings
3. **Multiple Profiles**: Create different Olm profiles for work/personal
4. **Resource Groups**: Use tags in Pangolin to organize resources
5. **Audit Logs**: Review connection logs in Pangolin dashboard regularly

## More Information

- **Full Setup Guide**: [README.md](README.md)
- **Resource Examples**: [RESOURCE_CONFIG_GUIDE.md](RESOURCE_CONFIG_GUIDE.md)
- **Pangolin Docs**: https://docs.pangolin.net
- **Get Help**: https://github.com/fosrl/pangolin/issues

---

**Estimated Total Setup Time**: ~10 minutes

**Cost**: $0 (no VPS needed thanks to Cloudflare Tunnel UDP support)

**Maintenance**: ~5 minutes/month (updates)

