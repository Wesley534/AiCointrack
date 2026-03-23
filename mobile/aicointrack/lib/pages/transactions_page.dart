import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/api_service.dart';
import '../services/pending_transactions_service.dart';
import '../utils/formatters.dart';
import 'add_transaction_sheet.dart';
import 'pending_transactions_page.dart';

/// Transactions list page – shows recent transactions with filters.
class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _data = [];
  String _activeFilter = 'all';

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
      final result = await ApiService.fetchTransactions(
        limit: 50,
        source: _apiSourceForFilter(_activeFilter),
      );
      if (mounted) {
        setState(() {
          _data = _applyClientFilter(result);
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

  String? _apiSourceForFilter(String filter) {
    switch (filter) {
      case 'onchain':
        return 'onchain';
      case 'manual':
        return 'cash';
      default:
        return null;
    }
  }

  List<dynamic> _applyClientFilter(List<dynamic> items) {
    if (_activeFilter != 'auto') {
      return items;
    }
    return items.where((item) {
      final source = (item['source'] ?? '').toString().toLowerCase();
      return source != 'onchain' && source != 'cash';
    }).toList();
  }

  Future<void> _openAddSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddTransactionSheet(onSuccess: _loadData),
    );
  }

  Future<void> _setFilter(String filter) async {
    if (mounted) {
      setState(() {
        _activeFilter = filter;
      });
    }
    await _loadData();
  }

  String _emojiForSource(String source) {
    switch (source.toLowerCase()) {
      case 'mpesa':
        return '📱';
      case 'onchain':
        return '⛓️';
      case 'bank':
        return '🏦';
      case 'cash':
      default:
        return '💵';
    }
  }

  String _displayAmount(Map<String, dynamic> item) {
    final amount = ((item['amount'] ?? 0) as num).toDouble();
    final type = (item['transaction_type'] ?? 'expense')
        .toString()
        .toLowerCase();
    return '${type == 'income' ? '+' : '-'}${Formatters.formatKes(amount)}';
  }

  String _displaySource(String source) {
    return source == 'onchain' ? 'chain' : source;
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
            const Text('💸', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(
              'No transactions yet',
              style: TextStyle(color: mutedColor, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _openAddSheet,
              child: const Text('Add Transaction'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    Color cardColor,
    Color borderColor,
    Color textColor,
    Color mutedColor,
  ) {
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
                onPressed: _openAddSheet,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  side: BorderSide(color: borderColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                ),
                child: const Text('+ Add', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _activeFilter == 'all',
                  onTap: () => _setFilter('all'),
                ),
                _FilterChip(
                  label: 'Auto-logged',
                  selected: _activeFilter == 'auto',
                  onTap: () => _setFilter('auto'),
                ),
                _FilterChip(
                  label: 'Onchain',
                  selected: _activeFilter == 'onchain',
                  onTap: () => _setFilter('onchain'),
                ),
                _FilterChip(
                  label: 'Manual',
                  selected: _activeFilter == 'manual',
                  onTap: () => _setFilter('manual'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<int>(
            valueListenable: pendingCountNotifier,
            builder: (context, pendingCount, _) {
              if (pendingCount <= 0) return const SizedBox.shrink();

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.danger.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.pending_actions_outlined,
                      color: AppColors.danger,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '$pendingCount transaction${pendingCount == 1 ? '' : 's'} pending review',
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PendingTransactionsPage(),
                        ),
                      ),
                      child: const Text(
                        'Review →',
                        style: TextStyle(color: AppColors.danger, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          if (_data.isEmpty) _buildEmpty(mutedColor),
          ..._data.map((raw) {
            final item = Map<String, dynamic>.from(raw as Map);
            final amount = _displayAmount(item);
            final source = (item['source'] ?? '').toString();
            final displaySource = _displaySource(source);
            final isPositive = amount.startsWith('+');
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
                                _emojiForSource(source),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (item['description'] ?? 'Transaction')
                                      .toString(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      Formatters.formatDate(
                                        item['created_at']?.toString(),
                                      ),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: mutedColor,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    if (displaySource == 'chain')
                                      const _SourcePill(
                                        text: 'Onchain',
                                        color: AppColors.accent,
                                      ),
                                    if (displaySource == 'cash')
                                      const _SourcePill(text: 'Manual'),
                                    if (displaySource != 'cash' &&
                                        displaySource != 'chain' &&
                                        displaySource.isNotEmpty)
                                      _SourcePill(text: displaySource),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      amount,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isPositive
                            ? AppColors.positive
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
          }),
        ],
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

    return Container(
      color: bgColor,
      child: _isLoading
          ? _buildLoader(mutedColor)
          : _error != null
          ? _buildError(mutedColor)
          : _buildContent(cardColor, borderColor, textColor, mutedColor),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

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
          foregroundColor: selected ? AppColors.accent : mutedColor,
          side: BorderSide(color: selected ? AppColors.accent : borderColor),
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
