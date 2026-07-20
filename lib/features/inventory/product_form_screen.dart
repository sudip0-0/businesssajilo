import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/money.dart';
import '../../data/repositories/products_repository.dart';
import '../../domain/models/product.dart';
import '../../features/auth/providers/auth_provider.dart';
import 'product_image.dart';
import 'providers.dart';

String generateProductSku() {
  final random = Random();
  final hex = List.generate(
    8,
    (_) => random.nextInt(16).toRadixString(16),
  ).join().toUpperCase();
  return 'BS-$hex';
}

class ProductFormScreen extends ConsumerStatefulWidget {
  const ProductFormScreen({
    super.key,
    this.product,
    this.embedded = false,
    this.onSaved,
  });

  final Product? product;
  final bool embedded;

  /// When set (e.g. web), called with the saved product instead of popping.
  final ValueChanged<Product>? onSaved;

  @override
  ConsumerState<ProductFormScreen> createState() => ProductFormScreenState();
}

class ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _nameNpController;
  late final TextEditingController _skuController;
  late final TextEditingController _unitController;
  late final TextEditingController _costController;
  late final TextEditingController _refController;
  late final TextEditingController _thresholdController;
  Uint8List? _imageBytes;
  String? _imageMime;
  bool _loading = false;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _nameNpController = TextEditingController(text: p?.nameNp ?? '');
    final existingSku = p?.sku?.trim();
    _skuController = TextEditingController(
      text: (existingSku != null && existingSku.isNotEmpty)
          ? existingSku
          : generateProductSku(),
    );
    _unitController = TextEditingController(text: p?.unit ?? 'piece');
    _costController = TextEditingController(
      text: p != null ? formatNpr(Paisa(p.costPrice), showPaisa: false) : '',
    );
    _refController = TextEditingController(
      text: p != null
          ? formatNpr(Paisa(p.referencePrice), showPaisa: false)
          : '',
    );
    _thresholdController = TextEditingController(
      text: p?.lowStockThreshold.toString() ?? '0',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameNpController.dispose();
    _skuController.dispose();
    _unitController.dispose();
    _costController.dispose();
    _refController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _imageBytes = bytes;
      _imageMime = file.mimeType ?? 'image/jpeg';
    });
  }

  /// Optional money field: empty is allowed, otherwise must parse to >= 0.
  String? _validateMoney(String? v, AppLocalizations l10n) {
    if (v == null || v.trim().isEmpty) return null;
    final parsed = parseNpr(v);
    if (parsed == null || parsed.value < 0) return l10n.invalidNumber;
    return null;
  }

  Future<void> submit() => _submit();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final repo = ref.read(productsRepositoryProvider);
      final cost = parseNpr(_costController.text)?.value ?? 0;
      final refPrice = parseNpr(_refController.text)?.value ?? 0;
      final threshold = int.tryParse(_thresholdController.text) ?? 0;
      final session = ref.read(authProvider).value;
      final businessId = session?.member?.businessId;
      final sku = _skuController.text.trim();

      Product saved;
      if (_isEdit) {
        saved = await repo.update(
          id: widget.product!.id,
          name: _nameController.text.trim(),
          nameNp: _nameNpController.text.trim().isEmpty
              ? null
              : _nameNpController.text.trim(),
          sku: sku.isEmpty ? null : sku,
          categoryId: widget.product!.categoryId,
          unit: _unitController.text.trim(),
          costPrice: cost,
          referencePrice: refPrice,
          lowStockThreshold: threshold,
          imageUrl: widget.product!.imageUrl,
        );
      } else {
        saved = await repo.create(
          name: _nameController.text.trim(),
          nameNp: _nameNpController.text.trim().isEmpty
              ? null
              : _nameNpController.text.trim(),
          sku: sku.isEmpty ? null : sku,
          categoryId: null,
          unit: _unitController.text.trim(),
          costPrice: cost,
          referencePrice: refPrice,
          lowStockThreshold: threshold,
        );
      }

      if (_imageBytes != null && businessId != null) {
        final path = await repo.uploadImage(
          businessId: businessId,
          productId: saved.id,
          bytes: _imageBytes!,
          mimeType: _imageMime ?? 'image/jpeg',
        );
        saved = await repo.update(
          id: saved.id,
          name: saved.name,
          nameNp: saved.nameNp,
          sku: saved.sku,
          categoryId: saved.categoryId,
          unit: saved.unit,
          costPrice: saved.costPrice,
          referencePrice: saved.referencePrice,
          lowStockThreshold: saved.lowStockThreshold,
          imageUrl: path,
        );
      }

      bumpInventoryRevision(ref);
      ref.invalidate(productListProvider);
      ref.invalidate(lowStockCountProvider);
      if (_isEdit) {
        ref.invalidate(productDetailProvider(saved.id));
      }

      if (!mounted) return;
      if (widget.onSaved != null) {
        widget.onSaved!(saved);
      } else {
        Navigator.pop(context, true);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).actionFailed),
            backgroundColor: BsColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final formBody = _buildForm(context, l10n);

    if (widget.embedded) return formBody;

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? l10n.editProduct : l10n.addProduct)),
      body: formBody,
    );
  }

  Widget _buildForm(BuildContext context, AppLocalizations l10n) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoCol = constraints.maxWidth >= 600;
        return SingleChildScrollView(
          padding: EdgeInsets.all(widget.embedded ? 0 : 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_imageBytes != null)
                  Image.memory(_imageBytes!, height: 120, fit: BoxFit.cover)
                else if (_isEdit)
                  ProductImage(
                    storagePath: widget.product!.imageUrl,
                    size: 120,
                  ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image_outlined),
                  label: Text(l10n.pickImage),
                ),
                const SizedBox(height: 16),
                _fieldRow(
                  twoCol: twoCol,
                  left: TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: l10n.productName),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? l10n.fieldRequired
                        : null,
                  ),
                  right: TextFormField(
                    controller: _nameNpController,
                    decoration: InputDecoration(labelText: l10n.productNameNp),
                  ),
                ),
                const SizedBox(height: 12),
                _fieldRow(
                  twoCol: twoCol,
                  left: TextFormField(
                    controller: _skuController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: l10n.sku,
                      helperText: l10n.skuAutoGenerated,
                    ),
                  ),
                  right: TextFormField(
                    controller: _unitController,
                    decoration: InputDecoration(labelText: l10n.unit),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? l10n.fieldRequired
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                _fieldRow(
                  twoCol: twoCol,
                  left: TextFormField(
                    controller: _costController,
                    decoration: InputDecoration(labelText: l10n.costPrice),
                    keyboardType: TextInputType.number,
                    validator: (v) => _validateMoney(v, l10n),
                  ),
                  right: TextFormField(
                    controller: _refController,
                    decoration: InputDecoration(labelText: l10n.referencePrice),
                    keyboardType: TextInputType.number,
                    validator: (v) => _validateMoney(v, l10n),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _thresholdController,
                  decoration: InputDecoration(labelText: l10n.lowStockThreshold),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final n = int.tryParse(v.trim());
                    if (n == null || n < 0) return l10n.invalidNumber;
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                if (!widget.embedded)
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.save),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _fieldRow({
    required bool twoCol,
    required Widget left,
    required Widget right,
  }) {
    if (!twoCol) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          left,
          const SizedBox(height: 12),
          right,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 16),
        Expanded(child: right),
      ],
    );
  }
}
