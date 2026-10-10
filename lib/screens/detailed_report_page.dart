import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/shopping_item.dart';
import '../models/receipt.dart';
import 'admin_panel_page.dart';

class DetailedReportPage extends StatefulWidget {
  const DetailedReportPage({super.key});

  @override
  State<DetailedReportPage> createState() => _DetailedReportPageState();
}

class _DetailedReportPageState extends State<DetailedReportPage> {
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  String _selectedCategory = 'Hepsi';
  String _selectedMarket = 'Hepsi';
  String _searchQuery = '';

  final List<String> _categories = [
    'Hepsi',
    'Sebze/Meyve',
    'Süt Ürünleri',
    'Et & Şarküteri',
    'Kuru Gıda',
    'Tatlı',
    'İçecek',
    'Diğer'
  ];

  final List<int> _years = [2026, 2025, 2024];

  String _getMonthName(int month) {
    const months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = Provider.of<AppState>(context);

    // 1. Gather all unique market names from receipts to populate market filter
    final markets = {'Hepsi'};
    for (var r in appState.receipts) {
      if (r.storeName.isNotEmpty) {
        // Clean market name from brackets or tags (e.g. Migros (Taranan Fiş) -> Migros)
        String cleaned = r.storeName.split('(')[0].trim();
        markets.add(cleaned);
      }
    }

    // 2. Fetch current filtered items
    final List<Map<String, dynamic>> filteredPurchases = [];
    double totalSpent = 0.0;

    for (var receipt in appState.receipts) {
      // Date check
      if (receipt.date.year == _selectedYear && receipt.date.month == _selectedMonth) {
        String cleanedMarket = receipt.storeName.split('(')[0].trim();
        if (_selectedMarket == 'Hepsi' || cleanedMarket == _selectedMarket) {
          for (var item in receipt.items) {
            // Category check
            if (_selectedCategory == 'Hepsi' || item.category == _selectedCategory) {
              // Search query check
              if (_searchQuery.isEmpty || item.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
                filteredPurchases.add({
                  'name': item.name,
                  'amount': item.amount,
                  'unit': item.unit,
                  'price': item.price,
                  'market': cleanedMarket,
                  'date': receipt.date,
                  'category': item.category,
                });
                totalSpent += item.price;
              }
            }
          }
        }
      }
    }

    // 3. Sort purchases by date desc
    filteredPurchases.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    // 4. Calculate trend comparison (current month vs previous month)
    int prevYear = _selectedMonth == 1 ? _selectedYear - 1 : _selectedYear;
    int prevMonth = _selectedMonth == 1 ? 12 : _selectedMonth - 1;
    double prevMonthTotal = appState.getMonthlyTotalSpending(prevYear, prevMonth);
    double currentMonthTotal = appState.getMonthlyTotalSpending(_selectedYear, _selectedMonth);
    double diff = currentMonthTotal - prevMonthTotal;
    double percentageDiff = prevMonthTotal > 0 ? (diff / prevMonthTotal) * 100 : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detaylı Ekonomi Raporu', style: TextStyle(fontWeight: FontWeight.bold)),
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
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FILTERS SECTION
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filtreleme & Arama',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _selectedYear,
                            decoration: const InputDecoration(
                              labelText: 'Yıl',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            items: _years.map((y) {
                              return DropdownMenuItem(value: y, child: Text(y.toString()));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedYear = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _selectedMonth,
                            decoration: const InputDecoration(
                              labelText: 'Ay',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            items: List.generate(12, (i) => i + 1).map((m) {
                              return DropdownMenuItem(value: m, child: Text(_getMonthName(m)));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedMonth = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            decoration: const InputDecoration(
                              labelText: 'Kategori',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            items: _categories.map((c) {
                              return DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 12)));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedCategory = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedMarket,
                            decoration: const InputDecoration(
                              labelText: 'Market / Bayi',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            items: markets.map((m) {
                              return DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 12)));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedMarket = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Ürün Adı Ara',
                        prefixIcon: Icon(Icons.search, size: 20),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: (val) {
                        setState(() => _searchQuery = val);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // REPORT METRICS
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: Colors.teal[50],
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Filtrelenmiş Toplam', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal)),
                          const SizedBox(height: 6),
                          Text('${totalSpent.toStringAsFixed(2)} TL', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Card(
                    color: Colors.indigo[50],
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Ürün Adedi', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo)),
                          const SizedBox(height: 6),
                          Text('${filteredPurchases.length} Kalem', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // TREND ANALİZİ KARTI
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: diff <= 0 ? Colors.green[50] : Colors.red[50],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        diff <= 0 ? Icons.trending_down : Icons.trending_up,
                        color: diff <= 0 ? Colors.green : Colors.red,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Trend Analizi (${_getMonthName(prevMonth)} vs ${_getMonthName(_selectedMonth)})',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            diff <= 0
                                ? 'Geçen aya göre %${percentageDiff.abs().toStringAsFixed(1)} daha az harcama yaptınız! (Fark: ${diff.abs().toStringAsFixed(2)} TL)'
                                : 'Geçen aya göre %${percentageDiff.toStringAsFixed(1)} daha fazla harcama yaptınız! (Fark: ${diff.toStringAsFixed(2)} TL)',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ITEM DETAILS LIST
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Harcama Detayları',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  '${filteredPurchases.length} sonuç listelendi',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 10),

            filteredPurchases.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40.0),
                      child: Column(
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 10),
                          const Text(
                            'Seçilen filtrelere uygun harcama bulunamadı.',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  )
                : Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredPurchases.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = filteredPurchases[index];
                        final date = item['date'] as DateTime;
                        final String dateStr = '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: Colors.teal[50],
                            radius: 18,
                            child: Icon(
                              _getCategoryIcon(item['category']),
                              color: Colors.teal[800],
                              size: 16,
                            ),
                          ),
                          title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          subtitle: Text('${item['market']} • $dateStr', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          trailing: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${(item['price'] as double).toStringAsFixed(2)} TL',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${item['amount'] % 1 == 0 ? item['amount'].toInt() : item['amount']} ${item['unit']}',
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                            ],
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
