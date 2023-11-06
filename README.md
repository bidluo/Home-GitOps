# K3s GitOps

Hey there! 👋 Thanks for stopping by. This repo is a little window into my world of managing Kubernetes with K3s on Flux. It's a practical setup, a bit of experimentation, and a whole lot of learning on the go. Dive in and take a look around!
It's kept up to date as it is a 'production' cluster

## Table of Contents

- [Repository Structure](#repository-structure)
- [Project Catalogue](#project-catalogue)
- [Security and Compliance](#security-and-compliance)
- [License](#license)
- [Acknowledgements](#acknowledgements)

## Repository Structure

The repository is structured as follows:

```
├── .github/            # GitHub Actions and workflows
├── apps/               # Application values and definitions
├── base/               # Base configuration and flux generated files
├── charts/             # Chart repository definitions
├── configs/            # Cluster wide configurations
└── README.md
```

## Project Catalogue

### Media Applications
These applications are for managing, automating, and serving media content.

> The [common chart](https://github.com/bjw-s/helm-charts) provided by [bjw-s](https://github.com/bjw-s) has been used for a lot of the applications as it's robust and easy enough to learn.

| Project          | Description                                                                               | GitHub Link                                                      | Directory in Repo                                                     |
|------------------|-------------------------------------------------------------------------------------------|------------------------------------------------------------------|-----------------------------------------------------------------------|
| Plex             | Plex is a feature-rich media library platform that organizes and streams your media files. | [Plex](https://github.com/plexinc/pms-docker)                    | [apps/media/plex](https://github.com/bidluo/Home-GitOps/tree/main/apps/media/plex) |
| Sonarr           | Automated TV show management tool for downloading and serving television series.          | [Sonarr](https://github.com/Sonarr/Sonarr)                       | [apps/media/sonarr](https://github.com/bidluo/Home-GitOps/tree/main/apps/media/sonarr) |
| Radarr           | A fork of Sonarr to work with movies à la Couchpotato.                                    | [Radarr](https://github.com/Radarr/Radarr)                       | [apps/media/radarr](https://github.com/bidluo/Home-GitOps/tree/main/apps/media/radarr) |
| Overseerr        | A request management and media discovery tool to integrate with Plex and other services.   | [Overseerr](https://github.com/sct/overseerr)                    | [apps/media/overseerr](https://github.com/bidluo/Home-GitOps/tree/main/apps/media/overseerr) |
| Plaxt            | Allows for Plex plays to be scrobbled to Trakt.tv instantly.                               | [Plaxt](https://github.com/xanderstrike/goplaxt)                 | [apps/media/plaxt](https://github.com/bidluo/Home-GitOps/tree/main/apps/media/plaxt) |
| intel-gpu-plugin | A plugin to facilitate Intel GPU usage in Kubernetes clusters for various workloads.       | [intel-gpu-plugin](https://github.com/intel/intel-device-plugins-for-kubernetes) | [apps/media/intel-gpu-plugin](https://github.com/bidluo/Home-GitOps/tree/main/apps/media/intel-gpu-plugin) |
| Immich           | An open-source personal media backup solution with a mobile-first approach.                | [Immich](https://github.com/immich-app/immich)                    | [apps/media/immich](https://github.com/bidluo/Home-GitOps/tree/main/apps/media/immich) |
| SABnzbd          | A robust and reliable binary newsgrabber for downloading files from Usenet servers.        | [SABnzbd](https://github.com/sabnzbd/sabnzbd)                     | [apps/media/sabnzbd](https://github.com/bidluo/Home-GitOps/tree/main/apps/media/sabnzbd) |
| Tautulli         | Monitoring and tracking tool for Plex Media Server with a rich feature set.                | [Tautulli](https://github.com/Tautulli/Tautulli)                  | [apps/media/tautulli](https://github.com/bidluo/Home-GitOps/tree/main/apps/media/tautulli) |
| Tdarr            | A distributed media transcoding system with a focus on automation and scalability.         | [Tdarr](https://github.com/HaveAGitGat/Tdarr)                     | [apps/media/tdarr](https://github.com/bidluo/Home-GitOps/tree/main/apps/media/tdarr) |


### Network Tools
Network tools are essential for routing, load balancing, and managing certificates within a Kubernetes cluster.


| Project         | Description                                                         | GitHub Link                                                            | Directory in Repo                                                       |
|-----------------|---------------------------------------------------------------------|------------------------------------------------------------------------|-------------------------------------------------------------------------|
| Traefik         | A modern HTTP reverse proxy and load balancer.                      | [Traefik](https://github.com/traefik/traefik)                          | [apps/network/traefik](https://github.com/bidluo/Home-GitOps/tree/main/apps/network/traefik) |
| Cert-Manager    | Automates the management and issuance of TLS certificates.          | [Cert-Manager](https://github.com/cert-manager/cert-manager)            | [apps/network/cert-manager](https://github.com/bidluo/Home-GitOps/tree/main/apps/network/cert-manager) |
| MetalLB         | A load-balancer implementation for bare metal Kubernetes clusters.  | [MetalLB](https://github.com/metallb/metallb)                           | [apps/network/metallb](https://github.com/bidluo/Home-GitOps/tree/main/apps/network/metallb) |

### Standalone Services
Services that are typically deployed in their own namespace due to their scope or operational requirements.

| Project     | Description                                                                         | GitHub Link                                                          | Directory in Repo                                                         |
|-------------|-------------------------------------------------------------------------------------|----------------------------------------------------------------------|---------------------------------------------------------------------------|
| Authentik   | An identity provider to facilitate authentication, authorization, and more.         | [Authentik](https://github.com/goauthentik/authentik)                | [apps/authentik](https://github.com/bidluo/Home-GitOps/tree/main/apps/authentik) |
| Longhorn    | Cloud-native distributed storage built on and for Kubernetes.                       | [Longhorn](https://github.com/longhorn/longhorn)                     | [apps/longhorn](https://github.com/bidluo/Home-GitOps/tree/main/apps/longhorn) |

### Data Management
Tools for persistent storage, database management, and in-memory data structures.

| Project       | Description                                                         | GitHub Link                                                            | Directory in Repo                                                       |
|---------------|---------------------------------------------------------------------|------------------------------------------------------------------------|-------------------------------------------------------------------------|
| CSI-NFS       | CSI driver that allows Kubernetes to use NFS volumes for storage.   | [CSI-NFS](https://github.com/kubernetes-csi/csi-driver-nfs)            | [apps/data/csi-nfs](https://github.com/bidluo/Home-GitOps/tree/main/apps/data/csi-nfs) |
| MinIO         | High performance, Kubernetes-native object storage.                 | [MinIO](https://github.com/minio/minio)                                | [apps/data/minio](https://github.com/bidluo/Home-GitOps/tree/main/apps/data/minio) |
| PostgreSQL    | Robust and reliable open-source relational database system.         | [PostgreSQL](https://github.com/postgres/postgres)                     | [apps/data/postgres](https://github.com/bidluo/Home-GitOps/tree/main/apps/data/postgres) |
| Redis         | An in-memory data structure store, used as a database and cache.    | [Redis](https://github.com/redis/redis)                                | [apps/data/redis](https://github.com/bidluo/Home-GitOps/tree/main/apps/data/redis) |
| Elasticsearch | A distributed search and analytics engine.                          | [Elasticsearch](https://github.com/elastic/elasticsearch)              | [apps/data/elasticsearch](https://github.com/bidluo/Home-GitOps/tree/main/apps/data/elasticsearch) |

### Social Platform
Open-source social networking services.

| Project       | Description                                                         | GitHub Link                                                            | Directory in Repo                                                       |
|---------------|---------------------------------------------------------------------|------------------------------------------------------------------------|-------------------------------------------------------------------------|
| Mastodon      | A free and open-source self-hosted social networking service.       | [Mastodon](https://github.com/mastodon/mastodon)                       | [apps/social/mastodon](https://github.com/bidluo/Home-GitOps/tree/main/apps/social/mastodon) |

### Home Automation
Tools for automating and managing home infrastructure.

| Project         | Description                                                         | GitHub Link                                                            | Directory in Repo                                                       |
|-----------------|---------------------------------------------------------------------|------------------------------------------------------------------------|-------------------------------------------------------------------------|
| Home Assistant  | An open-source home automation platform that prioritizes local control. | [Home Assistant](https://github.com/home-assistant/core)              | [apps/home/home-assistant](https://github.com/bidluo/Home-GitOps/tree/main/apps/home/home-assistant) |

### Public Services
Applications designed for public-facing web services.

| Project       | Description                                                         | GitHub Link                                                            | Directory in Repo                                                       |
|---------------|---------------------------------------------------------------------|------------------------------------------------------------------------|-------------------------------------------------------------------------|
| Ghost         | A professional publishing platform focused on aesthetics and user experience. | [Ghost](https://github.com/TryGhost/Ghost)                           | [apps/public/ghost](https://github.com/bidluo/Home-GitOps/tree/main/apps/public/ghost) |

### Monitoring
Systems and tools for monitoring the health and performance of the cluster and applications.

| Project           | Description                                                         | GitHub Link                                                            | Directory in Repo                                                       |
|-------------------|---------------------------------------------------------------------|------------------------------------------------------------------------|-------------------------------------------------------------------------|
| Uptime-Kuma       | A fancy self-hosted monitoring tool.                                | [Uptime-Kuma](https://github.com/louislam/uptime-kuma)                 | [apps/monitoring/uptime-kuma](https://github.com/bidluo/Home-GitOps/tree/main/apps/monitoring/uptime-kuma) |
| Goldilocks        | Provides recommendations on Kubernetes resource requests and limits. | [Goldilocks](https://github.com/FairwindsOps/goldilocks)               | [apps/monitoring/goldilocks](https://github.com/bidluo/Home-GitOps/tree/main/apps/monitoring/goldilocks) |
| Kube-Prometheus   | A collection of community curated Kubernetes manifests, Grafana dashboards, and Prometheus rules. | [kube-prometheus](https://github.com/prometheus-operator/kube-prometheus) | [apps/monitoring/kube-prom](https://github.com/bidluo/Home-GitOps/tree/main/apps/monitoring/kube-prom) |
| Loki              | A horizontally-scalable, highly-available, multi-tenant log aggregation system. | [Loki](https://github.com/grafana/loki)                               | [apps/monitoring/loki](https://github.com/bidluo/Home-GitOps/tree/main/apps/monitoring/loki) |
| Promtail          | An agent which ships the contents of local logs to a private Loki instance. | [Promtail](https://github.com/grafana/loki/tree/main/clients/promtail) | [apps/monitoring/prom-tail](https://github.com/bidluo/Home-GitOps/tree/main/apps/monitoring/prom-tail) |


## Security

I use SOPS (Secrets OPerationS) for managing secrets securely. SOPS lets me encrypt my secrets so that I can safely store them in my Git repository.

### Why?
- Transparent Encryption/Decryption: SOPS decrypts files on-the-fly, making it feel like you're working with plain text.
- Fine-Grained Control: It allows encrypting only the values, not the keys, in my secret files. This balances security and usability well.
- Versatile Key Management: It supports various key management services, fitting well in different cloud environments.
- Smooth Integration with Flux: I’ve set things up so Flux and SOPS work seamlessly together, decrypting secrets during deployment without exposing sensitive information.

## License

This project is open-sourced under the [MIT License](LICENSE).

## Acknowledgements

A big thank you to all the contributors and maintainers of the tools and technologies used in this project, including K3s, KairOS, Flux, and the wider Kubernetes community.
