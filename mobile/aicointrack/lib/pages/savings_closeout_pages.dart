import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/api_service.dart';
import '../services/local_db_service.dart';
import '../utils/formatters.dart';
import '../widgets/design_system.dart';

/// Savings goals page.
class SavingsPage extends StatefulWidget {
  const SavingsPage({super.key});

  @override
  State<SavingsPage> createState() => _SavingsPageState();
}

class _SavingsPageState extends State<SavingsPage> {
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isStale = true;
  String? _error;
  List<dynamic> _data = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final cached = await ApiService.fetchCachedSavingsGoals();
    final isStale = await LocalDbService.instance.isCacheStale('savings_goals');
    if (mounted) {
      setState(() {
        _data = cached;
        _isLoading = cached.isEmpty;
        _isRefreshing = cached.isNotEmpty;
        _isStale = isStale;
        _error = null;
      });
    }
    try {
      final result = await ApiService.refreshSavingsGoalsCache();
      if (mounted) {
        setState(() {
          _data = result;
          _isLoading = false;
          _isRefreshing = false;
          _isStale = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (_data.isEmpty) {
            _error = e.toString().replaceFirst('Exception: ', '');
          }
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _openNewGoalSheet() async {
    final bool? created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _NewGoalSheet(),
    );

    if (created == true && mounted) {
      await _loadData();
    }
  }

  Future<void> _openContributeSheet(Map<String, dynamic> goal) async {
    final bool? contributed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ContributeSheet(goalId: goal['id'] as int),
    );

    if (contributed == true && mounted) {
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Contribution added!')));
    }
  }

  Widget _buildLoader(Color mutedColor) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(AppColors.accent),
          ),
          const SizedBox(height: 12),
          Text('Loading...', style: TextStyle(color: mutedColor, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildError(Color mutedColor) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 48),
          const SizedBox(height: 12),
          Text(
            _error!,
            style: TextStyle(color: mutedColor, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildEmpty(Color mutedColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎯', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(
              'No savings goals yet',
              style: TextStyle(color: mutedColor, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _openNewGoalSheet,
              child: const Text('Create Goal'),
            ),
          ],
        ),
      ),
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

    final goals = _data.cast<Map<String, dynamic>>();

    final totalSaved = goals.fold<double>(
      0,
      (sum, g) => sum + (((g['saved'] ?? 0) as num).toDouble()),
    );

    return Container(
      color: bgColor,
      child: _isLoading
          ? _buildLoader(mutedColor)
          : _error != null
          ? _buildError(mutedColor)
          : SingleChildScrollView(
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
                        onPressed: _openNewGoalSheet,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.accent,
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
                  if (goals.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (_isRefreshing)
                            const AppPill(
                              label: 'Refreshing',
                              color: AppColors.accent,
                            ),
                          if (_isStale)
                            const AppPill(
                              label: 'Showing cached goals',
                              color: AppColors.warning,
                            ),
                        ],
                      ),
                    ),
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
                          Formatters.formatKes(totalSaved),
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (goals.isEmpty) _buildEmpty(mutedColor),
                  Column(
                    children: goals.map((g) {
                      final saved = ((g['saved'] ?? 0) as num).toDouble();
                      final target = ((g['target'] ?? 0) as num).toDouble();
                      final monthly = ((g['monthly'] ?? 0) as num).toDouble();
                      final pct = target <= 0
                          ? 0.0
                          : (saved / target * 100).clamp(0, 100).toDouble();
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
                                  (g['name'] ?? '').toString(),
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
                                    color: AppColors.accent,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: LinearProgressIndicator(
                                value: (pct / 100),
                                minHeight: 6,
                                backgroundColor: borderColor,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.accent,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${Formatters.formatKes(saved)} saved',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: mutedColor,
                                  ),
                                ),
                                Text(
                                  'Goal: ${Formatters.formatKes(target)}',
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
                                  'Monthly: ${Formatters.formatKes(monthly)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: mutedColor,
                                  ),
                                ),
                                OutlinedButton(
                                  onPressed: () => _openContributeSheet(g),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.accent,
                                    side: BorderSide(
                                      color: AppColors.accent.withOpacity(0.3),
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
            ),
    );
  }
}

class _NewGoalSheet extends StatefulWidget {
  const _NewGoalSheet();

  @override
  State<_NewGoalSheet> createState() => _NewGoalSheetState();
}

class _NewGoalSheetState extends State<_NewGoalSheet> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _targetCtrl = TextEditingController();
  final TextEditingController _monthlyCtrl = TextEditingController();
  String? _error;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _targetCtrl.dispose();
    _monthlyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final target = double.tryParse(_targetCtrl.text.trim());
    final monthly = double.tryParse(_monthlyCtrl.text.trim());

    if (name.isEmpty ||
        target == null ||
        target <= 0 ||
        monthly == null ||
        monthly <= 0) {
      setState(() {
        _error = 'Enter a valid name, target amount, and monthly contribution';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final navigator = Navigator.of(context);

    try {
      await ApiService.createSavingsGoal(name, target, monthly);
      navigator.pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    InputDecoration inputDec(String label) => InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: mutedColor),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.accent),
      ),
    );

    return Container(
      color: bgColor,
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'New Goal',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            style: TextStyle(color: textColor),
            decoration: inputDec('Name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _targetCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: textColor),
            decoration: inputDec('Target Amount'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _monthlyCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: textColor),
            decoration: inputDec('Monthly Contribution'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(color: AppColors.danger, fontSize: 12),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Create Goal'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContributeSheet extends StatefulWidget {
  final int goalId;

  const _ContributeSheet({required this.goalId});

  @override
  State<_ContributeSheet> createState() => _ContributeSheetState();
}

class _ContributeSheetState extends State<_ContributeSheet> {
  final TextEditingController _amountCtrl = TextEditingController();
  String? _error;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      setState(() {
        _error = 'Enter a valid amount';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final navigator = Navigator.of(context);

    try {
      await ApiService.contributeToSavingsGoal(
        widget.goalId,
        amountUsdc: amount,
        txHash: Formatters.generateMockTxHash(),
      );
      navigator.pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    return Container(
      color: bgColor,
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contribute',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              labelText: 'Amount',
              labelStyle: TextStyle(color: mutedColor),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.accent),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(color: AppColors.danger, fontSize: 12),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Add Contribution'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Monthly closeout summary page.
class CloseoutPage extends StatelessWidget {
  const CloseoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBg : AppColors.lightBg;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    final summary = ApiService.exampleCloseoutSummary;

    return Container(
      color: bgColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Closeout',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'February 2025 summary',
              style: TextStyle(fontSize: 13, color: mutedColor),
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
              childAspectRatio: 1.2,
              children: summary.metrics.map((m) {
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
                      Text(
                        m.label,
                        style: TextStyle(fontSize: 11, color: mutedColor),
                      ),
                      Text(
                        m.value,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: m.color,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
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
                  ...summary.categoryDiffs.map(
                    (c) => Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              c.label,
                              style: TextStyle(fontSize: 13, color: textColor),
                            ),
                            Text(
                              c.delta,
                              style: TextStyle(
                                fontSize: 13,
                                color: c.delta.startsWith('-')
                                    ? AppColors.danger
                                    : AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Divider(height: 1, color: borderColor),
                        const SizedBox(height: 6),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
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
              color: active ? AppColors.accent : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: active ? AppColors.accent : mutedColor,
          ),
        ),
      ),
    );
  }
}
