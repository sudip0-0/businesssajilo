import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../domain/enums.dart';
import '../../domain/models/quote.dart';
import '../../domain/models/quote_item.dart';
import '../remote/supabase_provider.dart';

final quotesRepositoryProvider = Provider<QuotesRepository>((ref) {
  return QuotesRepository(ref.watch(supabaseClientProvider));
});

class QuoteLineInput {
  const QuoteLineInput({
    required this.productId,
    required this.qty,
    required this.rate,
    this.discount = 0,
    required this.lineTotal,
  });

  final String productId;
  final int qty;
  final int rate;
  final int discount;
  final int lineTotal;
}

class QuotesRepository {
  QuotesRepository(this._client);

  final SupabaseClient? _client;

  Future<Quote> get(String id) async {
    final client = _requireClient();
    final row = await client
        .from('quotes')
        .select('*, quote_items(*, products(name))')
        .eq('id', id)
        .single();
    return _mapQuoteRow(row);
  }

  Future<List<Quote>> listForOrder(String orderId) async {
    final client = _requireClient();
    final rows = await client
        .from('quotes')
        .select('*, quote_items(*, products(name))')
        .eq('order_id', orderId)
        .order('version', ascending: false);
    return (rows as List).map(_mapQuoteRow).toList();
  }

  Future<Quote?> latestSent(String orderId) async {
    final quotes = await listForOrder(orderId);
    return quotes.where((q) => q.status == QuoteStatus.sent).firstOrNull;
  }

  Future<Quote?> latestAccepted(String orderId) async {
    final quotes = await listForOrder(orderId);
    return quotes.where((q) => q.status == QuoteStatus.accepted).firstOrNull;
  }

  Future<Quote> sendQuote({
    required String orderId,
    required String createdByMemberId,
    required int total,
    required List<QuoteLineInput> lines,
  }) async {
    final client = _requireClient();
    final existing = await listForOrder(orderId);
    final version = existing.isEmpty
        ? 1
        : existing.map((q) => q.version).reduce((a, b) => a > b ? a : b) + 1;
    final quoteId = const Uuid().v4();

    await client.from('quotes').insert({
      'id': quoteId,
      'order_id': orderId,
      'version': version,
      'status': QuoteStatus.sent.name,
      'total': total,
      'created_by': createdByMemberId,
    });

    if (lines.isNotEmpty) {
      await client.from('quote_items').insert(
            lines
                .map(
                  (line) => {
                    'id': const Uuid().v4(),
                    'quote_id': quoteId,
                    'product_id': line.productId,
                    'qty': line.qty,
                    'rate': line.rate,
                    'discount': line.discount,
                    'line_total': line.lineTotal,
                  },
                )
                .toList(),
          );
    }

    final quotes = await listForOrder(orderId);
    return quotes.firstWhere((q) => q.id == quoteId);
  }

  Future<Quote> accept(String quoteId, {String? comment}) async {
    final client = _requireClient();
    await client.from('quotes').update({
      'status': QuoteStatus.accepted.name,
      'response_comment': ?comment,
    }).eq('id', quoteId);
    final row = await client
        .from('quotes')
        .select('*, quote_items(*, products(name))')
        .eq('id', quoteId)
        .single();
    return _mapQuoteRow(row);
  }

  Future<Quote> reject(String quoteId, {required String comment}) async {
    final client = _requireClient();
    await client.from('quotes').update({
      'status': QuoteStatus.rejected.name,
      'response_comment': comment,
    }).eq('id', quoteId);
    final row = await client
        .from('quotes')
        .select('*, quote_items(*, products(name))')
        .eq('id', quoteId)
        .single();
    return _mapQuoteRow(row);
  }

  Quote _mapQuoteRow(dynamic row) {
    final map = Map<String, dynamic>.from(row as Map);
    final itemsRaw = map.remove('quote_items');
    final quote = Quote.fromJson(map);
    if (itemsRaw is List) {
      final items = itemsRaw.map((raw) {
        final itemMap = Map<String, dynamic>.from(raw as Map);
        final product = itemMap.remove('products');
        if (product is Map) {
          itemMap['product_name'] = product['name'];
        }
        return QuoteItem.fromJson(itemMap);
      }).toList();
      return quote.copyWith(items: items);
    }
    return quote;
  }

  SupabaseClient _requireClient() {
    final client = _client;
    if (client == null) throw Exception('Supabase not configured');
    return client;
  }
}
