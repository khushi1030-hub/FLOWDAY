import '../entities/category.dart';

/// Repository interface for categories.
abstract class CategoryRepository {
  Future<List<Category>> getAllCategories();
  Future<Category?> getCategoryById(int id);
  Future<int> insertCategory(Category category);
  Future<void> updateCategory(Category category);
  Future<void> deleteCategory(int id);
}
