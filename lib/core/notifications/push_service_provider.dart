import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/device_tokens_repository.dart';
import 'push_service.dart';

final pushServiceProvider = Provider<PushService>((ref) {
  return PushService(ref.watch(deviceTokensRepositoryProvider));
});
