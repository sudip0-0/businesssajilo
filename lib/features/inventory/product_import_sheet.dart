import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/export/export_share_service.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/adaptive_sheet.dart';
import '../../core/ui/bs_snackbar.dart';
import '../../data/repositories/product_import_repository.dart';
import '../../data/repositories/products_repository.dart';
import '../../data/repositories/stock_repository.dart';
import '../auth/providers/auth_provider.dart';
import 'product_excel_import.dart';
import 'product_import_session_store.dart';
import 'providers.dart';

/// Opens the product Excel import sheet. Returns `true` if any products
/// were imported successfully.
Future<bool?> showProductImportSheet(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return showAdaptiveSheet<bool>(
    context: context,
    title: l10n.importFromExcel,
    webPanelWidth: 520,
    child: const ProductImportSheet(),
  );
}

class ProductImportSheet extends ConsumerStatefulWidget {
  const ProductImportSheet({super.key});

  @override
  ConsumerState<ProductImportSheet> createState() => _ProductImportSheetState();
}

class _ProductImportSheetState extends ConsumerState<ProductImportSheet> {
  bool _busy = false;
  bool _loadingSaved = true;
  ProductImportSession? _savedSession;
  String? _status;
  List<String> _errorLines = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSavedSession());
  }

  ImportSessionScope? _currentScope() {
    final member = ref.read(authProvider).value?.member;
    if (member == null) return null;
    final scope = ImportSessionScope(
      businessId: member.businessId,
      memberId: member.id,
      role: member.role,
    );
    return scope.isValid ? scope : null;
  }

  Future<void> _loadSavedSession() async {
    final saved = await ref
        .read(productImportSessionStoreProvider)
        .load(_currentScope());
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _loadingSaved = false;
      _savedSession = saved;
      if (saved != null) {
        _errorLines = _formatErrors(l10n, saved.allErrors);
      }
    });
  }

  Future<void> _discardSession() async {
    if (_busy) return;
    await ref.read(productImportSessionStoreProvider).clear(_currentScope());
    if (!mounted) return;
    setState(() {
      _savedSession = null;
      _status = null;
      _errorLines = const [];
    });
  }

  Future<void> _downloadSample() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _status = null;
      _errorLines = const [];
    });
    try {
      final bytes = ref.read(productExcelImportProvider).buildSampleBytes();
      await ref
          .read(exportShareServiceProvider)
          .shareBytes(
            filename: ProductExcelImport.sampleFileName,
            bytes: bytes,
            mimeType:
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            subject: l10n.downloadSampleExcel,
          );
    } catch (_) {
      if (!mounted) return;
      showBsSnackBar(
        context,
        message: l10n.importInvalidFile,
        backgroundColor: BsColors.danger,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickAndImport() async {
    if (_busy || _savedSession != null) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _status = null;
      _errorLines = const [];
    });

    try {
      final picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['xlsx', 'csv'],
        withData: true,
      );
      if (picked == null || picked.files.isEmpty) {
        if (mounted) setState(() => _busy = false);
        return;
      }

      final file = picked.files.first;
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        if (!mounted) return;
        setState(() {
          _busy = false;
          _status = l10n.importInvalidFile;
        });
        return;
      }

      final importer = ref.read(productExcelImportProvider);
      late final ProductImportParseResult parsed;
      try {
        parsed = importer.parseBytes(bytes, filename: file.name);
      } on ProductImportParseException catch (e) {
        if (!mounted) return;
        setState(() {
          _busy = false;
          _status = _parseExceptionMessage(l10n, e);
        });
        return;
      }

      if (parsed.rows.isEmpty) {
        if (!mounted) return;
        setState(() {
          _busy = false;
          _status = l10n.importNoRows;
          _errorLines = _formatErrors(l10n, parsed.errors);
        });
        return;
      }

      final session = ProductImportSession.create(
        filename: file.name,
        rows: parsed.rows,
        priorErrors: parsed.errors,
      );
      await _executeSession(session);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _status = l10n.importInvalidFile;
      });
    }
  }

  Future<void> _resumeSavedSession() async {
    final session = _savedSession;
    if (_busy || session == null) return;
    await _executeSession(session);
  }

  Future<void> _executeSession(ProductImportSession session) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final member = ref.read(authProvider).value?.member;
    final scope = _currentScope();
    final store = ref.read(productImportSessionStoreProvider);

    setState(() {
      _busy = true;
      _savedSession = session;
      _errorLines = _formatErrors(l10n, session.allErrors);
    });

    // Persist the session with pre-generated operation IDs before the first write.
    await store.save(scope, session);

    final runner = ProductImportRunner(
      products: ref.read(productsRepositoryProvider),
      stock: ref.read(stockRepositoryProvider),
      memberId: member?.id,
      idempotentImport: ref.read(productImportRepositoryProvider),
      role: member?.role,
    );

    final finished = await runner.runSession(
      session,
      onSessionUpdated: (updated) async {
        await store.save(scope, updated);
        if (mounted) {
          setState(() => _savedSession = updated);
        }
      },
      onProgress: (current, total) {
        if (!mounted) return;
        setState(() => _status = l10n.importingRow(current, total));
      },
    );

    if (!mounted) return;
    bumpInventoryRevision(ref);
    ref.invalidate(productListProvider);
    ref.invalidate(lowStockCountProvider);

    final errors = finished.allErrors;
    final errorLines = _formatErrors(l10n, errors);

    if (finished.isFullySucceeded) {
      await store.clear(scope);
      if (!mounted) return;
      showBsSnackBar(
        context,
        message: l10n.importSuccess(finished.completedCount),
      );
      Navigator.of(context).pop(true);
      return;
    }

    await store.save(scope, finished);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _savedSession = finished;
      _status = l10n.importPartial(
        finished.completedCount,
        finished.completedCount + errors.length,
        errors.length,
      );
      _errorLines = errorLines;
    });
  }

  List<String> _formatErrors(
    AppLocalizations l10n,
    List<ProductImportRowError> errors,
  ) {
    return errors.map((e) {
      final identity = [
        e.productName,
        e.sku,
        e.productId,
      ].whereType<String>().join(' · ');
      final message = _rowCode(l10n, e.code);
      return l10n.importRowError(
        e.rowNumber,
        identity.isEmpty ? message : '$identity: $message',
      );
    }).toList();
  }

  String _parseExceptionMessage(
    AppLocalizations l10n,
    ProductImportParseException e,
  ) {
    return switch (e.message) {
      'empty' || 'no_rows' => l10n.importNoRows,
      'missing_header' || 'missing_name_column' => l10n.importMissingHeader,
      _ => l10n.importInvalidFile,
    };
  }

  String _rowCode(AppLocalizations l10n, String code) {
    return switch (code) {
      'missing_name' => l10n.importMissingName,
      'invalid_cost' => l10n.importInvalidCost,
      'invalid_price' => l10n.importInvalidPrice,
      'invalid_threshold' =>
        '${l10n.lowStockThreshold}: ${l10n.importInvalidQty}',
      'invalid_qty' => '${l10n.initialQuantity}: ${l10n.importInvalidQty}',
      'create_failed' => l10n.importCreateFailed,
      'create_unconfirmed' => l10n.importCreateUnconfirmed,
      'stock_unconfirmed' => l10n.importStockUnconfirmed,
      'missing_member' => l10n.importMissingMember,
      'opening_stock_owner_only' => l10n.importOpeningStockOwnerOnly,
      _ => l10n.importInvalidFile,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final saved = _savedSession;
    final canResume =
        saved != null &&
        saved.remainingCount > 0 &&
        ref.watch(productImportRepositoryProvider) != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        8,
        24,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!kIsWeb) ...[
              Text(l10n.importFromExcel, style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
            ],
            Text(
              l10n.importExcelHint,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (_loadingSaved)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: LinearProgressIndicator(),
              )
            else if (saved != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(BsRadii.lg),
                  border: Border.all(
                    color: BsColors.accent.withValues(alpha: 0.45),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          PhosphorIconsRegular.clockCounterClockwise,
                          size: 18,
                          color: BsColors.accent,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.importSessionSavedTitle,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.importSessionSavedBody(
                        saved.filename,
                        saved.completedCount,
                        saved.totalRowCount,
                        saved.remainingCount,
                      ),
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (canResume)
                          FilledButton.icon(
                            onPressed: _busy ? null : _resumeSavedSession,
                            icon: const Icon(
                              PhosphorIconsRegular.arrowsClockwise,
                              size: 16,
                            ),
                            label: Text(l10n.importResumeSafe),
                          ),
                        OutlinedButton.icon(
                          onPressed: _busy ? null : _discardSession,
                          icon: const Icon(
                            PhosphorIconsRegular.trash,
                            size: 16,
                          ),
                          label: Text(l10n.importDiscardSession),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ] else ...[
              OutlinedButton.icon(
                onPressed: _busy ? null : _downloadSample,
                icon: const Icon(PhosphorIconsRegular.downloadSimple),
                label: Text(l10n.downloadSampleExcel),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _busy ? null : _pickAndImport,
                icon: const Icon(PhosphorIconsRegular.uploadSimple),
                label: Text(l10n.chooseExcelFile),
              ),
            ],
            if (_busy || _status != null) ...[
              const SizedBox(height: 16),
              if (_busy)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: LinearProgressIndicator(),
                ),
              if (_status != null)
                Text(
                  _status!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
            if (saved != null && !_busy) ...[
              const SizedBox(height: 8),
              Text(
                l10n.importRecoveryHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (_errorLines.isNotEmpty) ...[
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 180),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _errorLines.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    return Text(
                      _errorLines[index],
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
