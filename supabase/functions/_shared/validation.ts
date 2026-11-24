/** Shared Edge Function input, CORS, auth, and rate-limit helpers. */

const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

export const MAX_FIELD_LEN = 200;
export const MIN_PASSWORD_LEN = 8;
export const MAX_PASSWORD_LEN = 72;
export const MAX_BODY_BYTES = 65_536;
export const MAX_MONEY_PAISA = 100_000_000_000;

/** Synthetic auth domain for phone-based logins (sync with login_identifier.dart). */
export const PHONE_LOGIN_DOMAIN = "phone.businesssajilo.app";

/** Shared Supabase client options for stateless Deno Edge Function isolates. */
export const NO_SESSION_CLIENT_OPTIONS = {
  auth: {
    persistSession: false,
    autoRefreshToken: false,
  },
} as const;

export function str(v: unknown): string | null {
  return typeof v === "string" ? v : null;
}

/** Pragmatic email shape check shared by create-member / register-business. */
export const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export function isUuid(v: string): boolean {
  return UUID_RE.test(v);
}

export function clampField(v: string, max = MAX_FIELD_LEN): string {
  return v.trim().slice(0, max);
}

export function validatePassword(password: string): string | null {
  if (password.length < MIN_PASSWORD_LEN || password.length > MAX_PASSWORD_LEN) {
    return `Password must be ${MIN_PASSWORD_LEN}-${MAX_PASSWORD_LEN} characters`;
  }
  return null;
}

export function isSyntheticPhoneEmail(email: string): boolean {
  return email.trim().toLowerCase().endsWith(`@${PHONE_LOGIN_DOMAIN}`);
}

/** Normalizes a Nepali mobile phone number to +9779XXXXXXXXX, or null if invalid. */
export function normalizePhone(raw: string): string | null {
  const digits = raw.replace(/[\s\-()]/g, "").replace(/^\+/, "");
  let local: string;
  if (digits.startsWith("977")) {
    local = digits.slice(3);
  } else if (/^0\d{9,}$/.test(digits)) {
    local = digits.slice(1);
  } else {
    local = digits;
  }
  if (!/^9\d{9}$/.test(local)) return null;
  return `+977${local}`;
}

/** Synthetic auth email for phone-based logins: 98XXXXXXXX@phone.businesssajilo.app */
export function phoneLoginEmail(normalizedPhone: string): string {
  return `${normalizedPhone.slice(4)}@${PHONE_LOGIN_DOMAIN}`;
}

/**
 * Validates ALLOWED_ORIGIN at boot (fail-closed, no wildcard, valid http/https
 * origin) and builds CORS headers.
 */
export function buildCorsHeaders(rawOrigin: string | undefined): Record<string, string> {
  const trimmed = rawOrigin?.trim() ?? "";
  if (!trimmed) {
    throw new Error("ALLOWED_ORIGIN must be set");
  }
  if (trimmed === "*") {
    throw new Error(
      "ALLOWED_ORIGIN must be a concrete origin, not '*' — set it via `supabase secrets set ALLOWED_ORIGIN=https://…`",
    );
  }
  let parsed: URL;
  try {
    parsed = new URL(trimmed);
  } catch {
    throw new Error("ALLOWED_ORIGIN must be a valid http(s) origin URL");
  }
  if (
    (parsed.protocol !== "http:" && parsed.protocol !== "https:") ||
    parsed.origin !== trimmed
  ) {
    throw new Error("ALLOWED_ORIGIN must be an exact http(s) origin without path or trailing slash");
  }
  return {
    "Access-Control-Allow-Origin": parsed.origin,
    "Access-Control-Allow-Headers":
      "authorization, x-client-info, apikey, content-type",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Vary": "Origin",
  };
}

/**
 * Reads and parses a JSON object request body with a strict size cap.
 * Returns null if the body exceeds maxBytes, is malformed JSON, or is not a plain object.
 */
export async function parseJsonObject(
  req: Request,
  maxBytes = MAX_BODY_BYTES,
): Promise<Record<string, unknown> | null> {
  const contentLength = req.headers.get("content-length");
  if (contentLength) {
    const declared = Number(contentLength);
    if (Number.isFinite(declared) && declared > maxBytes) {
      return null;
    }
  }
  let text: string;
  try {
    text = await req.text();
  } catch {
    return null;
  }
  if (new TextEncoder().encode(text).byteLength > maxBytes) {
    return null;
  }
  let parsed: unknown;
  try {
    parsed = JSON.parse(text);
  } catch {
    return null;
  }
  if (typeof parsed !== "object" || parsed === null || Array.isArray(parsed)) {
    return null;
  }
  return parsed as Record<string, unknown>;
}

/** Constant-time UTF-8 string equality check to prevent timing attacks on secrets. */
export function timingSafeEqual(a: string, b: string): boolean {
  const enc = new TextEncoder();
  const ab = enc.encode(a);
  const bb = enc.encode(b);
  const maxLen = Math.max(ab.length, bb.length);
  let diff = ab.length ^ bb.length;
  for (let i = 0; i < maxLen; i++) {
    diff |= (ab[i] ?? 0) ^ (bb[i] ?? 0);
  }
  return diff === 0;
}

/** Extracts best-effort client IP from trusted proxy headers. */
export function getClientIp(req: Request): string {
  return (
    req.headers.get("cf-connecting-ip")?.trim() ||
    req.headers.get("x-real-ip")?.trim() ||
    req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ||
    "unknown"
  );
}

/** Bounded-memory per-isolate fixed-window rate limiter (defense in depth). */
export function createRateLimiter(opts: {
  windowMs: number;
  maxPerWindow: number;
  maxTrackedKeys?: number;
}): (key: string, nowMs?: number) => boolean {
  const attempts = new Map<string, { count: number; windowStart: number }>();
  const maxKeys = opts.maxTrackedKeys ?? 10_000;

  return (key: string, nowMs = Date.now()): boolean => {
    if (attempts.size > 0 && attempts.size % 100 === 0) {
      for (const [k, v] of attempts) {
        if (nowMs - v.windowStart > opts.windowMs) attempts.delete(k);
      }
    }
    while (attempts.size >= maxKeys) {
      const oldestKey = attempts.keys().next().value;
      if (oldestKey === undefined) break;
      attempts.delete(oldestKey);
    }
    const entry = attempts.get(key);
    if (!entry || nowMs - entry.windowStart > opts.windowMs) {
      attempts.set(key, { count: 1, windowStart: nowMs });
      return false;
    }
    entry.count += 1;
    return entry.count > opts.maxPerWindow;
  };
}
