/// Domain entity representing a task category.
class Category {
  const Category({
    this.id,
    required this.name,
    required this.color,
    required this.iconKey,
    this.isDefault = false,
  });

  final int? id;
  final String name;
  final int color;
  final String iconKey;
  final bool isDefault;

  Category copyWith({
    int? id,
    String? name,
    int? color,
    String? iconKey,
    bool? isDefault,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      iconKey: iconKey ?? this.iconKey,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'color': color,
      'icon_key': iconKey,
      'is_default': isDefault ? 1 : 0,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
      color: map['color'] as int,
      iconKey: map['icon_key'] as String,
      isDefault: (map['is_default'] as int? ?? 0) == 1,
    );
  }
}
