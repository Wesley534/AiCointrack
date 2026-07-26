import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/api_service.dart';
import '../services/local_db_service.dart';
import '../utils/formatters.dart';
import '../widgets/design_system.dart';

void _shopLog(
  String scope,
  String message, [
  Object? error,
  StackTrace? stack,
]) {
  final line = '[shopping][$scope] $message';
  debugPrint(line);
  if (error != null) {
    debugPrint('[shopping][$scope][error] $error');
  }
  if (stack != null) {
    debugPrint('[shopping][$scope][stack] $stack');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHOPPING LISTS PAGE
// ─────────────────────────────────────────────────────────────────────────────

class ShoppingListsPage extends StatefulWidget {
  const ShoppingListsPage({super.key});

  @override
  State<ShoppingListsPage> createState() => _ShoppingListsPageState();
}

class _ShoppingListsPageState extends State<ShoppingListsPage> {
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isStale = true;
  String? _error;
  List<dynamic> _data = [];

  @override
  void initState() {
    super.initState();
    _shopLog('ShoppingListsPage', 'initState mounted=$mounted');
    _loadData();
  }

  @override
  void dispose() {
    _shopLog('ShoppingListsPage', 'dispose mounted=$mounted');
    super.dispose();
  }

  Future<void> _loadData() async {
    _shopLog('ShoppingListsPage', '_loadData start mounted=$mounted');
    // Parallelise cache reads for better performance
    final results = await Future.wait([
      ApiService.fetchCachedShoppingLists(),
      LocalDbService.instance.isCacheStale('shopping_lists'),
    ]);
    final cached = results[0] as List<dynamic>;
    final isStale = results[1] as bool;

    if (!mounted) return;
    setState(() {
      _data = cached;
      _isLoading = cached.isEmpty;
      _isRefreshing = cached.isNotEmpty;
      _isStale = isStale;
      _error = null;
    });
    try {
      final result = await ApiService.refreshShoppingListsCache();
      _shopLog(
        'ShoppingListsPage',
        '_loadData success count=${result.length} mounted=$mounted',
      );
      if (!mounted) return;
      setState(() {
        _data = result;
        _isLoading = false;
        _isRefreshing = false;
        _isStale = false;
      });
    } catch (e, st) {
      _shopLog(
        'ShoppingListsPage',
        '_loadData failure mounted=$mounted',
        e,
        st,
      );
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

  Future<void> _openNewListSheet(BuildContext scaffoldCtx) async {
    _shopLog('ShoppingListsPage', '_openNewListSheet open mounted=$mounted');
    final bool? created = await showModalBottomSheet<bool>(
      context: scaffoldCtx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _NewListSheet(),
    );

    _shopLog(
      'ShoppingListsPage',
      '_openNewListSheet closed created=$created mounted=$mounted scaffoldMounted=${scaffoldCtx.mounted}',
    );

    if (created == true && mounted) {
      await _loadData();
    }
  }

  double _totalForItems(List<dynamic> items) => items.fold<double>(
    0.0,
    (sum, item) =>
        sum +
        ((item['price'] ?? 0) as num).toDouble() *
            ((item['qty'] ?? 1) as num).toDouble(),
  );

  // ── State sub-widgets ──────────────────────────────────────────────────────

  Widget _buildError() => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 48),
          const SizedBox(height: 12),
          Text(
            _error!,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry'),
          ),
        ],
      ),
    ),
  );

  Widget _buildEmpty(BuildContext scaffoldCtx) => Center(
    child: Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🛒', style: TextStyle(fontSize: 32)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No shopping lists yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Create a list to start tracking your shopping budget.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _openNewListSheet(scaffoldCtx),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Create List'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

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
              Text('Shopping Lists', style: theme.textTheme.headlineMedium),
              OutlinedButton.icon(
                onPressed: () => _openNewListSheet(context),
                icon: const Icon(Icons.add, size: 14),
                label: const Text('New List'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  side: BorderSide(
                    color: AppColors.accent.withOpacity(0.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Manage your shopping lists and track spending against budgets.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          if (_data.isNotEmpty)
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
                      label: 'Showing cached lists',
                      color: AppColors.warning,
                    ),
                ],
              ),
            ),
          if (_data.isEmpty) _buildEmpty(context),
          ...(_data.map((raw) {
            final list = Map<String, dynamic>.from(raw as Map);
            final items = (list['items'] as List<dynamic>? ?? []);
            final total = _totalForItems(items);
            final budget = ((list['budget'] ?? 0) as num).toDouble();
            final pct = budget <= 0
                ? 0.0
                : (total / budget).clamp(0.0, 1.0);
            final status = (list['status'] ?? 'green').toString();

            Color barColor;
            Color statusBg;
            Color statusFg;

            switch (status) {
              case 'red':
                barColor = AppColors.danger;
                statusBg = AppColors.danger.withOpacity(0.1);
                statusFg = AppColors.danger;
                break;
              case 'yellow':
                barColor = AppColors.warning;
                statusBg = AppColors.warning.withOpacity(0.1);
                statusFg = AppColors.warning;
                break;
              default:
                barColor = AppColors.accent;
                statusBg = AppColors.accent.withOpacity(0.1);
                statusFg = AppColors.accent;
            }

            return GestureDetector(
              onTap: () =>
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ShoppingDetailPage(listId: list['id'] as int),
                    ),
                  ).then((_) => _loadData()),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppGlassCard(
                  radius: 24,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              (list['name'] ?? '').toString(),
                              style: theme.textTheme.titleMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(
                                color: statusFg.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              '${items.length} item${items.length == 1 ? '' : 's'}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: statusFg,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 6,
                          backgroundColor: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            barColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Spent: ${Formatters.formatKes(total)}',
                              style: theme.textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Budget: ${Formatters.formatKes(budget)}',
                              style: theme.textTheme.bodySmall,
                              textAlign: TextAlign.end,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (total > budget && budget > 0) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              size: 12,
                              color: AppColors.danger,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Over by ${Formatters.formatKes(total - budget)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }).toList()),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NEW LIST SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _NewListSheet extends StatefulWidget {
  const _NewListSheet();

  @override
  State<_NewListSheet> createState() => _NewListSheetState();
}

class _NewListSheetState extends State<_NewListSheet> {
  String? _error;
  bool _isSubmitting = false;
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _budgetCtrl = TextEditingController();

  @override
  void dispose() {
    _shopLog('NewListSheet', 'dispose mounted=$mounted');
    _nameCtrl.dispose();
    _budgetCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final budget = double.tryParse(_budgetCtrl.text.trim());
    if (name.isEmpty || budget == null || budget <= 0) {
      setState(() => _error = 'Enter a valid name and budget amount.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    // Capture Navigator BEFORE await — avoids deactivated context after async gap
    final navigator = Navigator.of(context);

    try {
      await ApiService.createShoppingList(name: name, budget: budget);
      navigator.pop(true);
    } catch (e, st) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isSubmitting = false;
        });
      }
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
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'New Shopping List',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Add a name and a total budget for this list.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'List name',
              hintText: 'e.g. Weekly Groceries',
            ),
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _budgetCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Budget (KES)',
              hintText: '0',
            ),
            style: theme.textTheme.bodyLarge,
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.danger),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppColors.danger, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.accent.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Create List',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHOPPING DETAIL PAGE
// ─────────────────────────────────────────────────────────────────────────────

class ShoppingDetailPage extends StatefulWidget {
  final int listId;
  const ShoppingDetailPage({super.key, required this.listId});

  @override
  State<ShoppingDetailPage> createState() => _ShoppingDetailPageState();
}

class _ShoppingDetailPageState extends State<ShoppingDetailPage> {
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isStale = true;
  String? _error;
  Map<String, dynamic> _data = {};
  final Set<int> _checked = {};
  bool _isCheckoutLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadData() async {
    // Parallelise cache reads
    final cacheKey = 'shopping_detail_${widget.listId}';
    final results = await Future.wait([
      ApiService.fetchCachedShoppingListDetail(widget.listId),
      LocalDbService.instance.isCacheStale(cacheKey),
    ]);
    final cached = results[0] as Map<String, dynamic>;
    final isStale = results[1] as bool;

    if (!mounted) return;
    setState(() {
      _data = cached;
      _isLoading = cached.isEmpty;
      _isRefreshing = cached.isNotEmpty;
      _isStale = isStale;
      _error = null;
    });
    try {
      final result = await ApiService.refreshShoppingListDetailCache(
        widget.listId,
      );
      if (!mounted) return;
      setState(() {
        _data = result;
        _isLoading = false;
        _isRefreshing = false;
        _isStale = false;
      });
    } catch (e, st) {
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

  Future<void> _openAddItemSheet(BuildContext scaffoldCtx) async {
    final bool? added = await showModalBottomSheet<bool>(
      context: scaffoldCtx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddItemSheet(listId: widget.listId),
    );

    if (added == true && mounted) {
      await _loadData();
    }
  }

  Future<void> _openEditItemSheet(
    BuildContext scaffoldCtx, {
    required int itemId,
    required String currentName,
    required int currentQty,
    required double currentPrice,
  }) async {
    final bool? edited = await showModalBottomSheet<bool>(
      context: scaffoldCtx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditItemSheet(
        listId: widget.listId,
        itemId: itemId,
        initialName: currentName,
        initialQty: currentQty,
        initialPrice: currentPrice,
      ),
    );

    if (edited == true && mounted) {
      await _loadData();
    }
  }

  Future<void> _checkout(BuildContext scaffoldCtx) async {
    final items = (_data['items'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final unchecked = [
      for (int i = 0; i < items.length; i++)
        if (!_checked.contains(i)) items[i],
    ];

    if (unchecked.isEmpty) {
      ScaffoldMessenger.of(scaffoldCtx).showSnackBar(
        const SnackBar(content: Text('All items are already marked complete.')),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isCheckoutLoading = true);

    final messenger = ScaffoldMessenger.of(scaffoldCtx);

    try {
      for (final item in unchecked) {
        final qty = ((item['qty'] ?? 1) as num).toDouble();
        final price = ((item['price'] ?? 0) as num).toDouble();
        await ApiService.recordOffchainTransaction(
          description: (item['name'] ?? 'Shopping item').toString(),
          amount: qty * price,
          source: 'cash',
          category: 'Shopping',
          transactionType: 'expense',
        );
      }
      if (!mounted) return;
      setState(() {
        for (int i = 0; i < items.length; i++) {
          _checked.add(i);
        }
        _isCheckoutLoading = false;
      });
      messenger.showSnackBar(
        const SnackBar(
          content: Text('All items logged as expenses!'),
          backgroundColor: AppColors.accent,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCheckoutLoading = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Widget _buildError() => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 48),
          const SizedBox(height: 12),
          Text(
            _error!,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry'),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    final title = (_data['title'] ?? 'Shopping List').toString();
    final total = ((_data['total'] ?? 0) as num).toDouble();
    final remaining = ((_data['remaining'] ?? 0) as num).toDouble();
    final items = (_data['items'] as List<dynamic>? ?? []);
    final checkedCount = _checked.length;
    final totalCount = items.length;

    if (_isLoading) {
      return Scaffold(
        body: const AppSkeletonList(count: 5),
      );
    }
    if (_error != null) {
      return Scaffold(
        body: AppPage(child: _buildError()),
      );
    }

    return Scaffold(
      body: AppPage(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title row ──────────────────────────────────────────────
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Icon(
                      Icons.arrow_back,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.headlineMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _openAddItemSheet(context),
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('Add Item'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: BorderSide(
                      color: AppColors.accent.withOpacity(0.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_data.isNotEmpty)
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
                        label: 'Showing cached details',
                        color: AppColors.warning,
                      ),
                  ],
                ),
              ),

            // ── Budget summary card ────────────────────────────────────
            AppGlassCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TOTAL ESTIMATED',
                              style: theme.textTheme.bodySmall?.copyWith(
                                letterSpacing: 0.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              Formatters.formatKes(total),
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: theme.dividerColor,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'REMAINING',
                              style: theme.textTheme.bodySmall?.copyWith(
                                letterSpacing: 0.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              Formatters.formatKes(remaining),
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: remaining < 0
                                    ? AppColors.danger
                                    : AppColors.accent,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: (total + remaining) > 0
                          ? (total / (total + remaining)).clamp(0.0, 1.0)
                          : 0.0,
                      minHeight: 6,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        remaining < 0 ? AppColors.danger : AppColors.accent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$checkedCount of $totalCount items checked',
                        style: theme.textTheme.bodySmall,
                      ),
                      if (checkedCount > 0)
                        GestureDetector(
                          onTap: () => setState(() => _checked.clear()),
                          child: Text(
                            'Clear all',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Items ──────────────────────────────────────────────────
            if (items.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Column(
                    children: [
                      const Text('🧾', style: TextStyle(fontSize: 36)),
                      const SizedBox(height: 12),
                      Text(
                        'No items yet. Tap Add Item to get started.',
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              Text(
                'Items',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              AppGlassCard(
                radius: 20,
                padding: EdgeInsets.zero,
                child: Column(
                  children: items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = Map<String, dynamic>.from(
                      entry.value as Map,
                    );
                    final isChecked = _checked.contains(index);
                    final isLast = index == items.length - 1;
                    final price = ((item['price'] ?? 0) as num).toDouble();
                    final qty = ((item['qty'] ?? 1) as num).toInt();
                    final itemId = (item['id'] as int?) ?? 0;

                    return Column(
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.vertical(
                            top: index == 0
                                ? const Radius.circular(20)
                                : Radius.zero,
                            bottom: isLast
                                ? const Radius.circular(20)
                                : Radius.zero,
                          ),
                          onTap: () => setState(() {
                            if (isChecked) {
                              _checked.remove(index);
                            } else {
                              _checked.add(index);
                            }
                          }),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: isChecked
                                        ? AppColors.accent
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isChecked
                                          ? AppColors.accent
                                          : theme.dividerColor,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: isChecked
                                      ? const Icon(
                                          Icons.check,
                                          size: 14,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        (item['name'] ?? '').toString(),
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          color: isChecked
                                              ? theme.colorScheme.onSurfaceVariant
                                              : null,
                                          decoration: isChecked
                                              ? TextDecoration.lineThrough
                                              : TextDecoration.none,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Qty: $qty · ${Formatters.formatKes(price)} each',
                                        style: theme.textTheme.bodySmall,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                // Edit button
                                GestureDetector(
                                  onTap: () => _openEditItemSheet(
                                    context,
                                    itemId: itemId,
                                    currentName: (item['name'] ?? '').toString(),
                                    currentQty: qty,
                                    currentPrice: price,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.edit_rounded,
                                      size: 14,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  Formatters.formatKes(price * qty),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: isChecked
                                        ? theme.colorScheme.onSurfaceVariant
                                        : null,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (!isLast)
                          Divider(
                            height: 1,
                            indent: 52,
                            color: theme.dividerColor,
                          ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isCheckoutLoading
                    ? null
                    : () => _checkout(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.accent.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isCheckoutLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_cart_checkout, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Checkout → Log as Expenses',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ADD ITEM SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _AddItemSheet extends StatefulWidget {
  final int listId;

  const _AddItemSheet({required this.listId});

  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  String? _error;
  bool _isSubmitting = false;
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _qtyCtrl = TextEditingController(text: '1');
  final TextEditingController _priceCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final qty = int.tryParse(_qtyCtrl.text.trim());
    final price = double.tryParse(_priceCtrl.text.trim());

    if (name.isEmpty ||
        qty == null ||
        qty <= 0 ||
        price == null ||
        price <= 0) {
      setState(
        () => _error = 'Please enter a valid name, quantity, and price.',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final navigator = Navigator.of(context);

    try {
      await ApiService.addShoppingItem(
        widget.listId,
        name: name,
        qty: qty,
        price: price,
      );
      navigator.pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isSubmitting = false;
        });
      }
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
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Add Item',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Enter the item details to add it to the list.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Item name',
              hintText: 'e.g. Milk 2L',
            ),
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    hintText: '1',
                  ),
                  style: theme.textTheme.bodyLarge,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Price (KES)',
                    hintText: '0',
                  ),
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.danger),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppColors.danger, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.accent.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )                    : const Text(
                      'Add Item',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EDIT ITEM SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _EditItemSheet extends StatefulWidget {
  final int listId;
  final int itemId;
  final String initialName;
  final int initialQty;
  final double initialPrice;

  const _EditItemSheet({
    required this.listId,
    required this.itemId,
    required this.initialName,
    required this.initialQty,
    required this.initialPrice,
  });

  @override
  State<_EditItemSheet> createState() => _EditItemSheetState();
}

class _EditItemSheetState extends State<_EditItemSheet> {
  String? _error;
  bool _isSubmitting = false;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _priceCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
    _qtyCtrl = TextEditingController(text: widget.initialQty.toString());
    _priceCtrl = TextEditingController(text: widget.initialPrice.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final qty = int.tryParse(_qtyCtrl.text.trim());
    final price = double.tryParse(_priceCtrl.text.trim());

    if (name.isEmpty || qty == null || qty <= 0 || price == null || price <= 0) {
      setState(() => _error = 'Please enter a valid name, quantity, and price.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final navigator = Navigator.of(context);

    try {
      await ApiService.updateShoppingItem(
        widget.listId,
        widget.itemId,
        name: name,
        qty: qty,
        price: price,
      );
      navigator.pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isSubmitting = false;
        });
      }
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
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Edit Item',
                style: theme.textTheme.headlineSmall,
              ),
              const Spacer(),
              Icon(Icons.edit_rounded, size: 18, color: AppColors.accent),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Update the item details.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Item name',
              hintText: 'e.g. Milk 2L',
            ),
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    hintText: '1',
                  ),
                  style: theme.textTheme.bodyLarge,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Price (KES)',
                    hintText: '0',
                  ),
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.danger),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppColors.danger, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.accent.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Save Changes',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
