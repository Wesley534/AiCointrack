import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../services/api_service.dart';
import '../services/notification_transaction_service.dart';
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

  // Historical scan state
  int _scanDuration = 30;
  // Historical scan state
  bool _isScanning = false;
  bool _scanDone = false;
  int _scanCount = 0;
  bool _showScanCard = false;

  // Approve all state
  bool _isApprovingAll = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final source = _apiSourceForFilter(_activeFilter);

    // Parallelize cache reads for better performance
    final results = await Future.wait([
      ApiService.fetchCachedTransactions(limit: 50, source: source),
      PendingTxService.getAll(),
      ApiService.getTransactionsLastSyncedAt(),
      ApiService.isTransactionsCacheStale(),
    ]);

    final cached = results[0] as List<Map<String, dynamic>>;
    final pending = results[1] as List<PendingTx>;
    final lastSyncedAt = results[2] as DateTime?;
    final isCacheStale = results[3] as bool;

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
    pendingCountNotifier.value = pending.length;

    try {
      final result = await ApiService.refreshTransactionsCache(
        limit: 50,
        source: source,
      );

      if (!mounted) return;
      setState(() {
        _data = _applyClientFilter(result);
        _lastSyncedAt = DateTime.now().toUtc();
        _isCacheStale = false;
        _isLoading = false;
        _isRefreshing = false;
      });
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

  // ── Historical SMS Scan ─────────────────────────────────────────────────

  Future<void> _scanHistoricalMessages() async {
    // Check SMS permission first
    final hasSms = await NotificationTransactionService.hasSmsPermission();
    if (!hasSms && mounted) {
      final grant = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('SMS Permission'),
          content: const Text(
            'CoinTrack needs SMS permission to read past M-Pesa and bank messages. '
            'Would you like to grant it now?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Grant'),
            ),
          ],
        ),
      );

      if (grant == true && mounted) {
        await NotificationTransactionService.requestSmsPermission();
        await Future.delayed(const Duration(milliseconds: 500));
      }

      if (!mounted) return;
      final stillHas = await NotificationTransactionService.hasSmsPermission();
      if (!stillHas && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SMS permission is required to scan past messages.'),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }
    }

    setState(() {
      _isScanning = true;
      _scanDone = false;
      _scanCount = 0;
    });

    try {
      final transactions = await NotificationTransactionService
          .scanHistoricalMessages(durationDays: _scanDuration);

      if (!mounted) return;

      for (final tx in transactions) {
        await PendingTxService.add(
          PendingTx(
            id: '${tx.hash}_${DateTime.now().millisecondsSinceEpoch}',
            amount: tx.amount,
            type: tx.type,
            description: tx.description,
            source: tx.source,
            category: tx.type == 'income' ? 'Income' : 'General',
            detectedAt: DateTime.now(),
            rawText: tx.rawText,
            transactionCode: tx.transactionCode,
          ),
        );
      }

      if (!mounted) return;
      pendingCountNotifier.value = await PendingTxService.count();

      setState(() {
        _isScanning = false;
        _scanDone = true;
        _scanCount = transactions.length;
      });

      // Refresh the pending transactions display
      await _loadData();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Found ${transactions.length} historical transaction${transactions.length == 1 ? '' : 's'} — review them in Pending',
          ),
          backgroundColor: AppColors.accent,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _scanDone = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Scan failed: ${e.toString().replaceFirst("Exception: ", "")}',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  // ── End actions ─────────────────────────────────────────────────────────

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
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _busyIds.remove(tx.id));
      }
    }
  }

  Future<void> _approveAllPending() async {
    if (_pendingTxs.isEmpty || _isApprovingAll) return;

    setState(() => _isApprovingAll = true);
    final toApprove = List<PendingTx>.from(_pendingTxs);
    int approved = 0;
    int failed = 0;

    // Process in batches of 5 for parallel efficiency without overwhelming
    for (int i = 0; i < toApprove.length; i += 5) {
      if (!mounted) break;
      final batch = toApprove.sublist(
        i, (i + 5).clamp(0, toApprove.length),
      );

      final batchResults = await Future.wait(
        batch.map((tx) => _approveSinglePending(tx)),
      );

      for (final success in batchResults) {
        if (success) approved++;
        else failed++;
      }
    }

    if (!mounted) return;
    setState(() => _isApprovingAll = false);

    // Reload data once at the end
    await _loadData();

    if (!mounted) return;
    _showMessage('Approved $approved transactions${failed > 0 ? ', $failed failed' : ''}');
  }

  /// Approve a single pending transaction. Returns true on success.
  Future<bool> _approveSinglePending(PendingTx tx) async {
    try {
      await ApiService.recordOffchainTransaction(
        description: tx.description,
        amount: tx.amount,
        source: _sourceForApi(tx.source),
        transactionType: tx.type,
        category: tx.category,
      );
      await PendingTxService.remove(tx.id);
      if (mounted) {
        setState(() {
          _pendingTxs.removeWhere((item) => item.id == tx.id);
        });
      }
      return true;
    } catch (_) {
      return false;
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
    final theme = Theme.of(context);

    return AppPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Transaction Feed',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'Review detected payments, track manual entries, and keep the ledger clean.',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
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
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 36,
                child: OutlinedButton.icon(
                  onPressed: _manualSync,
                  icon: const Icon(Icons.sync_rounded, size: 16),
                  label: const Text('Sync'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 36,
                child: ElevatedButton.icon(
                  onPressed: _openAddSheet,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Add'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Historical Scan Card ──────────────────────────────────────
          GestureDetector(
            onTap: () => setState(() => _showScanCard = !_showScanCard),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 18,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Scan past M-Pesa & bank messages',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    _showScanCard
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 18,
                    color: AppColors.accent,
                  ),
                ],
              ),
            ),
          ),

          if (_showScanCard) ...[
            const SizedBox(height: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: theme.dividerColor.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Read past SMS from M-Pesa, KCB, Equity & NCBA',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _DurationDropdown(
                          value: _scanDuration,
                          onChanged: (v) {
                            if (v != null) setState(() => _scanDuration = v);
                          },
                          cardColor: theme.colorScheme.surface,
                          textColor: theme.colorScheme.onSurface,
                          borderColor: theme.dividerColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 90,
                        height: 40,
                        child: ElevatedButton.icon(
                          onPressed: _isScanning ? null : _scanHistoricalMessages,
                          icon: _isScanning
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.search_rounded, size: 16),
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(_isScanning ? 'Scanning...' : 'Scan'),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                AppColors.accent.withValues(alpha: 0.4),
                            minimumSize: const Size(78, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_scanDone) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          _scanCount > 0
                              ? Icons.check_circle_outline
                              : Icons.info_outline,
                          size: 14,
                          color: _scanCount > 0
                              ? AppColors.accent
                              : AppColors.warning,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _scanCount > 0
                                ? 'Found $_scanCount transaction${_scanCount == 1 ? '' : 's'}. Review them in Pending above.'
                                : 'No financial transactions found in the selected period.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: _scanCount > 0
                                  ? AppColors.accent
                                  : AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── Status pills ─────────────────────────────────────────────
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

          // ── Content ──────────────────────────────────────────────────
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
                children: [
                  Expanded(
                    child: Text(
                      'Pending Review',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_pendingTxs.length > 1) ...[
                    SizedBox(
                      height: 30,
                      child: OutlinedButton(
                        onPressed: _isApprovingAll
                            ? null
                            : _approveAllPending,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          visualDensity: VisualDensity.compact,
                          side: BorderSide(color: AppColors.accent.withValues(alpha: 0.5)),
                        ),
                        child: _isApprovingAll
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                'Approve All',
                                style: const TextStyle(fontSize: 11),
                              ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  AppPill(
                    label: '${_pendingTxs.length} new',
                    color: AppColors.danger,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._pendingTxs.take(5).map(_buildPendingCard),
              if (_pendingTxs.length > 5) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                  child: Center(
                    child: TextButton(
                      onPressed: () {
                        // Scroll to expand is implicit — we just show a count
                        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                          SnackBar(
                            content: Text('${_pendingTxs.length - 5} more pending transactions'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Text(
                        '+${_pendingTxs.length - 5} more pending',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 18),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Activity', style: theme.textTheme.titleLarge),
                Text(
                  '${_data.length} items',
                  style: theme.textTheme.bodySmall,
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
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Text(
                          Formatters.formatDate(item['created_at']?.toString()),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: 6),
                        AppPill(
                          label: _sourceLabel(source),
                          color: _sourceTone(source),
                        ),
                        const SizedBox(width: 6),
                        _SyncStatusPill(
                          status:
                              (item['sync_status'] ?? 'synced').toString(),
                        ),
                      ],
                    ),
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

/// Duration picker dropdown reused for historical scan duration.
class _DurationDropdown extends StatelessWidget {
  final int value;
  final ValueChanged<int?> onChanged;
  final Color cardColor;
  final Color textColor;
  final Color borderColor;

  const _DurationDropdown({
    required this.value,
    required this.onChanged,
    required this.cardColor,
    required this.textColor,
    required this.borderColor,
  });

  static const _options = <int, String>{
    1: 'Last 1 day',
    7: 'Last 7 days',
    14: 'Last 2 weeks',
    30: 'Last 1 month',
    90: 'Last 3 months',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
        color: Colors.transparent,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          dropdownColor: cardColor,
          style: TextStyle(color: textColor, fontSize: 13),
          isExpanded: true,
          items: _options.entries
              .map((e) => DropdownMenuItem<int>(
                    value: e.key,
                    child: Text(e.value),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
