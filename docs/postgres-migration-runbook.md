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

## Immich notes (PR3)
- `immich-pg` uses the pgvecto.rs image; ensure `CREATE EXTENSION IF NOT EXISTS vectors;` exists in
  each target DB (the image provides it) before restore, or restore with the extension pre-created.
- Two DBs (`immich`, `limmich`) live in one `immich-pg` cluster; repeat step 3 for each.
- Stop immich server + machine-learning + any workers during the dump. Verify photo browse **and**
  search (search exercises the vector index) afterward.

## Authentik notes (PR4 — do last)
- Authentik gates all SSO. Keep the old DB as break-glass; if login breaks, revert the secret host to
  `data-cluster-rw` and resume — `kubectl` access is unaffected regardless.
- Rotate the weak `postgrespassword` during the cutover.
