import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../services/api_service.dart';
import '../services/pending_transactions_service.dart';
import '../utils/formatters.dart';

class PendingTransactionsPage extends StatefulWidget {
  const PendingTransactionsPage({super.key});

  @override
  State<PendingTransactionsPage> createState() =>
      _PendingTransactionsPageState();
}

class _PendingTransactionsPageState extends State<PendingTransactionsPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final Set<String> _busyIds = <String>{};

  bool _isLoading = true;
  String? _error;
  List<PendingTx> _items = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final items = await PendingTxService.getAll();
      if (!mounted) return;
      setState(() {
        _items = items;
        _isLoading = false;
      });
      pendingCountNotifier.value = items.length;
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _dismiss(PendingTx tx) async {
    if (_busyIds.contains(tx.id)) return;
    setState(() => _busyIds.add(tx.id));

    try {
      await PendingTxService.remove(tx.id);
      if (!mounted) return;
      setState(() {
        _items.removeWhere((item) => item.id == tx.id);
      });
      pendingCountNotifier.value = _items.length;
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _busyIds.remove(tx.id));
      }
    }
  }

  Future<void> _approve(PendingTx tx) async {
    if (_busyIds.contains(tx.id)) return;
    setState(() => _busyIds.add(tx.id));

    try {
      await ApiService.recordOffchainTransaction(
        description: tx.description,
        amount: tx.amount,
        source: _sourceForApi(tx.source),
        transactionType: tx.type,
        category: tx.category,
      );
      await PendingTxService.remove(tx.id);

      if (!mounted) return;
      setState(() {
        _items.removeWhere((item) => item.id == tx.id);
      });
      pendingCountNotifier.value = _items.length;
      _showMessage('Transaction logged');
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _busyIds.remove(tx.id));
      }
    }
  }

  Future<void> _edit(PendingTx tx) async {
    final updated = await showModalBottomSheet<PendingTx>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PendingTxEditSheet(tx: tx),
    );

    if (updated == null || !mounted) return;
    await _approve(updated);
  }

  void _showMessage(String message) {
    final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
    scaffoldMessenger?.showSnackBar(SnackBar(content: Text(message)));
  }

  String _sourceForApi(String source) {
    final lower = source.toLowerCase();
    if (lower.contains('m-pesa') || lower.contains('mpesa')) return 'mpesa';
    if (lower.contains('bank')) return 'bank';
    return 'cash';
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
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
      key: _scaffoldKey,
      backgroundColor: bgColor,
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: _loadItems,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Pending Review',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: AppColors.danger.withValues(alpha: 0.1),
                    border: Border.all(
                      color: AppColors.danger.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    '${_items.length} pending',
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Approve, edit, or dismiss transactions detected from incoming notifications.',
              style: TextStyle(color: mutedColor, fontSize: 13),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.only(top: 80),
                child: Column(
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(AppColors.accent),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Loading pending transactions...',
                      style: TextStyle(color: mutedColor),
                    ),
                  ],
                ),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 64),
                child: Column(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.danger,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: mutedColor),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadItems,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else if (_items.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 84),
                child: Column(
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accent.withValues(alpha: 0.1),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.25),
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.check_rounded,
                          color: AppColors.accent,
                          size: 42,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'All caught up!',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No pending transactions to review.',
                      style: TextStyle(color: mutedColor),
                    ),
                  ],
                ),
              )
            else
              ..._items.map((tx) {
                final isIncome = tx.type == 'income';
                final tone = isIncome ? AppColors.accent : AppColors.danger;
                final busy = _busyIds.contains(tx.id);

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: tone.withValues(alpha: 0.1),
                            ),
                            child: Icon(
                              isIncome
                                  ? Icons.south_west_rounded
                                  : Icons.north_east_rounded,
                              color: tone,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tx.description,
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${tx.source} · ${_formatDate(tx.detectedAt)}',
                                  style: TextStyle(
                                    color: mutedColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${isIncome ? '+' : '-'}${Formatters.formatKes(tx.amount)}',
                            style: TextStyle(
                              color: tone,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: AppColors.purple.withValues(alpha: 0.1),
                          border: Border.all(
                            color: AppColors.purple.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          tx.category,
                          style: const TextStyle(
                            color: AppColors.purple,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Divider(color: borderColor, height: 1),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: busy ? null : () => _dismiss(tx),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.danger,
                                side: BorderSide(color: borderColor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text('Dismiss'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: busy ? null : () => _edit(tx),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: textColor,
                                side: BorderSide(color: borderColor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text('Edit'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: busy ? null : () => _approve(tx),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: busy
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Approve'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _PendingTxEditSheet extends StatefulWidget {
  final PendingTx tx;

  const _PendingTxEditSheet({required this.tx});

  @override
  State<_PendingTxEditSheet> createState() => _PendingTxEditSheetState();
}

class _PendingTxEditSheetState extends State<_PendingTxEditSheet> {
  late final TextEditingController _amountCtrl;
  late final TextEditingController _descriptionCtrl;

  String _type = 'expense';
  String _category = 'General';
  String? _error;

  static const _categories = [
    'General',
    'Food',
    'Transport',
    'Entertainment',
    'Shopping',
    'Health',
    'Savings',
    'Income',
    'Bills',
    'Fees',
  ];

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(
      text: widget.tx.amount.toStringAsFixed(2),
    );
    _descriptionCtrl = TextEditingController(text: widget.tx.description);
    _type = widget.tx.type;
    _category = widget.tx.category;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final navigator = Navigator.of(context);
    final amount = double.tryParse(_amountCtrl.text.trim());
    final description = _descriptionCtrl.text.trim();

    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid positive amount');
      return;
    }
    if (description.isEmpty) {
      setState(() => _error = 'Description is required');
      return;
    }

    navigator.pop(
      widget.tx.copyWith(
        amount: amount,
        type: _type,
        description: description,
        category: _category,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Edit Transaction',
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: textColor),
            decoration: _inputDec('Amount (KES)', mutedColor, borderColor),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionCtrl,
            style: TextStyle(color: textColor),
            decoration: _inputDec('Description', mutedColor, borderColor),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _TypeChip(
                label: 'Expense',
                selected: _type == 'expense',
                color: AppColors.danger,
                onTap: () => setState(() => _type = 'expense'),
              ),
              const SizedBox(width: 8),
              _TypeChip(
                label: 'Income',
                selected: _type == 'income',
                color: AppColors.accent,
                onTap: () => setState(() => _type = 'income'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _category,
            dropdownColor: bgColor,
            style: TextStyle(color: textColor),
            decoration: _inputDec('Category', mutedColor, borderColor),
            items: _categories
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _category = value);
              }
            },
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: const TextStyle(color: AppColors.danger, fontSize: 12),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Save & Log'),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDec(String label, Color mutedColor, Color borderColor) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: mutedColor),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.accent),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? color : color.withValues(alpha: 0.2),
            ),
            color: selected
                ? color.withValues(alpha: 0.12)
                : Colors.transparent,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected
                  ? color
                  : Theme.of(context).textTheme.bodyMedium?.color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
