/**
 * SN87 miner reverse proxy for Cloudflare Workers.
 *
 * Public:  https://provx.mstjeon6.workers.dev
 * Origin:  ORIGIN env (e.g. http://VAST_IP:PUBLIC_PORT → miner on :8787)
 *
 * Forwards POST /v1/assurance with exact bytes + btauth headers,
 * GET /ready, and GET /.well-known/sn87-miner-announcement.json.
 */

const HOP_BY_HOP = new Set([
  "connection",
  "keep-alive",
  "proxy-authenticate",
  "proxy-authorization",
  "te",
  "trailers",
  "transfer-encoding",
  "upgrade",
  "host",
  "cf-connecting-ip",
  "cf-ipcountry",
  "cf-ray",
  "cf-visitor",
  "cf-worker",
  "cdn-loop",
  "x-forwarded-for",
  "x-forwarded-proto",
  "x-real-ip",
]);

function originBase(env) {
  const raw = (env.ORIGIN || "").trim().replace(/\/$/, "");
  if (!raw) {
    throw new Error("ORIGIN secret/var is not set");
  }
  return raw;
}

function filterRequestHeaders(headers) {
  const out = new Headers();
  for (const [key, value] of headers.entries()) {
    if (HOP_BY_HOP.has(key.toLowerCase())) continue;
    out.append(key, value);
  }
  return out;
}

function filterResponseHeaders(headers) {
  const out = new Headers();
  const seen = new Set();
  for (const [key, value] of headers.entries()) {
    const lower = key.toLowerCase();
    if (HOP_BY_HOP.has(lower)) continue;
    // SN87 client rejects duplicate header names (e.g. doubled x-robots-tag).
    if (seen.has(lower)) continue;
    seen.add(lower);
    out.set(key, value);
  }
  return out;
}

export default {
  async fetch(request, env) {
    let base;
    try {
      base = originBase(env);
    } catch (err) {
      return new Response(JSON.stringify({ error: "ORIGIN_NOT_CONFIGURED" }), {
        status: 503,
        headers: { "content-type": "application/json" },
      });
    }

    const incoming = new URL(request.url);
    const target = new URL(incoming.pathname + incoming.search, base + "/");

    // Only miner paths (and health) — avoid open proxy.
    const path = incoming.pathname;
    const allowed =
      path === "/ready" ||
      path === "/v1/assurance" ||
      path === "/.well-known/sn87-miner-announcement.json" ||
      path === "/";
    if (!allowed) {
      return new Response(JSON.stringify({ error: "NOT_FOUND" }), {
        status: 404,
        headers: { "content-type": "application/json" },
      });
    }

    if (path === "/" && request.method === "GET") {
      return new Response(
        JSON.stringify({
          service: "sn87-miner-proxy",
          endpoint: "https://provx.mstjeon6.workers.dev",
          paths: ["/ready", "/v1/assurance", "/.well-known/sn87-miner-announcement.json"],
        }),
        { status: 200, headers: { "content-type": "application/json" } },
      );
    }

    const fwd = filterRequestHeaders(request.headers);
    // Ask origin for uncompressed bytes; btauth signs/verifies raw body.
    fwd.set("Accept-Encoding", "identity");

    const init = {
      method: request.method,
      headers: fwd,
      redirect: "manual",
      cf: { cacheTtl: 0, cacheEverything: false },
    };

    if (request.method !== "GET" && request.method !== "HEAD") {
      init.body = await request.arrayBuffer();
    }

    let upstream;
    try {
      upstream = await fetch(target.toString(), init);
    } catch (err) {
      return new Response(
        JSON.stringify({ error: "ORIGIN_UNREACHABLE", detail: String(err) }),
        { status: 502, headers: { "content-type": "application/json" } },
      );
    }

    const body = new Uint8Array(await upstream.arrayBuffer());
    const headers = filterResponseHeaders(upstream.headers);
    headers.delete("content-encoding");
    headers.delete("content-length");
    headers.set("Content-Type", headers.get("Content-Type") || "application/json");
    // SN87 verifies aiter_raw() against btauth over the exact miner JSON.
    // workers.dev still auto-gzips JSON when CE is absent, even with encodeBody:manual.
    // Claim CE:gzip + encodeBody:manual so the edge passes our (uncompressed) bytes
    // through unchanged. Clients use aiter_raw() and do not decompress.
    if (path === "/v1/assurance") {
      headers.set("Content-Encoding", "gzip");
      return new Response(body, {
        status: upstream.status,
        statusText: upstream.statusText,
        headers,
        encodeBody: "manual",
      });
    }
    return new Response(body, {
      status: upstream.status,
      statusText: upstream.statusText,
      headers,
      encodeBody: "manual",
    });
  },
};
