import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../providers/recipe_provider.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _SettingsManualAddDialog extends StatefulWidget {
  final Function(String) onAdd;
  const _SettingsManualAddDialog({required this.onAdd});

  @override
  State<_SettingsManualAddDialog> createState() => _SettingsManualAddDialogState();
}

class _SettingsManualAddDialogState extends State<_SettingsManualAddDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.darkCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.borderSlate, width: 1.5),
      ),
      title: const Text('Ürün Ekle'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          hintText: 'Örn: Yoğurt, Süt...',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal', style: TextStyle(color: AppTheme.textSecondary)),
        ),
        ElevatedButton(
          onPressed: () {
            final text = _controller.text.trim();
            if (text.isNotEmpty) {
              widget.onAdd(text);
            }
            Navigator.pop(context);
          },
          child: const Text('Ekle'),
        ),
      ],
    );
  }
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final Set<String> _purchasedItems = {};

  String _categorizeItem(String item) {
    final lower = item.toLowerCase();
    
    // Manav
    if (lower.contains('domates') ||
        lower.contains('biber') ||
        lower.contains('soğan') ||
        lower.contains('sarımsak') ||
        lower.contains('patates') ||
        lower.contains('maydanoz') ||
        lower.contains('limon') ||
        lower.contains('havuç') ||
        lower.contains('ıspanak') ||
        lower.contains('salatalık') ||
        lower.contains('marul') ||
        lower.contains('dereotu') ||
        lower.contains('nane') ||
        lower.contains('patlıcan') ||
        lower.contains('kabak') ||
        lower.contains('elma') ||
        lower.contains('portakal') ||
        lower.contains('muz') ||
        lower.contains('çilek') ||
        lower.contains('sebze') ||
        lower.contains('meyve')) {
      return 'Manav 🍎';
    }
    
    // Süt Ürünleri
    if (lower.contains('süt') ||
        lower.contains('peynir') ||
        lower.contains('tereyağı') ||
        lower.contains('yoğurt') ||
        lower.contains('krema') ||
        lower.contains('kaşar') ||
        lower.contains('lor') ||
        lower.contains('kaymak') ||
        lower.contains('ayran')) {
      return 'Süt Ürünleri 🥛';
    }
    
    // Kasap & Şarküteri
    if (lower.contains('tavuk') ||
        lower.contains('et') ||
        lower.contains('kıyma') ||
        lower.contains('balık') ||
        lower.contains('salam') ||
        lower.contains('sosis') ||
        lower.contains('pastırma') ||
        lower.contains('hindi') ||
        lower.contains('bonfile') ||
        lower.contains('pirzola') ||
        lower.contains('kavurma') ||
        lower.contains('köfte')) {
      return 'Kasap & Şarküteri 🥩';
    }
    
    // Kuru Gıda & Baharat
    if (lower.contains('un') ||
        lower.contains('şeker') ||
        lower.contains('tuz') ||
        lower.contains('yağ') ||
        lower.contains('pirinç') ||
        lower.contains('makarna') ||
        lower.contains('salça') ||
        lower.contains('pul biber') ||
        lower.contains('karabiber') ||
        lower.contains('kekik') ||
        lower.contains('kimyon') ||
        lower.contains('karbonat') ||
        lower.contains('kabartma') ||
        lower.contains('sirke') ||
        lower.contains('bulgur') ||
        lower.contains('mercimek') ||
        lower.contains('nohut') ||
        lower.contains('fasulye') ||
        lower.contains('sos')) {
      return 'Kuru Gıda & Baharat 🌾';
    }
    
    return 'Diğer Malzemeler 🛒';
  }

  @override
  Widget build(BuildContext context) {
    final recipeProvider = Provider.of<RecipeProvider>(context);
    final shoppingList = recipeProvider.shoppingList;

    // Grouping shopping list
    final Map<String, List<String>> categorizedItems = {};
    for (final item in shoppingList) {
      final category = _categorizeItem(item);
      categorizedItems.putIfAbsent(category, () => []).add(item);
    }
    
    // Sort categories consistently
    final sortedCategories = categorizedItems.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Marketim',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              'Alışveriş Listem',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ],
        ),
        actions: [
          if (shoppingList.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: AppTheme.errorRed),
              tooltip: 'Listeyi Temizle',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: AppTheme.darkCard,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppTheme.borderSlate),
                    ),
                    title: const Text('Listeyi Temizle'),
                    content: const Text('Alışveriş listenizdeki tüm ürünleri silmek istediğinize emin misiniz?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('İptal', style: TextStyle(color: AppTheme.textSecondary)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
                        onPressed: () {
                          recipeProvider.clearShoppingList();
                          setState(() {
                            _purchasedItems.clear();
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Temizle'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: shoppingList.isEmpty
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
                        Icons.shopping_basket_rounded,
                        color: AppTheme.primaryTeal,
                        size: 64,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Alışveriş Listeniz Boş',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tarif detaylarında eksik olan malzemeleri sepetinize ekleyebilir veya alttaki butondan manuel ürün ekleyebilirsiniz.',
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
              itemCount: sortedCategories.length,
              itemBuilder: (context, catIndex) {
                final category = sortedCategories[catIndex];
                final items = categorizedItems[category] ?? [];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Header
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryTeal.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.primaryTeal.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              category,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryTeal,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              height: 1,
                              color: AppTheme.borderSlate,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Category items list
                    ...items.map((item) {
                      final isPurchased = _purchasedItems.contains(item.toLowerCase());
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: CheckboxListTile(
                          value: isPurchased,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _purchasedItems.add(item.toLowerCase());
                              } else {
                                _purchasedItems.remove(item.toLowerCase());
                              }
                            });
                          },
                          title: Text(
                            item,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              decoration: isPurchased ? TextDecoration.lineThrough : null,
                              color: isPurchased ? AppTheme.textSecondary : AppTheme.textPrimary,
                            ),
                          ),
                          activeColor: AppTheme.primaryTeal,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          controlAffinity: ListTileControlAffinity.leading,
                          secondary: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.errorRed),
                            onPressed: () {
                              recipeProvider.removeIngredientFromShoppingList(item);
                              setState(() {
                                _purchasedItems.remove(item.toLowerCase());
                              });
                            },
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => _SettingsManualAddDialog(
              onAdd: (newItem) {
                recipeProvider.addIngredientsToShoppingList([newItem]);
              },
            ),
          );
        },
        backgroundColor: AppTheme.primaryTeal,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }
}
