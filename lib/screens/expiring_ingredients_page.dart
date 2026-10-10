import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../utils/food_image_provider.dart';
import 'recipe_detail_page.dart';

class ExpiringIngredientsPage extends StatelessWidget {
  const ExpiringIngredientsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);
    final expiringItems = appState.getExpiringPantryIngredients();

    String formatAmount(double val) {
      if (val == val.roundToDouble()) {
        return val.round().toString();
      }
      return val.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('SKT Yaklaşan Malzemeler', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: expiringItems.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline, size: 80, color: Colors.green[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Harika! SKT Yaklaşan Malzeme Yok',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Kilerinizdeki tüm malzemelerin son kullanma tarihleri güvende.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Aşağıdaki malzemelerin son kullanma tarihi (SKT) geçmek üzere. Bozulmadan önce tüketebileceğiniz yemek önerileri listelenmiştir:',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                ...expiringItems.map((item) {
                  // Find recipes containing this ingredient
                  final matchingRecipes = appState.recipes.where((recipe) {
                    return recipe.ingredients.any(
                      (ri) => ri.name.trim().toLowerCase() == item.name.trim().toLowerCase()
                    );
                  }).toList();

                  // Sort by compatibility score descending
                  matchingRecipes.sort((a, b) => appState.getRecipeMatchScore(b, appState.personCount).compareTo(appState.getRecipeMatchScore(a, appState.personCount)));

                  final now = DateTime.now();
                  final daysLeft = item.expiryDate!.difference(now).inDays;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.red.withOpacity(0.2), width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header for expiring ingredient
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  FoodImageProvider.getIngredientImage(item.name),
                                  width: 45,
                                  height: 45,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    width: 45,
                                    height: 45,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.kitchen, color: Colors.grey),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Kalan Stok: ${formatAmount(item.amount)} ${item.unit}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  daysLeft <= 0
                                      ? 'Bugün Son!'
                                      : 'Son $daysLeft Gün',
                                  style: TextStyle(
                                    color: Colors.red[700],
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          
                          // Suggested Recipes using this item
                          Text(
                            'Bu Malzemeyi Eritmek İçin Yemek Önerileri:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          matchingRecipes.isEmpty
                              ? const Text(
                                  'Bu malzemeyi içeren kayıtlı bir tarif bulunamadı.',
                                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
                                )
                              : SizedBox(
                                  height: 130,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: matchingRecipes.length,
                                    itemBuilder: (context, rIndex) {
                                      final recipe = matchingRecipes[rIndex];
                                      final score = appState.getRecipeMatchScore(recipe, appState.personCount);
                                      final missing = appState.getMissingIngredients(recipe, appState.personCount);

                                      return Container(
                                        width: 140,
                                        margin: const EdgeInsets.only(right: 10),
                                        child: Card(
                                          elevation: 1,
                                          color: Colors.grey[50],
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
                                              padding: const EdgeInsets.all(8.0),
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(recipe.emoji, style: const TextStyle(fontSize: 24)),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    recipe.name,
                                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    score >= 0.999
                                                        ? 'Uyum: %100'
                                                        : 'Eksik: ${missing.length}',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: score >= 0.999 ? Colors.green[700] : Colors.amber[800],
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}
