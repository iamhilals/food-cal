import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../providers/recipe_provider.dart';
import 'recipe_detail_screen.dart';

class RecipeHistoryScreen extends StatelessWidget {
  const RecipeHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final recipeProvider = Provider.of<RecipeProvider>(context);
    final history = recipeProvider.history;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tarif Defterim',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              'Geçmişte Ürettiğiniz Tarifler',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ],
        ),
      ),
      body: history.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryTeal.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        color: AppTheme.primaryTeal,
                        size: 64,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Henüz Tarif Yok',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Dolabınızdan malzemeleri seçip ilk lezzetli tarifinizi oluşturun!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final recipe = history[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryTeal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.restaurant_menu_rounded,
                        color: AppTheme.primaryTeal,
                      ),
                    ),
                    title: Text(
                      recipe.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.timer_outlined, size: 14, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            recipe.prepTime,
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.local_fire_department_rounded, size: 14, color: Colors.orangeAccent),
                          const SizedBox(width: 4),
                          Text(
                            '${recipe.calories.toStringAsFixed(0)} kcal',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.errorRed),
                      onPressed: () {
                        // Confirm deletion
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: AppTheme.darkCard,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(color: AppTheme.borderSlate),
                            ),
                            title: const Text('Tarifi Sil'),
                            content: const Text('Bu tarifi geçmişinizden kalıcı olarak silmek istediğinize emin misiniz?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('İptal', style: TextStyle(color: AppTheme.textSecondary)),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
                                onPressed: () {
                                  recipeProvider.deleteRecipe(index);
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Tarif başarıyla silindi.'),
                                      backgroundColor: AppTheme.errorRed,
                                    ),
                                  );
                                },
                                child: const Text('Sil'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    onTap: () {
                      recipeProvider.setRecipe(recipe);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const RecipeDetailScreen(),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
