#!/usr/bin/env bash
# SN87 Provenonce miner — rabi-h1 on testnet netuid 582 (uid 4)
set -euo pipefail

ROOT=/workspace/sn87-provenonce-public
KEYFILE=/workspace/sn87-miner-rabi/keys/rabi-h1
VALKEY_URL="${SN87_VALKEY_URL:-redis://127.0.0.1:6379/0}"
PORT="${SN87_PORT:-8787}"
HOST="${SN87_HOST:-127.0.0.1}"
METHOD="${SN87_METHOD:-sn87_provenonce.miners.rabi_ic:rabi_approval_witness}"
ANNOUNCEMENT="${SN87_ANNOUNCEMENT:-/workspace/sn87-miner-rabi/announcement.json}"

cd "$ROOT"
chmod 600 "$KEYFILE"

EXTRA=()
if [[ "$HOST" != "127.0.0.1" && "$HOST" != "localhost" && "$HOST" != "::1" ]]; then
  EXTRA+=(--allow-non-loopback --host "$HOST")
fi
if [[ -f "$ANNOUNCEMENT" ]]; then
  EXTRA+=(--announcement "$ANNOUNCEMENT" --netuid 582)
fi

if [[ "${1:-}" == "--check" ]]; then
  exec uv run sn87-miner serve \
    --method "$METHOD" \
    --hotkey-keyfile "$KEYFILE" \
    --valkey-url "$VALKEY_URL" \
    "${EXTRA[@]}" \
    --check
fi

exec uv run sn87-miner serve \
  --method "$METHOD" \
  --hotkey-keyfile "$KEYFILE" \
  --valkey-url "$VALKEY_URL" \
  --port "$PORT" \
  "${EXTRA[@]}"
