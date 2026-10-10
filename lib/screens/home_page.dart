import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/recipe.dart';
import '../models/meal_plan.dart';
import 'recipe_detail_page.dart';
import 'expiring_ingredients_page.dart';
import '../utils/food_image_provider.dart';
import 'admin_panel_page.dart';

import 'wheel_page.dart';

class HomePage extends StatelessWidget {
  final Function(int, {int? subTabIndex}) onTabChange;

  const HomePage({super.key, required this.onTabChange});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);

    // Get today's plan
    // We can use current weekday name in Turkish
    final weekdaysTurkish = {
      1: 'Pazartesi',
      2: 'Salı',
      3: 'Çarşamba',
      4: 'Perşembe',
      5: 'Cuma',
      6: 'Cumartesi',
      7: 'Pazar',
    };
    final int weekdayIndex = DateTime.now().weekday;
    final String todayName = weekdaysTurkish[weekdayIndex] ?? 'Pazartesi';
    
    final todayPlan = appState.weeklyPlan.firstWhere(
      (p) => p.day == todayName,
      orElse: () => appState.weeklyPlan.isNotEmpty
          ? appState.weeklyPlan[0]
          : DailyMealPlan(day: todayName),
    );

    int totalPantryItems = appState.pantry.length;
    int outOfStockItems = appState.pantry.where((i) => i.amount <= 0).length;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Elegant Custom AppBar
          SliverAppBar(
            expandedHeight: 180.0,
            floating: false,
            pinned: true,
            backgroundColor: theme.colorScheme.primary,
            surfaceTintColor: Colors.transparent,
            elevation: 3,
            shadowColor: Colors.black26,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: Icon(
                  appState.themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
                  color: Colors.white,
                ),
                tooltip: appState.themeMode == ThemeMode.dark ? 'Aydınlık Mod' : 'Karanlık Mod',
                onPressed: () {
                  appState.toggleThemeMode();
                },
              ),
              if (appState.currentUser?.role == 'admin' || appState.currentUser?.role == 'content_manager')
                IconButton(
                  icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
                  tooltip: 'Yönetim Paneli',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AdminPanelPage()),
                    );
                  },
                ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
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
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'TarifMatik',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      offset: const Offset(1, 1),
                      blurRadius: 3.0,
                      color: Colors.black.withOpacity(0.3),
                    ),
                  ],
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      bottom: -20,
                      child: Icon(
                        Icons.restaurant_menu,
                        size: 150,
                        color: Colors.white.withOpacity(0.15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Dashboard Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Expiry Warnings banner
                  Builder(
                    builder: (context) {
                      final expiring = appState.getExpiringPantryIngredients();
                      if (expiring.isEmpty) return const SizedBox.shrink();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.red.withOpacity(0.3), width: 1),
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ExpiringIngredientsPage(),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.red[50],
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.warning_amber_rounded,
                                      color: Colors.red,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'SKT Yaklaşan Malzemeler Var!',
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red[800],
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Kilerinizdeki ${expiring.length} malzemenin son kullanma tarihi yaklaştı. Bozulmadan değerlendirmek için dokunun!',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  // 1. Serving Size Picker Card (Yeni Evliler/Kişi Sayısı Ayarı)
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.people,
                              color: theme.colorScheme.primary,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Kişi Sayısı Ayarı',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Malzemeler bu sayıya göre hesaplanır',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: appState.personCount > 1
                                    ? () => appState.savePersonCount(appState.personCount - 1)
                                    : null,
                                icon: const Icon(Icons.remove_circle_outline),
                                color: theme.colorScheme.primary,
                              ),
                              Text(
                                '${appState.personCount}',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                onPressed: () => appState.savePersonCount(appState.personCount + 1),
                                icon: const Icon(Icons.add_circle_outline),
                                color: theme.colorScheme.primary,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. Today's Meal Plan Card
                  Text(
                    'Bugün Ne Yiyeceksiniz? ($todayName)',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildMealCategoryCard(
                    context: context,
                    category: 'Kahvaltı',
                    recipe: todayPlan.breakfastMeal,
                    isCooked: todayPlan.breakfastCooked,
                    onCook: () => appState.markPlannedMealAsCooked(todayName, 'Kahvaltı'),
                    color: Colors.amber,
                    icon: Icons.light_mode,
                  ),
                  const SizedBox(height: 8),
                  _buildMealCategoryCard(
                    context: context,
                    category: 'Öğle Yemeği',
                    recipe: todayPlan.lunchMeal,
                    isCooked: todayPlan.lunchCooked,
                    onCook: () => appState.markPlannedMealAsCooked(todayName, 'Öğle Yemeği'),
                    color: Colors.orange,
                    icon: Icons.wb_sunny,
                  ),
                  const SizedBox(height: 8),
                  _buildMealCategoryCard(
                    context: context,
                    category: 'Akşam Yemeği',
                    recipe: todayPlan.dinnerMeal,
                    isCooked: todayPlan.dinnerCooked,
                    onCook: () => appState.markPlannedMealAsCooked(todayName, 'Akşam Yemeği'),
                    color: Colors.indigo,
                    icon: Icons.nights_stay,
                  ),
                  const SizedBox(height: 24),

                  // 3. Pantry status quick card
                  Text(
                    'Kiler Durumu Özet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatusCounterCard(
                          title: 'Toplam Malzeme',
                          count: '$totalPantryItems',
                          icon: Icons.kitchen,
                          color: Colors.teal,
                          onTap: () => onTabChange(1), // Go to Pantry tab
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatusCounterCard(
                          title: 'Biten Malzemeler',
                          count: '$outOfStockItems',
                          icon: Icons.warning_amber_rounded,
                          color: Colors.red,
                          onTap: () => onTabChange(1), // Go to Pantry tab
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 4. Quick Action Buttons
                  Text(
                    'Hızlı Eylemler',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.6,
                    children: [
                      _buildQuickActionCard(
                        title: 'Yemek Çarkı\nDöndür',
                        subtitle: 'Kararsız mısınız?',
                        icon: Icons.rotate_right,
                        color: theme.colorScheme.primary,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const WheelPage()),
                          );
                        },
                      ),
                      _buildQuickActionCard(
                        title: 'Ne Pişirebilirim?',
                        subtitle: 'Malzemelere göre',
                        icon: Icons.soup_kitchen_outlined,
                        color: theme.colorScheme.secondary,
                        onTap: () => onTabChange(2),
                      ),
                      _buildQuickActionCard(
                        title: 'Alışveriş\nListesi',
                        subtitle: 'Eksikleri planla',
                        icon: Icons.shopping_basket_outlined,
                        color: Colors.teal[600]!,
                        onTap: () => onTabChange(4, subTabIndex: 0),
                      ),
                      _buildQuickActionCard(
                        title: 'Bütçe &\nHarcamalar',
                        subtitle: 'Ekonomi takibi',
                        icon: Icons.donut_large_outlined,
                        color: Colors.indigo[600]!,
                        onTap: () => onTabChange(4, subTabIndex: 1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealCategoryCard({
    required BuildContext context,
    required String category,
    required Recipe? recipe,
    required bool isCooked,
    required VoidCallback onCook,
    required Color color,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            if (recipe != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  FoodImageProvider.getRecipeImage(recipe.name),
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 40,
                    height: 40,
                    color: color.withOpacity(0.08),
                    child: Center(
                      child: Text(recipe.emoji, style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    recipe != null ? '${recipe.emoji} ${recipe.name}' : 'Yemek seçilmedi',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      decoration: isCooked ? TextDecoration.lineThrough : null,
                      color: isCooked ? Colors.grey : null,
                    ),
                  ),
                ],
              ),
            ),
            if (recipe != null) ...[
              if (isCooked)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check, color: Colors.green, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Pişirildi',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.receipt_long_outlined),
                      color: Colors.grey[700],
                      tooltip: 'Tarife Git',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RecipeDetailPage(recipe: recipe),
                          ),
                        );
                      },
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        // Confirm cooking
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Yemek Pişirildi mi?'),
                            content: Text(
                              '${recipe.name} yemeğini pişirdiğinizi onaylıyor musunuz? Evdeki kiler malzemeleri kişi sayısına göre azaltılacaktır.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('İptal'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  onCook();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${recipe.name} pişti! Malzemeler stoktan düşüldü.'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                },
                                child: const Text('Evet, Pişirdim'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: const Text('Pişirdim'),
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCounterCard({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          border: Border.all(color: color.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              count,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(icon, color: color, size: 30),
          ],
        ),
      ),
    );
  }
}
