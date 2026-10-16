#!/usr/bin/env bash
# Self-test signed endpoint (fixture capsule). Wait ~13s after Valkey start.
set -euo pipefail

ROOT=/workspace/sn87-provenonce-public
HOTKEY_SS58=5HEtPjhaCs859sdCjMG1a3TEZWFftKRs4VAYzCjnNUf82iDL
ENDPOINT="${SN87_ENDPOINT:-http://127.0.0.1:8787}"
VALKEY_URL="${SN87_VALKEY_URL:-redis://127.0.0.1:6379/0}"

cd "$ROOT"
exec uv run sn87-miner probe \
  --endpoint "$ENDPOINT" \
  --miner-hotkey "$HOTKEY_SS58" \
  --valkey-url "$VALKEY_URL"
