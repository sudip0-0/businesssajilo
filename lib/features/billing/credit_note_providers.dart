import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/credit_notes_repository.dart';
import 'providers.dart';

final billReturnedQtyProvider = FutureProvider.autoDispose
    .family<Map<String, int>, String>((ref, billId) {
      ref.watch(billingRevisionProvider);
      return ref
          .watch(creditNotesRepositoryProvider)
          .returnedQtyByBillItem(billId);
    });
