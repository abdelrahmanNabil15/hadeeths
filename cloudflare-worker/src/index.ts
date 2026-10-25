/**
 * Backend proxy for the Quran Foundation Content API v4 and Search API, on Cloudflare Workers'
 * free tier.
 *
 * Why this exists: docs/QURAN_API_REFACTOR_PLAN.md, section 2. Both APIs use OAuth2 Client
 * Credentials, which requires a client secret. A secret embedded in the Flutter app could be
 * extracted from the compiled binary, so the app must never call either API directly. This
 * Worker holds the secret (Cloudflare secret, set with `wrangler secret put`, never in source or
 * logs), exchanges and caches the OAuth tokens itself, and forwards only an explicit allow-list
 * of read-only endpoints the app actually needs. The app calls this Worker; it never sees the
 * secret or any token.
 *
 * Runs on Cloudflare Workers rather than Firebase Cloud Functions because Firebase's free
 * (Spark) plan blocks outbound requests to anything but Google APIs -- calling a third-party API
 * needs the paid Blaze plan. Workers' free tier (100,000 requests/day, no card required) allows
 * outbound fetch to any host, which is all this proxy needs.
 *
 * Endpoint facts below (auth flow, header names, URLs, token lifecycle) are taken verbatim from
 * https://api-docs.quran.foundation (Content APIs' Manual Authentication, Token Management and
 * First API Call pages; the Search APIs' Search Quran content page for the `/search` route),
 * read on 2026-10-17. Re-check that documentation if anything here starts failing -- it is the
 * source of truth, not this comment.
 *
 * TODO before this handles real app traffic at any scale: add a lightweight shared-secret or
 * signature check so only the real app (not anyone who finds this Worker's URL) can spend the
 * free-tier quota. Nothing below is a substitute for that; it only keeps the OAuth secret off
 * the device.
 */

export interface Env {
  QURAN_PRELIVE_CLIENT_ID: string;
  QURAN_PRELIVE_CLIENT_SECRET: string;
  QURAN_PRODUCTION_CLIENT_ID: string;
  QURAN_PRODUCTION_CLIENT_SECRET: string;
}

type QfEnv = "prelive" | "production";

// The Search API is a separate product from the Content API (api-docs.quran.foundation, Search
// APIs section, read 2026-10-17): its own base URL, and it requires an OAuth token carrying the
// `search` scope rather than `content` -- a token fetched for one is rejected for the other, so
// tokens are cached per (environment, scope) pair below, not just per environment. Qira'at
// (docs/QURAN_API_REFACTOR_PLAN.md flag F) is a third such case: same Content API base url, but
// its own `qiraat` scope (`content` alone gets HTTP 403 insufficient_scope), and -- per the
// OAuth2 Scopes page, read 2026-10-22 -- production only; prelive has no Qira'at data at all.
type QfScope = "content" | "search" | "qiraat";

const ENVIRONMENTS: Record<QfEnv, {authBaseUrl: string; apiBaseUrl: string; searchBaseUrl: string}> = {
  prelive: {
    authBaseUrl: "https://prelive-oauth2.quran.foundation",
    apiBaseUrl: "https://apis-prelive.quran.foundation/content/api/v4",
    searchBaseUrl: "https://apis-prelive.quran.foundation/search",
  },
  production: {
    authBaseUrl: "https://oauth2.quran.foundation",
    apiBaseUrl: "https://apis.quran.foundation/content/api/v4",
    searchBaseUrl: "https://apis.quran.foundation/search",
  },
};

function credentialsFor(env: Env, qfEnv: QfEnv): {clientId: string; clientSecret: string} {
  return qfEnv === "prelive"
    ? {clientId: env.QURAN_PRELIVE_CLIENT_ID, clientSecret: env.QURAN_PRELIVE_CLIENT_SECRET}
    : {clientId: env.QURAN_PRODUCTION_CLIENT_ID, clientSecret: env.QURAN_PRODUCTION_CLIENT_SECRET};
}

// A custom User-Agent is required: the API blocks default User-Agents (HTTP 403, "error code:
// 1010") as an anti-bot measure. Documented at docs/quickstart/manual-authentication.
const USER_AGENT = "hadeeths-quran-proxy/1.0 (cloudflare-worker)";

interface CachedToken {
  accessToken: string;
  expiresAtMs: number;
}

interface TokenState {
  cached: CachedToken | null;
  inFlight: Promise<CachedToken> | null;
}

function emptyTokenState(): TokenState {
  return {cached: null, inFlight: null};
}

