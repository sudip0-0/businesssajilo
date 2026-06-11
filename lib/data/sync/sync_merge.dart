/// Last-write-wins merge for mutable cache rows pulled from the server.
DateTime? pickNewerUpdatedAt(DateTime? local, DateTime? remote) {
  if (remote == null) return local;
  if (local == null) return remote;
  return remote.isAfter(local) ? remote : local;
}

bool remoteWins(DateTime? local, DateTime? remote) {
  if (remote == null) return false;
  if (local == null) return true;
  return !local.isAfter(remote);
}
