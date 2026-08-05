import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../providers/ingredient_provider.dart';
import '../providers/recipe_provider.dart';
import 'recipe_detail_screen.dart';
import 'widgets/settings_dialog.dart';
import 'barcode_scanner_screen.dart';

class IngredientSelectionScreen extends StatefulWidget {
  const IngredientSelectionScreen({super.key});

  @override
  State<IngredientSelectionScreen> createState() => _IngredientSelectionScreenState();
}

class _IngredientSelectionScreenState extends State<IngredientSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _newIngredientController = TextEditingController();
  Timer? _debounceTimer;
  final Set<String> _collapsedCategories = {};
  final Set<String> _activeCategorySearches = {};
  final Map<String, String> _categorySearchQueries = {};

  @override
  void dispose() {
    _searchController.dispose();
    _newIngredientController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }
  Future<void> _detectIngredientsFromPhoto() async {
    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
    final ingProvider = Provider.of<IngredientProvider>(context, listen: false);

    if (!recipeProvider.hasApiKey) {
      showDialog(
        context: context,
        builder: (context) => const SettingsDialog(),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fotoğraf tespiti için lütfen önce API anahtarınızı girin.'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    final List<XFile> pickedFiles = [];
    final picker = ImagePicker();

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded, color: AppTheme.primaryTeal),
              title: const Text('Kameradan Fotoğraf Çek'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppTheme.primaryTeal),
              title: const Text('Galeriden Çoklu Görsel Seç'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      if (source == ImageSource.gallery) {
        final List<XFile> images = await picker.pickMultiImage(
          imageQuality: 60,
          maxWidth: 1024,
        );
        if (images.isNotEmpty) {
          pickedFiles.addAll(images);
        }
      } else {
        bool addMore = true;
        while (addMore) {
          final XFile? file = await picker.pickImage(
            source: ImageSource.camera,
            imageQuality: 60,
            maxWidth: 1024,
          );
          if (file != null) {
            pickedFiles.add(file);
            
            if (!mounted) break;
            final bool? choice = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: AppTheme.darkCard,
                title: const Text('Fotoğraf Eklendi'),
                content: Text('Şu an ${pickedFiles.length} adet fotoğraf seçildi. Başka bir fotoğraf çekmek ister misiniz?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Analiz Et', style: TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.bold)),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Yeni Çek'),
                  ),
                ],
              ),
            );
            addMore = choice == true;
          } else {
            addMore = false;
          }
        }
      }

      if (pickedFiles.isEmpty) return;

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.darkCard,
          content: Row(
            children: [
              const CircularProgressIndicator(color: AppTheme.primaryTeal),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  '${pickedFiles.length} görsel analiz ediliyor...',
                  style: const TextStyle(color: AppTheme.textPrimary),
                ),
              ),
            ],
          ),
        ),
      );

      final List<String> base64Images = [];
      for (final file in pickedFiles) {
        final bytes = await file.readAsBytes();
        base64Images.add(base64Encode(bytes));
      }

      await ingProvider.detectAndAddIngredients(base64Images, recipeProvider.apiKey);

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${pickedFiles.length} görseldeki tüm malzemeler başarıyla tespit edildi!'),
            backgroundColor: AppTheme.primaryTeal,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.darkCard,
            title: const Text('Hata'),
            content: Text('Malzemeler tespit edilirken bir hata oluştu: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tamam'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _scanBarcode() async {
    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
    );

    if (barcode == null || barcode.isEmpty) return;

    if (!mounted) return;

    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
    final ingProvider = Provider.of<IngredientProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        content: Row(
          children: [
            const CircularProgressIndicator(color: AppTheme.primaryTeal),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                'Barkod sorgulanıyor...',
                style: TextStyle(color: AppTheme.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );

    try {
      final String apiKey = recipeProvider.apiKey;
      final productName = await ingProvider.resolveBarcode(barcode, apiKey);

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (productName != null && productName.isNotEmpty) {
        ingProvider.addAndSelectIngredients([productName]);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"$productName" başarıyla eklendi ve seçildi!'),
            backgroundColor: AppTheme.primaryTeal,
          ),
        );
      } else {
        _showManualProductAddDialog(barcode);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Barkod sorgulanırken hata oluştu: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  void _showManualProductAddDialog(String barcode) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.borderSlate),
        ),
        title: const Text('Ürün Bulunamadı'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Girdiğiniz barkod Open Food Facts üzerinde bulunamadı. Lütfen ürün ismini kendiniz girin:'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Örn: Krem Peynir',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                Provider.of<IngredientProvider>(context, listen: false).addAndSelectIngredients([text]);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('"$text" başarıyla eklendi ve seçildi!'),
                    backgroundColor: AppTheme.primaryTeal,
                  ),
                );
              }
              Navigator.pop(context);
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  void _onNewIngredientChanged(String text) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        Provider.of<IngredientProvider>(context, listen: false).fetchSuggestions(text);
      }
    });
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => const SettingsDialog(),
    );
  }

  void _addNewIngredient() async {
    final name = _newIngredientController.text.trim();
    if (name.isEmpty) return;

    final provider = Provider.of<IngredientProvider>(context, listen: false);
    provider.clearSuggestions();
    _newIngredientController.clear();
    FocusScope.of(context).unfocus();

    final success = await provider.addCustomIngredient(name);
    if (!success && mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.darkCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.errorRed, width: 1.5),
          ),
          title: Row(
            children: const [
              Icon(Icons.error_outline_rounded, color: AppTheme.errorRed, size: 28),
              SizedBox(width: 8),
              Text('Doğrulanamadı'),
            ],
          ),
          content: Text(
            provider.validationError ?? 'Girdiğiniz kelime bir gıda/besin maddesi olarak doğrulanamadı. Lütfen geçerli bir besin ismi girdiğinizden emin olun.',
            style: const TextStyle(height: 1.4),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
              onPressed: () {
                provider.clearValidationError();
                Navigator.of(context).pop();
              },
              child: const Text('Tamam'),
            ),
          ],
        ),
      );
    } else if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"$name" doğrulandı ve seçildi!'),
          backgroundColor: AppTheme.accentEmerald,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Smart Ingredients',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              'Dolaptaki Malzemeleri Seçin',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: AppTheme.textSecondary),
            onPressed: _showSettings,
          ),
        ],
      ),
      body: Consumer<IngredientProvider>(
        builder: (context, provider, child) {
          return Stack(
            children: [
              Column(
                children: [
                  const UserProfileCard(),
                  // Search Bar and Add Custom section
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Search bar
                        TextField(
                          controller: _searchController,
                          onChanged: provider.setSearchQuery,
                          decoration: InputDecoration(
                            hintText: 'Malzeme ara...',
                            prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, color: AppTheme.textSecondary),
                                    onPressed: () {
                                      _searchController.clear();
                                      provider.setSearchQuery('');
                                    },
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.photo_camera_rounded, color: AppTheme.primaryTeal),
                                        onPressed: _detectIngredientsFromPhoto,
                                        tooltip: 'Fotoğraf ile Malzeme Tespiti',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.qr_code_scanner_rounded, color: AppTheme.primaryTeal),
                                        onPressed: _scanBarcode,
                                        tooltip: 'Barkod Tarayıcı',
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Add custom section
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _newIngredientController,
                                onChanged: _onNewIngredientChanged,
                                decoration: const InputDecoration(
                                  hintText: 'Yeni besin ekle (Örn: Chia Tohumu)',
                                  prefixIcon: Icon(Icons.add_rounded, color: AppTheme.textSecondary),
                                ),
                                onSubmitted: (_) => _addNewIngredient(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _addNewIngredient,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  backgroundColor: AppTheme.secondaryIndigo,
                                ),
                                child: const Icon(Icons.check_rounded),
                              ),
                            ),
                          ],
                        ),
                        if (provider.isLoadingSuggestions)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryTeal),
                              ),
                            ),
                          )
                        else if (provider.suggestions.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.darkCard,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.borderSlate),
                            ),
                            constraints: const BoxConstraints(maxHeight: 200),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: provider.suggestions.length,
                              itemBuilder: (context, index) {
                                final suggestion = provider.suggestions[index];
                                return ListTile(
                                  title: Text(suggestion),
                                  leading: const Icon(Icons.search_rounded, size: 18),
                                  dense: true,
                                  onTap: () {
                                    _newIngredientController.text = suggestion;
                                    provider.clearSuggestions();
                                  },
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Selected Ingredients Basket (Basket/Bucket)
                  Consumer<IngredientProvider>(
                    builder: (context, provider, child) {
                      final selectedIngs = provider.ingredients.where((item) => item.isSelected).toList();
                      if (selectedIngs.isEmpty) return const SizedBox.shrink();

                      return Container(
                        height: 52,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: selectedIngs.length,
                          itemBuilder: (context, index) {
                            final ing = selectedIngs[index];
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: InputChip(
                                label: Text(ing.name),
                                onDeleted: () => provider.toggleIngredient(ing.id),
                                deleteIconColor: AppTheme.errorRed,
                                backgroundColor: AppTheme.primaryTeal.withValues(alpha: 0.1),
                                labelStyle: const TextStyle(
                                  color: AppTheme.primaryTeal,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(color: AppTheme.primaryTeal, width: 1.2),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),

                  // Categories and Ingredients List
                  Expanded(
                    child: provider.filteredIngredients.isEmpty
                        ? Center(
                            child: Text(
                              'Malzeme bulunamadı.',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                            itemCount: provider.categories.length,
                            itemBuilder: (context, index) {
                              final category = provider.categories[index];
                              var categoryIngredients = provider.getIngredientsByCategory(category);
                              
                              final isSearchActive = _activeCategorySearches.contains(category);
                              final catQuery = _categorySearchQueries[category];
                              
                              if (isSearchActive && catQuery != null && catQuery.trim().isNotEmpty) {
                                categoryIngredients = categoryIngredients
                                    .where((ing) => ing.name.toLowerCase().contains(catQuery.trim().toLowerCase()))
                                    .toList();
                              }

                              final isCollapsed = _collapsedCategories.contains(category);

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: InkWell(
                                            onTap: () {
                                              setState(() {
                                                if (isCollapsed) {
                                                  _collapsedCategories.remove(category);
                                                } else {
                                                  _collapsedCategories.add(category);
                                                }
                                              });
                                            },
                                            borderRadius: BorderRadius.circular(10),
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                              child: Row(
                                                children: [
                                                  Text(
                                                    _getCategoryEmoji(category),
                                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                          color: AppTheme.primaryTeal,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Icon(
                                                    isCollapsed
                                                        ? Icons.keyboard_arrow_down_rounded
                                                        : Icons.keyboard_arrow_up_rounded,
                                                    color: AppTheme.primaryTeal,
                                                    size: 20,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            isSearchActive ? Icons.search_off_rounded : Icons.search_rounded,
                                            color: AppTheme.primaryTeal,
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              if (isSearchActive) {
                                                _activeCategorySearches.remove(category);
                                                _categorySearchQueries.remove(category);
                                              } else {
                                                _activeCategorySearches.add(category);
                                                _collapsedCategories.remove(category); // Expand on search
                                              }
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSearchActive) ...[
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                                      child: TextField(
                                        style: const TextStyle(fontSize: 14),
                                        decoration: InputDecoration(
                                          hintText: '$category içinde ara...',
                                          prefixIcon: const Icon(Icons.search_rounded, size: 16, color: AppTheme.textSecondary),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          fillColor: AppTheme.darkBg,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: const BorderSide(color: AppTheme.borderSlate),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: const BorderSide(color: AppTheme.borderSlate),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: const BorderSide(color: AppTheme.primaryTeal),
                                          ),
                                        ),
                                        onChanged: (val) {
                                          setState(() {
                                            _categorySearchQueries[category] = val;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                  if (!isCollapsed) ...[
                                    const SizedBox(height: 8),
                                    categoryIngredients.isEmpty
                                        ? const Padding(
                                            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                            child: Text(
                                              'Aramayla eşleşen malzeme bulunamadı.',
                                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontStyle: FontStyle.italic),
                                            ),
                                          )
                                        : Wrap(
                                            spacing: 8.0,
                                            runSpacing: 8.0,
                                            children: categoryIngredients.map((ing) {
                                              return FilterChip(
                                                label: Text(ing.name),
                                                selected: ing.isSelected,
                                                onSelected: (_) => provider.toggleIngredient(ing.id),
                                                backgroundColor: AppTheme.darkCard,
                                                selectedColor: AppTheme.primaryTeal.withValues(alpha: 0.2),
                                                checkmarkColor: AppTheme.primaryTeal,
                                                labelStyle: TextStyle(
                                                  color: ing.isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                                                  fontWeight: ing.isSelected ? FontWeight.bold : FontWeight.normal,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                  side: BorderSide(
                                                    color: ing.isSelected ? AppTheme.primaryTeal : AppTheme.borderSlate,
                                                    width: ing.isSelected ? 1.5 : 1.0,
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                    const SizedBox(height: 16),
                                  ],
                                ],
                              );
                            },
                          ),
                  ),
                ],
              ),

              // Loading Validation screen overlay
              if (provider.isValidating)
                Container(
                  color: Colors.black.withValues(alpha: 0.6),
                  child: const Center(
                    child: Card(
                      color: AppTheme.darkCard,
                      margin: EdgeInsets.symmetric(horizontal: 40),
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SpinKitDoubleBounce(color: AppTheme.primaryTeal, size: 50),
                            SizedBox(height: 16),
                            Text(
                              'Besin API üzerinden doğrulanıyor...',
                              style: TextStyle(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: Consumer2<IngredientProvider, RecipeProvider>(
        builder: (context, ingProvider, recipeProvider, child) {
          final selectedCount = ingProvider.selectedIngredientNames.length;
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppTheme.darkCard,
              border: Border(
                top: BorderSide(color: AppTheme.borderSlate, width: 1),
              ),
            ),
            child: SafeArea(
              child: ElevatedButton(
                onPressed: selectedCount == 0
                    ? null
                    : () {
                        if (!recipeProvider.hasApiKey) {
                          _showSettings();
                        } else {
                          recipeProvider.generateRecipe(ingProvider.selectedIngredientNames);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const RecipeDetailScreen(),
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppTheme.primaryTeal,
                  disabledBackgroundColor: AppTheme.borderSlate,
                ),
                child: Text(
                  selectedCount == 0
                      ? 'Malzeme Seçin'
                      : 'Tarif Oluştur ($selectedCount Malzeme)',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _getCategoryEmoji(String category) {
    switch (category) {
      case 'Sebzeler':
        return '🥦 Sebzeler';
      case 'Bakliyatlar':
        return '🌾 Bakliyatlar';
      case 'Et & Balık Ürünleri':
        return '🥩 Et & Balık Ürünleri';
      case 'Süt Ürünleri':
        return '🥛 Süt Ürünleri';
      case 'Diğer':
        return '🥚 Diğer';
      default:
        return '🛒 $category';
    }
  }
}

class UserProfileCard extends StatefulWidget {
  const UserProfileCard({super.key});

  @override
  State<UserProfileCard> createState() => _UserProfileCardState();
}

class _UserProfileCardState extends State<UserProfileCard> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recipeProvider = Provider.of<RecipeProvider>(context);

    if (recipeProvider.hasUserName) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderSlate),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.primaryTeal.withValues(alpha: 0.1),
              child: const Text('👨‍🍳', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hoş geldin, Şef ${recipeProvider.userName}!',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const Text(
                    'Bugün hangi lezzeti tasarlıyoruz?',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_rounded, size: 18, color: AppTheme.textSecondary),
              onPressed: () => _showNameEditDialog(context, recipeProvider),
            )
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryTeal.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryTeal.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: const [
              Text('👨‍🍳', style: TextStyle(fontSize: 24)),
              SizedBox(width: 8),
              Text(
                'Mutfak Karşılaması',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Yemek serüvenine başlamak için şef adınızı girin:',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'Şef Adınız...',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  textCapitalization: TextCapitalization.words,
                  onSubmitted: (_) => _saveName(recipeProvider),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () => _saveName(recipeProvider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryTeal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Giriş'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _saveName(RecipeProvider provider) {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      provider.setUserName(name);
    }
  }

  void _showNameEditDialog(BuildContext context, RecipeProvider provider) {
    final controller = TextEditingController(text: provider.userName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.borderSlate),
        ),
        title: const Text('Şef Adını Düzenle'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Şef Adınız...'),
          textCapitalization: TextCapitalization.words,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                provider.setUserName(name);
              }
              Navigator.of(context).pop();
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }
}

