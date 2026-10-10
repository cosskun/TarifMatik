import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/recipe.dart';
import '../models/ingredient.dart';

class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({super.key});

  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AppState>(context, listen: false).currentUser;
    // Admin has 2 tabs, content manager only has recipe management
    int tabCount = (user?.role == 'admin') ? 2 : 1;
    _tabController = TabController(length: tabCount, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Parses text lines into List<Ingredient>
  List<Ingredient> _parseIngredients(String text) {
    List<Ingredient> result = [];
    final lines = text.split('\n');
    for (var line in lines) {
      if (line.trim().isEmpty) continue;
      final parts = line.split(':');
      if (parts.length < 2) continue;
      final name = parts[0].trim();
      final rest = parts[1].trim();
      
      // Matches numbers with decimal points or commas, followed by optional unit string
      final match = RegExp(r'^([\d\.,]+)\s*(.*)$').firstMatch(rest);
      if (match != null) {
        final amtStr = match.group(1)!.replaceAll(',', '.');
        final amount = double.tryParse(amtStr) ?? 0.0;
        final unit = match.group(2)!.trim();
        result.add(Ingredient(name: name, amount: amount, unit: unit));
      } else {
        result.add(Ingredient(name: name, amount: 0, unit: rest));
      }
    }
    return result;
  }

  // Format List<Ingredient> back to text format for editing
  String _formatIngredientsForEdit(List<Ingredient> ingredients) {
    return ingredients.map((i) {
      // Format number to remove .0 if it's whole
      final amt = i.amount % 1 == 0 ? i.amount.toInt().toString() : i.amount.toString();
      return '${i.name}: $amt ${i.unit}';
    }).join('\n');
  }

  void _showRecipeDialog([Recipe? recipe]) {
    final theme = Theme.of(context);
    final isEdit = recipe != null;
    
    final nameCtrl = TextEditingController(text: recipe?.name ?? '');
    final emojiCtrl = TextEditingController(text: recipe?.emoji ?? '🍲');
    final durationCtrl = TextEditingController(text: recipe?.durationMinutes.toString() ?? '30');
    final servingsCtrl = TextEditingController(text: recipe?.baseServings.toString() ?? '4');
    final ingredientsCtrl = TextEditingController(
      text: recipe != null ? _formatIngredientsForEdit(recipe.ingredients) : '',
    );
    final instructionsCtrl = TextEditingController(
      text: recipe?.instructions.join('\n') ?? '',
    );
    
    String category = recipe?.category ?? 'Akşam Yemeği';
    final categories = ['Kahvaltı', 'Öğle Yemeği', 'Akşam Yemeği', 'İçecek', 'Tatlı'];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                isEdit ? 'Tarifi Düzenle' : 'Yeni Tarif Ekle',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: nameCtrl,
                              decoration: const InputDecoration(labelText: 'Tarif Adı'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 1,
                            child: TextField(
                              controller: emojiCtrl,
                              decoration: const InputDecoration(labelText: 'Emoji (Örn: 🍕)'),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              value: category,
                              decoration: const InputDecoration(labelText: 'Kategori'),
                              items: categories.map((cat) {
                                return DropdownMenuItem(value: cat, child: Text(cat));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() {
                                    category = val;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 1,
                            child: TextField(
                              controller: durationCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Süre (Dakika)'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 1,
                            child: TextField(
                              controller: servingsCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Porsiyon'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: ingredientsCtrl,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          labelText: 'Malzemeler (Her satıra bir malzeme - Adı: Miktar Birim)',
                          hintText: 'Soğan: 1 adet\nTereyağı: 20 g\nTuz: 4 g',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: instructionsCtrl,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          labelText: 'Yapılışı (Her satıra bir adım)',
                          hintText: 'Soğanları doğrayın.\nTencerede kavurun.\nSıcak servis yapın.',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;
                    
                    final parsedIngredients = _parseIngredients(ingredientsCtrl.text);
                    final parsedInstructions = instructionsCtrl.text
                        .split('\n')
                        .map((s) => s.trim())
                        .where((s) => s.isNotEmpty)
                        .toList();

                    final newRecipe = Recipe(
                      id: isEdit ? recipe.id : 'custom_${DateTime.now().millisecondsSinceEpoch}',
                      name: name,
                      category: category,
                      durationMinutes: int.tryParse(durationCtrl.text) ?? 30,
                      baseServings: int.tryParse(servingsCtrl.text) ?? 4,
                      emoji: emojiCtrl.text.trim(),
                      ingredients: parsedIngredients,
                      instructions: parsedInstructions,
                    );

                    final appState = Provider.of<AppState>(context, listen: false);
                    if (isEdit) {
                      appState.updateRecipe(newRecipe);
                    } else {
                      appState.addRecipe(newRecipe);
                    }
                    Navigator.pop(context);
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isEdit ? 'Tarif başarıyla güncellendi!' : 'Yeni tarif başarıyla eklendi!')),
                    );
                  },
                  child: Text(isEdit ? 'Kaydet' : 'Ekle'),
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
    final theme = Theme.of(context);
    final appState = Provider.of<AppState>(context);
    final currentUser = appState.currentUser;
    final isAdmin = currentUser?.role == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yönetim Paneli', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          tabs: [
            const Tab(icon: Icon(Icons.restaurant_menu), text: 'Tarif Yönetimi'),
            if (isAdmin) const Tab(icon: Icon(Icons.people), text: 'Kullanıcı Yetkileri'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Recipe Management
          _buildRecipeManagementTab(appState),
          
          // Tab 2: User Roles
          if (isAdmin) _buildUserRolesTab(appState),
        ],
      ),
    );
  }

  Widget _buildRecipeManagementTab(AppState appState) {
    final theme = Theme.of(context);
    final filteredRecipes = appState.recipes.where((r) {
      return r.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.category.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tarif adı veya kategori ile ara...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () => _showRecipeDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Yeni Tarif', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: filteredRecipes.length,
              itemBuilder: (context, index) {
                final recipe = filteredRecipes[index];
                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: Text(
                      recipe.emoji,
                      style: const TextStyle(fontSize: 32),
                    ),
                    title: Text(
                      recipe.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${recipe.category} • ${recipe.durationMinutes} dk • ${recipe.baseServings} Porsiyon',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showRecipeDialog(recipe),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text('Tarifi Sil'),
                                  content: Text('"${recipe.name}" tarifini silmek istediğinize emin misiniz?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('İptal'),
                                    ),
                                    TextButton(
                                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                                      onPressed: () {
                                        appState.deleteRecipe(recipe.id);
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('"${recipe.name}" silindi!')),
                                        );
                                      },
                                      child: const Text('Sil'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserRolesTab(AppState appState) {
    final currentUser = appState.currentUser;
    final users = appState.users;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active User / Session Info Card
          Card(
            color: theme.colorScheme.primary.withOpacity(0.06),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.2), width: 1.5),
            ),
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.shield_outlined,
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mevcut Aktif Kullanıcı',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentUser?.username ?? 'Misafir',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Çevrimiçi • Rol: ${currentUser?.role == 'admin' ? 'Admin' : currentUser?.role == 'content_manager' ? 'İçerik Yöneticisi' : 'Üye'}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Tüm Kayıtlı Kullanıcılar (${users.length})',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                final isSelf = currentUser?.username == user.username;

                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  user.username,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                if (isSelf) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green[50],
                                      border: Border.all(color: Colors.green[200]!),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'Aktif',
                                      style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isSelf ? 'Siz (Aktif Oturum)' : 'Kullanıcı hesabı',
                              style: TextStyle(color: isSelf ? Colors.blue : Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                        // Role selector
                        DropdownButton<String>(
                          value: user.role,
                          disabledHint: Text(user.role),
                          onChanged: isSelf
                              ? null // Cannot change their own role to avoid locking themselves out
                              : (newRole) {
                                  if (newRole != null) {
                                    appState.updateUserRole(user.username, newRole);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('"${user.username}" yetkisi "${newRole}" olarak güncellendi!')),
                                    );
                                  }
                                },
                          items: const [
                            DropdownMenuItem(value: 'admin', child: Text('Admin')),
                            DropdownMenuItem(value: 'content_manager', child: Text('İçerik Yöneticisi')),
                            DropdownMenuItem(value: 'member', child: Text('Üye')),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
