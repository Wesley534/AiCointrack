import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../services/api_service.dart';
import '../services/pending_transactions_service.dart';
import '../services/sync_service.dart';
import '../utils/formatters.dart';
import '../widgets/design_system.dart';
import 'add_transaction_sheet.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;
  List<Map<String, dynamic>> _data = [];
  List<PendingTx> _pendingTxs = [];
  String _activeFilter = 'all';
  final Set<String> _busyIds = <String>{};
  DateTime? _lastSyncedAt;
  bool _isCacheStale = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final source = _apiSourceForFilter(_activeFilter);
    final cached = await ApiService.fetchCachedTransactions(
      limit: 50,
      source: source,
    );
    final pending = await PendingTxService.getAll();
    final lastSyncedAt = await ApiService.getTransactionsLastSyncedAt();
    final isCacheStale = await ApiService.isTransactionsCacheStale();

    if (!mounted) return;
    setState(() {
      _data = _applyClientFilter(cached);
      _pendingTxs = pending;
      _lastSyncedAt = lastSyncedAt;
      _isCacheStale = isCacheStale;
      _isLoading = cached.isEmpty;
      _isRefreshing = cached.isNotEmpty;
      _error = null;
    });

    try {
      final result = await ApiService.refreshTransactionsCache(
        limit: 50,
        source: source,
      );

      if (!mounted) return;
      setState(() {
        _data = _applyClientFilter(result);
        _pendingTxs = pending;
        _lastSyncedAt = DateTime.now().toUtc();
        _isCacheStale = false;
        _isLoading = false;
        _isRefreshing = false;
      });
      pendingCountNotifier.value = pending.length;
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (_data.isEmpty) {
          _error = e.toString().replaceFirst('Exception: ', '');
        }
        _isLoading = false;
        _isRefreshing = false;
      });
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

  List<Map<String, dynamic>> _applyClientFilter(
    List<Map<String, dynamic>> items,
  ) {
    if (_activeFilter != 'auto') return items;
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
    setState(() => _activeFilter = filter);
    await _loadData();
  }

  Future<void> _manualSync() async {
    await SyncService.instance.syncAll(trigger: 'transactions_manual');
    await _loadData();
    if (!mounted) return;
    _showMessage('Transactions synced');
  }

  Future<void> _dismissPending(PendingTx tx) async {
    if (_busyIds.contains(tx.id)) return;
    setState(() => _busyIds.add(tx.id));

    try {
      await PendingTxService.remove(tx.id);
      if (!mounted) return;
      setState(() {
        _pendingTxs.removeWhere((item) => item.id == tx.id);
      });
      pendingCountNotifier.value = _pendingTxs.length;
      _showMessage('Transaction dismissed');
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _busyIds.remove(tx.id));
      }
    }
  }

  Future<void> _approvePending(PendingTx tx) async {
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
        _pendingTxs.removeWhere((item) => item.id == tx.id);
      });
      pendingCountNotifier.value = _pendingTxs.length;
      _showMessage('Transaction logged');
      await _loadData();
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _busyIds.remove(tx.id));
      }
    }
  }

  String _sourceForApi(String source) {
    final lower = source.toLowerCase();
    if (lower.contains('m-pesa') || lower.contains('mpesa')) return 'mpesa';
    if (lower.contains('bank')) return 'bank';
    return 'cash';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(SnackBar(content: Text(message)));
  }

  String _displayAmount(Map<String, dynamic> item) {
    final amount = ((item['amount'] ?? 0) as num).toDouble();
    final type = (item['transaction_type'] ?? 'expense')
        .toString()
        .toLowerCase();
    return '${type == 'income' ? '+' : '-'}${Formatters.formatKes(amount)}';
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transaction Feed',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Review detected payments, track manual entries, and keep the ledger clean.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _manualSync,
                icon: const Icon(Icons.sync_rounded),
                label: const Text('Sync'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _openAddSheet,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterPill(
                  label: 'All',
                  selected: _activeFilter == 'all',
                  onTap: () => _setFilter('all'),
                ),
                _FilterPill(
                  label: 'Auto-logged',
                  selected: _activeFilter == 'auto',
                  onTap: () => _setFilter('auto'),
                ),
                _FilterPill(
                  label: 'Onchain',
                  selected: _activeFilter == 'onchain',
                  onTap: () => _setFilter('onchain'),
                ),
                _FilterPill(
                  label: 'Manual',
                  selected: _activeFilter == 'manual',
                  onTap: () => _setFilter('manual'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (_lastSyncedAt != null)
                AppPill(
                  label:
                      'Last sync ${_formatRelativeDate(_lastSyncedAt!.toLocal())}',
                  color: AppColors.accent,
                ),
              if (_isRefreshing)
                const AppPill(label: 'Refreshing', color: AppColors.accent),
              if (_isCacheStale)
                const AppPill(
                  label: 'Offline or stale cache',
                  color: AppColors.warning,
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
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.danger,
                    size: 40,
                  ),
                  const SizedBox(height: 10),
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else ...[
            if (_pendingTxs.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pending Review',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  AppPill(
                    label: '${_pendingTxs.length} new',
                    color: AppColors.danger,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._pendingTxs.map(_buildPendingCard),
              const SizedBox(height: 18),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Activity', style: Theme.of(context).textTheme.titleLarge),
                Text(
                  '${_data.length} items',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_data.isEmpty)
              const AppGlassCard(
                child: Text(
                  'No transactions yet. Add one to start building your activity feed.',
                ),
              )
            else
              ..._data.map(_buildTransactionCard),
          ],
        ],
      ),
    );
  }

  Widget _buildPendingCard(PendingTx tx) {
    final isIncome = tx.type == 'income';
    final busy = _busyIds.contains(tx.id);
    final iconData = _iconForSource(tx.source);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppGlassCard(
        radius: 24,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppIconBadge(
                  icon: iconData.$1,
                  background: iconData.$2,
                  foreground: iconData.$3,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx.description,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${tx.source} · ${_formatRelativeDate(tx.detectedAt)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  '${isIncome ? '+' : '-'}${Formatters.formatKes(tx.amount)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: isIncome ? AppColors.positive : AppColors.danger,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            AppPill(label: tx.category, color: AppColors.purple),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: busy ? null : () => _dismissPending(tx),
                    child: const Text('Dismiss'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: busy ? null : () => _approvePending(tx),
                    child: busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
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
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> item) {
    final source = (item['source'] ?? '').toString();
    final amount = _displayAmount(item);
    final iconData = _iconForSource(source);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppGlassCard(
        radius: 24,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            AppIconBadge(
              icon: iconData.$1,
              background: iconData.$2,
              foreground: iconData.$3,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (item['description'] ?? 'Transaction').toString(),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          Formatters.formatDate(item['created_at']?.toString()),
                          style: Theme.of(context).textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      AppPill(
                        label: _sourceLabel(source),
                        color: _sourceTone(source),
                      ),
                      const SizedBox(width: 8),
                      _SyncStatusPill(
                        status: (item['sync_status'] ?? 'synced').toString(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              amount,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: amount.startsWith('+')
                    ? AppColors.positive
                    : AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  (IconData, Color, Color) _iconForSource(String source) {
    switch (source.toLowerCase()) {
      case 'mpesa':
      case 'm-pesa':
        return (
          Icons.sms_rounded,
          AppColors.greenBg.withValues(alpha: 0.28),
          AppColors.positive,
        );
      case 'bank':
      case 'kcb bank':
      case 'equity bank':
      case 'ncba bank':
        return (
          Icons.account_balance_rounded,
          AppColors.indigoBg.withValues(alpha: 0.45),
          AppColors.accent,
        );
      case 'onchain':
        return (
          Icons.currency_bitcoin_rounded,
          AppColors.amberBg.withValues(alpha: 0.45),
          AppColors.purple,
        );
      default:
        return (
          Icons.payments_outlined,
          AppColors.indigoBg.withValues(alpha: 0.35),
          AppColors.lightText,
        );
    }
  }

  String _sourceLabel(String source) {
    switch (source.toLowerCase()) {
      case 'onchain':
        return 'On-chain';
      case 'cash':
        return 'Manual';
      case 'mpesa':
      case 'm-pesa':
        return 'Auto';
      default:
        return source.isEmpty ? 'Activity' : source;
    }
  }

  Color _sourceTone(String source) {
    switch (source.toLowerCase()) {
      case 'onchain':
        return AppColors.accent;
      case 'cash':
        return AppColors.purple;
      case 'mpesa':
      case 'm-pesa':
        return AppColors.positive;
      default:
        return AppColors.purple;
    }
  }

  String _formatRelativeDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _SyncStatusPill extends StatelessWidget {
  const _SyncStatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final color = switch (normalized) {
      'pending' => AppColors.warning,
      'failed' => AppColors.danger,
      _ => AppColors.positive,
    };
    return AppPill(label: normalized, color: color);
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AppPill(
          label: label,
          color: selected ? AppColors.accent : AppColors.purple,
          filled: selected,
        ),
      ),
    );
  }
}
