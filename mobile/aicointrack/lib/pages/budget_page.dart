import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/api_service.dart';

/// Budget overview page – Flutter implementation of the CoinTrack MVP budget screen.
class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  late Future<List<BudgetCategoryExample>> _budgetsFuture;

  @override
  void initState() {
    super.initState();
    _budgetsFuture = ApiService.fetchBudgetOverview();
  }

  void _refresh() {
    setState(() {
      _budgetsFuture = ApiService.fetchBudgetOverview();
    });
  }

  static String _currentMonth() {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final now = DateTime.now();
    return '${months[now.month]} ${now.year}';
  }

  void _showAddBudgetModal(BuildContext context) {
    final labelController = TextEditingController();
    final plannedController = TextEditingController();
    String tag = 'need';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkBg
          : AppColors.lightBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: StatefulBuilder(
            builder: (ctx, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add Category',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkText
                          : AppColors.lightText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: labelController,
                    decoration: const InputDecoration(
                      labelText: 'Category Label (e.g. 🍔 Food)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: plannedController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Planned Amount (KES)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Kind:'),
                      const SizedBox(width: 10),
                      ChoiceChip(
                        label: const Text('Need'),
                        selected: tag == 'need',
                        onSelected: (val) => setModalState(() => tag = 'need'),
                        selectedColor: AppColors.purple.withOpacity(0.3),
                      ),
                      const SizedBox(width: 10),
                      ChoiceChip(
                        label: const Text('Want'),
                        selected: tag == 'want',
                        onSelected: (val) => setModalState(() => tag = 'want'),
                        selectedColor: AppColors.warning.withOpacity(0.3),
                      ),
                      const SizedBox(width: 10),
                      ChoiceChip(
                        label: const Text('Save'),
                        selected: tag == 'save',
                        onSelected: (val) => setModalState(() => tag = 'save'),
                        selectedColor: AppColors.accentGreen.withOpacity(0.3),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentGreen,
                        foregroundColor: AppColors.darkBg,
                      ),
                      onPressed: () async {
                        final amt = double.tryParse(plannedController.text);
                        final label = labelController.text.trim();
                        if (amt == null || label.isEmpty) return;

                        Navigator.pop(ctx);
                        try {
                          await ApiService.createBudget(
                            label: label,
                            planned: amt,
                            tag: tag,
                            kind: tag,
                            month: _currentMonth(),
                          );
                          _refresh();
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                      child: const Text('Save Budget Category'),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBg : AppColors.lightBg;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    return Container(
      color: bgColor,
      child: FutureBuilder<List<BudgetCategoryExample>>(
        future: _budgetsFuture,
        builder: (context, snapshot) {
          final categories = snapshot.data ?? [];
          final isLoading = snapshot.connectionState == ConnectionState.waiting;

          double totalPlanned = 0;
          double totalActual = 0;
          for (var c in categories) {
            totalPlanned += c.planned;
            totalActual += c.actual;
          }
          final remaining = totalPlanned - totalActual;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Budget — ${_currentMonth()}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () => _showAddBudgetModal(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: mutedColor,
                        side: BorderSide(color: borderColor),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        '+ Category',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Planned / Actual / Remaining summary cards
                Row(
                  children: [
                    _SummaryCard(
                      label: 'Planned',
                      value: 'Ksh ${totalPlanned.toStringAsFixed(0)}',
                      color: mutedColor,
                      cardColor: cardColor,
                      borderColor: borderColor,
                    ),
                    const SizedBox(width: 10),
                    _SummaryCard(
                      label: 'Actual',
                      value: 'Ksh ${totalActual.toStringAsFixed(0)}',
                      color: AppColors.warning,
                      cardColor: cardColor,
                      borderColor: borderColor,
                    ),
                    const SizedBox(width: 10),
                    _SummaryCard(
                      label: 'Remaining',
                      value: 'Ksh ${remaining.toStringAsFixed(0)}',
                      color: remaining < 0
                          ? AppColors.danger
                          : AppColors.accentGreen,
                      cardColor: cardColor,
                      borderColor: borderColor,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (categories.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Center(
                      child: Text(
                        'No budget categories yet.',
                        style: TextStyle(color: mutedColor),
                      ),
                    ),
                  )
                else
                  Column(
                    children: categories.map((cat) {
                      final planned = cat.planned;
                      final actual = cat.actual;
                      final pct = planned > 0
                          ? (actual / planned).clamp(0, 1)
                          : 1;
                      final over = planned > 0 && actual > planned;
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
                                  over
                                      ? AppColors.danger
                                      : AppColors.accentGreen,
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
          );
        },
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
              style: TextStyle(fontSize: 10, color: color.withOpacity(0.8)),
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
        text.toUpperCase(),
        style: TextStyle(fontSize: 10, color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }
}
