import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recipe.dart';
import '../models/ingredient.dart';
import '../providers/app_state.dart';
import '../utils/food_image_provider.dart';

class CookingAssistantPage extends StatefulWidget {
  final Recipe recipe;
  final int servings;

  const CookingAssistantPage({
    super.key,
    required this.recipe,
    required this.servings,
  });

  @override
  State<CookingAssistantPage> createState() => _CookingAssistantPageState();
}

class _CookingAssistantPageState extends State<CookingAssistantPage> {
  late PageController _pageController;
  int _currentStepIndex = 0;
  late int _servings;

  // Smart Timer State
  Timer? _timer;
  int _timerTotalSeconds = 0;
  int _timerRemainingSeconds = 0;
  bool _isTimerRunning = false;
  bool _isTimerActive = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _servings = widget.servings;
    _checkAndSuggestTimerForStep(0);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // Parses minutes mentioned in step text e.g., "15 dakika", "20 dk", "30-35 dakika"
  int? _extractMinutesFromText(String text) {
    final RegExp regex = RegExp(r'(\d+)\s*(?:dakika|dk|min)', caseSensitive: false);
    final match = regex.firstMatch(text);
    if (match != null) {
      return int.tryParse(match.group(1)!);
    }
    return null;
  }

  void _checkAndSuggestTimerForStep(int stepIndex) {
    if (stepIndex < widget.recipe.instructions.length) {
      final text = widget.recipe.instructions[stepIndex];
      final mins = _extractMinutesFromText(text);
      if (mins != null && !_isTimerRunning) {
        _setTimer(mins * 60, startImmediately: false);
      }
    }
  }

  void _setTimer(int seconds, {bool startImmediately = false}) {
    _timer?.cancel();
    setState(() {
      _timerTotalSeconds = seconds;
      _timerRemainingSeconds = seconds;
      _isTimerActive = true;
      _isTimerRunning = false;
    });
    if (startImmediately) {
      _startTimer();
    }
  }

  void _startTimer() {
    if (_timerRemainingSeconds <= 0) return;
    _timer?.cancel();
    setState(() {
      _isTimerRunning = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerRemainingSeconds > 1) {
        setState(() {
          _timerRemainingSeconds--;
        });
      } else {
        _timer?.cancel();
        setState(() {
          _timerRemainingSeconds = 0;
          _isTimerRunning = false;
        });
        _onTimerComplete();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isTimerRunning = false;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _timerRemainingSeconds = _timerTotalSeconds;
      _isTimerRunning = false;
    });
  }

  void _addSeconds(int seconds) {
    setState(() {
      _timerRemainingSeconds += seconds;
      _timerTotalSeconds = _timerTotalSeconds < _timerRemainingSeconds ? _timerRemainingSeconds : _timerTotalSeconds;
    });
  }

