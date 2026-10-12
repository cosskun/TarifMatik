import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/shopping_item.dart';
import '../models/receipt.dart';
import 'admin_panel_page.dart';
import 'detailed_report_page.dart';

class ShoppingBudgetPage extends StatefulWidget {
  final int initialTabIndex;
  const ShoppingBudgetPage({super.key, this.initialTabIndex = 0});

  @override
  State<ShoppingBudgetPage> createState() => _ShoppingBudgetPageState();
}

class _ShoppingBudgetPageState extends State<ShoppingBudgetPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int? _selectedFilterYear;
  int? _selectedFilterMonth;

  // Add shopping item form state
  final _itemNameCtrl = TextEditingController();
  final _itemAmountCtrl = TextEditingController();
  String _selectedUnit = 'adet';
  String _selectedCategory = 'Diğer';
  final List<String> _units = ['adet', 'kg', 'g', 'litre', 'ml', 'paket', 'kaşık', 'diş'];
  final List<String> _categories = [
    'Sebze/Meyve',
    'Süt Ürünleri',
    'Et & Şarküteri',
    'Kuru Gıda',
    'Tatlı',
    'İçecek',
    'Diğer'
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedFilterYear = now.year;
    _selectedFilterMonth = now.month;
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTabIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _itemNameCtrl.dispose();
    _itemAmountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alışveriş & Bütçe', style: TextStyle(fontWeight: FontWeight.bold)),
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.shopping_cart), text: 'Alışveriş Listesi'),
            Tab(icon: Icon(Icons.pie_chart), text: 'Fişlerim & Harcamalar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildShoppingListTab(context, appState),
          _buildBudgetAnalyticsTab(context, appState),
        ],
      ),
    );
  }

  // --- TAB 1: SHOPPING LIST ---
  Widget _buildShoppingListTab(BuildContext context, AppState appState) {
    final theme = Theme.of(context);
    final items = appState.shoppingList;
    final pendingItems = items.where((i) => !i.isBought).toList();
    final completedItems = items.where((i) => i.isBought).toList();

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Quick Add Form
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hızlı Ürün Ekle',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _itemNameCtrl,
                        decoration: const InputDecoration(
                          isDense: true,
                          labelText: 'Ürün Adı',
                          hintText: 'Örn: Süt, Elma',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _itemAmountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          isDense: true,
                          labelText: 'Miktar',
                          hintText: 'Örn: 2',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedUnit,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          isDense: true,
                          labelText: 'Birim',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        ),
                        items: _units.map((unit) {
                          return DropdownMenuItem(
                            value: unit, 
                            child: Text(unit, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedUnit = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedCategory,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          isDense: true,
                          labelText: 'Kategori',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        ),
                        items: _categories.map((cat) {
                          return DropdownMenuItem(
                            value: cat, 
                            child: Text(cat, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedCategory = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.add_shopping_cart, size: 18),
                    label: const Text('Listeye Ekle', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      final name = _itemNameCtrl.text.trim();
                      final amount = double.tryParse(_itemAmountCtrl.text) ?? 1.0;
                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Lütfen ürün adı girin!')),
                        );
                        return;
                      }
                      appState.addShoppingItem(name, amount, _selectedUnit, _selectedCategory);
                      _itemNameCtrl.clear();
                      _itemAmountCtrl.clear();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('"${appState.capitalize(name)}" alışveriş listesine eklendi.')),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Alınacaklar (${pendingItems.length})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (items.isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.green[700],
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                    ),
                    icon: const Icon(Icons.share, size: 16),
                    label: const Text('Paylaş', style: TextStyle(fontSize: 12)),
                    onPressed: () => _shareShoppingList(appState),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Listeyi Temizle?'),
                          content: const Text('Tüm alışveriş listesini temizlemek istediğinize emin misiniz?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
                            TextButton(
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                              onPressed: () {
                                appState.clearShoppingList();
                                Navigator.pop(ctx);
                              },
                              child: const Text('Temizle'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.delete_sweep, size: 18),
                    label: const Text('Temizle'),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.playlist_add_check, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 10),
                  Text(
                    'Alışveriş listeniz boş!',
                    style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          )
        else ...[
          ...pendingItems.map((item) => _buildShoppingItemRow(context, appState, item, false)),
          if (completedItems.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(),
            ),
            Text(
              'Satın Alınanlar (${completedItems.length})',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
            ),
            const SizedBox(height: 8),
            ...completedItems.map((item) => _buildShoppingItemRow(context, appState, item, true)),
          ],
        ],
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildShoppingItemRow(BuildContext context, AppState appState, ShoppingItem item, bool isBought) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Checkbox(
          value: isBought,
          activeColor: Colors.green,
          onChanged: (val) {
            if (isBought) {
              appState.toggleShoppingItem(item.id);
            } else {
              _showConfirmBoughtDialog(context, appState, item);
            }
          },
        ),
        title: Text(
          item.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: isBought ? TextDecoration.lineThrough : null,
            color: isBought ? Colors.grey : Colors.black87,
          ),
        ),
        subtitle: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                item.category,
                style: TextStyle(fontSize: 10, color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              '${item.amount % 1 == 0 ? item.amount.toInt() : item.amount} ${item.unit}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isBought && item.price > 0)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Text(
                  '${item.price.toStringAsFixed(2)} TL',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 13),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
              onPressed: () => appState.deleteShoppingItem(item.id),
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmBoughtDialog(BuildContext context, AppState appState, ShoppingItem item) {
    final amountCtrl = TextEditingController(text: item.amount.toString());
    final priceCtrl = TextEditingController();
    DateTime? expiryDate;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.green),
                  const SizedBox(width: 10),
                  Expanded(child: Text('${item.name} Satın Alındı')),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Alınan Miktar (${item.unit})',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: priceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Ödenen Toplam Tutar (TL)',
                        hintText: 'Örn: 45.50',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Date picker for expiry date
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        expiryDate == null
                            ? 'Son Kullanma Tarihi Seç'
                            : 'SKT: ${expiryDate!.day}.${expiryDate!.month}.${expiryDate!.year}',
                      ),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 7)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setStateDialog(() {
                            expiryDate = picked;
                          });
                        }
                      },
                    ),
                    if (expiryDate != null)
                      TextButton(
                        onPressed: () {
                          setStateDialog(() {
                            expiryDate = null;
                          });
                        },
                        child: const Text('Tarihi Temizle', style: TextStyle(color: Colors.red)),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  onPressed: () {
                    final finalAmount = double.tryParse(amountCtrl.text) ?? item.amount;
                    final price = double.tryParse(priceCtrl.text) ?? 0.0;

                    appState.completeShoppingItemAndPantryTransfer(
                      item.id,
                      finalAmount,
                      price,
                      expiryDate,
                    );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('"${item.name}" kilere eklendi ve harcama kaydedildi!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: const Text('Kilerime Aktar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _shareShoppingList(AppState appState) {
    final pending = appState.shoppingList.where((i) => !i.isBought).toList();
    if (pending.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paylaşılacak alınacak ürün bulunmamaktadır.')),
      );
      return;
    }

    final StringBuffer buffer = StringBuffer();
    buffer.writeln('🛒 *TarifMatik Alışveriş Listesi*');
    buffer.writeln('📅 ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}');
    buffer.writeln('------------------------------');
    for (var item in pending) {
      String amt = item.amount % 1 == 0 ? item.amount.toInt().toString() : item.amount.toString();
      buffer.writeln('▫️ [ ] $amt ${item.unit} ${item.name} (${item.category})');
    }
    buffer.writeln('------------------------------');
    buffer.writeln('Toplam: ${pending.length} ürün');

    Clipboard.setData(ClipboardData(text: buffer.toString()));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📋 Alışveriş listesi panoya kopyalandı! WhatsApp veya mesajda yapıştırabilirsiniz.'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showSetBudgetLimitDialog(BuildContext context, AppState appState) {
    final ctrl = TextEditingController(text: appState.monthlyBudgetLimit.toInt().toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.savings_outlined, color: Colors.indigo),
            SizedBox(width: 8),
            Text('Aylık Bütçe Hedefi'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Aylık mutfak ve market harcamalarınız için bir bütçe tavanı belirleyin. Harcamalarınız bu sınıra yaklaştığında uyarılırsınız.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Aylık Hedef Limit (TL)',
                hintText: 'Örn: 5000',
                prefixIcon: Icon(Icons.currency_lira),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final val = double.tryParse(ctrl.text);
              if (val != null && val > 0) {
                appState.setMonthlyBudgetLimit(val);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Aylık bütçe hedefi ${val.toStringAsFixed(0)} TL olarak güncellendi.'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyBudgetCapCard(BuildContext context, AppState appState, double monthlyTotal) {
    final theme = Theme.of(context);
    final limit = appState.monthlyBudgetLimit;
    final ratio = limit > 0 ? (monthlyTotal / limit) : 0.0;
    final progress = ratio.clamp(0.0, 1.0);
    final percent = (ratio * 100).round();

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (ratio >= 1.0) {
      statusColor = Colors.red;
      statusText = 'Bütçe Limiti Aşıldı! (%$percent)';
      statusIcon = Icons.error_outline;
    } else if (ratio >= 0.85) {
      statusColor = Colors.orange[800]!;
      statusText = 'Bütçe Sınırına Yaklaşıldı (%$percent)';
      statusIcon = Icons.warning_amber_rounded;
    } else {
      statusColor = Colors.green;
      statusText = 'Bütçeniz Güvende (%$percent)';
      statusIcon = Icons.check_circle_outline;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.savings_outlined, color: theme.colorScheme.primary, size: 24),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Aylık Bütçe Hedefi',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.edit, size: 14),
                  label: const Text('Hedefi Değiştir', style: TextStyle(fontSize: 12)),
                  onPressed: () => _showSetBudgetLimitDialog(context, appState),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${monthlyTotal.toStringAsFixed(0)} TL / ${limit.toStringAsFixed(0)} TL',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: statusColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Kalan Bütçe: ${(limit - monthlyTotal > 0 ? (limit - monthlyTotal) : 0).toStringAsFixed(0)} TL',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Hedef: ${limit.toStringAsFixed(0)} TL',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 2: BUDGET & ANALYTICS ---
  Widget _buildBudgetAnalyticsTab(BuildContext context, AppState appState) {
    final theme = Theme.of(context);
    final filterYear = _selectedFilterYear ?? DateTime.now().year;
    final filterMonth = _selectedFilterMonth ?? DateTime.now().month;

    final monthlyTotal = appState.getMonthlyTotalSpending(filterYear, filterMonth);
    final weeklyTotal = appState.getWeeklyTotalSpending();
    final categoriesMap = appState.getCategorySpendingBreakdown(filterYear, filterMonth);
    final productsMap = appState.getProductSpendingBreakdown(filterYear, filterMonth);
    final receiptsList = appState.receipts.where((r) {
      return r.date.year == filterYear && r.date.month == filterMonth;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Yıl/Ay Filtre Satırı
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: filterYear,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Yıl Seçin',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 2026, child: Text('2026')),
                    DropdownMenuItem(value: 2025, child: Text('2025')),
                    DropdownMenuItem(value: 2024, child: Text('2024')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedFilterYear = val;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: filterMonth,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Ay Seçin',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: List.generate(12, (index) => index + 1).map((m) {
                    return DropdownMenuItem(value: m, child: Text(_getMonthName(m), overflow: TextOverflow.ellipsis));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedFilterMonth = val;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // HARCAMA ÖZET KARTI (Vibrant Colors)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.colorScheme.primary, Colors.indigo[900]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Bu Ayki Harcama Özeti',
                        style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_getMonthName(filterMonth)} $filterYear',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '${monthlyTotal.toStringAsFixed(2)} TL',
                  style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Son 7 Gün (Haftalık)',
                            style: TextStyle(color: Colors.white60, fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${weeklyTotal.toStringAsFixed(2)} TL',
                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Kayıtlı Fiş Sayısı',
                            style: TextStyle(color: Colors.white60, fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${receiptsList.length} adet',
                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // AYLIK BÜTÇE HEDEFİ KARTI
          _buildMonthlyBudgetCapCard(context, appState, monthlyTotal),
          const SizedBox(height: 16),
          // DETAYLI EKONOMİ RAPORU BUTONU
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 1,
              ),
              icon: const Icon(Icons.analytics_outlined),
              label: const Text('Detaylı Ekonomi Raporu Görüntüle', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DetailedReportPage()),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // QUICK ECTION BUTTONS: SCAN & ADD MANUAL
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.document_scanner),
                  label: const Text('Fiş Tara (Mock)', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () => _showMockScannerDialog(context, appState),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Manuel Fiş Gir', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () => _showAddReceiptDialog(context, appState),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // KATEGORİSEL HARCAMA DAĞILIMI
          const Text(
            'Kategori Dağılımı',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          categoriesMap.isEmpty
              ? _buildEmptyAnalyticsCard('Bu ay henüz kategorize edilmiş harcama bulunmamaktadır.')
              : Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: categoriesMap.entries.map((entry) {
                        double percentage = monthlyTotal > 0 ? entry.value / monthlyTotal : 0.0;
                        return InkWell(
                          onTap: () => _showCategoryDetailsDialog(context, appState, entry.key, filterYear, filterMonth),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                            child: Column(
                              children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      entry.key,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${entry.value.toStringAsFixed(2)} TL (${(percentage * 100).toStringAsFixed(1)}%)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: percentage,
                                  minHeight: 8,
                                  backgroundColor: Colors.grey[200],
                                  valueColor: AlwaysStoppedAnimation<Color>(_getCategoryColor(entry.key)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    ),
                  ),
                ),
          const SizedBox(height: 24),

          // EN ÇOK HARCANAN ÜRÜNLER
          const Text(
            'En Çok Harcanan Ürünler',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          productsMap.isEmpty
              ? _buildEmptyAnalyticsCard('Bu ay harcanan ürün detayı bulunmamaktadır.')
              : Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    child: Column(
                      children: (productsMap.entries.toList()
                        ..sort((a, b) => b.value.compareTo(a.value)))
                        .take(5).map((entry) {
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.amber[50],
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.arrow_upward, color: Colors.orange, size: 18),
                            ),
                            title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            trailing: Text(
                              '${entry.value.toStringAsFixed(2)} TL',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                            ),
                          );
                        }).toList(),
                    ),
                  ),
                ),
          const SizedBox(height: 24),

          // FİŞ GEÇMİŞİ LİSTESİ
          const Text(
            'Fiş Geçmişi',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          receiptsList.isEmpty
              ? _buildEmptyAnalyticsCard('Kayıtlı fiş bulunmamaktadır.')
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: receiptsList.length,
                  itemBuilder: (context, index) {
                    final r = receiptsList[index];
                    return Card(
                      elevation: 0.5,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.receipt_long, color: theme.colorScheme.primary, size: 20),
                        ),
                        title: Text(
                          r.storeName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        subtitle: Text(
                          '${r.date.day}.${r.date.month}.${r.date.year} • ${r.items.length} ürün',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${r.totalAmount.toStringAsFixed(2)} TL',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                              onPressed: () => appState.deleteReceipt(r.id),
                            ),
                          ],
                        ),
                        onTap: () => _showReceiptDetailsDialog(context, r),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildEmptyAnalyticsCard(String text) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
        ),
      ),
    );
  }

  // --- MOCK RECIPE SCANNER ---
  void _showMockScannerDialog(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return const MockScannerWidget();
      },
    );
  }

  // --- ADD MANUAL RECEIPT ---
  void _showAddReceiptDialog(BuildContext context, AppState appState) {
    final storeCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();
    List<ShoppingItem> receiptItems = [];

    // Fields for adding an item to the receipt in-progress
    final itemNameCtrl = TextEditingController();
    final itemAmountCtrl = TextEditingController();
    String itemUnit = 'adet';
    String itemCategory = 'Diğer';
    final itemPriceCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.add_shopping_cart, color: Colors.orange),
                  SizedBox(width: 10),
                  Text('Manuel Fiş Ekle'),
                ],
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Store Name
                      TextField(
                        controller: storeCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Market Adı',
                          hintText: 'Örn: Migros, Şok, A101',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Date picker
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tarih: ${selectedDate.day}.${selectedDate.month}.${selectedDate.year}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          TextButton(
                            child: const Text('Tarih Değiştir'),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setStateDialog(() {
                                  selectedDate = picked;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      const Divider(),

                      // Current items list in receipt
                      const Text(
                        'Fişteki Ürünler:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      if (receiptItems.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text('Henüz ürün eklenmedi.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        )
                      else
                        ...receiptItems.map((item) {
                          return Card(
                            elevation: 0,
                            color: Colors.grey[100],
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            child: ListTile(
                              dense: true,
                              title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${item.amount} ${item.unit} • ${item.category}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('${item.price.toStringAsFixed(2)} TL', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 16),
                                    onPressed: () {
                                      setStateDialog(() {
                                        receiptItems.remove(item);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      const Divider(),

                      // Add Item Form inside receipt
                      const Text(
                        'Ürün Ekle:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: itemNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Ürün Adı',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: itemAmountCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Miktar',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: itemUnit,
                              decoration: const InputDecoration(
                                labelText: 'Birim',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              items: _units.map((unit) {
                                return DropdownMenuItem(value: unit, child: Text(unit));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setStateDialog(() => itemUnit = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: itemPriceCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Toplam Tutar (TL)',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: itemCategory,
                              decoration: const InputDecoration(
                                labelText: 'Kategori',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              items: _categories.map((cat) {
                                return DropdownMenuItem(value: cat, child: Text(cat));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setStateDialog(() => itemCategory = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Ürünü Fişe Ekle'),
                          onPressed: () {
                            final name = itemNameCtrl.text.trim();
                            final amount = double.tryParse(itemAmountCtrl.text) ?? 1.0;
                            final price = double.tryParse(itemPriceCtrl.text) ?? 0.0;

                            if (name.isEmpty) return;

                            setStateDialog(() {
                              receiptItems.add(
                                ShoppingItem(
                                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                                  name: appState.capitalize(name),
                                  amount: amount,
                                  unit: itemUnit,
                                  price: price,
                                  category: itemCategory,
                                  isBought: true,
                                ),
                              );
                              itemNameCtrl.clear();
                              itemAmountCtrl.clear();
                              itemPriceCtrl.clear();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                  onPressed: () async {
                    final store = storeCtrl.text.trim();
                    if (store.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Lütfen market adı girin!')),
                      );
                      return;
                    }
                    if (receiptItems.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Lütfen en az bir ürün ekleyin!')),
                      );
                      return;
                    }

                    // Calculate total
                    double total = receiptItems.fold(0.0, (sum, item) => sum + item.price);

                    // Add receipt
                    await appState.addReceipt(store, selectedDate, receiptItems, total);

                    // Auto transfer each item in receipt to pantry
                    for (var item in receiptItems) {
                      await appState.addOrUpdatePantryIngredient(item.name, item.amount, item.unit);
                    }

                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('"${store}" fişi kaydedildi ve tüm ürünler kilere aktarıldı!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: const Text('Fişi Kaydet & Aktar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- DETAILS DIALOG ---
  void _showReceiptDetailsDialog(BuildContext context, Receipt r) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.receipt_long, color: Colors.blue),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.storeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('${r.date.day}.${r.date.month}.${r.date.year}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: r.items.length,
              itemBuilder: (ctx2, i) {
                final item = r.items[i];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${item.amount} ${item.unit} • ${item.category}'),
                  trailing: Text(
                    '${item.price.toStringAsFixed(2)} TL',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Kapat'),
            ),
          ],
        );
      },
    );
  }

  // --- HELPERS ---
  String _getMonthName(int month) {
    const names = [
      '',
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık'
    ];
    return names[month];
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Sebze/Meyve':
        return Colors.green;
      case 'Süt Ürünleri':
        return Colors.blue;
      case 'Et & Şarküteri':
        return Colors.red;
      case 'Kuru Gıda':
        return Colors.brown;
      case 'Tatlı':
        return Colors.pink;
      case 'İçecek':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  void _showCategoryDetailsDialog(BuildContext context, AppState appState, String categoryName, int filterYear, int filterMonth) {
    final List<Map<String, dynamic>> categoryPurchases = [];
    double totalSpent = 0.0;

    for (var receipt in appState.receipts) {
      if (receipt.date.year == filterYear && receipt.date.month == filterMonth) {
        String cleanedMarket = receipt.storeName.split('(')[0].trim();
        for (var item in receipt.items) {
          if (item.category == categoryName) {
            categoryPurchases.add({
              'name': item.name,
              'amount': item.amount,
              'unit': item.unit,
              'price': item.price,
              'market': cleanedMarket,
              'date': receipt.date,
            });
            totalSpent += item.price;
          }
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(_getCategoryIcon(categoryName), color: _getCategoryColor(categoryName)),
              const SizedBox(width: 8),
              Text('$categoryName Detayları', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Toplam Harcama:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue)),
                      Text('${totalSpent.toStringAsFixed(2)} TL', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (categoryPurchases.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Text('Bu kategoriye ait harcama bulunmamaktadır.', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  )
                else
                  Container(
                    constraints: const BoxConstraints(maxHeight: 250),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: categoryPurchases.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = categoryPurchases[index];
                        final date = item['date'] as DateTime;
                        final String dateStr = '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          subtitle: Text('${item['market']} • $dateStr', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          trailing: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('${(item['price'] as double).toStringAsFixed(2)} TL', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 2),
                              Text('${item['amount'] % 1 == 0 ? item['amount'].toInt() : item['amount']} ${item['unit']}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kapat'),
            ),
          ],
        );
      },
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Sebze/Meyve':
        return Icons.eco;
      case 'Süt Ürünleri':
        return Icons.egg_outlined;
      case 'Et & Şarküteri':
        return Icons.kebab_dining;
      case 'Kuru Gıda':
        return Icons.breakfast_dining;
      case 'Tatlı':
        return Icons.cake_outlined;
      case 'İçecek':
        return Icons.local_drink_outlined;
      default:
        return Icons.shopping_bag_outlined;
    }
  }
}

// --- ANIMATED MOCK SCANNER WIDGET ---
class MockScannerWidget extends StatefulWidget {
  const MockScannerWidget({super.key});

  @override
  State<MockScannerWidget> createState() => _MockScannerWidgetState();
}

class _MockScannerWidgetState extends State<MockScannerWidget> with SingleTickerProviderStateMixin {
  late AnimationController _laserController;
  bool _isScanning = false;
  bool _scanComplete = false;
  String _scanStatus = 'Lütfen fiş görselini yükleyin veya kameradan fotoğraf çekin.';
  List<ShoppingItem> _scannedItems = [];

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _laserController.dispose();
    super.dispose();
  }

  void _startScan() {
    setState(() {
      _isScanning = true;
      _scanStatus = 'Fiş taranıyor... Lütfen bekleyin.';
    });
    _laserController.repeat(reverse: true);

    Timer(const Duration(seconds: 3), () {
      _laserController.stop();
      setState(() {
        _isScanning = false;
        _scanComplete = true;
        _scanStatus = 'Tarama tamamlandı! Ürünleri ve fiyatları teyit edip düzenleyebilirsiniz.';
        _scannedItems = [
          ShoppingItem(id: 'mock_s1', name: 'Kaşar Peyniri', amount: 1.0, unit: 'adet', price: 145.00, category: 'Süt Ürünleri', isBought: true),
          ShoppingItem(id: 'mock_s2', name: 'Domates', amount: 2.0, unit: 'kg', price: 70.00, category: 'Sebze/Meyve', isBought: true),
          ShoppingItem(id: 'mock_s3', name: 'Dana Kıyma', amount: 1.0, unit: 'kg', price: 420.00, category: 'Et & Şarküteri', isBought: true),
          ShoppingItem(id: 'mock_s4', name: 'Maden Suyu', amount: 6.0, unit: 'adet', price: 36.00, category: 'İçecek', isBought: true),
        ];
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    double total = _scannedItems.fold(0.0, (sum, i) => sum + i.price);

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.qr_code_scanner, color: Colors.teal),
          SizedBox(width: 10),
          Text('Akıllı Fiş Tarayıcı'),
        ],
      ),
      content: SizedBox(
        width: 550,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status bar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _scanComplete ? Colors.green[50] : Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _scanStatus,
                style: TextStyle(
                  color: _scanComplete ? Colors.green[800] : Colors.blue[800],
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),

            // Animated scan area
            if (!_scanComplete)
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[300]!, width: 2),
                    ),
                    child: _isScanning
                        ? Opacity(
                            opacity: 0.6,
                            child: Image.network(
                              'https://images.unsplash.com/photo-1554415707-6e8cfc93fe23?q=80&w=300&auto=format&fit=crop',
                              fit: BoxFit.cover,
                            ),
                          )
                        : Icon(Icons.receipt_long, size: 72, color: Colors.grey[400]),
                  ),
                  if (_isScanning)
                    AnimatedBuilder(
                      animation: _laserController,
                      builder: (context, child) {
                        return Positioned(
                          top: _laserController.value * 190,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.greenAccent,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.greenAccent.withOpacity(0.8),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  if (!_isScanning && !_scanComplete)
                    Positioned(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Fotoğraf Çek / Yükle'),
                        onPressed: _startScan,
                      ),
                    ),
                ],
              )
            else
              // Scan result list (Editable)
              Container(
                constraints: const BoxConstraints(maxHeight: 350),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Market: Migros (Düzenlenebilir)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.teal)),
                        Text('Tarih: Bugün', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                      ],
                    ),
                    const Divider(),
                    ..._scannedItems.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;

                      return Card(
                        color: Colors.grey[50],
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey[200]!),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: item.name,
                                      decoration: const InputDecoration(
                                        labelText: 'Ürün Adı',
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      ),
                                      onChanged: (val) {
                                        _scannedItems[index] = item.copyWith(name: val);
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                    onPressed: () {
                                      setState(() {
                                        _scannedItems.removeAt(index);
                                      });
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      initialValue: item.amount.toString(),
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: const InputDecoration(
                                        labelText: 'Miktar',
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      ),
                                      onChanged: (val) {
                                        double? parsed = double.tryParse(val);
                                        if (parsed != null) {
                                          _scannedItems[index] = item.copyWith(amount: parsed);
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      initialValue: item.unit,
                                      decoration: const InputDecoration(
                                        labelText: 'Birim',
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      ),
                                      onChanged: (val) {
                                        _scannedItems[index] = item.copyWith(unit: val);
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    flex: 3,
                                    child: TextFormField(
                                      initialValue: item.price.toString(),
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: const InputDecoration(
                                        labelText: 'Tutar (TL)',
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      ),
                                      onChanged: (val) {
                                        double? parsed = double.tryParse(val);
                                        if (parsed != null) {
                                          setState(() {
                                            _scannedItems[index] = item.copyWith(price: parsed);
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    flex: 4,
                                    child: DropdownButtonFormField<String>(
                                      value: item.category,
                                      decoration: const InputDecoration(
                                        labelText: 'Kategori',
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                      ),
                                      style: const TextStyle(fontSize: 11, color: Colors.black87),
                                      items: const [
                                        DropdownMenuItem(value: 'Sebze/Meyve', child: Text('Sebze/Meyve', style: TextStyle(fontSize: 9))),
                                        DropdownMenuItem(value: 'Süt Ürünleri', child: Text('Süt Ürünleri', style: TextStyle(fontSize: 9))),
                                        DropdownMenuItem(value: 'Et & Şarküteri', child: Text('Et & Şarküteri', style: TextStyle(fontSize: 9))),
                                        DropdownMenuItem(value: 'Kuru Gıda', child: Text('Kuru Gıda', style: TextStyle(fontSize: 9))),
                                        DropdownMenuItem(value: 'Tatlı', child: Text('Tatlı', style: TextStyle(fontSize: 9))),
                                        DropdownMenuItem(value: 'İçecek', child: Text('İçecek', style: TextStyle(fontSize: 9))),
                                        DropdownMenuItem(value: 'Diğer', child: Text('Diğer', style: TextStyle(fontSize: 9))),
                                      ],
                                      onChanged: (val) {
                                        if (val != null) {
                                          _scannedItems[index] = item.copyWith(category: val);
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 8),
                    // Add new item button
                    TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: Colors.teal),
                      icon: const Icon(Icons.add_circle_outline, size: 18),
                      label: const Text('Yeni Ürün Ekle', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () {
                        setState(() {
                          _scannedItems.add(ShoppingItem(
                            id: DateTime.now().microsecondsSinceEpoch.toString(),
                            name: '',
                            amount: 1.0,
                            unit: 'adet',
                            price: 0.0,
                            category: 'Diğer',
                            isBought: true,
                          ));
                        });
                      },
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Toplam Tutar:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('${total.toStringAsFixed(2)} TL', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.green)),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Kapat'),
        ),
        if (_scanComplete)
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () async {
              // Add edited receipt log
              await appState.addReceipt('Migros (Taranan Fiş)', DateTime.now(), _scannedItems, total);

              // Auto pantry transfer
              for (var item in _scannedItems) {
                if (item.name.trim().isNotEmpty) {
                  await appState.addOrUpdatePantryIngredient(item.name, item.amount, item.unit);
                }
              }

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fiş başarıyla doğrulandı ve aktarıldı! Tüm ürünler kilerime eklendi ve harcamalar güncellendi.'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Teyit Et & Kilere Aktar'),
          ),
      ],
    );
  }
}
