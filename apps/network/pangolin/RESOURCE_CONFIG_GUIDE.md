# Pangolin Resource Configuration Guide

This guide provides specific examples for configuring resources in Pangolin to access your home network.

## Resource Types

Pangolin supports two main resource types:

1. **Private Resources**: Accessed via Olm VPN client (NAS, SSH, etc.)
2. **Public Resources**: Exposed via reverse proxy with optional authentication

## Common Private Resource Configurations

### 1. Full Home Network Access

Access everything on your home network:

```
Resource Type: Private
Name: Home Network
Site: home-cluster
Access Type: Network Range
Network CIDR: 192.168.1.0/24
Ports: *
Protocol: TCP/UDP
Description: Full access to home LAN
```

This allows you to access any device on your home network when connected via Olm.

### 2. NAS/File Server Access

#### TrueNAS / Synology / Generic NAS

```
Resource Type: Private
Name: NAS
Site: home-cluster
Access Type: Host
IP Address: 192.168.1.50
Ports: 22,80,443,445,2049,5000,5001
Protocol: TCP
Description: NAS access (SSH, HTTP, HTTPS, SMB, NFS, DSM)
```

Common NAS ports:
- `22`: SSH/SFTP
- `80/443`: Web UI
- `445`: SMB/CIFS (Windows shares)
- `2049`: NFS
- `5000/5001`: Synology DSM
- `8080`: QNAP web interface

#### SMB/CIFS Shares Only

```
Resource Type: Private
Name: SMB Shares
Site: home-cluster
Access Type: Host
IP Address: 192.168.1.50
Ports: 445,139
Protocol: TCP
Description: Windows file sharing
```

Usage when connected:
```
Windows: \\192.168.1.50\sharename
macOS: smb://192.168.1.50/sharename
Linux: smb://192.168.1.50/sharename
```

### 3. SSH Access to Multiple Hosts

#### All SSH Hosts

```
Resource Type: Private
Name: SSH Access
Site: home-cluster
Access Type: Network Range
Network CIDR: 192.168.1.0/24
Ports: 22
Protocol: TCP
Description: SSH to all home devices
```

#### Specific SSH Hosts

For individual servers:

```
Resource Type: Private
Name: Pi-hole SSH
Site: home-cluster
Access Type: Host
IP Address: 192.168.1.10
Ports: 22
Protocol: TCP
```

```
Resource Type: Private
Name: Docker Host SSH
Site: home-cluster
Access Type: Host
IP Address: 192.168.1.20
Ports: 22
Protocol: TCP
```

### 4. Kubernetes Cluster Access

#### Access K8s Services

```
Resource Type: Private
Name: K8s Services
Site: home-cluster
Access Type: Network Range
Network CIDR: 10.43.0.0/16
Ports: *
Protocol: TCP/UDP
Description: Access to K8s cluster services
```

Note: Replace `10.43.0.0/16` with your actual Kubernetes service CIDR.

#### Access K8s API

```
Resource Type: Private
Name: K8s API
Site: home-cluster
Access Type: Host
IP Address: 192.168.1.100
Ports: 6443
Protocol: TCP
Description: Kubernetes API server
```

Usage when connected:
```bash
# Update kubeconfig server to internal IP
kubectl config set-cluster mycluster --server=https://192.168.1.100:6443
kubectl get nodes
```

### 5. IoT Devices / Home Automation

#### Home Assistant

```
Resource Type: Private
Name: Home Assistant
Site: home-cluster
Access Type: Host
IP Address: 192.168.1.30
Ports: 8123
Protocol: TCP
```

#### ESPHome / Zigbee Devices

```
Resource Type: Private
Name: IoT Devices
Site: home-cluster
Access Type: Network Range
Network CIDR: 192.168.1.0/24
Ports: 80,443,6053,1883
Protocol: TCP
Description: IoT/ESPHome devices (HTTP, mDNS, MQTT)
```

### 6. Media Servers

#### Plex

```
Resource Type: Private
Name: Plex
Site: home-cluster
Access Type: Host
IP Address: 192.168.1.40
Ports: 32400,32469
Protocol: TCP
Description: Plex Media Server
```

#### Jellyfin

```
Resource Type: Private
Name: Jellyfin
Site: home-cluster
Access Type: Host
IP Address: 192.168.1.41
Ports: 8096,8920
Protocol: TCP
Description: Jellyfin Media Server
```

### 7. Network Equipment Access

#### Router/Firewall

```
Resource Type: Private
Name: Router Admin
Site: home-cluster
Access Type: Host
IP Address: 192.168.1.1
Ports: 80,443,22
Protocol: TCP
Description: Router web interface and SSH
```

#### Managed Switches

```
Resource Type: Private
Name: Network Switches
Site: home-cluster
Access Type: Network Range
Network CIDR: 192.168.1.2-192.168.1.5
Ports: 80,443,22,23
Protocol: TCP
Description: Managed switch access
```

### 8. Gaming Servers

#### Minecraft

```
Resource Type: Private
Name: Minecraft Server
Site: home-cluster
Access Type: Host
IP Address: 192.168.1.60
Ports: 25565
Protocol: TCP
Description: Minecraft server
```

Connect with: `192.168.1.60:25565` when Olm is connected

### 9. Database Access

#### PostgreSQL

```
Resource Type: Private
Name: PostgreSQL
Site: home-cluster
Access Type: Host
IP Address: 192.168.1.70
Ports: 5432
Protocol: TCP
Description: PostgreSQL database
```

#### MySQL/MariaDB

```
Resource Type: Private
Name: MySQL
Site: home-cluster
Access Type: Host
IP Address: 192.168.1.71
Ports: 3306
Protocol: TCP
```

