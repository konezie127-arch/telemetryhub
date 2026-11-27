#!/usr/bin/env bash
# Interroge /health toutes les 0,5 s et compte les indisponibilites. Ctrl+C pour arreter.
URL="${1:?Usage: watch_availability.sh <url-sans-slash-final>}"
ok=0; ko=0
trap 'echo; echo "Requetes OK : $ok / indisponibles : $ko"; exit 0' INT
echo "Surveillance de $URL/health (Ctrl+C pour terminer)"
while true; do
  code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 2 "$URL/health" || true)"
  if [ "$code" = "200" ]; then
    ok=$((ok+1))
  else
    ko=$((ko+1)); echo "$(date +%H:%M:%S)  code=$code  <-- indisponible"
  fi
  sleep 0.5
done
