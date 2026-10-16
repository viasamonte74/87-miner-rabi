#!/usr/bin/env bash
# After tunnel restart, URL changes — push new ORIGIN to the Worker.
set -euo pipefail
. /opt/nvm/nvm.sh
LOG=/root/.pm2/logs/sn87-rabi-h1-tunnel-error.log
TUNNEL=$(grep -ohE 'https://[a-zA-Z0-9.-]+\.trycloudflare\.com' "$LOG" /root/.pm2/logs/sn87-rabi-h1-tunnel-out.log 2>/dev/null | tail -1)
if [[ -z "$TUNNEL" ]]; then
  echo "No trycloudflare URL found in tunnel logs. Is sn87-rabi-h1-tunnel online?"
  exit 1
fi
echo "Setting ORIGIN=$TUNNEL"
printf '%s' "$TUNNEL" | npx wrangler secret put ORIGIN --cwd /workspace/sn87-miner-rabi/worker
echo "$TUNNEL" > /workspace/sn87-miner-rabi/WORKER_ORIGIN.txt
curl -sS --max-time 20 https://provx.mstjeon6.workers.dev/ready; echo
