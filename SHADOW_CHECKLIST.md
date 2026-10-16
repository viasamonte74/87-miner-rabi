# Path to real testnet scoring (shadow cohort)

You are at: registered uid **4**, miner **online**, public HTTPS probe **OK**.

**Live origin:** `https://provx.mstjeon6.workers.dev`  
(Worker → trycloudflare tunnel → Caddy `:9000` → miner `:8787`)

Quick tunnels alone fail SN87 (`DUPLICATE_RESPONSE_HEADER` on `x-robots-tag`). The Worker collapses duplicates and keeps `/v1/assurance` bodies uncompressed for btauth.

## Keep the public path healthy

```bash
# after tunnel restart (URL rotates):
/workspace/sn87-miner-rabi/sync_worker_origin.sh

# redeploy worker + set ORIGIN from current tunnel:
/workspace/sn87-miner-rabi/worker/deploy.sh

# announce + probe
/workspace/sn87-miner-rabi/announce.sh https://provx.mstjeon6.workers.dev
SN87_ENDPOINT=https://provx.mstjeon6.workers.dev /workspace/sn87-miner-rabi/probe.sh
# expect: probe OK: ... FINDINGS ['STALE_APPROVAL']
```

**More stable later:** named Cloudflare tunnel + your domain (`sn87.YOURDOMAIN` → `http://127.0.0.1:8787`), then re-announce that origin.

## File the GitHub application

Open: https://github.com/provenonce-ai/sn87-provenonce-public/issues/new?template=shadow-cohort-application.yml

| Field | Value |
|-------|-------|
| Uid | `4` |
| Hotkey | `5HEtPjhaCs859sdCjMG1a3TEZWFftKRs4VAYzCjnNUf82iDL` |
| Netuid | `582` |
| HTTPS endpoint origin | `https://provx.mstjeon6.workers.dev` |
| Announcement URL | `https://provx.mstjeon6.workers.dev/.well-known/sn87-miner-announcement.json` |
| sn87-miner version | `0.1.0` / commit `e36ae55217783ad082644db3ca811167efbc7109` |
| Platform | Linux |
| Method | Reconstructs IC approval chains from the public capsule contract; reports STALE_APPROVAL when a review certified a condition that was no longer governing at action time; abstains on incomplete/ambiguous evidence. |

Tick all four confirmations. Paste **no** keys/seeds.

After maintainers merge you into `shadow/allowlist.json`, watch results at https://provenonce.ai/sn87/shadow
