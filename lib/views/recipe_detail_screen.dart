import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../providers/ingredient_provider.dart';
import '../providers/recipe_provider.dart';
import 'widgets/macro_chart.dart';
import 'widgets/missing_ingredients_modal.dart';

class RecipeDetailScreen extends StatefulWidget {
  const RecipeDetailScreen({super.key});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  bool _modalShown = false;
  final Set<String> _checkedMissingIngredients = {};

  void _showMissingIngredients(BuildContext context, List<String> missing) {
    setState(() {
      _modalShown = true;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MissingIngredientsModal(
        missingIngredients: missing,
        onContinue: () {
          // User chose to view the recipe anyway
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recipeProvider = Provider.of<RecipeProvider>(context);
    final ingProvider = Provider.of<IngredientProvider>(context);

    // Auto open missing ingredients modal once when recipe loaded and has missing items
    if (!_modalShown &&
        recipeProvider.status == RecipeStatus.success &&
        recipeProvider.recipe != null &&
        !recipeProvider.recipe!.isSufficient) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showMissingIngredients(context, recipeProvider.recipe!.missingIngredients);
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary),
          onPressed: () {
            recipeProvider.reset();
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Tarif Detayı',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Builder(
        builder: (context) {
          switch (recipeProvider.status) {
            case RecipeStatus.idle:
              return const Center(
                child: Text('Tarif oluşturulması bekleniyor...'),
              );

            case RecipeStatus.loading:
              return const AnimatedRecipeLoader();

            case RecipeStatus.error:
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Card(
                    color: AppTheme.darkCard,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppTheme.errorRed, width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: AppTheme.errorRed,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Tarif Oluşturulamadı',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            recipeProvider.error ?? 'Bilinmeyen bir hata oluştu.',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              recipeProvider.generateRecipe(ingProvider.selectedIngredientNames);
                            },
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Yeniden Dene'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );

            case RecipeStatus.success:
              final recipe = recipeProvider.recipe!;
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  // Title and Food badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryTeal.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.restaurant_menu_rounded,
                          color: AppTheme.primaryTeal,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              recipe.name,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.timer_outlined, size: 16, color: AppTheme.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  recipe.prepTime,
                                  style: const TextStyle(color: AppTheme.textSecondary),
                                ),
                                const SizedBox(width: 12),
                                // Sufficiency Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: recipe.isSufficient
                                        ? AppTheme.accentEmerald.withValues(alpha: 0.15)
                                        : Colors.orange.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    recipe.isSufficient ? 'Malzemeler Tam' : 'Eksik Malzeme Var',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: recipe.isSufficient ? AppTheme.accentEmerald : Colors.orangeAccent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Chef's Comment Bubble
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryIndigo.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.secondaryIndigo.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '👨‍🍳',
                          style: TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Şefin Yorumu',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.secondaryIndigo,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                recipe.chefComment,
                                style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                  fontSize: 14,
                                  color: AppTheme.textPrimary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Nutritional Macros Chart Card
                  MacroChart(
                    calories: recipe.calories,
                    protein: recipe.protein,
                    fat: recipe.fat,
                    carbs: recipe.carbs,
                  ),
                  const SizedBox(height: 28),

                  // Missing ingredients indicator (if clicked 'view anyway')
                  if (!recipe.isSufficient) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Bu tarif için eksik olan malzemeler:',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orangeAccent),
                              ),
                            ],
                          ),
                           Column(
                             children: recipe.missingIngredients.map((item) {
                               final isChecked = _checkedMissingIngredients.contains(item);
                               return CheckboxListTile(
                                 value: isChecked,
                                 onChanged: (bool? val) {
                                   setState(() {
                                     if (val == true) {
                                       _checkedMissingIngredients.add(item);
                                     } else {
                                       _checkedMissingIngredients.remove(item);
                                     }
                                   });
                                 },
                                 title: Text(
                                   item,
                                   style: TextStyle(
                                     color: isChecked ? AppTheme.textSecondary : AppTheme.textPrimary,
                                     decoration: isChecked ? TextDecoration.lineThrough : null,
                                     fontSize: 14,
                                   ),
                                 ),
                                 dense: true,
                                 controlAffinity: ListTileControlAffinity.leading,
                                 activeColor: Colors.orangeAccent,
                                 contentPadding: EdgeInsets.zero,
                               );
                             }).toList(),
                           ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Step-by-Step Instructions
                  Text(
                    'Hazırlanışı',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),

                  // Clean list showing chronological steps
                  ...List.generate(recipe.steps.length, (idx) {
                    final isLast = idx == recipe.steps.length - 1;
                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Column(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                  color: AppTheme.primaryTeal,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${idx + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              if (!isLast)
                                Expanded(
                                  child: Container(
                                    width: 2,
                                    color: AppTheme.borderSlate,
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: Text(
                                recipe.steps[idx],
                                style: const TextStyle(
                                  fontSize: 15,
                                  height: 1.4,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              );
          }
        },
      ),
    );
  }
}

class AnimatedRecipeLoader extends StatefulWidget {
  const AnimatedRecipeLoader({super.key});

  @override
  State<AnimatedRecipeLoader> createState() => _AnimatedRecipeLoaderState();
}

class _AnimatedRecipeLoaderState extends State<AnimatedRecipeLoader> {
  late Timer _timer;
  int _currentIndex = 0;
  final List<String> _loadingMessages = [
    'Dolaptaki malzemeler yıkanıyor ve doğranıyor...',
    'Tuz, zeytinyağı ve baharatlar hazırlandı...',
    'Şef Gemini en lezzetli tarifi tasarlıyor...',
    'Kalori ve makro besin değerleri hesaplanıyor...',
    'Tarif sunum tabağına hazırlanıyor...',
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _loadingMessages.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SpinKitSpinningLines(
              color: AppTheme.primaryTeal,
              size: 80,
            ),
            const SizedBox(height: 36),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Text(
                _loadingMessages[_currentIndex],
                key: ValueKey<int>(_currentIndex),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Yapay zeka analizi nedeniyle birkaç saniye sürebilir.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

