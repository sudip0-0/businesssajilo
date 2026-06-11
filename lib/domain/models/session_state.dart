import 'package:supabase_flutter/supabase_flutter.dart';

import 'member.dart';

class SessionState {
  const SessionState({this.user, this.member});

  final User? user;
  final Member? member;

  bool get isAuthenticated => user != null && member != null && member!.isActive;

  static const empty = SessionState();
}
