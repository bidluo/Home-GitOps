# Postgres per-app migration — data cutover runbook

Reusable procedure for moving one app's data off the shared `data-cluster` onto its new
per-app CNPG cluster (`<app>-pg`). See `~/.claude/plans/ancient-riding-tiger.md` for the
overall plan. Order matters: **restore the data before the app points at the new cluster.**

Variables per app:

| App | old DB | new cluster | new DB/owner | image |
|-----|--------|-------------|--------------|-------|
| zipline | `zipline` | `zipline-pg` | `zipline` | plain PG |
| immich | `immich` | `immich-pg` | `immich` | pgvecto.rs |
| immich-lotus | `limmich` | `immich-pg` | `limmich` | pgvecto.rs |
| authentik | `authentik` | `authentik-pg` | `authentik` | plain PG |

## Per-app cutover (example: zipline)

1. **Land the new cluster** (its manifest is already committed). Reconcile and confirm it's healthy:
   ```sh
   flux reconcile kustomization apps --with-source
   kubectl cnpg status zipline-pg          # primary Ready; database `zipline` + role exist
   ```

2. **Quiesce the app** so nothing writes during the dump (Zipline isn't actively used, but still):
   ```sh
   flux suspend helmrelease zipline -n media
   kubectl scale deploy -n media -l app.kubernetes.io/name=zipline --replicas=0
   ```

3. **Dump from the old shared cluster, restore into the new cluster.** Run inside the cluster
   (the CNPG pods have `pg_dump`/`pg_restore`). Simplest is a one-shot pipe via the primaries:
   ```sh
   # dump old DB (custom format) to a local file on the old primary, copy out, restore in.
   OLD=$(kubectl get pods -n data -l cnpg.io/cluster=data-cluster,role=primary -o name | head -1)
   NEW=$(kubectl get pods -n data -l cnpg.io/cluster=zipline-pg -o name | head -1)

   kubectl exec -n data "$OLD" -- bash -lc \
     'pg_dump -U postgres -Fc -d zipline -f /var/lib/postgresql/data/zipline.dump'
   kubectl cp data/"${OLD#pod/}":/var/lib/postgresql/data/zipline.dump /tmp/zipline.dump
   kubectl cp /tmp/zipline.dump data/"${NEW#pod/}":/var/lib/postgresql/data/zipline.dump

   # restore as the new owner; --no-owner/--no-acl so objects land under the new role
   kubectl exec -n data "$NEW" -- bash -lc \
     'pg_restore -U postgres --no-owner --no-acl --role=zipline -d zipline /var/lib/postgresql/data/zipline.dump'
   ```
   Sanity-check row counts match, e.g. `kubectl exec -n data "$NEW" -- psql -U postgres -d zipline -c '\dt'`.

4. **Flip the app to the new cluster.** I do this in the follow-up commit: update the app's
   SOPS secret DSN/host to `zipline-pg-rw.data.svc.cluster.local:5432` (+ rotated password) and add
   `postgres-zipline` to its `dependsOn`. Then:
   ```sh
   flux resume helmrelease zipline -n media
   flux reconcile kustomization apps --with-source
   ```

5. **Verify** the app works against the new DB (Zipline lists existing uploads / links resolve).

6. **Leave the old `zipline` DB in `data-cluster` untouched** as a fallback. To roll back, revert
   the secret host to `data-cluster-rw` and resume. Drop the old DB only in the final decommission
   phase, after everything is verified.

## Immich (PR3) — concrete cutover
`immich-pg` (pgvecto.rs) hosts BOTH databases: `immich` (initdb) and `limmich` (Database CR + managed
role). Owner passwords are **reused** from the existing immich secrets, so the app flip is host-only.

1. Reconcile; confirm cluster + both DBs exist:
   ```sh
   kubectl get cluster,database -n data | grep immich
   kubectl exec -n data immich-pg-1 -- psql -U postgres -c "\l" | grep -E 'immich|limmich'
   ```
2. Quiesce both Immich instances (server + machine-learning):
   ```sh
   flux suspend hr immich immich-lotus -n media
   kubectl scale deploy -n media -l app.kubernetes.io/instance=immich --replicas=0
   kubectl scale deploy -n media -l app.kubernetes.io/instance=immich-lotus --replicas=0
   ```
3. Dump→restore each DB. Restore as **superuser, WITHOUT `--no-owner`** so ownership carries over and the
   `vectors`/`cube`/`earthdistance` extensions get created (they need superuser):
   ```sh
   kubectl exec -n data data-cluster-3 -- pg_dump -U postgres -Fc -d immich \
    | kubectl exec -i -n data immich-pg-1 -- pg_restore -U postgres --no-acl -d immich
   kubectl exec -n data data-cluster-3 -- pg_dump -U postgres -Fc -d limmich \
    | kubectl exec -i -n data immich-pg-1 -- pg_restore -U postgres --no-acl -d limmich
   ```
   A few "already exists" notices for the extensions are benign. Sanity-check counts (e.g. `assets`).
4. Tell me — I flip `DB_HOSTNAME` in both immich secrets to `immich-pg-rw.data.svc.cluster.local` (host only),
   commit; you push.
5. `flux resume hr immich immich-lotus -n media`; verify photos **browse and search** (search exercises the
   vector index) on both instances. Old immich/limmich DBs stay in data-cluster as fallback.

## Authentik (PR4 — do last) — concrete cutover + break-glass
Authentik gates all SSO. `authentik-pg` is plain PG (only `plpgsql`), db+owner `authentik` via initdb,
password **rotated** off the default `postgrespassword` (new value in `authentik-pg-owner`). The app flip
changes **both** `AUTHENTIK_POSTGRESQL__HOST` and `__PASSWORD`.

**Break-glass first:** before you start, note the current rollback = revert both `__HOST` (→ `data-cluster-rw`)
and `__PASSWORD` (→ `postgrespassword`) in `authentik-secrets` and restart. `kubectl` is unaffected if SSO is
down, so you can always recover from the terminal. Do this during a low-traffic window.

1. After pushing the cluster commit, confirm `authentik-pg` healthy + db exists.
2. Quiesce Authentik (stops writes to the old DB):
   ```sh
   kubectl scale deploy -n auth authentik-server authentik-worker --replicas=0
   ```
3. Dump→restore (superuser, keep ownership; `authentik` role pre-exists via initdb):
   ```sh
   kubectl exec -n data data-cluster-3 -- pg_dump -U postgres -Fc -d authentik \
    | kubectl exec -i -n data authentik-pg-1 -- pg_restore -U postgres --no-acl -d authentik
   ```
   Check table count == 207.
4. Tell me — I flip `__HOST` + `__PASSWORD` in `authentik-secrets`, commit; you push.
5. Scale back up: `kubectl scale deploy -n auth authentik-server authentik-worker --replicas=1`.
   Verify a full login flow to a downstream app (e.g. Longhorn/Sonarr via the outpost). Old DB stays as fallback.
