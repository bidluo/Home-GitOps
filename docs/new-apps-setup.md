# New apps batch — setup runbook

Branch: `feat/new-apps-batch`. Six new apps added following existing repo conventions
(bjw-s `app-template`, shared CNPG, per-app Redis, Authentik proxy outposts, Cloudflare
tunnel, SOPS/age). Nothing deploys until Flux reconciles this branch.

| App | Namespace | URL | Auth | Backing services |
|-----|-----------|-----|------|------------------|
| Prowlarr | media | `prowlarr.liaw.me` | Authentik (media outpost) | config PVC only |
| PicoShare | media | `share.liaw.me` | own admin secret (links public) | Longhorn block PVC |
| Paperless-ngx | home | `paperless.liaw.me` | Authentik (home outpost) | Postgres + Redis |
| Homepage | home | `dash.liaw.me` | Authentik (home outpost) | configMap + RBAC |
| Postiz | social | `postiz.liaw.me` | own login (OAuth callbacks) | Postgres + Redis |
| Open WebUI | tools | internal / Tailscale only | own login | Longhorn PVC |

## Manual steps required BEFORE reconcile (or the app crashloops)

### 1. Create Postgres databases + roles (Paperless, Postiz)
The shared `data-cluster` does not create per-app DBs declaratively. Passwords are already
generated and stored (encrypted) in the app secrets — pull them out, don't retype:

```sh
# Paperless DB password:
sops -d apps/home/paperless/app/paperless-secrets.sops.yaml | grep PAPERLESS_DBPASS
# Postiz DB password (inside the DATABASE_URL):
sops -d apps/social/postiz/app/postiz-secrets.sops.yaml | grep DATABASE_URL
```

Then, connected to `data-cluster` as superuser (e.g. `kubectl exec` into the primary pod
and run `psql`, or `kubectl cnpg psql data-cluster`):

```sql
CREATE ROLE paperless WITH LOGIN PASSWORD '<PAPERLESS_DBPASS>';
CREATE DATABASE paperless OWNER paperless;

CREATE ROLE postiz WITH LOGIN PASSWORD '<POSTIZ_DBPASS>';
CREATE DATABASE postiz OWNER postiz;
```

Both apps run their own migrations on first boot. If Postiz's Prisma migration errors on a
missing extension, create it once as superuser in the `postiz` DB:
`CREATE EXTENSION IF NOT EXISTS "uuid-ossp";`

### 2. Assign the Authentik proxy providers to the outposts (UI step)
The blueprints create the proxy providers + applications automatically, but the *managed
outpost → provider* assignment is done in the Authentik UI (same as your existing apps):

- **Applications → Outposts → edit the `media` outpost** → add **Prowlarr**.
- **edit the `home` outpost** → add **Paperless** and **Homepage**.

Until this is done the outpost returns 404 for those hostnames.

### 3. DNS
New hostnames: `prowlarr`, `share`, `paperless`, `dash`, `postiz`. If you have a wildcard
`*.liaw.me` CNAME to the tunnel, nothing to do. Otherwise add a CNAME per host pointing at
`<tunnel-id>.cfargotunnel.com` (or via the Cloudflare Zero Trust tunnel UI).

## Fill in the placeholder secrets (edit with `sops <file>`)

- **Open WebUI** — `apps/tools/open-webui/app/openwebui-secrets.sops.yaml`: set `OPENAI_API_KEY`.
  (Open WebUI speaks the OpenAI API. For Claude, point `OPENAI_API_BASE_URL` at a LiteLLM
  proxy — that's a good candidate for the 5700 XT follow-up too.)
- **Postiz** — social platform API keys (X, LinkedIn, etc.) are added as extra keys in
  `apps/social/postiz/app/postiz-secrets.sops.yaml` when you connect each provider; none are
  required to boot.

## Retrieve the Paperless admin login
Auto-created on first boot from the secret:
```sh
sops -d apps/home/paperless/app/paperless-secrets.sops.yaml | grep PAPERLESS_ADMIN
```

## Verify image tags
Tags were set to recent-known values but not verified against registries from here. If a pod
is `ImagePullBackOff`, correct the tag (Renovate will also pin/bump these):

- `ghcr.io/home-operations/prowlarr:1.37.0`
- `ghcr.io/mtlynch/picoshare:latest`
- `ghcr.io/paperless-ngx/paperless-ngx:2.14.7`
- `ghcr.io/gethomepage/homepage:v0.10.9`
- `ghcr.io/gitroomhq/postiz-app:latest`
- `ghcr.io/open-webui/open-webui:v0.6.18`

## Reconcile
```sh
flux reconcile source git flux-system
flux reconcile kustomization apps --with-source
```

## Open WebUI access
No public tunnel (holds API keys + chats). Reach it in-cluster / over Tailscale at
`open-webui.tools.svc.cluster.local:8080`. To expose it behind SSO later, add a `home`/new
outpost route + an Authentik blueprint, same pattern as the others.