### 10. Development Environment

#### Full Dev Subnet

```
Resource Type: Private
Name: Dev Environment
Site: home-cluster
Access Type: Network Range
Network CIDR: 192.168.1.100-192.168.1.120
Ports: *
Protocol: TCP/UDP
Description: Development servers and services
```

## Public Resource Configurations

If you want to replace Cloudflare Tunnels with Pangolin's reverse proxy:

### Web Application with Authentication

```
Resource Type: Public
Name: Home Assistant
Hostname: home.yourdomain.com
Site: home-cluster
Target URL: http://home-assistant.home.svc.cluster.local:8123
Authentication: PIN / OIDC / None
SSL: Automatic (Let's Encrypt)
```

### Multiple Domains

For each service currently in your Cloudflare Tunnel config:

#### Sonarr
```
Hostname: sonarr.yourdomain.com
Target: http://ak-outpost-media.media.svc.cluster.local:9000
```

#### Plex
```
Hostname: plex.yourdomain.com
Target: http://plex.media.svc.cluster.local:32400
```

#### Immich
```
Hostname: img.yourdomain.com
Target: http://immich-main.media.svc.cluster.local:2283
```

## Access Control

### Per-User Resource Access

Create different clients with different permissions:

**Admin Client (Full Access):**
- All private resources
- All public resources

**Family Member Client (Limited):**
- NAS SMB shares only
- Media servers
- Home automation

**Guest Client (Minimal):**
- Specific IoT devices only
- Limited time access (can be revoked)

### Configuration in Dashboard

1. Go to **Clients** → Select client
2. Click **Edit**
3. Under **Allowed Resources**, select which resources this client can access
4. Save

## Resource Tags

Organize resources with tags:

```
Tag: production
Tag: development
Tag: media
Tag: iot
Tag: admin-only
```

Use tags to:
- Group similar resources
- Quickly grant/revoke access by tag
- Filter in dashboard

## Best Practices

1. **Start Broad, Then Restrict**
   - Initially create full network access
   - Test connectivity
   - Narrow down to specific hosts/ports as needed

2. **Use Descriptive Names**
   - Good: "NAS - TrueNAS Main (192.168.1.50)"
   - Bad: "Server1"

3. **Document IPs and Ports**
   - Keep a list of all devices and their IPs
   - Note which services run on which ports

4. **Network Segmentation**
   - Consider creating VLANs for different resource types
   - IoT VLAN: 192.168.10.0/24
   - Servers VLAN: 192.168.20.0/24
   - Trusted devices: 192.168.1.0/24

5. **Least Privilege**
   - Don't give all clients access to all resources
   - Create role-based access (admin, user, guest)

6. **Monitor Access**
   - Regularly review Pangolin access logs
   - Check for suspicious connection patterns
   - Revoke unused client credentials

## Testing Resource Access

### After Configuration

1. **Connect Olm Client**
   ```bash
   olm connect
   olm status  # Should show "Connected"
   ```

2. **Test Connectivity**
   ```bash
   # Ping test
   ping 192.168.1.50
   
   # Port test
   nc -zv 192.168.1.50 445
   
   # SSH test
   ssh user@192.168.1.10
   
   # HTTP test
   curl http://192.168.1.30:8123
   ```

3. **Test from Applications**
   - Mount SMB share
   - Open web UI in browser
   - Connect database client
   - Access Kubernetes API

### Troubleshooting Access Issues

**Can't Access Resource:**

1. Verify resource is configured in Pangolin dashboard
2. Check client has permission to access resource
3. Confirm Olm shows connected status
4. Test connectivity: `ping`, `traceroute`, `nc`
5. Check Newt logs in home cluster
6. Verify firewall rules on target device

**Slow Performance:**

1. Check VPS bandwidth limits
2. Monitor WireGuard tunnel overhead
3. Consider geographic location of VPS
4. Review resource usage on VPS

## Example: Migrating from Your Current Setup

Based on your Cloudflare Tunnel config, here's a mapping to Pangolin resources:

### Keep as Public Resources (Replace CF Tunnel)

```yaml
# These become Pangolin Public Resources
- sonarr.domain.com → http://ak-outpost-media.media:9000
- radarr.domain.com → http://ak-outpost-media.media:9000
- plex.domain.com → http://plex.media:32400
- img.domain.com → http://immich-main.media:2283
# ... etc
```

### Make Private Resources (New VPN Access)

```yaml
# These become Private Resources (via Olm)
- NAS: 192.168.1.x (SMB, NFS, SSH)
- SSH to all machines: 192.168.1.0/24:22
- K8s cluster internal: 10.43.0.0/16
- Router/switches: 192.168.1.1-5
```

## Quick Reference: Common Ports

| Service | Port(s) | Protocol |
|---------|---------|----------|
| SSH | 22 | TCP |
| HTTP | 80 | TCP |
| HTTPS | 443 | TCP |
| SMB/CIFS | 445, 139 | TCP |
| NFS | 2049 | TCP |
| RDP | 3389 | TCP |
| Kubernetes API | 6443 | TCP |
| PostgreSQL | 5432 | TCP |
| MySQL | 3306 | TCP |
| Redis | 6379 | TCP |
| MongoDB | 27017 | TCP |
| Plex | 32400 | TCP |
| Home Assistant | 8123 | TCP |
| Minecraft | 25565 | TCP |
| MQTT | 1883 | TCP |
| Synology DSM | 5000/5001 | TCP |

## Next Steps

1. Deploy Pangolin on VPS (see main README.md)
2. Connect Newt from home cluster
3. Create your first private resource (start with full network access)
4. Test with Olm client
5. Add specific resources as needed
6. Optionally migrate public services from CF Tunnel

