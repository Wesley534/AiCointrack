import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/api_service.dart';

/// Shopping lists overview page.
class ShoppingListsPage extends StatelessWidget {
  const ShoppingListsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBg : AppColors.lightBg;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    final lists = ApiService.exampleShoppingLists;

    return Container(
      color: bgColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Shopping Lists',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accentGreen,
                    side: BorderSide(color: borderColor),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('+ New List', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              children: lists.map((l) {
                final pct = (l.total / l.budget).clamp(0, 1);
                Color barColor;
                Color border;
                switch (l.status) {
                  case 'red':
                    barColor = AppColors.danger;
                    border = AppColors.danger.withOpacity(0.3);
                    break;
                  case 'yellow':
                    barColor = AppColors.warning;
                    border = AppColors.warning.withOpacity(0.3);
                    break;
                  default:
                    barColor = AppColors.accentGreen;
                    border = borderColor;
                }
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          _StatusPill(list: l),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: pct.toDouble(),
                          minHeight: 6,
                          backgroundColor: borderColor,
                          valueColor: AlwaysStoppedAnimation<Color>(barColor),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Est. Ksh ${l.total.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: mutedColor,
                            ),
                          ),
                          Text(
                            'Budget: Ksh ${l.budget.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: mutedColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Detail page for a single shopping list.
class ShoppingDetailPage extends StatelessWidget {
  const ShoppingDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBg : AppColors.lightBg;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    final detail = ApiService.exampleShoppingDetail;

    return Container(
      color: bgColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  color: mutedColor,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(width: 4),
                Text(
                  detail.title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 44),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  color: AppColors.purple.withOpacity(0.15),
                  border: Border.all(
                    color: AppColors.purple.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  'Linked: Food budget',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.purple,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL ESTIMATED',
                        style: TextStyle(
                          fontSize: 11,
                          color: mutedColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ksh ${detail.total.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'BUDGET REMAINING',
                        style: TextStyle(
                          fontSize: 11,
                          color: mutedColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ksh ${detail.remaining.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accentGreen,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...detail.items.map(
              (item) => Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: cardColor,
                              border: Border.all(color: borderColor),
                            ),
                            child: const Center(child: Text('☐')),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Qty: ${item.qty}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: mutedColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Text(
                        'Ksh ${item.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Divider(height: 1, color: borderColor),
                  const SizedBox(height: 10),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGreen,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('✓ Checkout → Log as Expenses'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final ShoppingListExample list;

  const _StatusPill({required this.list});

  @override
  Widget build(BuildContext context) {
    Color border;
    Color bg;
    Color fg;
    switch (list.status) {
      case 'red':
        border = AppColors.danger.withOpacity(0.3);
        bg = AppColors.danger.withOpacity(0.1);
        fg = AppColors.danger;
        break;
      case 'yellow':
        border = AppColors.warning.withOpacity(0.3);
        bg = AppColors.warning.withOpacity(0.1);
        fg = AppColors.warning;
        break;
      default:
        border = AppColors.accentGreen.withOpacity(0.3);
        bg = AppColors.accentGreen.withOpacity(0.1);
        fg = AppColors.accentGreen;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        color: bg,
        border: Border.all(color: border),
      ),
      child: Text(
        '${list.items} items',
        style: TextStyle(
          fontSize: 11,
          color: fg,
        ),
      ),
    );
  }
}

