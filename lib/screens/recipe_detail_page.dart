import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/recipe.dart';
import '../models/ingredient.dart';
import '../utils/food_image_provider.dart';
import 'cooking_assistant_page.dart';

class RecipeDetailPage extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailPage({super.key, required this.recipe});

  @override
  State<RecipeDetailPage> createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  late int _localServings;
  bool _isInitialized = false;

  String _formatAmount(double val) {
    if (val == val.roundToDouble()) {
      return val.round().toString();
    }
    return val.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final appState = Provider.of<AppState>(context, listen: false);
      _localServings = appState.personCount;
      _isInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);
    
    // Scale ingredients
    final scaledIngredients = widget.recipe.getScaledIngredients(_localServings);

    // Analyze pantry match
    bool hasAllIngredients = true;
    List<Map<String, dynamic>> ingredientStatus = [];

    for (var reqIng in scaledIngredients) {
      final pantryItem = appState.pantry.firstWhere(
        (pi) => pi.name.trim().toLowerCase() == reqIng.name.trim().toLowerCase(),
        orElse: () => Ingredient(name: '', amount: 0, unit: ''),
      );

      bool available = pantryItem.name.isNotEmpty && pantryItem.amount >= reqIng.amount;
      double missingAmount = 0;
      if (pantryItem.name.isEmpty) {
        missingAmount = reqIng.amount;
        hasAllIngredients = false;
      } else if (pantryItem.amount < reqIng.amount) {
        missingAmount = reqIng.amount - pantryItem.amount;
        hasAllIngredients = false;
      }

      ingredientStatus.add({
        'ingredient': reqIng,
        'available': available,
        'pantryAmount': pantryItem.name.isNotEmpty ? pantryItem.amount : 0.0,
        'missingAmount': missingAmount,
      });
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Banner Sliver AppBar
          SliverAppBar(
            expandedHeight: 220.0,
            pinned: true,
            backgroundColor: Theme.of(context).colorScheme.primary,
            surfaceTintColor: Colors.transparent,
            elevation: 3,
            shadowColor: Colors.black26,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: Icon(
                  appState.isFavorite(widget.recipe.id) ? Icons.favorite : Icons.favorite_border,
                  color: appState.isFavorite(widget.recipe.id) ? Colors.redAccent : Colors.white,
                  size: 26,
                ),
                tooltip: appState.isFavorite(widget.recipe.id) ? 'Favorilerden Çıkar' : 'Favorilere Ekle',
                onPressed: () {
                  appState.toggleFavorite(widget.recipe.id);
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      duration: const Duration(seconds: 1),
                      content: Text(
                        appState.isFavorite(widget.recipe.id)
                            ? '❤️ "${widget.recipe.name}" favorilere eklendi!'
                            : '🤍 "${widget.recipe.name}" favorilerden çıkarıldı.',
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 4),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 48, bottom: 12, right: 16),
              title: Text(
                widget.recipe.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(offset: Offset(1.5, 1.5), blurRadius: 6.0, color: Colors.black)
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    FoodImageProvider.getRecipeImage(widget.recipe.name),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary.withOpacity(0.8),
                            theme.colorScheme.secondary.withOpacity(0.9),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          widget.recipe.emoji,
                          style: const TextStyle(fontSize: 90),
                        ),
                      ),
                    ),
                  ),
                  // Bottom gradient overlay to make title text highly readable
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Colors.black54],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Detail Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.recipe.category,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.schedule, size: 16, color: Colors.black54),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.recipe.durationMinutes} dakika',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Servings Calculator Selector
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Porsiyon Hesaplayıcı',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Text(
                                'Tarif ${widget.recipe.baseServings} kişilik yazılmıştır.',
                                style: TextStyle(color: Colors.grey[600], fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: _localServings > 1
                                  ? () {
                                      setState(() {
                                        _localServings--;
                                      });
                                    }
                                  : null,
                              icon: const Icon(Icons.remove_circle_outline),
                              color: theme.colorScheme.primary,
                            ),
                            Text(
                              '$_localServings Kişilik',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _localServings++;
                                });
                              },
                              icon: const Icon(Icons.add_circle_outline),
                              color: theme.colorScheme.primary,
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Ingredients Section
                  Text(
                    'Malzemeler',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  
                  // Ingredients List with Stock Check
                  ...ingredientStatus.map((status) {
                    final Ingredient ing = status['ingredient'];
                    final bool isAvail = status['available'];
                    final double pantryAmt = status['pantryAmount'];
                    final double missingAmt = status['missingAmount'];

                    String cleanAmt = _formatAmount(ing.amount);
                    String cleanPantryAmt = _formatAmount(pantryAmt);
                    String cleanMissingAmt = _formatAmount(missingAmt);

                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isAvail ? Icons.check_circle : Icons.warning_amber_rounded,
                            color: isAvail ? Colors.green : Colors.amber[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          // Ingredient image thumbnail
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              FoodImageProvider.getIngredientImage(ing.name),
                              width: 32,
                              height: 32,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 32,
                                height: 32,
                                color: Colors.grey[200],
                                child: const Icon(Icons.kitchen_outlined, size: 16, color: Colors.grey),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ing.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: isAvail ? Colors.black87 : Colors.black,
                                  ),
                                ),
                                if (!isAvail)
                                  Text(
                                    pantryAmt > 0
                                        ? 'Stokta yetersiz (Kilerde: $cleanPantryAmt, Eksik: $cleanMissingAmt ${ing.unit})'
                                        : 'Stokta yok (Eksik: $cleanAmt ${ing.unit})',
                                    style: TextStyle(fontSize: 10, color: Colors.orange[800], fontWeight: FontWeight.bold),
                                  )
                                else
                                  Text(
                                    'Kilerde yeterli var ($cleanPantryAmt ${ing.unit})',
                                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            '$cleanAmt ${ing.unit}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 24),

                  // Preparation / Instructions
                  Text(
                    'Hazırlanışı',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ...widget.recipe.instructions.asMap().entries.map((entry) {
                    int index = entry.key + 1;
                    String instruction = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 11,
                            backgroundColor: theme.colorScheme.primary.withOpacity(0.8),
                            child: Text(
                              '$index',
                              style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              instruction,
                              style: const TextStyle(fontSize: 14, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  
                  const SizedBox(height: 30),

                  // "Pişirmeye Başla" (Hands-Free Cooking Assistant) Main Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.soup_kitchen, size: 24),
                      label: const Text(
                        'PİŞİRMEYE BAŞLA (Adım Adım Mod)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CookingAssistantPage(
                              recipe: widget.recipe,
                              servings: _localServings,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  // "I Cooked This" Quick Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: hasAllIngredients ? Colors.green : Colors.amber[800]!,
                          width: 1.5,
                        ),
                        foregroundColor: hasAllIngredients ? Colors.green[800] : Colors.amber[900],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: Icon(
                        Icons.check_circle_outline,
                        color: hasAllIngredients ? Colors.green : Colors.amber[800],
                        size: 20,
                      ),
                      label: Text(
                        hasAllIngredients ? 'Hızlı Onay: Bu Yemeği Yaptım' : 'Eksik Stokla Pişirdim',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Yemeği Pişirdiniz mi?'),
                            content: Text(
                              hasAllIngredients
                                  ? 'Harika! Bu yemeği pişirdiğinizde $_localServings kişilik malzeme miktarları kilerden otomatik olarak düşülecektir.'
                                  : 'Dikkat: Kilerde bazı malzemeler eksik veya yetersiz görünüyor. Yine de pişirdiğinizi onaylıyor musunuz? (Mevcut stoklar sıfırlanacaktır.)',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('İptal'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: hasAllIngredients ? Colors.green : Colors.amber[800],
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () {
                                  Navigator.pop(ctx); // Close dialog
                                  
                                  // Deduct from appState
                                  appState.cookMeal(widget.recipe, _localServings);
                                  
                                  // Show snackbar
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${widget.recipe.name} pişirildi. Malzemeler kilerden düşüldü.'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  
                                  // Go back to previous screen
                                  Navigator.pop(context);
                                },
                                child: const Text('Evet, Pişirdim'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
