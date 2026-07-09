import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/ui/async_body.dart';
import '../../core/ui/empty_state.dart';
import '../../data/repositories/categories_repository.dart';
import '../../domain/models/category.dart';
import 'providers.dart';

class CategoryListScreen extends ConsumerWidget {
  const CategoryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final categoriesAsync = ref.watch(categoryListProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.categories)),
      body: AsyncBody(
        value: categoriesAsync,
        onRetry: () => ref.invalidate(categoryListProvider),
        data: (categories) {
          if (categories.isEmpty) {
            return EmptyState(
              icon: Icons.category_outlined,
              message: l10n.noCategories,
              actionLabel: l10n.addCategory,
              onAction: () => _addCategory(context, ref),
            );
          }
          return ListView.separated(
            itemCount: categories.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final cat = categories[index];
              return ListTile(
                title: Text(cat.name),
                subtitle: cat.nameNp != null ? Text(cat.nameNp!) : null,
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: l10n.delete,
                  onPressed: () => _deleteCategory(context, ref, cat),
                ),
                onTap: () => _editCategory(context, ref, cat),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addCategory(context, ref),
        icon: const Icon(Icons.add),
        label: Text(l10n.addCategory),
      ),
    );
  }

  Future<void> _deleteCategory(
    BuildContext context,
    WidgetRef ref,
    Category cat,
  ) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(l10n.confirmDeleteCategory),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(categoriesRepositoryProvider).delete(cat.id);
      ref.invalidate(categoryListProvider);
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.actionFailed)));
    }
  }

  Future<void> _addCategory(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final name = await _prompt(context, l10n.addCategory, l10n.productName);
    if (name == null || name.isEmpty) return;
    await ref.read(categoriesRepositoryProvider).create(name: name);
    ref.invalidate(categoryListProvider);
  }

  Future<void> _editCategory(
    BuildContext context,
    WidgetRef ref,
    Category cat,
  ) async {
    final l10n = AppLocalizations.of(context);
    final name = await _prompt(
      context,
      l10n.editCategory,
      l10n.productName,
      initial: cat.name,
    );
    if (name == null || name.isEmpty) return;
    await ref.read(categoriesRepositoryProvider).update(id: cat.id, name: name);
    ref.invalidate(categoryListProvider);
  }

  Future<String?> _prompt(
    BuildContext context,
    String title,
    String label, {
    String initial = '',
  }) async {
    final controller = TextEditingController(text: initial);
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: label),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }
}
