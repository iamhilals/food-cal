import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../providers/ingredient_provider.dart';
import '../providers/recipe_provider.dart';
import 'widgets/macro_chart.dart';
import 'widgets/missing_ingredients_modal.dart';
import 'voice_cooking_screen.dart';

class RecipeDetailScreen extends StatefulWidget {
  const RecipeDetailScreen({super.key});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  bool _modalShown = false;
  final Set<String> _checkedMissingIngredients = {};
  int _portion = 2;

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

  Duration? _parseDurationFromStep(String step) {
    final regex = RegExp(r'(\d+)\s*(dakika|dk|saat|saniye)', caseSensitive: false);
    final match = regex.firstMatch(step);
    if (match != null) {
      final value = int.tryParse(match.group(1) ?? '0') ?? 0;
      final unit = match.group(2)?.toLowerCase() ?? '';
      if (unit.contains('saat')) {
        return Duration(hours: value);
      } else if (unit.contains('saniye')) {
        return Duration(seconds: value);
      } else {
        return Duration(minutes: value);
      }
    }
    return null;
  }

  String _scaleIngredient(String ingredient, double multiplier) {
    final regex = RegExp(r'(\d+(?:[.,]\d+)?)');
    return ingredient.replaceAllMapped(regex, (match) {
      final numberStr = match.group(1)?.replaceAll(',', '.') ?? '';
      final val = double.tryParse(numberStr);
      if (val != null) {
        final scaled = val * multiplier;
        if (scaled == scaled.toInt()) {
          return scaled.toInt().toString();
        }
        return scaled.toStringAsFixed(1).replaceAll('.', ',');
      }
      return match.group(0) ?? '';
    });
  }

