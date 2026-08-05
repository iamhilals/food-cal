import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/ingredient_provider.dart';
import '../../providers/recipe_provider.dart';

class MissingIngredientsModal extends StatelessWidget {
  final List<String> missingIngredients;
  final VoidCallback onContinue;

  const MissingIngredientsModal({
    super.key,
    required this.missingIngredients,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: const BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag indicator
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderSlate,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Warning Icon & Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orangeAccent,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Kritik Eksik Malzemeler!',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Seçtiğiniz malzemeler tek başına bu yemeği hazırlamak için yeterli görünmüyor. Ancak şu 1-2 malzemeyi de eklerseniz harika bir yemek hazırlayabilirsiniz:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 20),
          // Missing ingredients list
          ...missingIngredients.map(
            (ing) => Card(
              color: AppTheme.darkBg,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppTheme.borderSlate),
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.add_circle_outline_rounded,
                  color: AppTheme.primaryTeal,
                ),
                title: Text(
                  ing,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onContinue(); // Close modal and let them view the recipe details anyway
                  },
                  child: const Text(
                    'Yine de Tarifi Gör',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final ingProvider = Provider.of<IngredientProvider>(context, listen: false);
                    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);

                    // Add and select the missing ingredients in bulk
                    ingProvider.addAndSelectIngredients(missingIngredients);

                    // Pop modal
                    Navigator.of(context).pop();

                    // Automatically regenerate with the newly added ingredients
                    recipeProvider.generateRecipe(ingProvider.selectedIngredientNames);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryTeal,
                  ),
                  child: const Text('Ekle & Yeniden Dene'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
