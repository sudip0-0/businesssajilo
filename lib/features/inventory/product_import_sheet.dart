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
import '../../data/repositories/products_repository.dart';
import '../../data/repositories/stock_repository.dart';
import '../auth/providers/auth_provider.dart';
import 'product_excel_import.dart';
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
  String? _status;
  List<String> _errorLines = const [];

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
          _errorLines = parsed.errors
              .map(
                (e) => l10n.importRowError(e.rowNumber, _rowCode(l10n, e.code)),
              )
              .toList();
        });
        return;
      }

      final memberId = ref.read(authProvider).value?.member?.id;
      final runner = ProductImportRunner(
        products: ref.read(productsRepositoryProvider),
        stock: ref.read(stockRepositoryProvider),
        memberId: memberId,
      );

      final result = await runner.run(
        parsed.rows,
        priorErrors: parsed.errors,
        onProgress: (current, total) {
          if (!mounted) return;
          setState(() => _status = l10n.importingRow(current, total));
        },
      );

      bumpInventoryRevision(ref);
      ref.invalidate(productListProvider);
      ref.invalidate(lowStockCountProvider);

      if (!mounted) return;

      final errorLines = result.errors
          .map((e) => l10n.importRowError(e.rowNumber, _rowCode(l10n, e.code)))
          .toList();

      if (result.imported > 0 && result.failed == 0) {
        showBsSnackBar(context, message: l10n.importSuccess(result.imported));
        Navigator.of(context).pop(true);
        return;
      }

      setState(() {
        _busy = false;
        _status = result.imported > 0
            ? l10n.importPartial(result.imported, result.total, result.failed)
            : l10n.importNoRows;
        _errorLines = errorLines;
      });

      if (result.imported > 0) {
        // Keep sheet open so the user can read failures, but list already refreshed.
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _status = l10n.importInvalidFile;
      });
    }
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
      'invalid_threshold' || 'invalid_qty' => l10n.importInvalidQty,
      'create_failed' => l10n.importCreateFailed,
      _ => l10n.importInvalidFile,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

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
            const SizedBox(height: 20),
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
            if (_busy || _status != null) ...[
              const SizedBox(height: 20),
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
