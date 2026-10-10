import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/recipe.dart';
import 'recipe_detail_page.dart';
import 'admin_panel_page.dart';

class MealPlannerPage extends StatelessWidget {
  const MealPlannerPage({super.key});

  void _showSelectRecipeSheet(BuildContext context, String day, String category) {
    final appState = Provider.of<AppState>(context, listen: false);
    final theme = Theme.of(context);
    
    // Filter recipes for this category
    final categoryRecipes = appState.recipes
        .where((r) => r.category == category)
        .toList();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$day - $category Seçimi',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              categoryRecipes.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: Text('Bu kategoriye uygun tarif bulunamadı.')),
                    )
                  : Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: categoryRecipes.length,
                        itemBuilder: (context, index) {
                          final recipe = categoryRecipes[index];
                          final matchScore = appState.getRecipeMatchScore(recipe, appState.personCount);
                          final isCookable = matchScore >= 0.999;

                          return ListTile(
                            leading: Text(recipe.emoji, style: const TextStyle(fontSize: 24)),
                            title: Text(recipe.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${recipe.durationMinutes} dk | %${(matchScore * 100).round()} Uyum'),
                            trailing: isCookable
                                ? const Icon(Icons.check_circle_outline, color: Colors.green)
                                : const Icon(Icons.warning_amber_rounded, color: Colors.amber),
                            onTap: () {
                              appState.planMeal(day, category, recipe);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
              const SizedBox(height: 8),
              // Clear option
              ListTile(
                leading: const Icon(Icons.clear, color: Colors.red),
                title: const Text('Yemeği Kaldır', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                onTap: () {
                  appState.planMeal(day, category, null);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSmartSuggestionsBanner(BuildContext context, AppState appState) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withOpacity(0.95),
              theme.colorScheme.secondary.withOpacity(0.95),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.white, size: 24),
                SizedBox(width: 8),
                Text(
                  'Haftalık Akıllı Plan Önerisi',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Evdeki malzemelerinize göre (en az %70 uyumlu tarifler öncelikli) tüm haftayı besin dengesine uygun olarak otomatik planlayalım mı?',
              style: TextStyle(color: Colors.white, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: theme.colorScheme.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.auto_awesome),
                label: const Text(
                  'Haftayı Benim İçin Planla',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  appState.generateSmartWeeklyPlan();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Evdeki stoklarınıza göre haftalık yemek planınız otomatik oluşturuldu!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Haftalık Yemek Planı', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Haftayı Temizle',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Planı Temizle?'),
                  content: const Text('Tüm haftalık yemek planını sıfırlamak istediğinize emin misiniz?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('İptal'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                      onPressed: () {
                        appState.clearWeeklyPlan();
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Haftalık yemek planı temizlendi.')),
                        );
                      },
                      child: const Text('Temizle'),
                    ),
                  ],
                ),
              );
            },
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
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // Auto Planner Card
          _buildSmartSuggestionsBanner(context, appState),
          const SizedBox(height: 8),

          // Weekly plan days
          ...appState.weeklyPlan.map((dayPlan) {
            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Day Title
                    Text(
                      dayPlan.day,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const Divider(height: 16),
                    
                    // Breakfast Slot
                    _buildMealSlot(
                      context: context,
                      appState: appState,
                      label: '🍳 Kahvaltı',
                      recipe: dayPlan.breakfastMeal,
                      isCooked: dayPlan.breakfastCooked,
                      onTap: () => _showSelectRecipeSheet(context, dayPlan.day, 'Kahvaltı'),
                      onCook: () => appState.markPlannedMealAsCooked(dayPlan.day, 'Kahvaltı'),
                    ),
                    const SizedBox(height: 10),
                    
                    // Lunch Slot
                    _buildMealSlot(
                      context: context,
                      appState: appState,
                      label: '☀️ Öğle Yemeği',
                      recipe: dayPlan.lunchMeal,
                      isCooked: dayPlan.lunchCooked,
                      onTap: () => _showSelectRecipeSheet(context, dayPlan.day, 'Öğle Yemeği'),
                      onCook: () => appState.markPlannedMealAsCooked(dayPlan.day, 'Öğle Yemeği'),
                    ),
                    const SizedBox(height: 10),
                    
                    // Dinner Slot
                    _buildMealSlot(
                      context: context,
                      appState: appState,
                      label: '🌙 Akşam Yemeği',
                      recipe: dayPlan.dinnerMeal,
                      isCooked: dayPlan.dinnerCooked,
                      onTap: () => _showSelectRecipeSheet(context, dayPlan.day, 'Akşam Yemeği'),
                      onCook: () => appState.markPlannedMealAsCooked(dayPlan.day, 'Akşam Yemeği'),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildMealSlot({
    required BuildContext context,
    required AppState appState,
    required String label,
    required Recipe? recipe,
    required bool isCooked,
    required VoidCallback onTap,
    required VoidCallback onCook,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (recipe != null) ...[
                    Row(
                      children: [
                        Text(
                          recipe.emoji,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RecipeDetailPage(recipe: recipe),
                                ),
                              );
                            },
                            child: Text(
                              recipe.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                decoration: isCooked ? TextDecoration.lineThrough : null,
                                color: isCooked ? Colors.grey : Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Missing ingredients warning
                    if (!isCooked) ...[
                      Builder(builder: (context) {
                        final missing = appState.getMissingIngredients(recipe, appState.personCount);
                        if (missing.isNotEmpty) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 4.0, left: 22.0),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 12),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Eksik: ${missing.map((e) => e.name).join(", ")}',
                                    style: TextStyle(
                                      color: Colors.amber[900],
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }),
                    ],
                  ] else
                    Text(
                      'Seçmek için dokunun...',
                      style: TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[400],
                      ),
                    ),
                ],
              ),
            ),
            if (recipe != null) ...[
              if (isCooked)
                const Icon(Icons.check_circle, color: Colors.green, size: 24)
              else
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Yemek Pişirildi mi?'),
                        content: Text('${recipe.name} yemeğini pişirdiniz mi?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              onCook();
                            },
                            child: const Text('Pişirdim'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('Pişirdim', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
