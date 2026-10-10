import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/recipe.dart';
import 'recipe_detail_page.dart';
import '../utils/food_image_provider.dart';
import 'admin_panel_page.dart';

class WheelPage extends StatefulWidget {
  const WheelPage({super.key});

  @override
  State<WheelPage> createState() => _WheelPageState();
}

class _WheelPageState extends State<WheelPage> with TickerProviderStateMixin {
  late AnimationController _spinController;
  late Animation<double> _spinAnimation;
  
  // Confetti Animation
  late AnimationController _confettiController;
  final List<ConfettiParticle> _confettiParticles = [];

  String _categoryFilter = 'Akşam Yemeği'; // Akşam yemeği is default, as requested.
  bool _onlyCookable = false;

  List<Recipe> _cachedSelectedPool = [];
  String? _lastCategoryFilter;
  bool? _lastOnlyCookable;
  int? _lastTotalRecipeCount;

  void _shuffleNew20(List<Recipe> filteredPool) {
    setState(() {
      _showResult = false;
      _selectedRecipe = null;
      final random = math.Random();
      final tempPool = List<Recipe>.from(filteredPool);
      tempPool.shuffle(random);
      _cachedSelectedPool = tempPool.take(20).toList();
    });
  }
  
  Recipe? _selectedRecipe;
  bool _isSpinning = false;
  bool _showResult = false;
  double _currentRotationAngle = 0.0;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    );

    _spinController.addListener(() {
      if (_isSpinning) {
        setState(() {
          _currentRotationAngle = _spinAnimation.value;
        });
      }
    });

    _confettiController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..addListener(() {
        _updateConfetti();
      });
  }

  @override
  void dispose() {
    _spinController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  // Generate confetti particles
  void _createConfetti() {
    _confettiParticles.clear();
    final random = math.Random();
    final colors = [Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.orange, Colors.pink, Colors.purple];
    
    for (int i = 0; i < 80; i++) {
      _confettiParticles.add(
        ConfettiParticle(
          x: random.nextDouble() * 400, // will scale in canvas
          y: -10 - random.nextDouble() * 100,
          color: colors[random.nextInt(colors.length)],
          speedY: 2.0 + random.nextDouble() * 5.0,
          speedX: -2.0 + random.nextDouble() * 4.0,
          size: 5.0 + random.nextDouble() * 8.0,
          rotation: random.nextDouble() * math.pi * 2,
          rotationSpeed: -0.1 + random.nextDouble() * 0.2,
        ),
      );
    }
  }

  void _updateConfetti() {
    setState(() {
      for (var p in _confettiParticles) {
        p.y += p.speedY;
        p.x += p.speedX;
        p.rotation += p.rotationSpeed;
      }
    });
  }

  void _spinWheel(List<Recipe> pool) {
    if (_isSpinning || pool.isEmpty) return;

    setState(() {
      _isSpinning = true;
      _showResult = false;
      _selectedRecipe = null;
    });

    final random = math.Random();
    int targetIndex = random.nextInt(pool.length);
    _selectedRecipe = pool[targetIndex];

    // Total slices
    int count = pool.length;
    double sliceAngle = (2 * math.pi) / count;

    // Calculate rotation to land on target index at the top pointer (angle = 270 deg or -90 deg or 1.5 * pi)
    // Pointer is at -pi/2 (top). 
    // To align slice `targetIndex` with the top, we need the wheel rotated by:
    // Angle = 1.5 * pi - (targetIndex * sliceAngle + sliceAngle / 2)
    double targetAngleOffset = 1.5 * math.pi - (targetIndex * sliceAngle + sliceAngle / 2);
    
    // Add multiple full rotations for effect (e.g. 10-14 full spins)
    double fullSpins = (10 + random.nextInt(4)) * 2 * math.pi;
    double finalAngle = fullSpins + targetAngleOffset;

    _spinAnimation = Tween<double>(
      begin: _currentRotationAngle % (2 * math.pi),
      end: finalAngle,
    ).animate(CurvedAnimation(
      parent: _spinController,
      curve: Curves.easeOutCirc, // Perfect decelerating spin effect
    ));

    _spinController.forward(from: 0.0).then((_) {
      setState(() {
        _isSpinning = false;
        _showResult = true;
        _currentRotationAngle = finalAngle;
      });
      // Start confetti
      _createConfetti();
      _confettiController.forward(from: 0.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);

    // Build the recipe pool based on filters
    List<Recipe> pool = appState.recipes;
    if (_categoryFilter != 'Hepsi') {
      pool = pool.where((r) => r.category == _categoryFilter).toList();
    }
    
    // Always filter to recipes with at least 70% match score of ingredients
    pool = pool.where((r) {
      return appState.getRecipeMatchScore(r, appState.personCount) >= 0.70;
    }).toList();

    if (_onlyCookable) {
      pool = pool.where((r) {
        return appState.getRecipeMatchScore(r, appState.personCount) >= 0.999;
      }).toList();
    }

    // Cache the 20 selection
    if (_lastCategoryFilter != _categoryFilter ||
        _lastOnlyCookable != _onlyCookable ||
        _lastTotalRecipeCount != appState.recipes.length ||
        _cachedSelectedPool.isEmpty) {
      _lastCategoryFilter = _categoryFilter;
      _lastOnlyCookable = _onlyCookable;
      _lastTotalRecipeCount = appState.recipes.length;
      
      final random = math.Random();
      final tempPool = List<Recipe>.from(pool);
      tempPool.shuffle(random);
      _cachedSelectedPool = tempPool.take(20).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yemek Çarkı', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
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
      body: Stack(
        children: [
          Column(
            children: [
              // Filters Header
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Column(
                      children: [
                        // Category choices
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: ['Hepsi', 'Kahvaltı', 'Öğle Yemeği', 'Akşam Yemeği', 'Tatlı', 'İçecek'].map((cat) {
                              bool isSelected = _categoryFilter == cat;
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                child: ChoiceChip(
                                  label: Text(
                                    cat,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                  selected: isSelected,
                                  onSelected: _isSpinning
                                      ? null
                                      : (selected) {
                                          if (selected) {
                                            setState(() {
                                              _categoryFilter = cat;
                                              _showResult = false;
                                            });
                                          }
                                        },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const Divider(height: 8),
                        // Only Cookable toggle
                        SwitchListTile(
                          title: const Text(
                            'Sadece yapılabilecek yemekler (stokta var olanlar)',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          value: _onlyCookable,
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          onChanged: _isSpinning
                              ? null
                              : (val) {
                                  setState(() {
                                    _onlyCookable = val;
                                    _showResult = false;
                                  });
                                },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Empty Pool Warning
              if (_cachedSelectedPool.isEmpty)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.restaurant_menu_outlined, size: 60, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text(
                            'Çarkta Gösterilebilecek Yemek Kalmadı!',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Seçtiğiniz filtreye göre uygun tarif bulunamadı. Kilerinizi güncelleyebilir veya diğer filtreleri seçebilirsiniz.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Custom Wheel widget
                          // Custom Wood Stand and Wheel widget
                          SizedBox(
                            width: 320,
                            height: 420,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Background stand
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: WheelStandPainter(),
                                  ),
                                ),
                                // Inner Wheel spinning
                                Positioned(
                                  top: 50,
                                  child: AnimatedBuilder(
                                    animation: _spinController,
                                    builder: (context, child) {
                                      return Transform.rotate(
                                        angle: _currentRotationAngle,
                                        child: CustomPaint(
                                          size: const Size(280, 280),
                                          painter: MealWheelPainter(
                                            recipes: _cachedSelectedPool,
                                            theme: theme,
                                            animationValue: _spinController.value,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                // Center core
                                Positioned(
                                  top: 165, // centered relative to wheel: 50 + 140 - 25 = 165
                                  child: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.restaurant,
                                        color: Colors.orange,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                                // Outer Border indicator (the needle at the top)
                                Positioned(
                                  top: 15,
                                  left: 135, // centered horizontally: 160 - 25 = 135
                                  child: AnimatedBuilder(
                                    animation: _spinController,
                                    builder: (context, child) {
                                      // Wiggles back and forth as segments cross the top pointer
                                      double wiggle = _isSpinning 
                                          ? 0.22 * math.sin(_currentRotationAngle * _cachedSelectedPool.length)
                                          : 0.0;
                                      return Transform.rotate(
                                        angle: wiggle,
                                        alignment: const Alignment(0.0, -0.5), // rotate around the bolt center
                                        child: CustomPaint(
                                          size: const Size(50, 60),
                                          painter: NeedlePainter(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 30),

                          // SPIN button & Shuffle 100 button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 4,
                                ),
                                onPressed: _isSpinning || _cachedSelectedPool.isEmpty
                                    ? null
                                    : () => _spinWheel(_cachedSelectedPool),
                                icon: const Icon(Icons.play_arrow),
                                label: Text(
                                  _isSpinning ? 'DÖNÜYOR...' : 'ÇARKI ÇEVİR!',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ),
                              if (pool.length > 20) ...[
                                const SizedBox(width: 12),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: theme.colorScheme.primary,
                                    side: BorderSide(color: theme.colorScheme.primary),
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  onPressed: _isSpinning
                                      ? null
                                      : () => _shuffleNew20(pool),
                                  icon: const Icon(Icons.refresh),
                                  label: const Text(
                                    'Yenile (Farklı 20)',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Confetti overlay
          if (_showResult)
            IgnorePointer(
              child: CustomPaint(
                size: Size.infinite,
                painter: ConfettiPainter(particles: _confettiParticles),
              ),
            ),

          // Selected Recipe Result overlay card
          if (_showResult && _selectedRecipe != null)
            _buildResultCard(context, _selectedRecipe!),
        ],
      ),
    );
  }

  Widget _buildResultCard(BuildContext context, Recipe recipe) {
    final appState = Provider.of<AppState>(context, listen: false);
    final theme = Theme.of(context);

    // Calculate details
    double matchScore = appState.getRecipeMatchScore(recipe, appState.personCount);
    bool isCookable = matchScore >= 0.999;

    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '🎉 Bugünün Seçimi! 🎉',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                FoodImageProvider.getRecipeImage(recipe.name),
                height: 120,
                width: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Text(
                  recipe.emoji,
                  style: const TextStyle(fontSize: 60),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              recipe.name,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              '${recipe.category} • ${recipe.durationMinutes} dakika',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isCookable ? Colors.green[50] : Colors.amber[50],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isCookable ? 'Tüm malzemeler kilerde hazır!' : 'Eksik malzemeler var!',
                style: TextStyle(
                  color: isCookable ? Colors.green[800] : Colors.amber[900],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _showResult = false;
                      });
                    },
                    child: const Text('Kapat'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _showResult = false;
                      });
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RecipeDetailPage(recipe: recipe),
                        ),
                      );
                    },
                    child: const Text('Tarife Git'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Quick action to add to meal plan
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.calendar_today, size: 16),
                label: const Text('Bugünün Planına Ekle'),
                onPressed: () {
                  // Get current day name
                  final weekdaysTurkish = {
                    1: 'Pazartesi',
                    2: 'Salı',
                    3: 'Çarşamba',
                    4: 'Perşembe',
                    5: 'Cuma',
                    6: 'Cumartesi',
                    7: 'Pazar',
                  };
                  String today = weekdaysTurkish[DateTime.now().weekday] ?? 'Pazartesi';
                  appState.planMeal(today, recipe.category, recipe);
                  
                  setState(() {
                    _showResult = false;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${recipe.name} bugünkü (${today}) planınıza eklendi!'),
                      backgroundColor: Colors.indigo,
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
}

// Custom Painter for Meal Wheel
class MealWheelPainter extends CustomPainter {
  final List<Recipe> recipes;
  final ThemeData theme;
  final double animationValue;

  MealWheelPainter({
    required this.recipes,
    required this.theme,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (recipes.isEmpty) return;

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final double radius = size.width / 2;
    final center = Offset(radius, radius);
    final int count = recipes.length;
    final double sliceAngle = (2 * math.pi) / count;

    // Theme matching colors of the user's photo
    final colors = [
      const Color(0xFFE57373), // Red
      const Color(0xFF4DD0E1), // Teal
      const Color(0xFFF06292), // Pink
      const Color(0xFFAED581), // Lime Green
      const Color(0xFFFFD54F), // Yellow
      const Color(0xFFBA68C8), // Purple
      const Color(0xFF9CCC65), // Olive Green
      const Color(0xFF4FC3F7), // Blue
    ];

    for (int i = 0; i < count; i++) {
      // Draw slices
      paint.color = colors[i % colors.length];
      double startAngle = i * sliceAngle;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sliceAngle,
        true,
        paint,
      );

      // Draw thin border separator lines
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawLine(
        center,
        Offset(
          center.dx + radius * math.cos(startAngle),
          center.dy + radius * math.sin(startAngle),
        ),
        borderPaint,
      );

      // Draw Emoji / Text inside the slice
      final textPainter = TextPainter(
        textDirection: TextDirection.ltr,
      );

      double labelAngle = startAngle + sliceAngle / 2;
      double textRadius = radius * 0.55;
      
      String name = recipes[i].name;
      if (name.length > 14) {
        name = '${name.substring(0, 12)}..';
      }
      String label = '${recipes[i].emoji} $name';

      textPainter.text = TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      );

      textPainter.layout();

      canvas.save();
      double posX = center.dx + textRadius * math.cos(labelAngle);
      double posY = center.dy + textRadius * math.sin(labelAngle);
      
      canvas.translate(posX, posY);
      canvas.rotate(labelAngle);
      
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();
    }

    // Outer circle white rim
    final rimPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0;
    canvas.drawCircle(center, radius - 5, rimPaint);

    // Draw silver pegs/pins around the rim at slice divisions
    for (int i = 0; i < count; i++) {
      double startAngle = i * sliceAngle;
      double pegX = center.dx + (radius - 5) * math.cos(startAngle);
      double pegY = center.dy + (radius - 5) * math.sin(startAngle);
      
      final pegPaint = Paint()
        ..color = const Color(0xFFEEEEEE) // metallic silver reflection
        ..style = PaintingStyle.fill;
      final pegBorder = Paint()
        ..color = const Color(0xFF9E9E9E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawCircle(Offset(pegX, pegY), 4.5, pegPaint);
      canvas.drawCircle(Offset(pegX, pegY), 4.5, pegBorder);
      
      // small shine dot on the bolt
      final shinePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(pegX - 1.5, pegY - 1.5), 1.2, shinePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Confetti Particle System
class ConfettiParticle {
  double x;
  double y;
  final Color color;
  final double speedY;
  final double speedX;
  final double size;
  double rotation;
  final double rotationSpeed;

  ConfettiParticle({
    required this.x,
    required this.y,
    required this.color,
    required this.speedY,
    required this.speedX,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
  });
}

class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;

  ConfettiPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var p in particles) {
      paint.color = p.color;
      canvas.save();
      // map normalized particle x position (e.g. 0-400) to actual canvas size width
      double mappedX = (p.x / 400.0) * size.width;
      canvas.translate(mappedX, p.y);
      canvas.rotate(p.rotation);

      // Draw a small rectangle or circle
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 1.5),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Stand Backing Painter (Wooden base, White stand, Top circle mount)
class WheelStandPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    
    // Draw the dark brown wooden base at the bottom
    final basePaint = Paint()
      ..color = const Color(0xFF8D6E63) // Wood brown
      ..style = PaintingStyle.fill;
    final baseShadowPaint = Paint()
      ..color = const Color(0xFF5D4037) // Darker wood brown for depth
      ..style = PaintingStyle.fill;

    // Draw base shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(16, h - 20, w - 16, h),
        const Radius.circular(8),
      ),
      baseShadowPaint,
    );
    // Draw base top
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(20, h - 35, w - 20, h - 10),
        const Radius.circular(8),
      ),
      basePaint,
    );

    // Draw the vertical white stand stem
    final standPaint = Paint()
      ..color = const Color(0xFFF5F5F5) // Clean white
      ..style = PaintingStyle.fill;
    final standBorderPaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Stem: rectangle from base to top center
    final stemRect = Rect.fromLTRB(w / 2 - 40, 50, w / 2 + 40, h - 35);
    canvas.drawRect(stemRect, standPaint);
    canvas.drawRect(stemRect, standBorderPaint);

    // Top rounded backing piece: circle at the top center
    // Center of backing circle is at (w/2, 40). Radius of backing circle is 45.
    final backingCenter = Offset(w / 2, 40);
    canvas.drawCircle(backingCenter, 45, standPaint);
    canvas.drawCircle(backingCenter, 45, standBorderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Needle Pointer Painter (Yellow pointed arrow with central bolt)
class NeedlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    
    // Draw the yellow pointed wooden arrow pointing down
    final arrowPaint = Paint()
      ..color = const Color(0xFFFFD54F) // Amber/Yellow
      ..style = PaintingStyle.fill;
    
    final path = Path()
      ..moveTo(w / 2 - 15, 0)
      ..lineTo(w / 2 + 15, 0)
      ..lineTo(w / 2 + 12, h * 0.4)
      ..lineTo(w / 2, h) // point at bottom center
      ..lineTo(w / 2 - 12, h * 0.4)
      ..close();
    canvas.drawPath(path, arrowPaint);

    final borderPaint = Paint()
      ..color = const Color(0xFFFFA000) // Darker amber border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(path, borderPaint);

    // Draw the central mounting bolt (silver/grey circle)
    final boltPaint = Paint()
      ..color = const Color(0xFFB0BEC5)
      ..style = PaintingStyle.fill;
    final boltBorderPaint = Paint()
      ..color = const Color(0xFF78909C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(Offset(w / 2, h * 0.25), 6, boltPaint);
    canvas.drawCircle(Offset(w / 2, h * 0.25), 6, boltBorderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
