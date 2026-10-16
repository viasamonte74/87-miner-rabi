#!/usr/bin/env bash
# Usage: ./announce.sh https://your.public.hostname[:port]
set -euo pipefail
ENDPOINT="${1:?HTTPS origin required, e.g. https://miner.example.com}"
KEYFILE=/workspace/sn87-miner-rabi/keys/rabi-h1
OUT=/workspace/sn87-miner-rabi/announcement.json
PREV_ARGS=()
if [[ -f "$OUT" ]]; then
  mv -f "$OUT" "${OUT}.prev"
  PREV_ARGS=(--previous "${OUT}.prev")
fi
cd /workspace/sn87-provenonce-public
uv run sn87-miner announce \
  --hotkey-keyfile "$KEYFILE" \
  --netuid 582 \
  --endpoint "$ENDPOINT" \
  --valid-days 14 \
  "${PREV_ARGS[@]}" \
  --out "$OUT"
uv run sn87-miner verify-announcement "$OUT" --netuid 582 \
  --hotkey 5HEtPjhaCs859sdCjMG1a3TEZWFftKRs4VAYzCjnNUf82iDL
echo "$ENDPOINT" > /workspace/sn87-miner-rabi/PUBLIC_ENDPOINT.txt
pm2 restart sn87-rabi-h1
echo "Restarted miner with announcement. Probe remotely:"
echo "  SN87_ENDPOINT=$ENDPOINT /workspace/sn87-miner-rabi/probe.sh"
