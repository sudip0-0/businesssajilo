import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/env.dart';
import '../../core/errors/app_failure.dart';

final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  if (!Env.isConfigured) return null;
  return Supabase.instance.client;
});

/// Shared guard used by data-layer repositories instead of per-class copies.
SupabaseClient requireSupabaseClient(SupabaseClient? client) {
  if (client == null) {
    throw const AppFailure.notConfigured(
      detail:
          'Supabase not configured. Pass SUPABASE_URL and SUPABASE_ANON_KEY.',
    );
  }
  return client;
}
