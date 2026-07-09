import '../../domain/models/product.dart';

enum StockLevel { inStock, lowStock, outOfStock }

StockLevel stockLevelFor(Product product) {
  if (product.stockCached <= 0) return StockLevel.outOfStock;
  if (product.lowStockThreshold > 0 &&
      product.stockCached <= product.lowStockThreshold) {
    return StockLevel.lowStock;
  }
  return StockLevel.inStock;
}

bool isLowStock(Product product) =>
    stockLevelFor(product) == StockLevel.lowStock;

int countLowStock(Iterable<Product> products) =>
    products.where(isLowStock).length;
