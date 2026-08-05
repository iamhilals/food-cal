import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/recipe_provider.dart';
import '../../core/theme/app_theme.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late TextEditingController _apiKeyController;
  String _selectedDiet = '';
  final List<String> _selectedAllergens = [];

  final List<String> _diets = ['Yok', 'Vegan', 'Vejetaryen', 'Glutensiz', 'Keto'];
  final List<String> _allergenOptions = ['Gluten', 'Laktoz', 'Kuruyemiş', 'Deniz Ürünleri', 'Yumurta'];

  @override
  void initState() {
    super.initState();
    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
    _apiKeyController = TextEditingController(text: recipeProvider.apiKey);
    _selectedDiet = recipeProvider.dietProfile.isEmpty ? 'Yok' : recipeProvider.dietProfile;
    _selectedAllergens.addAll(recipeProvider.allergens);
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.darkCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppTheme.borderSlate, width: 1.5),
      ),
      title: Row(
        children: [
          const Icon(Icons.settings_rounded, color: AppTheme.primaryTeal),
          const SizedBox(width: 8),
          Text(
            'Profil & Diyet Ayarları',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20),
          ),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // API KEY Section
              Text(
                'Gemini API Anahtarı',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryTeal, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _apiKeyController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Gemini API Key',
                  hintText: 'AIzaSy...',
                  prefixIcon: Icon(Icons.key_rounded),
                ),
              ),
              const SizedBox(height: 20),

              // DIET PROFILE Section
              Text(
                'Diyet Tercihi',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryTeal, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: _diets.map((diet) {
                  final isSelected = _selectedDiet == diet;
                  return ChoiceChip(
                    label: Text(diet),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedDiet = diet;
                        });
                      }
                    },
                    selectedColor: AppTheme.primaryTeal.withValues(alpha: 0.2),
                    checkmarkColor: AppTheme.primaryTeal,
                    labelStyle: TextStyle(
                      color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // ALLERGENS Section
              Text(
                'Alerjenler (Uzak Durulacaklar)',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryTeal, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: _allergenOptions.map((allergen) {
                  final isSelected = _selectedAllergens.contains(allergen);
                  return FilterChip(
                    label: Text(allergen),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedAllergens.add(allergen);
                        } else {
                          _selectedAllergens.remove(allergen);
                        }
                      });
                    },
                    selectedColor: AppTheme.errorRed.withValues(alpha: 0.15),
                    checkmarkColor: AppTheme.errorRed,
                    labelStyle: TextStyle(
                      color: isSelected ? AppTheme.errorRed : AppTheme.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: isSelected ? AppTheme.errorRed : AppTheme.borderSlate),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'İptal',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
            final navigator = Navigator.of(context);
            final scaffoldMessenger = ScaffoldMessenger.of(context);

            await recipeProvider.setApiKey(_apiKeyController.text);
            await recipeProvider.setDietProfile(_selectedDiet == 'Yok' ? '' : _selectedDiet);
            await recipeProvider.setAllergens(_selectedAllergens);

            if (mounted) {
              navigator.pop();
              scaffoldMessenger.showSnackBar(
                const SnackBar(
                  content: Text('Profil ayarları başarıyla güncellendi!'),
                  backgroundColor: AppTheme.primaryTeal,
                ),
              );
            }
          },
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
}