  void _onTimerComplete() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.alarm_on, color: Colors.deepOrange, size: 30),
            SizedBox(width: 10),
            Text('Süre Doldu! ⏰', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          '${widget.recipe.name} tarifinin ${_currentStepIndex + 1}. adımı için ayarladığınız zamanlayıcı tamamlandı! Bir sonraki adıma geçebilirsiniz.',
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  String _formatTimerDisplay(int totalSecs) {
    final mins = totalSecs ~/ 60;
    final secs = totalSecs % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String _formatAmount(double val) {
    if (val == val.roundToDouble()) {
      return val.round().toString();
    }
    return val.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
  }

  void _showIngredientsBottomSheet() {
    final scaled = widget.recipe.getScaledIngredients(_servings);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Malzeme Listesi ($_servings Kişilik)',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        key: const Key('cooking_assistant_sheet_close_button'),
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: scaled.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final ing = scaled[index];
                        return ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              FoodImageProvider.getIngredientImage(ing.name),
                              width: 36,
                              height: 36,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 36,
                                height: 36,
                                color: Colors.grey[200],
                                child: const Icon(Icons.kitchen, size: 20, color: Colors.grey),
                              ),
                            ),
                          ),
                          title: Text(ing.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          trailing: Text(
                            '${_formatAmount(ing.amount)} ${ing.unit}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _finishCooking() {
    final appState = Provider.of<AppState>(context, listen: false);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Column(
          children: [
            Text('🎉', style: TextStyle(fontSize: 48)),
            SizedBox(height: 8),
            Text(
              'Afiyet Olsun!',
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Text(
          '${widget.recipe.name} yemeğini başarıyla tamamladınız! $_servings kişilik malzemeler kilerinizden düşülsün mü?',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Hayır, Sadece Çık'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              appState.cookMeal(widget.recipe, _servings);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${widget.recipe.name} pişti! Malzemeler kilerden düşüldü.'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pop(context);
            },
            child: const Text('Evet, Stoktan Düş'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalSteps = widget.recipe.instructions.length;
    final isLastStep = _currentStepIndex == totalSteps - 1;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.recipe.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          overflow: TextOverflow.ellipsis,
        ),
        elevation: 1,
        actions: [
          // Ingredient List Sheet Button
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
            ),
            icon: const Icon(Icons.receipt_long, size: 18),
            label: const Text('Malzemeler', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: _showIngredientsBottomSheet,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar
            LinearProgressIndicator(
              value: (totalSteps > 0) ? (_currentStepIndex + 1) / totalSteps : 0.0,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              minHeight: 5,
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: theme.colorScheme.surface,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Adım ${_currentStepIndex + 1} / $totalSteps',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Text(
                          '($_servings Kişilik)',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.visibility, color: Colors.green, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Ekran Açık',
                          style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // PageView for Instructions
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: totalSteps,
                onPageChanged: (index) {
                  setState(() {
                    _currentStepIndex = index;
                  });
                  _checkAndSuggestTimerForStep(index);
                },
                itemBuilder: (context, index) {
                  final instruction = widget.recipe.instructions[index];
                  final suggestedMins = _extractMinutesFromText(instruction);

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Step Number Header
                        Text(
                          'Adım ${index + 1}',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Instruction Big Typography
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(color: Colors.grey.withOpacity(0.15)),
                          ),
                          child: Text(
                            instruction,
                            style: const TextStyle(
                              fontSize: 18,
                              height: 1.6,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Smart Timer Suggestion Badge
                        if (suggestedMins != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.amber.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.timer_outlined, color: Colors.amber, size: 22),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Bu adım için $suggestedMins dakika süre algılandı.',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber[800],
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () {
                                    _setTimer(suggestedMins * 60, startImmediately: true);
                                  },
                                  child: const Text('Başlat', style: TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 24),

                        // Smart Timer Section Card
                        _buildSmartTimerCard(theme),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Navigation Controls
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Previous Step Button
                  if (_currentStepIndex > 0)
                    Expanded(
                      flex: 1,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Önceki'),
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                      ),
                    ),
                  if (_currentStepIndex > 0) const SizedBox(width: 12),

                  // Next Step / Finish Button
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isLastStep ? Colors.green : theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 2,
                      ),
                      icon: Icon(isLastStep ? Icons.check_circle : Icons.arrow_forward),
                      label: Text(
                        isLastStep ? 'Pişirmeyi Tamamla 🎉' : 'Sonraki Adım',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      onPressed: () {
                        if (isLastStep) {
                          _finishCooking();
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartTimerCard(ThemeData theme) {
    double progress = _timerTotalSeconds > 0
        ? (_timerTotalSeconds - _timerRemainingSeconds) / _timerTotalSeconds
        : 0.0;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.timer, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Mutfak Zamanlayıcısı',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isTimerActive)
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                    onPressed: () {
                      _timer?.cancel();
                      setState(() {
                        _isTimerActive = false;
                        _isTimerRunning = false;
                        _timerRemainingSeconds = 0;
                        _timerTotalSeconds = 0;
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Circular Countdown Display
            if (_isTimerActive) ...[
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 8,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _timerRemainingSeconds < 30 && _timerRemainingSeconds > 0
                            ? Colors.red
                            : theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTimerDisplay(_timerRemainingSeconds),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: _timerRemainingSeconds < 30 && _timerRemainingSeconds > 0
                              ? Colors.red
                              : theme.colorScheme.primary,
                        ),
                      ),
                      Text(
                        _isTimerRunning ? 'Geri sayılıyor...' : 'Duraklatıldı',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Timer Controls
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton.filledTonal(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Sıfırla',
                      onPressed: _resetTimer,
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isTimerRunning ? Colors.orange : theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: Icon(_isTimerRunning ? Icons.pause : Icons.play_arrow, size: 20),
                      label: Text(_isTimerRunning ? 'Duraklat' : 'Devam Et'),
                      onPressed: () {
                        if (_isTimerRunning) {
                          _pauseTimer();
                        } else {
                          _startTimer();
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.add),
                      tooltip: '+1 Dakika Ekle',
                      onPressed: () => _addSeconds(60),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Timer Presets Buttons
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Hızlı Sayaç Seçimi:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [1, 3, 5, 10, 15, 20, 30].map((mins) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _setTimer(mins * 60, startImmediately: true),
                      child: Text('$mins dk', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
