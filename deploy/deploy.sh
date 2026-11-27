#!/usr/bin/env bash
# Deploie un tag d'image avec verification de sante et rollback automatique.
# Usage : deploy.sh <image_tag>
set -euo pipefail

APP_DIR="${APP_DIR:-/opt/telemetryhub}"
NEW_TAG="${1:?Usage: deploy.sh <image_tag>}"
HEALTH_URL="http://127.0.0.1/health"
VERSION_URL="http://127.0.0.1/version"
RETRIES=15
DELAY=4

# Un seul deploiement a la fois
exec 9>/var/lock/telemetryhub-deploy.lock
flock -n 9 || { echo "Un deploiement est deja en cours"; exit 1; }

exec > >(tee -a /var/log/telemetryhub-deploy.log) 2>&1
cd "$APP_DIR"

CURRENT_TAG="$(grep -E '^IMAGE_TAG=' .env 2>/dev/null | cut -d= -f2 || true)"
echo "=== $(date -u +%FT%TZ) deploiement : ${CURRENT_TAG:-aucune} -> ${NEW_TAG}"

set_tag()     { echo "IMAGE_TAG=$1" > .env; }
start_stack() { docker compose pull --quiet && docker compose up -d --remove-orphans; }

check_once() {   # $1 = tag attendu
  curl -fsS --max-time 3 "$HEALTH_URL" >/dev/null 2>&1 || return 1
  local sha
  sha="$(curl -fsS --max-time 3 "$VERSION_URL" 2>/dev/null | grep -o '"git_sha":"[^"]*"' | cut -d'"' -f4)"
  [ "$sha" = "$1" ]
}

wait_healthy() {
  local i
  for i in $(seq 1 "$RETRIES"); do
    if check_once "$1"; then return 0; fi
    sleep "$DELAY"
  done
  return 1
}

# Deja a jour et sain : rien a faire
if [ "$CURRENT_TAG" = "$NEW_TAG" ] && check_once "$NEW_TAG"; then
  echo "NOCHANGE : ${NEW_TAG} deja en ligne"
  exit 0
fi

set_tag "$NEW_TAG"
if start_stack && wait_healthy "$NEW_TAG"; then
  echo "OK : version ${NEW_TAG} en ligne"
  exit 0
fi

echo "ECHEC du deploiement de ${NEW_TAG}" >&2
if [ -n "$CURRENT_TAG" ]; then
  echo "ROLLBACK vers ${CURRENT_TAG}" >&2
  set_tag "$CURRENT_TAG"
  start_stack || true
  if wait_healthy "$CURRENT_TAG"; then
    echo "ROLLBACK REUSSI : ${CURRENT_TAG} retabli" >&2
  else
    echo "ROLLBACK ECHOUE : intervention manuelle necessaire" >&2
  fi
fi
exit 1
