import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/api_service.dart';

/// Budget overview page – Flutter implementation of the CoinTrack MVP budget screen.
class BudgetPage extends StatelessWidget {
  const BudgetPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBg : AppColors.lightBg;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    // Placeholder data – in the future, replace with:
    // final data = await ApiService.fetchBudgetOverview();
    final categories = ApiService.exampleBudgetCategories;

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
                  'Budget — March 2025',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: mutedColor,
                    side: BorderSide(color: borderColor),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('+ Category', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Planned / Actual / Remaining summary cards
            Row(
              children: [
                _SummaryCard(
                  label: 'Planned',
                  value: 'Ksh 87,750',
                  color: mutedColor,
                  cardColor: cardColor,
                  borderColor: borderColor,
                ),
                const SizedBox(width: 10),
                _SummaryCard(
                  label: 'Actual',
                  value: 'Ksh 84,800',
                  color: AppColors.warning,
                  cardColor: cardColor,
                  borderColor: borderColor,
                ),
                const SizedBox(width: 10),
                _SummaryCard(
                  label: 'Remaining',
                  value: 'Ksh 2,950',
                  color: AppColors.accentGreen,
                  cardColor: cardColor,
                  borderColor: borderColor,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              children: categories.map((cat) {
                final planned = cat.planned;
                final actual = cat.actual;
                final pct = (actual / planned).clamp(0, 1);
                final over = actual > planned;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: over
                          ? AppColors.danger.withOpacity(0.3)
                          : borderColor,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            cat.label,
                            style: TextStyle(
                              fontSize: 14,
                              color: textColor,
                            ),
                          ),
                          _TagChip(text: cat.tag, kind: cat.kind),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: pct.toDouble(),
                          minHeight: 6,
                          backgroundColor: borderColor,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            over ? AppColors.danger : AppColors.accentGreen,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Planned: Ksh ${planned.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: mutedColor,
                            ),
                          ),
                          Text(
                            'Actual: Ksh ${actual.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: over
                                  ? AppColors.danger
                                  : AppColors.accentGreen,
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

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color cardColor;
  final Color borderColor;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.cardColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String text;
  final String kind; // need / want / save

  const _TagChip({required this.text, required this.kind});

  @override
  Widget build(BuildContext context) {
    Color border;
    Color bg;
    Color fg;
    switch (kind) {
      case 'need':
        border = AppColors.purple.withOpacity(0.3);
        bg = AppColors.purple.withOpacity(0.15);
        fg = AppColors.purple;
        break;
      case 'want':
        border = AppColors.warning.withOpacity(0.3);
        bg = AppColors.warning.withOpacity(0.12);
        fg = AppColors.warning;
        break;
      default:
        border = AppColors.accentGreen.withOpacity(0.25);
        bg = AppColors.accentGreen.withOpacity(0.1);
        fg = AppColors.accentGreen;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        color: bg,
        border: Border.all(color: border),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

