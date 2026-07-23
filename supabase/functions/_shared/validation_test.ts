import {
  assertEquals,
  assertMatch,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  clampField,
  isUuid,
  MAX_FIELD_LEN,
  MAX_PASSWORD_LEN,
  MIN_PASSWORD_LEN,
  str,
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
  assertEquals(validatePassword("short"), `Password must be ${MIN_PASSWORD_LEN}-${MAX_PASSWORD_LEN} characters`);
  assertEquals(
    validatePassword("x".repeat(MAX_PASSWORD_LEN + 1)),
    `Password must be ${MIN_PASSWORD_LEN}-${MAX_PASSWORD_LEN} characters`,
  );
  assertEquals(validatePassword("validpass"), null);
  assertMatch("validpass", /^.{8,72}$/);
});
