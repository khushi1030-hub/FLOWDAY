import 'package:sqflite/sqflite.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';

/// SQLite implementation of [CategoryRepository].
class SqliteCategoryRepository implements CategoryRepository {
  const SqliteCategoryRepository(this._db);

  final Database _db;

  @override
  Future<List<Category>> getAllCategories() async {
    final rows = await _db.query('categories', orderBy: 'id ASC');
    return rows.map(Category.fromMap).toList();
  }

  @override
  Future<Category?> getCategoryById(int id) async {
    final rows = await _db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Category.fromMap(rows.first);
  }

  @override
  Future<int> insertCategory(Category category) async {
    return await _db.insert('categories', category.toMap());
  }

  @override
  Future<void> updateCategory(Category category) async {
    if (category.id == null) return;
    await _db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  @override
  Future<void> deleteCategory(int id) async {
    await _db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }
}
