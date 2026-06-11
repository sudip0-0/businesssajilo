import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/quotes_repository.dart';
import '../../domain/models/quote.dart';

final orderQuotesProvider =
    FutureProvider.autoDispose.family<List<Quote>, String>((ref, orderId) {
  return ref.watch(quotesRepositoryProvider).listForOrder(orderId);
});
