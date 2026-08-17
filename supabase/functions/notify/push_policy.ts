export function shouldStampPushedAt(sent: number, failed: number): boolean {
  return sent > 0 && failed === 0;
}

export function isUnregisteredTokenError(status: number, body: string): boolean {
  if (status === 404) return true;
  return /UNREGISTERED|NOT_FOUND|INVALID_ARGUMENT/.test(body);
}
