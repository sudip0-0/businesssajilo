import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../domain/enums.dart';
import 'product_excel_import.dart';
import 'product_form_screen.dart';

const _uuid = Uuid();

/// Tenant, member, and role scope for durable product import sessions.
class ImportSessionScope {
  const ImportSessionScope({
    required this.businessId,
    required this.memberId,
    required this.role,
  });

  final String businessId;
  final String memberId;
  final Role role;

  bool get isValid =>
      businessId.trim().isNotEmpty && memberId.trim().isNotEmpty;

  String get storageKey =>
      'bs_product_import_session_v1::${businessId.trim()}::${memberId.trim()}::${role.name}';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ImportSessionScope &&
            other.businessId == businessId &&
            other.memberId == memberId &&
            other.role == role;
  }

  @override
  int get hashCode => Object.hash(businessId, memberId, role);
}

enum ProductImportRowStatus { pending, completed, failed, unconfirmed }

class ProductImportSessionRow {
  const ProductImportSessionRow({
    required this.operationId,
    required this.row,
    required this.sku,
    this.status = ProductImportRowStatus.pending,
    this.errorCode,
    this.productId,
  });

  final String operationId;
  final ProductImportRow row;
  final String sku;
  final ProductImportRowStatus status;
  final String? errorCode;
  final String? productId;

  bool get isDone => status == ProductImportRowStatus.completed;

  ProductImportSessionRow copyWith({
    ProductImportRowStatus? status,
    String? errorCode,
    bool clearError = false,
    String? productId,
  }) {
    return ProductImportSessionRow(
      operationId: operationId,
      row: row,
      sku: sku,
      status: status ?? this.status,
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
      productId: productId ?? this.productId,
    );
  }

  Map<String, dynamic> toJson() => {
    'operationId': operationId,
    'sku': sku,
    'status': status.name,
    'errorCode': errorCode,
    'productId': productId,
    'row': {
      'rowNumber': row.rowNumber,
      'name': row.name,
      'nameNp': row.nameNp,
      'sku': row.sku,
      'unit': row.unit,
      'costPrice': row.costPrice,
      'referencePrice': row.referencePrice,
      'lowStockThreshold': row.lowStockThreshold,
      'initialQuantity': row.initialQuantity,
    },
  };

  factory ProductImportSessionRow.fromJson(Map<String, dynamic> json) {
    final rowMap = Map<String, dynamic>.from(json['row'] as Map);
    final row = ProductImportRow(
      rowNumber: (rowMap['rowNumber'] as num).toInt(),
      name: rowMap['name'] as String,
      nameNp: rowMap['nameNp'] as String?,
      sku: rowMap['sku'] as String?,
      unit: (rowMap['unit'] as String?) ?? 'piece',
      costPrice: (rowMap['costPrice'] as num?)?.toInt() ?? 0,
      referencePrice: (rowMap['referencePrice'] as num?)?.toInt() ?? 0,
      lowStockThreshold: (rowMap['lowStockThreshold'] as num?)?.toInt() ?? 0,
      initialQuantity: (rowMap['initialQuantity'] as num?)?.toInt() ?? 0,
    );
    return ProductImportSessionRow(
      operationId: (json['operationId'] as String?) ?? _uuid.v4(),
      row: row,
      sku: (json['sku'] as String?) ?? row.sku ?? generateProductSku(),
      status: ProductImportRowStatus.values.firstWhere(
        (v) => v.name == json['status'],
        orElse: () => ProductImportRowStatus.pending,
      ),
      errorCode: json['errorCode'] as String?,
      productId: json['productId'] as String?,
    );
  }
}

class ProductImportSession {
  const ProductImportSession({
    required this.sessionId,
    required this.filename,
    required this.createdAt,
    required this.rows,
    this.priorErrors = const [],
  });

  factory ProductImportSession.create({
    required String filename,
    required List<ProductImportRow> rows,
    List<ProductImportRowError> priorErrors = const [],
  }) {
    return ProductImportSession(
      sessionId: _uuid.v4(),
      filename: filename,
      createdAt: DateTime.now().toUtc(),
      rows: rows
          .map(
            (r) => ProductImportSessionRow(
              operationId: _uuid.v4(),
              row: r,
              sku: r.sku ?? generateProductSku(),
            ),
          )
          .toList(),
      priorErrors: priorErrors,
    );
  }

