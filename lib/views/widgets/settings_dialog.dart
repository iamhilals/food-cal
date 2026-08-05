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

  @override
  void initState() {
    super.initState();
    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
    _apiKeyController = TextEditingController(text: recipeProvider.apiKey);
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
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.borderSlate, width: 1),
      ),
      title: Row(
        children: [
          const Icon(Icons.key_rounded, color: AppTheme.primaryTeal),
          const SizedBox(width: 8),
          Text(
            'API Ayarları',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tarif motorunun çalışması için Google Gemini API anahtarınızı girin.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _apiKeyController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Gemini API Anahtarı',
              hintText: 'AIzaSy...',
              prefixIcon: Icon(Icons.password_rounded),
            ),
          ),
        ],
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
          onPressed: () {
            Provider.of<RecipeProvider>(context, listen: false)
                .setApiKey(_apiKeyController.text);
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Gemini API anahtarı kaydedildi!'),
                backgroundColor: AppTheme.primaryTeal,
              ),
            );
          },
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
}
