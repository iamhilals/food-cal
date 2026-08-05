class Recipe {
  final String name;
  final String prepTime;
  final List<String> steps;
  final List<String> ingredients; // Tarifin malzeme listesi (miktarları ile birlikte)
  final double calories;
  final double protein;
  final double fat;
  final double carbs;
  final bool isSufficient;
  final List<String> missingIngredients;
  final String chefComment; // AI Şef'in eğlenceli yorumu ve mutfak notu

  Recipe({
    required this.name,
    required this.prepTime,
    required this.steps,
    required this.ingredients,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.isSufficient,
    required this.missingIngredients,
    required this.chefComment,
  });

  Map<String, dynamic> toJson() {
    return {
      'recipe_name': name,
      'prep_time': prepTime,
      'steps': steps,
      'ingredients': ingredients,
      'calories': calories,
      'protein': protein,
      'fat': fat,
      'carbohydrates': carbs,
      'is_sufficient': isSufficient,
      'missing_ingredients': missingIngredients,
      'chef_comment': chefComment,
    };
  }

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      name: json['recipe_name'] as String? ?? 'Bilinmeyen Tarif',
      prepTime: json['prep_time'] as String? ?? 'Bilinmiyor',
      steps: (json['steps'] as List?)?.map((e) => e.toString()).toList() ?? [],
      ingredients: (json['ingredients'] as List?)?.map((e) => e.toString()).toList() ?? [],
      calories: (json['calories'] ?? 0).toDouble(),
      protein: (json['protein'] ?? 0).toDouble(),
      fat: (json['fat'] ?? 0).toDouble(),
      carbs: (json['carbohydrates'] ?? json['carbs'] ?? 0).toDouble(),
      isSufficient: json['is_sufficient'] as bool? ?? true,
      missingIngredients: (json['missing_ingredients'] as List?)?.map((e) => e.toString()).toList() ?? [],
      chefComment: json['chef_comment'] as String? ?? 'Şefimiz bu malzemeleri bir araya getirdiğiniz için mutlu!',
    );
  }
}