  Widget _buildStepTextWithTooltips(BuildContext context, String text) {
    final List<InlineSpan> spans = [];
    
    final Map<String, String> matchPatterns = {
      r'(benmari)': 'benmari',
      r'(sotele\w*|sotelene\w*)': 'sotelemek',
      r'(marine\w*)': 'marine etmek',
      r'(jülyen|julienne)': 'jülyen',
      r'(mühürle\w*)': 'mühürlemek',
      r'(demle\w*)': 'demlemek',
      r'(blanş\w*)': 'blanş etmek',
      r'(al dente)': 'al dente',
      r'(karamelize\w*)': 'karamelize',
      r'(meyane\w*)': 'meyane',
    };
    
    final patternString = matchPatterns.keys.join('|');
    final regex = RegExp(patternString, caseSensitive: false);
    
    int lastIndex = 0;
    final matches = regex.allMatches(text);
    
    if (matches.isEmpty) {
      return Text(
        text,
        style: const TextStyle(fontSize: 15, height: 1.4, color: AppTheme.textPrimary),
      );
    }
    
    for (final match in matches) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: const TextStyle(color: AppTheme.textPrimary),
        ));
      }
      
      final matchedWord = text.substring(match.start, match.end);
      
      String matchedDictKey = '';
      for (final entry in matchPatterns.entries) {
        if (RegExp(entry.key, caseSensitive: false).hasMatch(matchedWord)) {
          matchedDictKey = entry.value;
          break;
        }
      }
      
      final definition = kCulinaryDictionary[matchedDictKey] ?? '';
      
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: GestureDetector(
            onTap: () {
              _showCulinaryTooltip(context, matchedWord, definition);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.primaryTeal,
                    width: 1.5,
                    style: BorderStyle.solid,
                  ),
                ),
              ),
              child: Text(
                matchedWord,
                style: const TextStyle(
                  color: AppTheme.primaryTeal,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
      );
      
      lastIndex = match.end;
    }
    
    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: const TextStyle(color: AppTheme.textPrimary),
      ));
    }
    
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 15, height: 1.4),
        children: spans,
      ),
    );
  }

  void _showCulinaryTooltip(BuildContext context, String word, String definition) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.borderSlate, width: 1.2),
        ),
        title: Row(
          children: const [
            Icon(Icons.menu_book_rounded, color: AppTheme.primaryTeal),
            SizedBox(width: 8),
            Text('Şefin Terim Sözlüğü'),
          ],
        ),
        content: Text(
          definition,
          style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anladım', style: TextStyle(color: AppTheme.primaryTeal)),
          ),
        ],
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

                  // Zero Waste Tip Card
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🌿',
                          style: TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Şefin Sıfır Atık Tavsiyesi',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                recipe.wasteTip,
                                style: const TextStyle(
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
                    calories: recipe.calories * (_portion / 2.0),
                    protein: recipe.protein * (_portion / 2.0),
                    fat: recipe.fat * (_portion / 2.0),
                    carbs: recipe.carbs * (_portion / 2.0),
                  ),
                  const SizedBox(height: 28),

                  // Portion selector & Ingredients list
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Malzemeler',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.darkCard,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.borderSlate, width: 1.2),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline_rounded, color: AppTheme.primaryTeal, size: 20),
                                  onPressed: _portion > 1
                                      ? () {
                                          setState(() {
                                            _portion--;
                                          });
                                        }
                                      : null,
                                ),
                                Text(
                                  '$_portion Porsiyon',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.primaryTeal, size: 20),
                                  onPressed: () {
                                    setState(() {
                                      _portion++;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (recipe.ingredients.isNotEmpty) ...[
                        Column(
                          children: recipe.ingredients.map((ing) {
                            final scaledText = _scaleIngredient(ing, _portion / 2.0);
                            return _IngredientCheckItem(key: ValueKey('$scaledText$_portion'), text: scaledText);
                          }).toList(),
                        ),
                      ] else ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Malzeme detayları yapay zeka tarafından bu tarif için listelenmedi.',
                            style: TextStyle(color: AppTheme.textSecondary, fontStyle: FontStyle.italic, fontSize: 13),
                          ),
                        ),
                      ],
                    ],
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
                           const SizedBox(height: 12),
                           SizedBox(
                             width: double.infinity,
                             child: OutlinedButton.icon(
                               style: OutlinedButton.styleFrom(
                                 foregroundColor: Colors.orangeAccent,
                                 side: const BorderSide(color: Colors.orangeAccent, width: 1.5),
                                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                 padding: const EdgeInsets.symmetric(vertical: 10),
                               ),
                               icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                               label: const Text('Tümünü Market Listeme Ekle', style: TextStyle(fontWeight: FontWeight.bold)),
                               onPressed: () {
                                 recipeProvider.addIngredientsToShoppingList(recipe.missingIngredients);
                                 ScaffoldMessenger.of(context).showSnackBar(
                                   const SnackBar(
                                     content: Text('Eksik malzemeler market sepetinize eklendi!'),
                                     backgroundColor: AppTheme.primaryTeal,
                                   ),
                                 );
                               },
                             ),
                           ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Step-by-Step Instructions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Hazırlanışı',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primaryTeal,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: AppTheme.primaryTeal, width: 1.5),
                          ),
                        ),
                        icon: const Icon(Icons.record_voice_over_rounded, size: 18),
                        label: const Text('Sesli Asistan', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VoiceCookingScreen(
                                recipeName: recipe.name,
                                steps: recipe.steps,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Clean list showing chronological steps
                  ...List.generate(recipe.steps.length, (idx) {
                    final isLast = idx == recipe.steps.length - 1;
                    final stepText = recipe.steps[idx];
                    final duration = _parseDurationFromStep(stepText);
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
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _buildStepTextWithTooltips(context, recipe.steps[idx]),
                                  ),
                                  if (duration != null) ...[
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.timer_outlined, color: AppTheme.primaryTeal),
                                      onPressed: () {
                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          builder: (context) => MutfakZamanlayiciSheet(
                                            stepName: 'Adım ${idx + 1}',
                                            duration: duration,
                                          ),
                                        );
                                      },
                                      tooltip: 'Zamanlayıcıyı Başlat',
                                    ),
                                  ],
                                ],
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

class MutfakZamanlayiciSheet extends StatefulWidget {
  final String stepName;
  final Duration duration;

  const MutfakZamanlayiciSheet({
    super.key,
    required this.stepName,
    required this.duration,
  });

  @override
  State<MutfakZamanlayiciSheet> createState() => _MutfakZamanlayiciSheetState();
}