// Module-scope state persists for the lifetime of the isolate (typically minutes to hours on
// Workers), which is enough to make the token-caching pattern below worthwhile. It is not
// durable storage: a cold isolate just re-fetches a token, which is cheap and expected. Keyed by
// `${qfEnv}:${scope}` so prelive/production and content/search never share a cached token.
const tokenState: Record<string, TokenState> = {
  "prelive:content": emptyTokenState(),
  "production:content": emptyTokenState(),
  "prelive:search": emptyTokenState(),
  "production:search": emptyTokenState(),
  "prelive:qiraat": emptyTokenState(),
  "production:qiraat": emptyTokenState(),
};

const EARLY_REFRESH_MS = 30_000;

async function requestNewToken(env: Env, qfEnv: QfEnv, scope: QfScope): Promise<CachedToken> {
  const {authBaseUrl} = ENVIRONMENTS[qfEnv];
  const {clientId, clientSecret} = credentialsFor(env, qfEnv);
  const basic = btoa(`${clientId}:${clientSecret}`);

  const response = await fetch(`${authBaseUrl}/oauth2/token`, {
    method: "POST",
    headers: {
      "Authorization": `Basic ${basic}`,
      "Content-Type": "application/x-www-form-urlencoded",
      "User-Agent": USER_AGENT,
    },
    body: `grant_type=client_credentials&scope=${scope}`,
  });

  if (!response.ok) {
    // Never log the response body here: on some failure paths it can echo request details.
    throw new Error(`Quran Foundation token request failed: HTTP ${response.status}`);
  }

  const body = (await response.json()) as {access_token: string; expires_in: number};
  return {
    accessToken: body.access_token,
    expiresAtMs: Date.now() + body.expires_in * 1000,
  };
}

/**
 * Token Management (docs/quickstart/token-management): reuse a cached token until it is close to
 * expiry, never mix caches between environments (or, here, between scopes), and let only one
 * in-flight request fetch a new token while others wait for it (stampede prevention).
 */
async function getAccessToken(
  env: Env,
  qfEnv: QfEnv,
  scope: QfScope,
  forceRefresh = false
): Promise<string> {
  const state = tokenState[`${qfEnv}:${scope}`];

  if (!forceRefresh && state.cached && state.cached.expiresAtMs - Date.now() > EARLY_REFRESH_MS) {
    return state.cached.accessToken;
  }

  if (!state.inFlight) {
    state.inFlight = requestNewToken(env, qfEnv, scope).finally(() => {
      state.inFlight = null;
    });
  }

  const token = await state.inFlight;
  state.cached = token;
  return token.accessToken;
}

/**
 * Calls one path on [baseUrl] with a [scope]-token. Retries once on 401 (treat the token as
 * expired, per Token Management's documented retry-once rule), and never loops beyond that.
 */
async function callApi(
  env: Env,
  qfEnv: QfEnv,
  scope: QfScope,
  baseUrl: string,
  path: string,
  searchParams?: Record<string, string>
): Promise<Response> {
  const {clientId} = credentialsFor(env, qfEnv);

  const url = new URL(`${baseUrl}${path}`);
  for (const [key, value] of Object.entries(searchParams ?? {})) {
    url.searchParams.set(key, value);
  }

  const doFetch = (token: string) =>
    fetch(url.toString(), {
      headers: {
        "x-auth-token": token,
        "x-client-id": clientId,
        "User-Agent": USER_AGENT,
      },
    });

  let token = await getAccessToken(env, qfEnv, scope);
  let response = await doFetch(token);

  if (response.status === 401) {
    token = await getAccessToken(env, qfEnv, scope, /* forceRefresh */ true);
    response = await doFetch(token);
  }

  return response;
}

function jsonResponse(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {"Content-Type": "application/json"},
  });
}

async function forward(
  env: Env,
  qfEnv: QfEnv,
  path: string,
  searchParams?: Record<string, string>
): Promise<Response> {
  try {
    const {apiBaseUrl} = ENVIRONMENTS[qfEnv];
    const upstream = await callApi(env, qfEnv, "content", apiBaseUrl, path, searchParams);
    const body = await upstream.text();
    return new Response(body, {
      status: upstream.status,
      headers: {"Content-Type": "application/json"},
    });
  } catch (error) {
    console.error("quran proxy request failed", path, (error as Error).message);
    return jsonResponse(502, {error: "upstream request failed"});
  }
}

async function forwardSearch(
  env: Env,
  qfEnv: QfEnv,
  path: string,
  searchParams?: Record<string, string>
): Promise<Response> {
  try {
    const {searchBaseUrl} = ENVIRONMENTS[qfEnv];
    const upstream = await callApi(env, qfEnv, "search", searchBaseUrl, path, searchParams);
    const body = await upstream.text();
    return new Response(body, {
      status: upstream.status,
      headers: {"Content-Type": "application/json"},
    });
  } catch (error) {
    console.error("quran proxy search request failed", path, (error as Error).message);
    return jsonResponse(502, {error: "upstream request failed"});
  }
}

