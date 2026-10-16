#!/usr/bin/env bash
# Deploy SN87 proxy Worker; ORIGIN = current trycloudflare tunnel hostname
set -euo pipefail
. /opt/nvm/nvm.sh
cd /workspace/sn87-miner-rabi/worker

TUNNEL=$(grep -ohE 'https://[a-zA-Z0-9.-]+\.trycloudflare\.com' \
  /root/.pm2/logs/sn87-rabi-h1-tunnel-error.log \
  /root/.pm2/logs/sn87-rabi-h1-tunnel-out.log 2>/dev/null | tail -1)
ORIGIN="${ORIGIN:-$TUNNEL}"
if [[ -z "$ORIGIN" ]]; then
  echo "No ORIGIN. Start: pm2 start sn87-rabi-h1-tunnel  (or set ORIGIN=https://....trycloudflare.com)"
  exit 1
fi
echo "ORIGIN=$ORIGIN"
echo "Public: https://provx.mstjeon6.workers.dev"

if ! npx wrangler whoami 2>/dev/null | grep -qiE 'Account|email|logged'; then
  echo "Run: npx wrangler login"
  exit 1
fi

npx wrangler deploy
printf '%s' "$ORIGIN" | npx wrangler secret put ORIGIN
echo "$ORIGIN" > /workspace/sn87-miner-rabi/WORKER_ORIGIN.txt
curl -sS --max-time 20 https://provx.mstjeon6.workers.dev/ready; echo
