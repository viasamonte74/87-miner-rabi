# SN87 miner — rabi-h1 (testnet 582)

| Item | Value |
|------|-------|
| Wallet | `rabi` / `rabi-h1` |
| Hotkey | `5HEtPjhaCs859sdCjMG1a3TEZWFftKRs4VAYzCjnNUf82iDL` |
| Netuid | **582** (Provenonce SN87) |
| UID | **4** |
| Method | `sn87_provenonce.miners.rabi_ic:rabi_approval_witness` |
| Keyfile | `keys/rabi-h1` (mode 0600; do not commit) |

## Run (local signed endpoint)

```bash
# 1) Valkey (once)
valkey-server /workspace/sn87-miner-rabi/valkey/valkey.conf --daemonize yes

# 2) Config check
/workspace/sn87-miner-rabi/serve.sh --check

# 3) Serve
/workspace/sn87-miner-rabi/serve.sh
# or pm2:
# pm2 start /workspace/sn87-miner-rabi/serve.sh --name sn87-rabi-h1 --interpreter bash

# 4) Probe (after ~13s warming)
/workspace/sn87-miner-rabi/probe.sh
```

Validators call **HTTPS** only for remote hosts. For shadow cohort: put TLS in front,
set `SN87_HOST=0.0.0.0`, sign an announcement, apply via GitHub issue.
