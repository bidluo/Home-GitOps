#!/usr/bin/env fish

# Define environment variables directly
set -gx BITNAMI_DEBUG false
set -gx MASTODON_MODE web
set -gx MASTODON_WEB_PORT_NUMBER 3000
set -gx PG_HOST data-cluster-rw.data.svc.cluster.local
set -gx PG_PORT 5432
set -gx PG_USER mastodon
set -gx DB_NAME mastodon
set -gx REDIS_HOST mastodon-redis-master

# Fetch values from ConfigMaps
# Example: set -gx CONFIG_VAR_NAME (kubectl get configmap CONFIG_MAP_NAME -o jsonpath='{.data.CONFIG_MAP_KEY}')

# Fetch values from Secrets
set -gx MASTODON_DATABASE_PASSWORD (kubectl get secret mastodon-secrets -n social -o jsonpath='{.data.DB_PASS}' | base64 --decode)
set -gx MASTODON_REDIS_PASSWORD (kubectl get secret mastodon-redis -n social -o jsonpath='{.data.redis-password}' | base64 --decode)
set -gx MASTODON_AWS_ACCESS_KEY_ID (kubectl get secret mastodon-secrets -n social -o jsonpath='{.data.MINIO_ACCESS_KEY}' | base64 --decode)
set -gx MASTODON_AWS_SECRET_ACCESS_KEY (kubectl get secret mastodon-secrets -n social -o jsonpath='{.data.MINIO_SECRET_KEY}' | base64 --decode)
set -gx SMTP_LOGIN (kubectl get secret mastodon-mail-secrets -n social -o jsonpath='{.data.login}' | base64 --decode)
set -gx SMTP_PASSWORD (kubectl get secret mastodon-mail-secrets -n social -o jsonpath='{.data.password}' | base64 --decode)

kubectl run mastodon-web-temp -n social -it --image docker.io/bitnami/mastodon:4.2.1-debian-11-r1 \
  --env="BITNAMI_DEBUG=$BITNAMI_DEBUG" \
  --env="MASTODON_MODE=$MASTODON_MODE" \
  --env="MASTODON_WEB_PORT_NUMBER=$MASTODON_WEB_PORT_NUMBER" \
  --env="MASTODON_DATABASE_HOST=$PG_HOST" \
  --env="MASTODON_DATABASE_PORT=$PG_PORT" \
  --env="DB_USER=$PG_USER" \
  --env="DB_PASS=$MASTODON_DATABASE_PASSWORD" \
  --env="DB_NAME=$DB_NAME" \
  --env="REDIS_HOST=$REDIS_HOST" \
  --env="MASTODON_REDIS_PASSWORD=$MASTODON_REDIS_PASSWORD" \
  --env="MASTODON_AWS_ACCESS_KEY_ID=$MASTODON_AWS_ACCESS_KEY_ID" \
  --env="MASTODON_AWS_SECRET_ACCESS_KEY=$MASTODON_AWS_SECRET_ACCESS_KEY" \
  --env="SMTP_LOGIN=$SMTP_LOGIN" \
  --env="SMTP_PASSWORD=$SMTP_PASSWORD" \
  -- /bin/bash
