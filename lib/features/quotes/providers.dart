import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/quotes_repository.dart';
import '../../domain/models/quote.dart';
import '../billing/providers.dart';

final orderQuotesProvider = FutureProvider.autoDispose
    .family<List<Quote>, String>((ref, orderId) {
      ref.watch(billingRevisionProvider);
      return ref.watch(quotesRepositoryProvider).listForOrder(orderId);
    });
