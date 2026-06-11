import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/env.dart';

final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  if (!Env.isConfigured) return null;
  return Supabase.instance.client;
});
