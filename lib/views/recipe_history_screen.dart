import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../providers/recipe_provider.dart';
import 'recipe_detail_screen.dart';

class RecipeHistoryScreen extends StatelessWidget {
  const RecipeHistoryScreen({super.key});

  void _showImportDialog(BuildContext context, RecipeProvider recipeProvider) {
    final TextEditingController urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.borderSlate, width: 1.5),
        ),
        title: Row(
          children: const [
            Icon(Icons.cloud_download_rounded, color: AppTheme.primaryTeal),
            SizedBox(width: 8),
            Text('Tarif İçe Aktar'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Yemek tarifi içeren herhangi bir web sayfasının linkini (URL) girin. Sistem sayfayı kazıyarak yapay zekayla tarif defterinize dönüştürecektir.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: urlController,
              keyboardType: TextInputType.url,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'https://ornektarif.com/corba-tarifi',
                prefixIcon: Icon(Icons.link_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('İptal', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final url = urlController.text.trim();
              if (url.isEmpty || !url.startsWith('http')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Lütfen geçerli bir http/https linki girin.'),
                    backgroundColor: AppTheme.errorRed,
                  ),
                );
                return;
              }

              // Close import dialog
              Navigator.pop(dialogContext);

              // Show ETL Pipeline loading overlay
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (loadingContext) => AlertDialog(
                  backgroundColor: AppTheme.darkCard,
                  content: Row(
                    children: [
                      const CircularProgressIndicator(color: AppTheme.primaryTeal),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'ETL Pipeline Çalışıyor...',
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryTeal),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Web sayfası kazınıyor ve tarif dönüştürülüyor...',
                              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );

              try {
                await recipeProvider.importRecipeFromUrl(url);
                
                if (context.mounted) {
                  Navigator.pop(context); // Close loading overlay
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tarif başarıyla içe aktarıldı ve defterinize yüklendi! (ETL Tamamlandı)'),
                      backgroundColor: AppTheme.primaryTeal,
                    ),
                  );

                  // Open imported recipe detail view
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RecipeDetailScreen()),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context); // Close loading overlay
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: AppTheme.darkCard,
                      title: const Text('İçe Aktarma Hatası'),
                      content: Text('Sayfa dönüştürülürken bir hata oluştu: $e'),
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
            },
            child: const Text('Aktar'),
          ),
        ],
      ),
    );
  }

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
      body: Column(
        children: [
          // URL Importer Card (ETL Pipeline Button)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Card(
              color: AppTheme.darkCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppTheme.borderSlate, width: 1.5),
              ),
              child: InkWell(
                onTap: () => _showImportDialog(context, recipeProvider),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryTeal.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.cloud_download_rounded, color: AppTheme.primaryTeal),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'İnternetten Tarif İçe Aktar (ETL)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Yemek tarifi linkini yapıştırarak defterine ekle',
                              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Haftalık Menü Planı Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Card(
              color: AppTheme.darkCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppTheme.borderSlate, width: 1.2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Haftalık Yemek Planım 📅',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
                        ),
                        if (recipeProvider.weeklyPlan.values.any((r) => r != null))
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.primaryTeal,
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            icon: const Icon(Icons.shopping_cart_checkout_rounded, size: 16),
                            label: const Text('Malzemeleri Sepete Ekle', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            onPressed: () async {
                              await recipeProvider.addWeeklyIngredientsToShoppingList();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Haftalık plandaki malzemeler akıllıca birleştirilerek Marketim listesine eklendi!'),
                                    backgroundColor: AppTheme.primaryTeal,
                                  ),
                                );
                              }
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: recipeProvider.weeklyPlan.entries.map((entry) {
                          final day = entry.key;
                          final recipe = entry.value;
                          final shortDay = day.substring(0, 3);

                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Stack(
                              children: [
                                InkWell(
                                  onTap: () {
                                    if (recipe != null) {
                                      recipeProvider.setRecipe(recipe);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const RecipeDetailScreen()),
                                      );
                                    } else {
                                      _showSelectRecipeForDayDialog(context, recipeProvider, day);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    width: 75,
                                    height: 75,
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                    decoration: BoxDecoration(
                                      color: recipe != null 
                                          ? AppTheme.primaryTeal.withValues(alpha: 0.08)
                                          : AppTheme.darkBg,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: recipe != null ? AppTheme.primaryTeal : AppTheme.borderSlate,
                                        width: recipe != null ? 1.5 : 1.0,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          shortDay,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: recipe != null ? AppTheme.primaryTeal : AppTheme.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        if (recipe == null)
                                          const Icon(
                                            Icons.add_circle_outline_rounded,
                                            color: AppTheme.textSecondary,
                                            size: 20,
                                          )
                                        else
                                          Expanded(
                                            child: Center(
                                              child: Text(
                                                recipe.name,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme.textPrimary,
                                                  height: 1.2,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (recipe != null)
                                  Positioned(
                                    right: 4,
                                    top: 4,
                                    child: GestureDetector(
                                      onTap: () {
                                        recipeProvider.removeRecipeFromWeeklyPlan(day);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: AppTheme.errorRed,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close_rounded,
                                          color: Colors.white,
                                          size: 8,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // History list
          Expanded(
            child: history.isEmpty
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
                            'Dolabınızdan malzemeleri seçip ilk lezzetli tarifinizi oluşturun veya yukarıdan link ile ekleyin!',
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
          ),
        ],
      ),
    );
  }

  void _showSelectRecipeForDayDialog(BuildContext context, RecipeProvider recipeProvider, String day) {
    final history = recipeProvider.history;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.borderSlate, width: 1.2),
        ),
        title: Text('$day İçin Tarif Seç'),
        content: history.isEmpty
            ? const Text(
                'Defterinizde henüz kayıtlı tarif bulunmuyor. Önce dolabınızdan tarif üretin veya link ile tarif ekleyin!',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              )
            : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final recipe = history[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.restaurant_menu_rounded, color: AppTheme.primaryTeal),
                      title: Text(
                        recipe.name,
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                      ),
                      onTap: () {
                        recipeProvider.addRecipeToWeeklyPlan(day, recipe);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat', style: TextStyle(color: AppTheme.textSecondary)),
          ),
        ],
      ),
    );
  }
}
