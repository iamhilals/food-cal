class Ingredient {
  final String id;
  final String name;
  final String category;
  bool isSelected;
  final bool isDefault; // Tuz, karabiber vb. implicit default malzemeler
  final bool isCustom;  // Kullanıcı tarafından sonradan eklenmiş ve doğrulanmış malzemeler

  Ingredient({
    required this.id,
    required this.name,
    required this.category,
    this.isSelected = false,
    this.isDefault = false,
    this.isCustom = false,
  });

  Ingredient copyWith({
    String? id,
    String? name,
    String? category,
    bool? isSelected,
    bool? isDefault,
    bool? isCustom,
  }) {
    return Ingredient(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      isSelected: isSelected ?? this.isSelected,
      isDefault: isDefault ?? this.isDefault,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'isSelected': isSelected,
      'isDefault': isDefault,
      'isCustom': isCustom,
    };
  }

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      isSelected: json['isSelected'] as bool? ?? false,
      isDefault: json['isDefault'] as bool? ?? false,
      isCustom: json['isCustom'] as bool? ?? false,
    );
  }

  @override
  String toString() => 'Ingredient(id: $id, name: $name, isSelected: $isSelected, isDefault: $isDefault)';
}
