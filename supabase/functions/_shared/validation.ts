/** Shared Edge Function input helpers. */

const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

export const MAX_FIELD_LEN = 200;
export const MIN_PASSWORD_LEN = 8;
export const MAX_PASSWORD_LEN = 72;

export function str(v: unknown): string | null {
  return typeof v === "string" ? v : null;
}

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
