import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/api_service.dart';
import '../utils/formatters.dart';

/// Budget overview page – Flutter implementation of the CoinTrack MVP budget screen.
class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _data = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final result = await ApiService.fetchCurrentBudget();
      if (mounted) {
        setState(() {
          _data = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  String _currentMonth() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    return '${now.year}-$month';
  }

  Future<void> _openBudgetSheet({Map<String, dynamic>? category}) async {
    final bool? saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          _BudgetSheet(category: category, currentMonth: _currentMonth()),
    );

    if (saved == true && mounted) {
      await _loadData();
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
            const Text('📊', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(
              'No budget categories yet',
              style: TextStyle(color: mutedColor, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _openBudgetSheet,
              child: const Text('Create Category'),
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

    final categories = _data.cast<Map<String, dynamic>>();
    final totalPlanned = categories.fold<double>(
      0.0,
      (s, c) => s + ((c['planned'] as num?)?.toDouble() ?? 0.0),
    );
    final totalActual = categories.fold<double>(
      0.0,
      (s, c) => s + ((c['actual'] as num?)?.toDouble() ?? 0.0),
    );
    final remaining = totalPlanned - totalActual;

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
                        'Budget — ${_currentMonth()}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      OutlinedButton(
                        onPressed: _openBudgetSheet,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.accent,
                          side: BorderSide(
                            color: AppColors.accent.withOpacity(0.4),
                          ),
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
                  Row(
                    children: [
                      _SummaryCard(
                        label: 'Planned',
                        value: Formatters.formatKes(totalPlanned),
                        color: mutedColor,
                        cardColor: cardColor,
                        borderColor: borderColor,
                      ),
                      const SizedBox(width: 10),
                      _SummaryCard(
                        label: 'Actual',
                        value: Formatters.formatKes(totalActual),
                        color: AppColors.warning,
                        cardColor: cardColor,
                        borderColor: borderColor,
                      ),
                      const SizedBox(width: 10),
                      _SummaryCard(
                        label: 'Remaining',
                        value: Formatters.formatKes(remaining),
                        color: AppColors.accent,
                        cardColor: cardColor,
                        borderColor: borderColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (categories.isEmpty) _buildEmpty(mutedColor),
                  Column(
                    children: categories.map((cat) {
                      final planned = ((cat['planned'] ?? 0) as num).toDouble();
                      final actual = ((cat['actual'] ?? 0) as num).toDouble();
                      final pct = planned <= 0
                          ? 0.0
                          : (actual / planned).clamp(0, 1).toDouble();
                      final over = actual > planned;
                      return GestureDetector(
                        onTap: () => _openBudgetSheet(category: cat),
                        child: Container(
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    (cat['label'] ?? '').toString(),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: textColor,
                                    ),
                                  ),
                                  _TagChip(
                                    text: (cat['tag'] ?? 'need').toString(),
                                    kind: (cat['kind'] ?? 'need').toString(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(99),
                                child: LinearProgressIndicator(
                                  value: pct,
                                  minHeight: 6,
                                  backgroundColor: borderColor,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    over ? AppColors.danger : AppColors.accent,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Planned: ${Formatters.formatKes(planned)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: mutedColor,
                                    ),
                                  ),
                                  Text(
                                    'Actual: ${Formatters.formatKes(actual)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: over
                                          ? AppColors.danger
                                          : AppColors.accent,
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
            ),
    );
  }
}

class _BudgetSheet extends StatefulWidget {
  final Map<String, dynamic>? category;
  final String currentMonth;

  const _BudgetSheet({required this.category, required this.currentMonth});

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
    _labelCtrl = TextEditingController(
      text: category?['label']?.toString() ?? '',
    );
    _plannedCtrl = TextEditingController(
      text: category == null
          ? ''
          : ((category['planned'] ?? 0) as num).toDouble().toStringAsFixed(0),
    );
    _actualCtrl = TextEditingController(
      text: category == null
          ? '0'
          : ((category['actual'] ?? 0) as num).toDouble().toStringAsFixed(0),
    );
    _tagCtrl = TextEditingController(
      text: category?['tag']?.toString() ?? 'need',
    );
    _monthCtrl = TextEditingController(
      text: category?['month']?.toString() ?? widget.currentMonth,
    );
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

    if (label.isEmpty ||
        planned == null ||
        planned <= 0 ||
        tag.isEmpty ||
        month.isEmpty) {
      setState(() {
        _error = 'Please fill in all required fields with valid values';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final navigator = Navigator.of(context);

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
            _isEditing ? 'Edit Category' : 'New Category',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _labelCtrl,
            style: TextStyle(color: textColor),
            decoration: inputDec('Label'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _plannedCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: textColor),
            decoration: inputDec('Planned Amount'),
          ),
          if (_isEditing) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _actualCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: TextStyle(color: textColor),
              decoration: inputDec('Actual Amount'),
            ),
          ],
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _kind,
            dropdownColor: bgColor,
            style: TextStyle(color: textColor),
            decoration: inputDec('Type'),
            items: const [
              DropdownMenuItem(value: 'need', child: Text('need')),
              DropdownMenuItem(value: 'want', child: Text('want')),
              DropdownMenuItem(value: 'save', child: Text('save')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _kind = value;
                });
              }
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _tagCtrl,
            style: TextStyle(color: textColor),
            decoration: inputDec('Category tag'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _monthCtrl,
            style: TextStyle(color: textColor),
            decoration: inputDec('Month'),
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
                  : Text(_isEditing ? 'Save Changes' : 'Create Category'),
            ),
          ),
        ],
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
        border = AppColors.accent.withOpacity(0.25);
        bg = AppColors.accent.withOpacity(0.1);
        fg = AppColors.accent;
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
        style: TextStyle(fontSize: 10, color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }
}