async function forwardQiraat(
  env: Env,
  qfEnv: QfEnv,
  path: string,
  searchParams?: Record<string, string>
): Promise<Response> {
  try {
    // Same Content API base url as `forward`, but a `qiraat`-scoped token -- `content` alone
    // gets HTTP 403 insufficient_scope on these routes.
    const {apiBaseUrl} = ENVIRONMENTS[qfEnv];
    const upstream = await callApi(env, qfEnv, "qiraat", apiBaseUrl, path, searchParams);
    const body = await upstream.text();
    return new Response(body, {
      status: upstream.status,
      headers: {"Content-Type": "application/json"},
    });
  } catch (error) {
    console.error("quran proxy qiraat request failed", path, (error as Error).message);
    return jsonResponse(502, {error: "upstream request failed"});
  }
}

// Routes, all under /:env/... where :env is 'prelive' or 'production'. Mirrors the allow-list in
// the (removed) Firebase Functions scaffold this replaced -- see git history if that's needed for
// reference.
const ROUTES: Array<{
  pattern: RegExp;
  handle: (env: Env, qfEnv: QfEnv, match: RegExpMatchArray, query: URLSearchParams) => Promise<Response>;
}> = [
  {
    pattern: /^\/chapters$/,
    handle: (env, qfEnv) => forward(env, qfEnv, "/chapters"),
  },
  {
    pattern: /^\/chapters\/(\d+)$/,
    handle: (env, qfEnv, m) => forward(env, qfEnv, `/chapters/${m[1]}`),
  },
  {
    pattern: /^\/editions\/translations$/,
    handle: (env, qfEnv, _m, query) =>
      forward(env, qfEnv, "/resources/translations", {language: query.get("language") ?? "en"}),
  },
  {
    pattern: /^\/editions\/tafsirs$/,
    handle: (env, qfEnv) => forward(env, qfEnv, "/resources/tafsirs"),
  },
  {
    pattern: /^\/editions\/recitations$/,
    handle: (env, qfEnv) => forward(env, qfEnv, "/resources/recitations"),
  },
  {
    pattern: /^\/translations\/([^/]+)\/ayah\/(\d+:\d+)$/,
    handle: (env, qfEnv, m) => forward(env, qfEnv, `/translations/${m[1]}/by_ayah/${m[2]}`),
  },
  {
    pattern: /^\/tafsirs\/([^/]+)\/ayah\/(\d+:\d+)$/,
    handle: (env, qfEnv, m) => forward(env, qfEnv, `/tafsirs/${m[1]}/by_ayah/${m[2]}`),
  },
  {
    pattern: /^\/recitations\/([^/]+)\/ayah\/(\d+:\d+)$/,
    handle: (env, qfEnv, m) => forward(env, qfEnv, `/recitations/${m[1]}/by_ayah/${m[2]}`),
  },
  // "Search inside a chosen translation" (docs/QURAN_API_REFACTOR_PLAN.md flag E): fixed to
  // Search API's advanced mode, filtered to one translation edition. `mode`, `get_text` and
  // `highlight` are not exposed to the app -- this route only ever does one kind of search.
  {
    pattern: /^\/search$/,
    handle: (env, qfEnv, _m, query) => {
      const q = query.get("query");
      const translationIds = query.get("translation_ids");
      if (!q || !translationIds) {
        return Promise.resolve(jsonResponse(400, {error: "query and translation_ids are required"}));
      }
      return forwardSearch(env, qfEnv, "/api/v1/search", {
        mode: "advanced",
        query: q,
        translation_ids: translationIds,
        page: query.get("page") ?? "1",
        get_text: "1",
        highlight: "0",
      });
    },
  },
  // Qira'at variations for one verse (docs/QURAN_API_REFACTOR_PLAN.md flag F): the full matrix
  // (every approved juncture, its readings, and which readers/transmitters hold each), not a
  // per-reader filter -- the upstream endpoint has none. A 404 ("no variations for this verse")
  // is forwarded as-is; the app treats that as a normal empty result, not an error.
  {
    pattern: /^\/qiraat\/matrix\/ayah\/(\d+:\d+)$/,
    handle: (env, qfEnv, m) => forwardQiraat(env, qfEnv, `/qiraat/matrix/by_verse/${m[1]}`),
  },
];

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);

    if (url.pathname === "/healthz") {
      return jsonResponse(200, {ok: true});
    }

    const envMatch = url.pathname.match(/^\/(prelive|production)(\/.*)$/);
    if (!envMatch) {
      return jsonResponse(400, {error: "path must start with /prelive/ or /production/"});
    }
    const qfEnv = envMatch[1] as QfEnv;
    const rest = envMatch[2];

    for (const route of ROUTES) {
      const match = rest.match(route.pattern);
      if (match) {
        return route.handle(env, qfEnv, match, url.searchParams);
      }
    }

    return jsonResponse(404, {error: "no such route"});
  },
};
