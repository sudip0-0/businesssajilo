/// Sync connectivity / queue state — kept out of UI widgets so data layer
/// can depend on it without importing `core/ui`.
enum SyncState { synced, pending, offline }
