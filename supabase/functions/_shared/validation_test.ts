import {
  assertEquals,
  assertMatch,
  assertThrows,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  buildCorsHeaders,
  clampField,
  createRateLimiter,
  isSyntheticPhoneEmail,
  isUuid,
  MAX_FIELD_LEN,
  MAX_PASSWORD_LEN,
  MIN_PASSWORD_LEN,
  normalizePhone,
  parseJsonObject,
  phoneLoginEmail,
  str,
  timingSafeEqual,
  validatePassword,
} from "./validation.ts";

Deno.test("str returns string or null", () => {
  assertEquals(str("hello"), "hello");
  assertEquals(str(""), "");
  assertEquals(str(null), null);
  assertEquals(str(42), null);
});

Deno.test("isUuid accepts RFC-4122 ids", () => {
  assertEquals(isUuid("550e8400-e29b-41d4-a716-446655440000"), true);
  assertEquals(isUuid("not-a-uuid"), false);
  assertEquals(isUuid(""), false);
});

Deno.test("clampField trims and caps length", () => {
  const long = "x".repeat(MAX_FIELD_LEN + 50);
  assertEquals(clampField(long).length, MAX_FIELD_LEN);
  assertEquals(clampField("  padded  "), "padded");
});

Deno.test("validatePassword enforces length bounds", () => {
  assertEquals(
    validatePassword("short"),
    `Password must be ${MIN_PASSWORD_LEN}-${MAX_PASSWORD_LEN} characters`,
  );
  assertEquals(
    validatePassword("x".repeat(MAX_PASSWORD_LEN + 1)),
    `Password must be ${MIN_PASSWORD_LEN}-${MAX_PASSWORD_LEN} characters`,
  );
  assertEquals(validatePassword("validpass"), null);
  assertMatch("validpass", /^.{8,72}$/);
});

Deno.test("normalizePhone and phoneLoginEmail handle Nepali numbers", () => {
  assertEquals(normalizePhone("9841234567"), "+9779841234567");
  assertEquals(normalizePhone("+977 98-4123-4567"), "+9779841234567");
  assertEquals(normalizePhone("09841234567"), "+9779841234567");
  assertEquals(normalizePhone("12345"), null);
  assertEquals(
    phoneLoginEmail("+9779841234567"),
    "9841234567@phone.businesssajilo.app",
  );
  assertEquals(
    isSyntheticPhoneEmail("9841234567@phone.businesssajilo.app"),
    true,
  );
  assertEquals(isSyntheticPhoneEmail("owner@example.com"), false);
});

Deno.test("buildCorsHeaders fails closed on missing, wildcard, or malformed origin", () => {
  assertThrows(() => buildCorsHeaders(undefined));
  assertThrows(() => buildCorsHeaders(""));
  assertThrows(() => buildCorsHeaders("*"));
  assertThrows(() => buildCorsHeaders("https://example.com/path"));
  const headers = buildCorsHeaders("https://app.businesssajilo.app");
  assertEquals(headers["Access-Control-Allow-Origin"], "https://app.businesssajilo.app");
  assertEquals(headers["Vary"], "Origin");
});

Deno.test("timingSafeEqual compares strings in constant time", () => {
  assertEquals(timingSafeEqual("secret-token", "secret-token"), true);
  assertEquals(timingSafeEqual("secret-token", "secret-tokeN"), false);
  assertEquals(timingSafeEqual("short", "longer-string"), false);
});

Deno.test("parseJsonObject rejects non-objects and oversized bodies", async () => {
  const okReq = new Request("http://localhost", {
    method: "POST",
    body: JSON.stringify({ a: 1 }),
  });
  assertEquals(await parseJsonObject(okReq), { a: 1 });

  const nullReq = new Request("http://localhost", {
    method: "POST",
    body: "null",
  });
  assertEquals(await parseJsonObject(nullReq), null);

  const arrReq = new Request("http://localhost", {
    method: "POST",
    body: "[1,2,3]",
  });
  assertEquals(await parseJsonObject(arrReq), null);

  const bigReq = new Request("http://localhost", {
    method: "POST",
    body: JSON.stringify({ pad: "x".repeat(200) }),
  });
  assertEquals(await parseJsonObject(bigReq, 100), null);
});

Deno.test("createRateLimiter blocks after maxPerWindow and resets after window", () => {
  const limited = createRateLimiter({ windowMs: 1000, maxPerWindow: 2 });
  assertEquals(limited("k1", 100), false);
  assertEquals(limited("k1", 200), false);
  assertEquals(limited("k1", 300), true);
  assertEquals(limited("k1", 1200), false);
});
