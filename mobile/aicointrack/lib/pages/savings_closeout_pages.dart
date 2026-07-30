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
    final results = await Future.wait([
      ApiService.fetchCachedSavingsGoals(),
      LocalDbService.instance.isCacheStale('savings_goals'),
    ]);
    final cached = results[0] as List<dynamic>;
    final isStale = results[1] as bool;

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

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 48),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
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
              style: Theme.of(context).textTheme.titleMedium,
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
    final theme = Theme.of(context);
    final goals = _data.cast<Map<String, dynamic>>();

    final totalSaved = goals.fold<double>(
      0,
      (sum, g) => sum + (((g['saved'] ?? 0) as num).toDouble()),
    );

    if (_isLoading) {
      return const AppSkeletonList(count: 4);
    }
    if (_error != null) {
      return AppPage(child: _buildError());
    }

    return AppPage(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Savings Goals', style: theme.textTheme.headlineMedium),
              OutlinedButton(
                onPressed: _openNewGoalSheet,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  side: BorderSide(color: theme.dividerColor),
                ),
                child: const Text('+ New Goal'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Track your progress toward financial milestones.',
            style: theme.textTheme.bodyMedium,
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
                    const AppPill(label: 'Refreshing', color: AppColors.accent),
                  if (_isStale)
                    const AppPill(
                      label: 'Showing cached goals',
                      color: AppColors.warning,
                    ),
                ],
              ),
            ),
          // Total saved card
          AppGlassCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOTAL SAVED',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  Formatters.formatKes(totalSaved),
                  style: theme.textTheme.displayMedium?.copyWith(
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (goals.isEmpty) _buildEmpty(),
          Column(
            children: goals.map((g) {
              final saved = ((g['saved'] ?? 0) as num).toDouble();
              final target = ((g['target'] ?? 0) as num).toDouble();
              final monthly = ((g['monthly'] ?? 0) as num).toDouble();
              final pct = target <= 0
                  ? 0.0
                  : (saved / target * 100).clamp(0, 100).toDouble();
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppGlassCard(
                  radius: 24,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              (g['name'] ?? '').toString(),
                              style: theme.textTheme.titleMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${pct.toStringAsFixed(0)}%',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: (pct / 100),
                          minHeight: 6,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.accent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${Formatters.formatKes(saved)} saved',
                              style: theme.textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Goal: ${Formatters.formatKes(target)}',
                              style: theme.textTheme.bodySmall,
                              textAlign: TextAlign.end,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Divider(height: 1, color: theme.dividerColor),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Monthly: ${Formatters.formatKes(monthly)}',
                              style: theme.textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
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
                ),
              );
            }).toList(),
          ),
        ],
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
    final theme = Theme.of(context);

    return Padding(
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
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            style: theme.textTheme.bodyLarge,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _targetCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: theme.textTheme.bodyLarge,
            decoration: const InputDecoration(labelText: 'Target Amount'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _monthlyCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: theme.textTheme.bodyLarge,
            decoration: const InputDecoration(labelText: 'Monthly Contribution'),
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
    final theme = Theme.of(context);

    return Padding(
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
          Text('Contribute', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 16),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: theme.textTheme.bodyLarge,
            decoration: const InputDecoration(labelText: 'Amount'),
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
    final theme = Theme.of(context);
    final summary = ApiService.exampleCloseoutSummary;

    return AppPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Monthly Closeout', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(
            'February 2025 summary',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          // Step indicators
          Row(
            children: [
              _StepLabel(label: 'Summary', active: true),
              _StepLabel(label: 'Surplus'),
              _StepLabel(label: 'Sweep'),
              _StepLabel(label: 'New Month'),
            ],
          ),
          const SizedBox(height: 16),
          // Metrics grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.4,
            children: summary.metrics.map((m) {
              return AppGlassCard(
                radius: 20,
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.label, style: theme.textTheme.bodySmall),
                    Text(
                      m.value,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: m.color,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          // Category breakdown
          AppGlassCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Category Breakdown',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                ...summary.categoryDiffs.map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          c.label,
                          style: theme.textTheme.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          c.delta,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: c.delta.startsWith('-')
                                ? AppColors.danger
                                : AppColors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
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
    );
  }
}

class _StepLabel extends StatelessWidget {
  final String label;
  final bool active;

  const _StepLabel({required this.label, this.active = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          style: theme.textTheme.bodySmall?.copyWith(
            color: active ? AppColors.accent : null,
          ),
        ),
      ),
    );
  }
}
