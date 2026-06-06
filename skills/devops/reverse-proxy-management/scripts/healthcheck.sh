#!/usr/bin/env bash
# Healthcheck — silent si OK, alerte Telegram si problème
# Usage: bash ~/.hermes/scripts/healthcheck.sh
# Intégré comme cron no_agent=true toutes les 15min
set -euo pipefail

ENDPOINTS=(
  "hermes.dev.mowtif.com/api/stats|200"
  "code.dev.mowtif.com|302"
)

ALERTS=""
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S UTC')

for entry in "${ENDPOINTS[@]}"; do
  path="${entry%%|*}"
  expected="${entry##*|}"
  url="https://$path"
  http_code=$(curl -s -o /dev/null -w '%{http_code}' --connect-timeout 10 --max-time 15 "$url" 2>/dev/null || echo "000")

  if [ "$http_code" != "$expected" ] && [ "$http_code" != "200" ] && [ "$http_code" != "302" ]; then
    ALERTS+="🔴 $url → HTTP $http_code (attendu: $expected)\n"
  fi
done

# Certificate expiry check (alerte < 15 jours)
# NOTE: || true est CRITICAL ici — sans ça, set -e + pipefail tue le script
# quand openssl s_client ne peut pas se connecter (port 443 down), et les
# alertes HTTP ne sont jamais émises.
for domain in hermes.dev.mowtif.com code.dev.mowtif.com; do
  expiry=$(echo | openssl s_client -servername "$domain" -connect "$domain":443 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2) || true
  if [ -n "$expiry" ]; then
    expiry_epoch=$(date -d "$expiry" +%s 2>/dev/null)
    now_epoch=$(date +%s)
    days_left=$(( (expiry_epoch - now_epoch) / 86400 ))
    if [ "$days_left" -lt 15 ]; then
      ALERTS+="⚠️  Certificat $domain expire dans $days_left jours ($expiry)\n"
    fi
  fi
done

if [ -n "$ALERTS" ]; then
  echo -e "🛡️ **Healthcheck — $TIMESTAMP**\n\n$ALERTS"
fi