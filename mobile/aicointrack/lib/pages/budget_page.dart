import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../services/api_service.dart';
import '../utils/formatters.dart';
import '../widgets/design_system.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _data = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await ApiService.fetchCurrentBudget();
      if (!mounted) return;
      setState(() {
        _data = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  String _currentMonth() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    return '${now.year}-$month';
  }

  Future<void> _openBudgetSheet({Map<String, dynamic>? category}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _BudgetSheet(
        category: category,
        currentMonth: _currentMonth(),
      ),
    );

    if (saved == true && mounted) {
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = _data;
    final totalPlanned = categories.fold<double>(
      0,
      (sum, item) => sum + ((item['planned'] ?? 0) as num).toDouble(),
    );
    final totalActual = categories.fold<double>(
      0,
      (sum, item) => sum + ((item['actual'] ?? 0) as num).toDouble(),
    );
    final remaining = totalPlanned - totalActual;
    final usage = totalPlanned <= 0 ? 0.0 : (totalActual / totalPlanned).clamp(0, 1);

    return AppPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Monthly Budget', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 6),
                    Text(
                      'Plan spending, track actuals, and adjust categories before the month closes.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _openBudgetSheet(),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Category'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 60),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            AppGlassCard(
              child: Column(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.danger, size: 40),
                  const SizedBox(height: 10),
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 14),
                  ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
                ],
              ),
            )
          else ...[
            AppGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Monthly Overview', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      AppMetricTile(
                        label: 'Planned',
                        value: Formatters.formatKes(totalPlanned),
                        tint: AppColors.accent,
                      ),
                      const SizedBox(width: 12),
                      AppMetricTile(
                        label: 'Actual',
                        value: Formatters.formatKes(totalActual),
                        tint: AppColors.positive,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AppGlassCard(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.28),
                    radius: 22,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            AppPill(
                              label: usage >= 0.9 ? 'Needs attention' : 'On track',
                              color: usage >= 0.9 ? AppColors.danger : AppColors.positive,
                            ),
                            Text(
                              '${(usage * 100).toStringAsFixed(0)}% used',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: usage.toDouble(),
                          minHeight: 10,
                          borderRadius: BorderRadius.circular(999),
                          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            usage >= 0.9 ? AppColors.danger : AppColors.accent,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${Formatters.formatKes(remaining)} remaining for ${_currentMonth()}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppSectionTitle(
              title: 'Categories',
              action: TextButton(
                onPressed: () => _openBudgetSheet(),
                child: const Text('Edit all'),
              ),
            ),
            const SizedBox(height: 12),
            if (categories.isEmpty)
              const AppGlassCard(
                child: Text('No budget categories yet. Add one to start tracking spend.'),
              )
            else
              ...categories.map(_buildCategoryCard),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    final planned = ((category['planned'] ?? 0) as num).toDouble();
    final actual = ((category['actual'] ?? 0) as num).toDouble();
    final remaining = planned - actual;
    final pct = planned <= 0 ? 0.0 : (actual / planned).clamp(0, 1);
    final over = actual > planned;
    final kind = (category['kind'] ?? 'need').toString();
    final tone = _toneForKind(kind);
    final icon = _iconForKind(kind);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _openBudgetSheet(category: category),
        borderRadius: BorderRadius.circular(24),
        child: AppGlassCard(
          radius: 24,
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Row(
                children: [
                  AppIconBadge(
                    icon: icon,
                    background: tone.withValues(alpha: 0.12),
                    foreground: tone,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (category['label'] ?? '').toString(),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Spent ${Formatters.formatKes(actual)} of ${Formatters.formatKes(planned)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  AppPill(
                    label: (category['tag'] ?? kind).toString(),
                    color: tone,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: pct.toDouble(),
                minHeight: 9,
                borderRadius: BorderRadius.circular(999),
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(over ? AppColors.danger : tone),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    over ? 'Over by ${Formatters.formatKes(actual - planned)}' : 'Left ${Formatters.formatKes(remaining)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: over ? AppColors.danger : tone,
                    ),
                  ),
                  Text(
                    '${(pct * 100).toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: over ? AppColors.danger : tone,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _toneForKind(String kind) {
    switch (kind) {
      case 'save':
        return AppColors.positive;
      case 'want':
        return AppColors.purple;
      default:
        return AppColors.accent;
    }
  }

  IconData _iconForKind(String kind) {
    switch (kind) {
      case 'save':
        return Icons.savings_outlined;
      case 'want':
        return Icons.auto_awesome_outlined;
      default:
        return Icons.shopping_basket_outlined;
    }
  }
}

class _BudgetSheet extends StatefulWidget {
  final Map<String, dynamic>? category;
  final String currentMonth;

  const _BudgetSheet({
    required this.category,
    required this.currentMonth,
  });

  @override
  State<_BudgetSheet> createState() => _BudgetSheetState();
}

class _BudgetSheetState extends State<_BudgetSheet> {
  late final bool _isEditing;
  late final TextEditingController _labelCtrl;
  late final TextEditingController _plannedCtrl;
  late final TextEditingController _actualCtrl;
  late final TextEditingController _tagCtrl;
  late final TextEditingController _monthCtrl;
  late String _kind;
  String? _error;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final category = widget.category;
    _isEditing = category != null;
    _labelCtrl = TextEditingController(text: category?['label']?.toString() ?? '');
    _plannedCtrl = TextEditingController(
      text: category == null ? '' : ((category['planned'] ?? 0) as num).toDouble().toStringAsFixed(0),
    );
    _actualCtrl = TextEditingController(
      text: category == null ? '0' : ((category['actual'] ?? 0) as num).toDouble().toStringAsFixed(0),
    );
    _tagCtrl = TextEditingController(text: category?['tag']?.toString() ?? 'need');
    _monthCtrl = TextEditingController(text: category?['month']?.toString() ?? widget.currentMonth);
    _kind = category?['kind']?.toString() ?? 'need';
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _plannedCtrl.dispose();
    _actualCtrl.dispose();
    _tagCtrl.dispose();
    _monthCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final label = _labelCtrl.text.trim();
    final planned = double.tryParse(_plannedCtrl.text.trim());
    final actual = double.tryParse(_actualCtrl.text.trim()) ?? 0.0;
    final tag = _tagCtrl.text.trim();
    final month = _monthCtrl.text.trim();

    if (label.isEmpty || planned == null || planned <= 0 || tag.isEmpty || month.isEmpty) {
      setState(() => _error = 'Please fill in all required fields with valid values.');
      return;
    }

    setState(() {
      _error = null;
      _isSubmitting = true;
    });

    try {
      if (_isEditing) {
        await ApiService.updateBudget(
          widget.category!['id'] as int,
          label: label,
          planned: planned,
          actual: actual,
          tag: tag,
          kind: _kind,
          month: month,
        );
      } else {
        await ApiService.createBudget(
          label: label,
          planned: planned,
          tag: tag,
          kind: _kind,
          month: month,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
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
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isEditing ? 'Edit category' : 'New category',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Use clear labels and realistic amounts so monthly insights stay useful.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          TextField(controller: _labelCtrl, decoration: const InputDecoration(labelText: 'Label')),
          const SizedBox(height: 12),
          TextField(
            controller: _plannedCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Planned amount'),
          ),
          if (_isEditing) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _actualCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Actual amount'),
            ),
          ],
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _kind,
            items: const [
              DropdownMenuItem(value: 'need', child: Text('need')),
              DropdownMenuItem(value: 'want', child: Text('want')),
              DropdownMenuItem(value: 'save', child: Text('save')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _kind = value);
              }
            },
            decoration: const InputDecoration(labelText: 'Type'),
          ),
          const SizedBox(height: 12),
          TextField(controller: _tagCtrl, decoration: const InputDecoration(labelText: 'Tag')),
          const SizedBox(height: 12),
          TextField(controller: _monthCtrl, decoration: const InputDecoration(labelText: 'Month')),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.danger),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(_isEditing ? 'Save changes' : 'Create category'),
            ),
          ),
        ],
      ),
    );
  }
}
