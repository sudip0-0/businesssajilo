const syncMaxAttempts = 5;
const syncMaxBackoff = Duration(minutes: 5);

Duration backoffForAttempts(int attempts) {
  if (attempts <= 0) return Duration.zero;
  final seconds = attempts >= 9 ? syncMaxBackoff.inSeconds : 1 << attempts;
  final delay = Duration(seconds: seconds);
  return delay > syncMaxBackoff ? syncMaxBackoff : delay;
}
