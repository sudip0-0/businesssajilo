/// Page size for Supabase bootstrap/delta pulls.
const syncPullPageSize = 500;

/// Max pages fetched per bootstrap pass before yielding (resumable).
const syncBootstrapMaxPagesPerPass = 20;

/// Max wall-clock time per bootstrap pass before yielding (resumable).
const syncBootstrapMaxDuration = Duration(seconds: 30);

/// [syncMeta] keys for resumable bootstrap progress.
const syncMetaBootstrapTable = 'bootstrap_table';
const syncMetaBootstrapOffset = 'bootstrap_offset';

/// Ordered remote tables for initial bootstrap (watermark keys).
const syncBootstrapTables = [
  'categories',
  'products',
  'customers',
  'bills',
  'payments',
  'stock_movements',
];
