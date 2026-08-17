import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  isUnregisteredTokenError,
  shouldStampPushedAt,
} from "./push_policy.ts";

Deno.test("stamps pushed_at only when every send succeeds", () => {
  assertEquals(shouldStampPushedAt(2, 0), true);
  assertEquals(shouldStampPushedAt(1, 1), false);
  assertEquals(shouldStampPushedAt(0, 2), false);
  assertEquals(shouldStampPushedAt(0, 0), false);
});

Deno.test("detects unregistered FCM tokens", () => {
  assertEquals(isUnregisteredTokenError(404, ""), true);
  assertEquals(
    isUnregisteredTokenError(400, '{"error":{"status":"UNREGISTERED"}}'),
    true,
  );
  assertEquals(isUnregisteredTokenError(500, "unavailable"), false);
});
