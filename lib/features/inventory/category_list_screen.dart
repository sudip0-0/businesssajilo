import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../data/repositories/categories_repository.dart';
import '../../domain/models/category.dart';

final categoryListProvider = FutureProvider.autoDispose<List<Category>>((ref) {
  return ref.watch(categoriesRepositoryProvider).list();
});

class CategoryListScreen extends ConsumerWidget {
  const CategoryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final categoriesAsync = ref.watch(categoryListProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.categories)),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (categories) => ListView.separated(
          itemCount: categories.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final cat = categories[index];
            return ListTile(
              title: Text(cat.name),
              subtitle: cat.nameNp != null ? Text(cat.nameNp!) : null,
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  await ref.read(categoriesRepositoryProvider).delete(cat.id);
                  ref.invalidate(categoryListProvider);
                },
              ),
              onTap: () => _editCategory(context, ref, cat),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addCategory(context, ref),
        icon: const Icon(Icons.add),
        label: Text(l10n.addCategory),
      ),
    );
  }

  Future<void> _addCategory(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final name = await _prompt(context, l10n.addCategory, l10n.productName);
    if (name == null || name.isEmpty) return;
    await ref.read(categoriesRepositoryProvider).create(name: name);
    ref.invalidate(categoryListProvider);
  }

  Future<void> _editCategory(BuildContext context, WidgetRef ref, Category cat) async {
    final l10n = AppLocalizations.of(context);
    final name = await _prompt(context, l10n.editCategory, l10n.productName, initial: cat.name);
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
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
