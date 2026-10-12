import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/recipe.dart';
import '../models/ingredient.dart';
import '../utils/food_image_provider.dart';
import 'recipe_detail_page.dart';
import 'admin_panel_page.dart';

class RecipeSuggestionsPage extends StatefulWidget {
  const RecipeSuggestionsPage({super.key});

  @override
  State<RecipeSuggestionsPage> createState() => _RecipeSuggestionsPageState();
}

class _RecipeSuggestionsPageState extends State<RecipeSuggestionsPage> {
  String _selectedCategoryFilter = 'Hepsi';
  String _searchQuery = '';

  final List<String> _filters = [
    'Hepsi',
    'Favorilerim ❤️',
    '⚡ 15 Dk Altı',
    '🌱 Vejetaryen',
    '🌾 Glutensiz',
    '🥛 Laktozsuz',
    '🥗 Diyet/Hafif',
    'Kahvaltı',
    'Öğle Yemeği',
    'Akşam Yemeği',
    'Tatlı',
    'İçecek',
  ];

  String _formatAmount(double val) {
    if (val == val.roundToDouble()) {
      return val.round().toString();
    }
    return val.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
  }

  int _getMinExpiryDaysLeft(Recipe recipe, AppState appState) {
    final expiring = appState.getExpiringIngredientsInRecipe(recipe);
    if (expiring.isEmpty) return 999;
    final now = DateTime.now();
    int minDays = 999;
    for (var item in expiring) {
      if (item.expiryDate != null) {
        final days = item.expiryDate!.difference(now).inDays;
        if (days < minDays) minDays = days;
      }
    }
    return minDays;
  }

  bool _matchesDietaryFilter(Recipe r, String filter, AppState appState) {
    if (filter == 'Hepsi') return true;
    if (filter == 'Favorilerim ❤️') {
      return appState.isFavorite(r.id);
    }
    if (filter == '⚡ 15 Dk Altı') {
      return r.durationMinutes <= 15;
    }
    if (filter == '🌱 Vejetaryen') {
      final nonVeg = ['kıyma', 'tavuk', 'et', 'sucuk', 'pastırma', 'balık', 'köfte', 'bonfile', 'kuşbaşı', 'jambon', 'hindi', 'ton balığı'];
      return !r.ingredients.any((i) => nonVeg.any((nv) => i.name.toLowerCase().contains(nv)));
    }
    if (filter == '🌾 Glutensiz') {
      final gluten = ['un', 'makarna', 'bulgur', 'şehriye', 'irmik', 'ekmek', 'yufka', 'galeta', 'bisküvi', 'erişte', 'kadayıf', 'kemalpaşa'];
      return !r.ingredients.any((i) => gluten.any((g) => i.name.toLowerCase().contains(g)));
    }
    if (filter == '🥛 Laktozsuz') {
      final dairy = ['süt', 'yoğurt', 'peynir', 'kaşar', 'tereyağı', 'kaymak', 'krema', 'labne', 'lor'];
      return !r.ingredients.any((i) => dairy.any((d) => i.name.toLowerCase().contains(d)));
    }
    if (filter == '🥗 Diyet/Hafif') {
      final lightKeywords = ['salata', 'çorba', 'fit', 'diyet', 'hafif', 'yoğurtlu', 'sebze'];
      return r.category == 'Salata' || 
             r.category == 'Çorba' || 
             lightKeywords.any((k) => r.name.toLowerCase().contains(k)) ||
             (r.durationMinutes <= 20 && !r.name.toLowerCase().contains('şerbet'));
    }
    return r.category == filter;
  }