  final String sessionId;
  final String filename;
  final DateTime createdAt;
  final List<ProductImportSessionRow> rows;
  final List<ProductImportRowError> priorErrors;

  int get completedCount => rows.where((r) => r.isDone).length;
  int get remainingCount => rows.where((r) => !r.isDone).length;
  int get totalRowCount => rows.length;
  bool get isFullySucceeded => remainingCount == 0 && priorErrors.isEmpty;

  List<ProductImportRowError> get allErrors {
    final list = List<ProductImportRowError>.from(priorErrors);
    for (final entry in rows) {
      if (!entry.isDone && entry.errorCode != null) {
        list.add(
          ProductImportRowError(
            rowNumber: entry.row.rowNumber,
            code: entry.errorCode!,
            productId: entry.productId,
            productName: entry.row.name,
            sku: entry.sku,
          ),
        );
      }
    }
    return list;
  }

  ProductImportSession copyWith({List<ProductImportSessionRow>? rows}) {
    return ProductImportSession(
      sessionId: sessionId,
      filename: filename,
      createdAt: createdAt,
      rows: rows ?? this.rows,
      priorErrors: priorErrors,
    );
  }

  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'filename': filename,
    'createdAt': createdAt.toIso8601String(),
    'rows': rows.map((r) => r.toJson()).toList(),
    'priorErrors': priorErrors
        .map(
          (e) => {
            'rowNumber': e.rowNumber,
            'code': e.code,
            'productId': e.productId,
            'productName': e.productName,
            'sku': e.sku,
          },
        )
        .toList(),
  };

  factory ProductImportSession.fromJson(Map<String, dynamic> json) {
    final rawRows = json['rows'];
    final rows = rawRows is List
        ? rawRows
              .whereType<Map>()
              .map(
                (m) => ProductImportSessionRow.fromJson(
                  Map<String, dynamic>.from(m),
                ),
              )
              .toList()
        : const <ProductImportSessionRow>[];
    final rawErrors = json['priorErrors'];
    final priorErrors = rawErrors is List
        ? rawErrors.whereType<Map>().map((m) {
            final map = Map<String, dynamic>.from(m);
            return ProductImportRowError(
              rowNumber: (map['rowNumber'] as num).toInt(),
              code: map['code'] as String,
              productId: map['productId'] as String?,
              productName: map['productName'] as String?,
              sku: map['sku'] as String?,
            );
          }).toList()
        : const <ProductImportRowError>[];
    return ProductImportSession(
      sessionId: (json['sessionId'] as String?) ?? _uuid.v4(),
      filename: (json['filename'] as String?) ?? 'import',
      createdAt:
          DateTime.tryParse((json['createdAt'] as String?) ?? '') ??
          DateTime.now().toUtc(),
      rows: rows,
      priorErrors: priorErrors,
    );
  }
}

/// Persists in-progress or partially-failed product import sessions across
/// sheet close / app restarts, scoped per `(businessId, memberId, role)`.
class ProductImportSessionStore {
  const ProductImportSessionStore();

  Future<ProductImportSession?> load(ImportSessionScope? scope) async {
    if (scope == null || !scope.isValid) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(scope.storageKey);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final session = ProductImportSession.fromJson(
        Map<String, dynamic>.from(decoded),
      );
      if (session.rows.isEmpty && session.priorErrors.isEmpty) return null;
      return session;
    } catch (_) {
      return null;
    }
  }

  Future<void> save(
    ImportSessionScope? scope,
    ProductImportSession session,
  ) async {
    if (scope == null || !scope.isValid) return;
    if (session.isFullySucceeded) {
      await clear(scope);
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(scope.storageKey, jsonEncode(session.toJson()));
    } catch (_) {}
  }

  Future<void> clear(ImportSessionScope? scope) async {
    if (scope == null || !scope.isValid) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(scope.storageKey);
    } catch (_) {}
  }
}

final productImportSessionStoreProvider = Provider<ProductImportSessionStore>(
  (ref) => const ProductImportSessionStore(),
);
