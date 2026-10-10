import 'package:flutter/material.dart';
import '../../core/utils/formatters.dart';

class BudgetCapWidget extends StatelessWidget {
  final double monthlyTotal;
  final double budgetLimit;
  final VoidCallback onEditLimit;

  const BudgetCapWidget({
    super.key,
    required this.monthlyTotal,
    required this.budgetLimit,
    required this.onEditLimit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = budgetLimit > 0 ? (monthlyTotal / budgetLimit) : 0.0;
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

    final remaining = budgetLimit - monthlyTotal > 0 ? (budgetLimit - monthlyTotal) : 0.0;

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
                Row(
                  children: [
                    Icon(Icons.savings_outlined, color: theme.colorScheme.primary, size: 24),
                    const SizedBox(width: 8),
                    const Text(
                      'Aylık Bütçe Hedefi',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.edit, size: 14),
                  label: const Text('Hedefi Değiştir', style: TextStyle(fontSize: 12)),
                  onPressed: onEditLimit,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${Formatters.formatPrice(monthlyTotal, showDecimals: false)} / ${Formatters.formatPrice(budgetLimit, showDecimals: false)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: statusColor,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
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
                backgroundColor: Colors.grey.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Kalan Bütçe: ${Formatters.formatPrice(remaining, showDecimals: false)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  'Hedef: ${Formatters.formatPrice(budgetLimit, showDecimals: false)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