class _MutfakZamanlayiciSheetState extends State<MutfakZamanlayiciSheet> {
  late int _remainingSeconds;
  Timer? _timer;
  bool _isRunning = true;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.duration.inSeconds;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel();
        setState(() {
          _isRunning = false;
        });
        _showAlarmDialog();
      }
    });
  }

  void _showAlarmDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.orangeAccent, width: 2),
        ),
        title: Row(
          children: const [
            Icon(Icons.alarm_on_rounded, color: Colors.orangeAccent, size: 28),
            SizedBox(width: 8),
            Text('Süre Doldu!'),
          ],
        ),
        content: Text(
          '"${widget.stepName}" için zamanlayıcı tamamlandı. Yemeğinizi kontrol etme zamanı!',
          style: const TextStyle(color: AppTheme.textPrimary),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
            onPressed: () {
              Navigator.pop(context); // close alarm dialog
              Navigator.pop(this.context); // close bottom sheet
            },
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime() {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final totalSeconds = widget.duration.inSeconds;
    final progress = totalSeconds > 0 ? _remainingSeconds / totalSeconds : 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppTheme.darkBg,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.borderSlate,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.stepName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 160,
                height: 160,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 10,
                  backgroundColor: AppTheme.borderSlate,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryTeal),
                ),
              ),
              Text(
                _formatTime(),
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
              ),
              IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.primaryTeal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
                icon: Icon(_isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 28),
                onPressed: () {
                  if (_isRunning) {
                    _timer?.cancel();
                    setState(() {
                      _isRunning = false;
                    });
                  } else {
                    setState(() {
                      _isRunning = true;
                    });
                    _startTimer();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _IngredientCheckItem extends StatefulWidget {
  final String text;
  const _IngredientCheckItem({super.key, required this.text});

  @override
  State<_IngredientCheckItem> createState() => _IngredientCheckItemState();
}

class _IngredientCheckItemState extends State<_IngredientCheckItem> {
  bool _checked = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        setState(() {
          _checked = !_checked;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            Icon(
              _checked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
              color: _checked ? AppTheme.primaryTeal : AppTheme.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.text,
                style: TextStyle(
                  fontSize: 14,
                  color: _checked ? AppTheme.textSecondary : AppTheme.textPrimary,
                  decoration: _checked ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const Map<String, String> kCulinaryDictionary = {
  'benmari': 'Benmari: Isıyla doğrudan temas etmesi istenmeyen yiyeceklerin (örneğin çikolata) sıcak su dolu bir kabın içine oturtulan başka bir kapta eritilmesi/pişirilmesi yöntemi.',
  'sotelemek': 'Sotelemek: Az miktarda yağda, yüksek ateşte, sürekli karıştırarak veya sallayarak yiyeceklerin hızlıca pişirilmesi yöntemi.',
  'marine etmek': 'Marine Etmek: Yiyeceklerin (özellikle etlerin) lezzet kazanması ve yumuşaması için baharat, yağ ve asitli sıvılarda bekletilmesi işlemi.',
  'jülyen': 'Jülyen (Julienne): Yiyeceklerin ince, uzun ve kibrit çöpü şeklinde doğranma stili.',
  'mühürlemek': 'Mühürlemek: Etin yüksek ısıda tavada hızlıca dış yüzeyinin pişirilerek suyunun ve lezzetinin içinde kalmasının sağlanması işlemi.',
  'demlemek': 'Demlemek: Pişen yiyeceklerin (pilav, makarna, çay) ocaktan alındıktan sonra kendi buharıyla dinlenmeye bırakılması.',
  'blanş etmek': 'Blanş Etmek (Şoklama): Yiyeceklerin kısa süre kaynar suya batırılıp ardından hemen buzlu suya alınarak renk ve diriliklerinin korunması işlemi.',
  'al dente': 'Al Dente: Makarnanın veya sebzelerin dişe dokunacak sertlikte (çok yumuşatılmadan) pişirilme derecesi.',
  'karamelize': 'Karamelize: Yiyeceklerin (örneğin soğanın) içindeki şekerlerin ısı etkisiyle kahverengiye dönerek tatlımsı bir lezzet kazanması.',
  'meyane': 'Meyane (Roux): Eşit miktarda un ve yağın (genellikle tereyağı) kavrularak sosları koyulaştırmak için hazırlanan karışım.',
};
