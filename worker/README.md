# SN87 proxy Worker — `provx.mstjeon6.workers.dev`

```
Validator → https://provx.mstjeon6.workers.dev
         → Cloudflare Worker (strips dup headers; keeps assurance body uncompressed)
         → https://….trycloudflare.com   (ORIGIN secret)
         → Caddy :9000 → miner :8787
```

Workers cannot fetch a raw IP origin (error 1003). ORIGIN must be the tunnel hostname.

`/v1/assurance` responses claim `Content-Encoding: gzip` with `encodeBody: "manual"` while the body stays raw signed JSON — otherwise `workers.dev` gzips JSON and SN87 `aiter_raw()` btauth fails.

## Deploy / refresh ORIGIN

```bash
# miner + caddy + tunnel online
pm2 list | grep sn87

/workspace/sn87-miner-rabi/worker/deploy.sh
# or after tunnel URL rotates:
/workspace/sn87-miner-rabi/sync_worker_origin.sh

curl -sS https://provx.mstjeon6.workers.dev/ready
```

## Announce + probe

```bash
/workspace/sn87-miner-rabi/announce.sh https://provx.mstjeon6.workers.dev
SN87_ENDPOINT=https://provx.mstjeon6.workers.dev /workspace/sn87-miner-rabi/probe.sh
```

Expect: `probe OK: ... FINDINGS ['STALE_APPROVAL']`
