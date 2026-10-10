import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/ingredient.dart';
import '../utils/food_image_provider.dart';
import 'admin_panel_page.dart';

class PantryPage extends StatefulWidget {
  const PantryPage({super.key});

  @override
  State<PantryPage> createState() => _PantryPageState();
}

class _PantryPageState extends State<PantryPage> {
  String _searchQuery = '';
  final _addNameController = TextEditingController();
  final _addAmountController = TextEditingController();
  String _selectedUnit = 'g';
  final List<String> _units = ['g', 'kg', 'ml', 'adet', 'paket', 'kaşık', 'diş'];
  DateTime? _selectedExpiryDate;

  @override
  void dispose() {
    _addNameController.dispose();
    _addAmountController.dispose();
    super.dispose();
  }

  void _showAddIngredientDialog(BuildContext context) {
    _addNameController.clear();
    _addAmountController.clear();
    setState(() {
      _selectedUnit = 'g';
      _selectedExpiryDate = null;
    });

    final appState = Provider.of<AppState>(context, listen: false);
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.kitchen, color: Colors.orange),
                  SizedBox(width: 10),
                  Text('Kilere Malzeme Ekle'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _addNameController,
                      decoration: const InputDecoration(
                        labelText: 'Malzeme Adı',
                        hintText: 'örn: Kıyma, Yumurta, Süt',
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _addAmountController,
                            decoration: const InputDecoration(
                              labelText: 'Miktar',
                              hintText: 'örn: 250, 2',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField<String>(
                            value: _selectedUnit,
                            decoration: const InputDecoration(
                              labelText: 'Birim',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            ),
                            items: _units.map((unit) {
                              return DropdownMenuItem(
                                value: unit,
                                child: Text(unit),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() {
                                  _selectedUnit = val;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_month),
                            label: Text(
                              _selectedExpiryDate == null
                                  ? 'Son Kullanma Tarihi Seç'
                                  : 'SKT: ${_selectedExpiryDate!.day}/${_selectedExpiryDate!.month}/${_selectedExpiryDate!.year}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                                lastDate: DateTime.now().add(const Duration(days: 1000)),
                              );
                              if (picked != null) {
                                setDialogState(() {
                                  _selectedExpiryDate = picked;
                                });
                              }
                            },
                          ),
                        ),
                        if (_selectedExpiryDate != null)
                          IconButton(
                            icon: const Icon(Icons.clear, color: Colors.red),
                            onPressed: () {
                              setDialogState(() {
                                _selectedExpiryDate = null;
                              });
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    final name = _addNameController.text.trim();
                    final amountStr = _addAmountController.text.trim();
                    final amount = double.tryParse(amountStr);

                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Lütfen geçerli bir malzeme adı girin.')),
                      );
                      return;
                    }
                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Lütfen geçerli bir miktar girin.')),
                      );
                      return;
                    }

                    appState.addPantryIngredient(Ingredient(
                      name: name,
                      amount: amount,
                      unit: _selectedUnit,
                      expiryDate: _selectedExpiryDate,
                    ));

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$name kiler listesine eklendi.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: const Text('Ekle'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditAmountDialog(BuildContext context, Ingredient ingredient) {
    final controller = TextEditingController(text: ingredient.amount.toString().replaceAll(RegExp(r'\.0$'), ''));
    final appState = Provider.of<AppState>(context, listen: false);
    DateTime? selectedExpiry = ingredient.expiryDate;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('${ingredient.name} Güncelle'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: 'Miktar (${ingredient.unit})',
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_month),
                          label: Text(
                            selectedExpiry == null
                                ? 'Son Kullanma Tarihi Seç'
                                : 'SKT: ${selectedExpiry!.day}/${selectedExpiry!.month}/${selectedExpiry!.year}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedExpiry ?? DateTime.now(),
                              firstDate: DateTime.now().subtract(const Duration(days: 30)),
                              lastDate: DateTime.now().add(const Duration(days: 1000)),
                            );
                            if (picked != null) {
                              setDialogState(() {
                                selectedExpiry = picked;
                              });
                            }
                          },
                        ),
                      ),
                      if (selectedExpiry != null)
                        IconButton(
                          icon: const Icon(Icons.clear, color: Colors.red),
                          onPressed: () {
                            setDialogState(() {
                              selectedExpiry = null;
                            });
                          },
                        ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('İptal'),
                ),
                TextButton(
                  onPressed: () {
                    appState.removePantryIngredient(ingredient.name);
                    Navigator.pop(context);
                  },
                  child: const Text('Sil', style: TextStyle(color: Colors.red)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final amount = double.tryParse(controller.text.trim());
                    if (amount != null && amount >= 0) {
                      appState.updatePantryIngredient(ingredient.name, amount, selectedExpiry);
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Geçerli bir miktar girin.')),
                      );
                    }
                  },
                  child: const Text('Kaydet'),
                ),
              ],
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

    // Filtered list
    final filteredPantry = appState.pantry.where((i) {
      return i.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    // Grouping: In stock vs out of stock
    final inStock = filteredPantry.where((i) => i.amount > 0).toList();
    final outOfStock = filteredPantry.where((i) => i.amount <= 0).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kilerim (Malzeme Stoğu)', style: TextStyle(fontWeight: FontWeight.bold)),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddIngredientDialog(context),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Search & Filter header
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Kilerde malzeme ara...',
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

          // Pantry items list
          Expanded(
            child: appState.pantry.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.kitchen_outlined, size: 80, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'Kileriniz Boş!',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Evdeki malzemeleri listeye ekleyin. Böylece yemek yaparken otomatik eksilir ve size uyan yemekler önerilir.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () => _showAddIngredientDialog(context),
                            icon: const Icon(Icons.add),
                            label: const Text('İlk Malzemeyi Ekle'),
                          ),
                        ],
                      ),
                    ),
                  )
                : filteredPantry.isEmpty
                    ? const Center(child: Text('Aradığınız malzeme bulunamadı.'))
                    : ListView(
                        padding: const EdgeInsets.all(12),
                        children: [
                          if (outOfStock.isNotEmpty) ...[
                            Text(
                              'Tükenen Malzemeler (${outOfStock.length})',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: Colors.red[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...outOfStock.map((i) => _buildIngredientTile(context, i, isOutOfStock: true)),
                            const SizedBox(height: 20),
                          ],
                          if (inStock.isNotEmpty) ...[
                            Text(
                              'Stoktaki Malzemeler (${inStock.length})',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: Colors.teal[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...inStock.map((i) => _buildIngredientTile(context, i, isOutOfStock: false)),
                          ],
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientTile(BuildContext context, Ingredient ingredient, {required bool isOutOfStock}) {
    final appState = Provider.of<AppState>(context, listen: false);
    final theme = Theme.of(context);

    String formatAmount(double val) {
      if (val == val.roundToDouble()) {
        return val.round().toString();
      }
      return val.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
    }

    String cleanAmount = formatAmount(ingredient.amount);

    final now = DateTime.now();
    bool isExpiringSoon = false;
    String expiryText = '';
    if (ingredient.expiryDate != null && ingredient.amount > 0) {
      final diff = ingredient.expiryDate!.difference(now).inDays;
      if (diff >= 0 && diff <= 3) {
        isExpiringSoon = true;
        expiryText = '⚠️ SKT Yaklaştı: ${ingredient.expiryDate!.day}/${ingredient.expiryDate!.month}/${ingredient.expiryDate!.year}';
      } else {
        expiryText = 'SKT: ${ingredient.expiryDate!.day}/${ingredient.expiryDate!.month}/${ingredient.expiryDate!.year}';
      }
    }

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: isOutOfStock
            ? BorderSide(color: Colors.red.withOpacity(0.3), width: 1)
            : isExpiringSoon
                ? BorderSide(color: Colors.amber[700]!.withOpacity(0.6), width: 1.5)
                : BorderSide.none,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            FoodImageProvider.getIngredientImage(ingredient.name),
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 40,
              height: 40,
              color: Colors.grey[200],
              child: const Icon(Icons.kitchen, color: Colors.grey),
            ),
          ),
        ),
        title: Text(
          ingredient.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: isOutOfStock ? TextDecoration.lineThrough : null,
            color: isOutOfStock ? Colors.grey : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isOutOfStock ? 'Stokta yok' : 'Stok: $cleanAmount ${ingredient.unit}',
              style: TextStyle(
                color: isOutOfStock ? Colors.red[600] : Colors.grey[600],
                fontSize: 12,
                fontWeight: isOutOfStock ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (expiryText.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                expiryText,
                style: TextStyle(
                  color: isExpiringSoon ? Colors.red[700] : Colors.grey[500],
                  fontSize: 11,
                  fontWeight: isExpiringSoon ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quick decrement
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed: () {
                if (ingredient.amount > 0) {
                  double step = ingredient.unit == 'g' || ingredient.unit == 'ml' ? 50 : 1;
                  double newVal = ingredient.amount - step;
                  appState.updatePantryIngredientAmount(ingredient.name, newVal < 0 ? 0 : newVal);
                }
              },
            ),
            // Tap amount to edit directly
            GestureDetector(
              onTap: () => _showEditAmountDialog(context, ingredient),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isOutOfStock ? Colors.red[50] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Düzenle',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isOutOfStock ? Colors.red[700] : theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