  void _showAddCustomRecipeDialog(BuildContext context, AppState appState) {
    final titleCtrl = TextEditingController();
    final durationCtrl = TextEditingController(text: '20');
    final servingsCtrl = TextEditingController(text: '4');
    String selectedCategory = 'Akşam Yemeği';
    String selectedEmoji = '🍲';

    final List<Map<String, TextEditingController>> ingredientControllers = [
      {'name': TextEditingController(), 'amount': TextEditingController(), 'unit': TextEditingController(text: 'adet')},
      {'name': TextEditingController(), 'amount': TextEditingController(), 'unit': TextEditingController(text: 'g')},
    ];

    final List<TextEditingController> instructionControllers = [
      TextEditingController(),
      TextEditingController(),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.85,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.add_circle_outline, color: theme.colorScheme.primary, size: 28),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Kendi Tarifini Ekle',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView(
                        children: [
                          TextField(
                            controller: titleCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Tarif Adı *',
                              hintText: 'Örn: Fırında Sebzeli Tavuk',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  initialValue: selectedCategory,
                                  decoration: const InputDecoration(
                                    labelText: 'Kategori',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: ['Kahvaltı', 'Öğle Yemeği', 'Akşam Yemeği', 'Tatlı', 'İçecek', 'Salata', 'Çorba']
                                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                      .toList(),
                                  onChanged: (v) {
                                    if (v != null) setModalState(() => selectedCategory = v);
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: durationCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Süre (dk)',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: servingsCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Kişilik',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Ingredients list
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(
                                child: Text(
                                  'Malzemeler',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Malzeme Ekle'),
                                onPressed: () {
                                  setModalState(() {
                                    ingredientControllers.add({
                                      'name': TextEditingController(),
                                      'amount': TextEditingController(),
                                      'unit': TextEditingController(text: 'adet'),
                                    });
                                  });
                                },
                              ),
                            ],
                          ),
                          ...ingredientControllers.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final map = entry.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: TextField(
                                      controller: map['name'],
                                      decoration: InputDecoration(
                                        labelText: '${idx + 1}. Malzeme',
                                        isDense: true,
                                        border: const OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    flex: 2,
                                    child: TextField(
                                      controller: map['amount'],
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'Miktar',
                                        isDense: true,
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    flex: 2,
                                    child: TextField(
                                      controller: map['unit'],
                                      decoration: const InputDecoration(
                                        labelText: 'Birim',
                                        isDense: true,
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                  if (ingredientControllers.length > 1)
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle, color: Colors.red, size: 20),
                                      onPressed: () {
                                        setModalState(() {
                                          ingredientControllers.removeAt(idx);
                                        });
                                      },
                                    ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 16),

                          // Steps list
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(
                                child: Text(
                                  'Hazırlanış Adımları',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Adım Ekle'),
                                onPressed: () {
                                  setModalState(() {
                                    instructionControllers.add(TextEditingController());
                                  });
                                },
                              ),
                            ],
                          ),
                          ...instructionControllers.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final ctrl = entry.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: ctrl,
                                      maxLines: 2,
                                      decoration: InputDecoration(
                                        labelText: '${idx + 1}. Adım',
                                        isDense: true,
                                        border: const OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                  if (instructionControllers.length > 1)
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle, color: Colors.red, size: 20),
                                      onPressed: () {
                                        setModalState(() {
                                          instructionControllers.removeAt(idx);
                                        });
                                      },
                                    ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          final name = titleCtrl.text.trim();
                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Lütfen tarif adını giriniz!')),
                            );
                            return;
                          }

                          final ingredients = ingredientControllers
                              .where((m) => m['name']!.text.trim().isNotEmpty)
                              .map((m) {
                            final iName = m['name']!.text.trim();
                            final iAmt = double.tryParse(m['amount']!.text) ?? 1.0;
                            final iUnit = m['unit']!.text.trim().isEmpty ? 'adet' : m['unit']!.text.trim();
                            return Ingredient(name: appState.capitalize(iName), amount: iAmt, unit: iUnit);
                          }).toList();

                          if (ingredients.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Lütfen en az bir malzeme ekleyin!')),
                            );
                            return;
                          }

                          final instructions = instructionControllers
                              .where((c) => c.text.trim().isNotEmpty)
                              .map((c) => c.text.trim())
                              .toList();

                          final newRecipe = Recipe(
                            id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                            name: appState.capitalize(name),
                            category: selectedCategory,
                            durationMinutes: int.tryParse(durationCtrl.text) ?? 20,
                            baseServings: int.tryParse(servingsCtrl.text) ?? 4,
                            emoji: selectedEmoji,
                            ingredients: ingredients,
                            instructions: instructions.isNotEmpty ? instructions : ['Malzemeleri karıştırıp pişirin.'],
                          );

                          appState.addRecipe(newRecipe);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('🎉 "${newRecipe.name}" tarifleriniz arasına eklendi!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        child: const Text('Tarifi Kaydet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);

    // Apply dietary/category filter and search query
    List<Recipe> filteredRecipes = appState.recipes.where((r) {
      return _matchesDietaryFilter(r, _selectedCategoryFilter, appState);
    }).toList();

    if (_searchQuery.isNotEmpty) {
      filteredRecipes = filteredRecipes
          .where((r) => r.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Classify recipes based on matches
    List<RecipeMatchInfo> matchesInfo = filteredRecipes.map((recipe) {
      final missing = appState.getMissingIngredients(recipe, appState.personCount);
      final score = appState.getRecipeMatchScore(recipe, appState.personCount);
      return RecipeMatchInfo(recipe: recipe, score: score, missingIngredients: missing);
    }).toList();

    // Sort: 
    // 1. Recipes with expiring ingredients first (lowest expiry days remaining)
    // 2. Then match score descending
    matchesInfo.sort((a, b) {
      final aExp = _getMinExpiryDaysLeft(a.recipe, appState);
      final bExp = _getMinExpiryDaysLeft(b.recipe, appState);
      if (aExp != bExp) {
        return aExp.compareTo(bExp);
      }
      return b.score.compareTo(a.score);
    });

    // Split into lists based on criteria:
    final fullMatches = matchesInfo.where((mi) => mi.missingIngredients.isEmpty).toList();
    final highCompatMatches = matchesInfo.where((mi) => mi.score >= 0.70 && mi.missingIngredients.isNotEmpty).toList();
    final singleMissingMatches = matchesInfo.where((mi) => mi.missingIngredients.length == 1 && mi.score < 0.70).toList();
    final partialMatches = matchesInfo.where((mi) => mi.missingIngredients.length > 1 && mi.score > 0 && mi.score < 0.70).toList();
    final noMatches = matchesInfo.where((mi) => mi.score <= 0).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ne Pişirebilirim?', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.post_add),
            tooltip: 'Kendi Tarifini Ekle',
            onPressed: () => _showAddCustomRecipeDialog(context, appState),
          ),
          if (appState.currentUser?.role == 'admin' || appState.currentUser?.role == 'content_manager')
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              tooltip: 'Yönetim Paneli',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminPanelPage()),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Çıkış Yap',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Çıkış Yap'),
                    content: const Text('Oturumunuzu kapatmak istediğinize emin misiniz?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('İptal'),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        onPressed: () {
                          Navigator.pop(context);
                          appState.logout();
                        },
                        child: const Text('Çıkış Yap'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Dietary & Category Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            color: theme.colorScheme.surface,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((cat) {
                  bool isSelected = _selectedCategoryFilter == cat;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ChoiceChip(
                      label: Text(
                        cat,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: theme.colorScheme.primary,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedCategoryFilter = cat;
                          });
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Yemek veya tarif ara...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            ),
          ),

          // Search results lists
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                if (fullMatches.isNotEmpty) ...[
                  _buildSectionHeader(context, 'Hemen Yapabileceğin Yemekler 🍳', Colors.green),
                  const SizedBox(height: 8),
                  ...fullMatches.take(20).map((mi) => _buildRecipeCard(context, mi)),
                  const SizedBox(height: 20),
                ],
                if (highCompatMatches.isNotEmpty) ...[
                  _buildSectionHeader(context, 'Yüksek Uyumlu Yemekler (%70+ Uyum) ✨', Colors.teal),
                  const SizedBox(height: 8),
                  ...highCompatMatches.take(20).map((mi) => _buildRecipeCard(context, mi)),
                  const SizedBox(height: 20),
                ],
                if (singleMissingMatches.isNotEmpty) ...[
                  _buildSectionHeader(context, 'Tek Malzemesi Eksik Yemekler 🛒', Colors.deepOrange),
                  const SizedBox(height: 8),
                  ...singleMissingMatches.take(20).map((mi) => _buildRecipeCard(context, mi)),
                  const SizedBox(height: 20),
                ],
                if (partialMatches.isNotEmpty) ...[
                  _buildSectionHeader(context, 'Birkaç Malzemesi Eksik Yemekler 📦', Colors.amber[800]!),
                  const SizedBox(height: 8),
                  ...partialMatches.take(20).map((mi) => _buildRecipeCard(context, mi)),
                  const SizedBox(height: 20),
                ],
                if (noMatches.isNotEmpty && 
                    fullMatches.isEmpty && 
                    highCompatMatches.isEmpty && 
                    singleMissingMatches.isEmpty && 
                    partialMatches.isEmpty) ...[
                  _buildSectionHeader(context, 'Diğer Tarifler 📘', Colors.grey[700]!),
                  const SizedBox(height: 8),
                  ...noMatches.take(20).map((mi) => _buildRecipeCard(context, mi)),
                ],
                if (fullMatches.isEmpty && 
                    highCompatMatches.isEmpty && 
                    singleMissingMatches.isEmpty && 
                    partialMatches.isEmpty && 
                    noMatches.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(Icons.search_off_outlined, size: 60, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          const Text('Bu filtrede veya aramada uygun tarif bulunamadı.'),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tarif Ekle', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _showAddCustomRecipeDialog(context, appState),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildRecipeCard(BuildContext context, RecipeMatchInfo mi) {
    final theme = Theme.of(context);
    final appState = Provider.of<AppState>(context);
    final recipe = mi.recipe;
    final score = mi.score;
    final missingIngredients = mi.missingIngredients;
    final isFav = appState.isFavorite(recipe.id);

    int matchPercent = (score * 100).round();

    // Check if there are expiring ingredients used in this recipe
    final expiringInRecipe = appState.getExpiringIngredientsInRecipe(recipe);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecipeDetailPage(recipe: recipe),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      FoodImageProvider.getRecipeImage(recipe.name),
                      width: 55,
                      height: 55,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 55,
                        height: 55,
                        color: theme.colorScheme.primary.withOpacity(0.08),
                        alignment: Alignment.center,
                        child: Text(
                          recipe.emoji,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  
                  // Text fields
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                recipe.category,
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.schedule, size: 12, color: Colors.grey[600]),
                                const SizedBox(width: 3),
                                Text(
                                  '${recipe.durationMinutes} dk',
                                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          recipe.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Favorite Toggle Button & Score Indicator
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav ? Colors.redAccent : Colors.grey[400],
                          size: 22,
                        ),
                        tooltip: isFav ? 'Favorilerden Çıkar' : 'Favorilere Ekle',
                        onPressed: () {
                          appState.toggleFavorite(recipe.id);
                        },
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: score >= 0.999
                              ? Colors.green.withOpacity(0.12)
                              : score >= 0.70
                                  ? Colors.teal.withOpacity(0.12)
                                  : score > 0.0
                                      ? Colors.amber.withOpacity(0.12)
                                      : Colors.grey.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$matchPercent% Uyum',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: score >= 0.999
                                ? Colors.green[800]
                                : score >= 0.70
                                    ? Colors.teal[800]
                                    : score > 0.0
                                        ? Colors.amber[900]
                                        : Colors.grey[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              // Expiring ingredient warning badge
              if (expiringInRecipe.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.red.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 12),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'SKT Yaklaşan Malzeme İçeriyor: ${expiringInRecipe.map((e) => e.name).join(", ")}',
                          style: TextStyle(fontSize: 10, color: Colors.red[800], fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Missing ingredients helper
              if (missingIngredients.isNotEmpty) ...[
                if (missingIngredients.length == 1) ...[
                  const Divider(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.shopping_cart_outlined, color: Colors.deepOrange, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                            children: [
                              const TextSpan(
                                text: '💡 Bu yemeği sadece ',
                                style: TextStyle(fontStyle: FontStyle.italic),
                              ),
                              TextSpan(
                                text: '${missingIngredients[0].name} (${_formatAmount(missingIngredients[0].amount)} ${missingIngredients[0].unit})',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange),
                              ),
                              const TextSpan(
                                text: ' edinerek yapabilirsiniz!',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const Divider(height: 16),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      children: [
                        const TextSpan(
                          text: 'Eksik malzemeler: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: missingIngredients.map((i) {
                            String amt = _formatAmount(i.amount);
                            return '${i.name} ($amt ${i.unit})';
                          }).join(', '),
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ] else ...[
                const Divider(height: 16),
                const Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.green, size: 14),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Tüm malzemeler kilerinizde hazır!',
                        style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class RecipeMatchInfo {
  final Recipe recipe;
  final double score;
  final List<Ingredient> missingIngredients;

  RecipeMatchInfo({
    required this.recipe,
    required this.score,
    required this.missingIngredients,
  });
}
