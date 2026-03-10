import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/api_service.dart';

class SavingsPage extends StatefulWidget {
  const SavingsPage({super.key});

  @override
  State<SavingsPage> createState() => _SavingsPageState();
}

class _SavingsPageState extends State<SavingsPage> {
  late Future<List<SavingsGoalExample>> _goalsFuture;

  @override
  void initState() {
    super.initState();
    _goalsFuture = ApiService.fetchSavingsGoals();
  }

  void _refresh() {
    setState(() {
      _goalsFuture = ApiService.fetchSavingsGoals();
    });
  }

  void _showContributeModal(BuildContext context, SavingsGoalExample goal) {
    final amountController = TextEditingController();

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
            left: 20, right: 20, top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Contribute to ${goal.name}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkText : AppColors.lightText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Saved Ksh ${goal.saved.toStringAsFixed(0)} of Ksh ${goal.target.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkMuted : AppColors.lightMuted,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount (USDC)',
                  border: OutlineInputBorder(),
                ),
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
                    final amount = double.tryParse(amountController.text);
                    if (amount == null || amount <= 0) return;
                    if (goal.id == null) return;

                    Navigator.pop(ctx);
                    try {
                      await ApiService.contributeToGoal(
                        goal.id!,
                        amountUsdc: amount,
                        txHash: 'mobile-${DateTime.now().millisecondsSinceEpoch}',
                      );
                      _refresh();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Contributed \$${amount.toStringAsFixed(2)} USDC to ${goal.name}'),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Contribute'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showAddGoalModal(BuildContext context) {
    final nameController = TextEditingController();
    final targetController = TextEditingController();
    final monthlyController = TextEditingController();

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'New Savings Goal',
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
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Goal Name (e.g. Vacation ✈️)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: targetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Target Amount (KES)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: monthlyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monthly Contribution (KES)',
                  border: OutlineInputBorder(),
                ),
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
                    final target = double.tryParse(targetController.text);
                    final monthly = double.tryParse(monthlyController.text);
                    final name = nameController.text.trim();
                    if (target == null || monthly == null || name.isEmpty)
                      return;

                    Navigator.pop(ctx);
                    try {
                      await ApiService.createSavingsGoal(
                        name: name,
                        saved: 0.0, // Initial saved amount is 0
                        target: target,
                        monthly: monthly,
                      );
                      _refresh();
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
                  child: const Text('Create Goal'),
                ),
              ),
              const SizedBox(height: 20),
            ],
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
      child: FutureBuilder<List<SavingsGoalExample>>(
        future: _goalsFuture,
        builder: (context, snapshot) {
          final goals = snapshot.data ?? [];
          final isLoading = snapshot.connectionState == ConnectionState.waiting;
          final totalSaved = goals.fold<double>(0, (sum, g) => sum + g.saved);

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Savings Goals',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () => _showAddGoalModal(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accentGreen,
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
                        '+ New Goal',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL SAVED',
                        style: TextStyle(fontSize: 12, color: mutedColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ksh ${totalSaved.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accentGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (goals.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Center(
                      child: Text(
                        'No savings goals yet.',
                        style: TextStyle(color: mutedColor),
                      ),
                    ),
                  )
                else
                  Column(
                    children: goals.map((g) {
                      final pct = g.target > 0
                          ? (g.saved / g.target * 100).clamp(0, 100)
                          : 0;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  g.name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                                Text(
                                  '${pct.toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.accentGreen,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: LinearProgressIndicator(
                                value: (pct / 100).toDouble(),
                                minHeight: 6,
                                backgroundColor: borderColor,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.accentGreen,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Ksh ${g.saved.toStringAsFixed(0)} saved',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: mutedColor,
                                  ),
                                ),
                                Text(
                                  'Goal: Ksh ${g.target.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: mutedColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Divider(height: 1),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Monthly: Ksh ${g.monthly.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: mutedColor,
                                  ),
                                ),
                                OutlinedButton(
                                  onPressed: () => _showContributeModal(context, g),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.accentGreen,
                                    side: BorderSide(
                                      color: AppColors.accentGreen.withOpacity(
                                        0.3,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: const Text(
                                    'Contribute',
                                    style: TextStyle(fontSize: 11),
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

/// Monthly closeout summary page.
class CloseoutPage extends StatefulWidget {
  const CloseoutPage({super.key});

  @override
  State<CloseoutPage> createState() => _CloseoutPageState();
}

class _CloseoutPageState extends State<CloseoutPage> {
  late Future<Map<String, dynamic>> _closeoutFuture;

  @override
  void initState() {
    super.initState();
    _closeoutFuture = ApiService.fetchCloseoutData();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBg : AppColors.lightBg;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    return Scaffold(
      backgroundColor: bgColor,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _closeoutFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data ?? {};
          final income = (data['income'] as num?)?.toDouble() ?? 0;
          final expenses = (data['expenses'] as num?)?.toDouble() ?? 0;
          final saved = (data['saved'] as num?)?.toDouble() ?? 0;
          final surplus = income - expenses;
          final month = data['month'] as String? ?? _currentMonth();
          final categories = data['categories'] as List<dynamic>? ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      color: mutedColor,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Monthly Closeout',
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
                  padding: const EdgeInsets.only(left: 52),
                  child: Text(
                    '$month summary',
                    style: TextStyle(fontSize: 13, color: mutedColor),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: const [
                    _StepLabel(label: 'Summary', active: true),
                    _StepLabel(label: 'Surplus'),
                    _StepLabel(label: 'Sweep'),
                    _StepLabel(label: 'New Month'),
                  ],
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.6,
                  children: [
                    _MetricCard(
                      label: 'Income',
                      value: 'Ksh ${income.toStringAsFixed(0)}',
                      color: AppColors.accentGreen,
                      cardColor: cardColor,
                      borderColor: borderColor,
                      mutedColor: mutedColor,
                    ),
                    _MetricCard(
                      label: 'Expenses',
                      value: 'Ksh ${expenses.toStringAsFixed(0)}',
                      color: AppColors.danger,
                      cardColor: cardColor,
                      borderColor: borderColor,
                      mutedColor: mutedColor,
                    ),
                    _MetricCard(
                      label: 'Saved',
                      value: 'Ksh ${saved.toStringAsFixed(0)}',
                      color: AppColors.accentGreen,
                      cardColor: cardColor,
                      borderColor: borderColor,
                      mutedColor: mutedColor,
                    ),
                    _MetricCard(
                      label: 'Surplus',
                      value: 'Ksh ${surplus.toStringAsFixed(0)}',
                      color: surplus >= 0 ? AppColors.accentGreen : AppColors.danger,
                      cardColor: cardColor,
                      borderColor: borderColor,
                      mutedColor: mutedColor,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Category Breakdown',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (categories.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'No category data yet.',
                            style: TextStyle(fontSize: 13, color: mutedColor),
                          ),
                        )
                      else
                        ...categories.map((c) {
                          final label = c['label'] as String? ?? '';
                          final planned = (c['planned'] as num?)?.toDouble() ?? 0;
                          final spent = (c['spent'] as num?)?.toDouble() ?? 0;
                          final diff = planned - spent;
                          final diffStr = diff >= 0
                              ? '+Ksh ${diff.toStringAsFixed(0)}'
                              : '-Ksh ${diff.abs().toStringAsFixed(0)}';
                          return Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    label,
                                    style: TextStyle(fontSize: 13, color: textColor),
                                  ),
                                  Text(
                                    diffStr,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: diff >= 0
                                          ? AppColors.accentGreen
                                          : AppColors.danger,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Divider(height: 1, color: borderColor),
                              const SizedBox(height: 6),
                            ],
                          );
                        }),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sweep coming soon!')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentGreen,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Sweep Surplus to Savings →'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static String _currentMonth() {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final now = DateTime.now();
    return '${months[now.month]} ${now.year}';
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color cardColor;
  final Color borderColor;
  final Color mutedColor;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.color,
    required this.cardColor,
    required this.borderColor,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: mutedColor)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepLabel extends StatelessWidget {
  final String label;
  final bool active;

  const _StepLabel({required this.label, this.active = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? AppColors.accentGreen : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: active ? AppColors.accentGreen : mutedColor,
          ),
        ),
      ),
    );
  }
}
