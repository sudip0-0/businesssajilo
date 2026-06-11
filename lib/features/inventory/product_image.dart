import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/repositories/products_repository.dart';

class ProductImage extends ConsumerWidget {
  const ProductImage({
    super.key,
    required this.storagePath,
    this.size = 48,
  });

  final String? storagePath;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (storagePath == null || storagePath!.isEmpty) {
      return _placeholder();
    }

    return FutureBuilder<String?>(
      future: ref.read(productsRepositoryProvider).signedImageUrl(storagePath),
      builder: (context, snapshot) {
        final url = snapshot.data;
        if (url == null) return _placeholder();
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: url,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorWidget: (_, _, _) => _placeholder(),
          ),
        );
      },
    );
  }

  Widget _placeholder() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: BsColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.inventory_2_outlined, color: BsColors.primary, size: size * 0.5),
    );
  }
}
