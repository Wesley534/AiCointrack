import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/api_service.dart';

/// Transactions list page – shows recent transactions with filters.
class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  late Future<List<TransactionExample>> _transactionsFuture;
  String _activeFilter = 'All';

  @override
  void initState() {
    super.initState();
    _transactionsFuture = ApiService.fetchTransactions();
  }

  void _refresh() {
    String? source;
    switch (_activeFilter) {
      case 'Auto-logged':
        source = 'auto';
      case 'Onchain':
        source = 'chain';
      case 'Manual':
        source = 'manual';
    }
    setState(() {
      _transactionsFuture = ApiService.fetchTransactions(source: source);
    });
  }

  void _setFilter(String label) {
    setState(() => _activeFilter = label);
    _refresh();
  }

  void _showAddTransactionModal(BuildContext context) {
    final amountController = TextEditingController();
    final descController = TextEditingController();
    String txType = 'expense';

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
                    'Add Transaction',
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
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount (KES)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Type:'),
                      const SizedBox(width: 20),
                      ChoiceChip(
                        label: const Text('Expense'),
                        selected: txType == 'expense',
                        onSelected: (val) =>
                            setModalState(() => txType = 'expense'),
                        selectedColor: AppColors.danger.withOpacity(0.2),
                      ),
                      const SizedBox(width: 10),
                      ChoiceChip(
                        label: const Text('Income'),
                        selected: txType == 'income',
                        onSelected: (val) =>
                            setModalState(() => txType = 'income'),
                        selectedColor: AppColors.accentGreen.withOpacity(0.2),
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
                        final amt = double.tryParse(amountController.text);
                        final desc = descController.text.trim();
                        if (amt == null || desc.isEmpty) return;

                        Navigator.pop(ctx);
                        try {
                          await ApiService.createTransaction(
                            amount: amt,
                            description: desc,
                            source: 'manual',
                            transactionType: txType,
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
                      child: const Text('Save Transaction'),
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
      child: FutureBuilder<List<TransactionExample>>(
        future: _transactionsFuture,
        builder: (context, snapshot) {
          final txs = snapshot.data ?? [];
          final isLoading = snapshot.connectionState == ConnectionState.waiting;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Transactions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () => _showAddTransactionModal(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accentGreen,
                        side: BorderSide(color: borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                      ),
                      child: const Text(
                        '+ Add',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Auto-logged', 'Onchain', 'Manual']
                        .map((label) => _FilterChip(
                              label: label,
                              selected: _activeFilter == label,
                              onTap: () => _setFilter(label),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 12),
                if (isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (txs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Center(
                      child: Text(
                        'No transactions yet.',
                        style: TextStyle(color: mutedColor),
                      ),
                    ),
                  )
                else
                  ...txs.map((t) {
                    final isPositive = t.amount.startsWith('+');
                    return Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: cardColor,
                                      border: Border.all(color: borderColor),
                                    ),
                                    child: Center(
                                      child: Text(
                                        t.emoji,
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          t.description,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: textColor,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Text(
                                              t.date,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: mutedColor,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            if (t.source == 'auto')
                                              _SourcePill(text: 'Auto'),
                                            if (t.source == 'chain')
                                              _SourcePill(
                                                text: 'Onchain',
                                                color: AppColors.accentGreen,
                                              ),
                                            if (t.source == 'manual')
                                              _SourcePill(text: 'Manual'),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              'Ksh ${t.amount}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isPositive
                                    ? AppColors.accentGreen
                                    : AppColors.danger,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Divider(height: 1, color: borderColor),
                        const SizedBox(height: 10),
                      ],
                    );
                  }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _FilterChip({required this.label, this.selected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: selected ? AppColors.accentGreen : mutedColor,
          side: BorderSide(
            color: selected ? AppColors.accentGreen : borderColor,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(label, style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}

class _SourcePill extends StatelessWidget {
  final String text;
  final Color? color;

  const _SourcePill({required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor =
        color ?? (isDark ? AppColors.darkMuted : AppColors.lightMuted);

    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: bgColor,
        border: Border.all(color: borderColor),
      ),
      child: Text(text, style: TextStyle(fontSize: 9, color: textColor)),
    );
  }
}
