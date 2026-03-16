import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/api_service.dart';
import '../utils/formatters.dart';

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
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await ApiService.fetchShoppingListsFromApi();
      _shopLog(
        'ShoppingListsPage',
        '_loadData success count=${result.length} mounted=$mounted',
      );
      if (!mounted) return;
      setState(() {
        _data = result;
        _isLoading = false;
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
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
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

  Widget _buildLoader(Color mutedColor) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(AppColors.accent),
        ),
        const SizedBox(height: 14),
        Text('Loading...', style: TextStyle(color: mutedColor, fontSize: 14)),
      ],
    ),
  );

  Widget _buildError(Color mutedColor) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
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
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildEmpty(BuildContext scaffoldCtx, Color mutedColor) => Center(
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
            style: TextStyle(
              color: mutedColor,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Create a list to start tracking your shopping budget.',
            style: TextStyle(color: mutedColor.withOpacity(0.7), fontSize: 12),
            textAlign: TextAlign.center,
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
    final bgColor = isDark ? AppColors.darkBg : AppColors.lightBg;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    return Scaffold(
      backgroundColor: bgColor,
      body: Builder(
        builder: (scaffoldCtx) {
          if (_isLoading) return _buildLoader(mutedColor);
          if (_error != null) return _buildError(mutedColor);

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Shopping Lists',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _openNewListSheet(scaffoldCtx),
                      icon: const Icon(Icons.add, size: 14),
                      label: const Text(
                        'New List',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accent,
                        side: BorderSide(
                          color: AppColors.accent.withOpacity(0.5),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_data.isEmpty) _buildEmpty(scaffoldCtx, mutedColor),
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
                  Color borderTint;
                  Color statusBg;
                  Color statusFg;

                  switch (status) {
                    case 'red':
                      barColor = AppColors.danger;
                      borderTint = AppColors.danger.withOpacity(0.25);
                      statusBg = AppColors.danger.withOpacity(0.1);
                      statusFg = AppColors.danger;
                      break;
                    case 'yellow':
                      barColor = AppColors.warning;
                      borderTint = AppColors.warning.withOpacity(0.25);
                      statusBg = AppColors.warning.withOpacity(0.1);
                      statusFg = AppColors.warning;
                      break;
                    default:
                      barColor = AppColors.accent;
                      borderTint = borderColor;
                      statusBg = AppColors.accent.withOpacity(0.1);
                      statusFg = AppColors.accent;
                  }

                  return GestureDetector(
                    onTap: () =>
                        Navigator.push(
                          scaffoldCtx,
                          MaterialPageRoute(
                            builder: (_) =>
                                ShoppingDetailPage(listId: list['id'] as int),
                          ),
                        ).then((_) {
                          _shopLog(
                            'ShoppingListsPage',
                            'returned from ShoppingDetailPage mounted=$mounted scaffoldMounted=${scaffoldCtx.mounted}',
                          );
                          _loadData();
                        }),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderTint),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  (list['name'] ?? '').toString(),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                              ),
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
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: statusFg,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
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
                              Text(
                                'Spent: ${Formatters.formatKes(total)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: mutedColor,
                                ),
                              ),
                              Text(
                                'Budget: ${Formatters.formatKes(budget)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: mutedColor,
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
                                Text(
                                  'Over by ${Formatters.formatKes(total - budget)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.danger,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList()),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NEW LIST SHEET
// The ROOT FIX: capture Navigator before the await so the reference is
// never stale when we call pop() after the async API call completes.
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

    // ── ROOT FIX ─────────────────────────────────────────────────────────────
    // Capture the NavigatorState BEFORE the await. After an async gap the
    // widget may have been deactivated and context.owner is null, making any
    // Navigator.of(context) call throw _dependents.isEmpty. Storing the state
    // object before the gap keeps a valid reference regardless of rebuild.
    final navigator = Navigator.of(context);
    _shopLog('NewListSheet', '_submit start mounted=$mounted');
    // ─────────────────────────────────────────────────────────────────────────

    try {
      await ApiService.createShoppingList(name: name, budget: budget);
      _shopLog('NewListSheet', '_submit success mounted=$mounted');
      navigator.pop(true); // safe: navigator ref is stable
    } catch (e, st) {
      _shopLog('NewListSheet', '_submit failure mounted=$mounted', e, st);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
                color: borderColor,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'New Shopping List',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add a name and a total budget for this list.',
            style: TextStyle(fontSize: 13, color: mutedColor),
          ),
          const SizedBox(height: 20),
          _ThemedField(
            controller: _nameCtrl,
            label: 'List name',
            hint: 'e.g. Weekly Groceries',
            textColor: textColor,
            mutedColor: mutedColor,
            borderColor: borderColor,
          ),
          const SizedBox(height: 12),
          _ThemedField(
            controller: _budgetCtrl,
            label: 'Budget (KES)',
            hint: '0',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textColor: textColor,
            mutedColor: mutedColor,
            borderColor: borderColor,
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            _InlineError(message: _error!),
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
  String? _error;
  Map<String, dynamic> _data = {};
  final Set<int> _checked = {};
  bool _isCheckoutLoading = false;

  @override
  void initState() {
    super.initState();
    _shopLog(
      'ShoppingDetailPage',
      'initState listId=${widget.listId} mounted=$mounted',
    );
    _loadData();
  }

  @override
  void dispose() {
    _shopLog(
      'ShoppingDetailPage',
      'dispose listId=${widget.listId} mounted=$mounted',
    );
    super.dispose();
  }

  Future<void> _loadData() async {
    _shopLog(
      'ShoppingDetailPage',
      '_loadData start listId=${widget.listId} mounted=$mounted',
    );
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await ApiService.fetchShoppingListDetail(widget.listId);
      _shopLog('ShoppingDetailPage', '_loadData success mounted=$mounted');
      if (!mounted) return;
      setState(() {
        _data = result;
        _isLoading = false;
      });
    } catch (e, st) {
      _shopLog(
        'ShoppingDetailPage',
        '_loadData failure mounted=$mounted',
        e,
        st,
      );
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _openAddItemSheet(BuildContext scaffoldCtx) async {
    _shopLog(
      'ShoppingDetailPage',
      '_openAddItemSheet open mounted=$mounted scaffoldMounted=${scaffoldCtx.mounted}',
    );
    final bool? added = await showModalBottomSheet<bool>(
      context: scaffoldCtx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddItemSheet(listId: widget.listId),
    );

    _shopLog(
      'ShoppingDetailPage',
      '_openAddItemSheet closed added=$added mounted=$mounted scaffoldMounted=${scaffoldCtx.mounted}',
    );

    if (added == true && mounted) {
      await _loadData();
    }
  }

  Future<void> _checkout(BuildContext scaffoldCtx) async {
    _shopLog(
      'ShoppingDetailPage',
      '_checkout start mounted=$mounted scaffoldMounted=${scaffoldCtx.mounted}',
    );
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

    // Capture messenger before await
    final messenger = ScaffoldMessenger.of(scaffoldCtx);
    _shopLog(
      'ShoppingDetailPage',
      '_checkout uncheckedCount=${unchecked.length}',
    );

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
        _shopLog('ShoppingDetailPage', '_checkout logged item=${item['name']}');
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
      _shopLog(
        'ShoppingDetailPage',
        '_checkout success mounted=$mounted scaffoldMounted=${scaffoldCtx.mounted}',
      );
    } catch (e, st) {
      _shopLog(
        'ShoppingDetailPage',
        '_checkout failure mounted=$mounted scaffoldMounted=${scaffoldCtx.mounted}',
        e,
        st,
      );
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

  Widget _buildLoader(Color mutedColor) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(AppColors.accent),
        ),
        const SizedBox(height: 14),
        Text('Loading...', style: TextStyle(color: mutedColor, fontSize: 14)),
      ],
    ),
  );

  Widget _buildError(Color mutedColor) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
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
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBg : AppColors.lightBg;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    final title = (_data['title'] ?? 'Shopping List').toString();
    final total = ((_data['total'] ?? 0) as num).toDouble();
    final remaining = ((_data['remaining'] ?? 0) as num).toDouble();
    final items = (_data['items'] as List<dynamic>? ?? []);
    final checkedCount = _checked.length;
    final totalCount = items.length;

    return Scaffold(
      backgroundColor: bgColor,
      body: Builder(
        builder: (scaffoldCtx) {
          if (_isLoading) return _buildLoader(mutedColor);
          if (_error != null) return _buildError(mutedColor);

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Title row ──────────────────────────────────────────────
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(scaffoldCtx).maybePop(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderColor),
                        ),
                        child: Icon(
                          Icons.arrow_back,
                          size: 18,
                          color: mutedColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _openAddItemSheet(scaffoldCtx),
                      icon: const Icon(Icons.add, size: 14),
                      label: const Text(
                        'Add Item',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accent,
                        side: BorderSide(
                          color: AppColors.accent.withOpacity(0.5),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Budget summary card ────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryCell(
                              label: 'TOTAL ESTIMATED',
                              value: Formatters.formatKes(total),
                              valueColor: textColor,
                              mutedColor: mutedColor,
                            ),
                          ),
                          Container(width: 1, height: 36, color: borderColor),
                          Expanded(
                            child: _SummaryCell(
                              label: 'REMAINING',
                              value: Formatters.formatKes(remaining),
                              valueColor: remaining < 0
                                  ? AppColors.danger
                                  : AppColors.accent,
                              mutedColor: mutedColor,
                              align: CrossAxisAlignment.end,
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
                          backgroundColor: borderColor,
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
                            style: TextStyle(fontSize: 11, color: mutedColor),
                          ),
                          if (checkedCount > 0)
                            GestureDetector(
                              onTap: () => setState(() => _checked.clear()),
                              child: Text(
                                'Clear all',
                                style: TextStyle(
                                  fontSize: 11,
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
                            style: TextStyle(color: mutedColor, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  Text(
                    'Items',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
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

                        return Column(
                          children: [
                            InkWell(
                              borderRadius: BorderRadius.vertical(
                                top: index == 0
                                    ? const Radius.circular(16)
                                    : Radius.zero,
                                bottom: isLast
                                    ? const Radius.circular(16)
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
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 150,
                                      ),
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
                                              : borderColor,
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
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: isChecked
                                                  ? mutedColor
                                                  : textColor,
                                              decoration: isChecked
                                                  ? TextDecoration.lineThrough
                                                  : TextDecoration.none,
                                              decorationColor: mutedColor,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Qty: $qty  ·  ${Formatters.formatKes(price)} each',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: mutedColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      Formatters.formatKes(price * qty),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: isChecked
                                            ? mutedColor
                                            : textColor,
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
                                color: borderColor,
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
                        : () => _checkout(scaffoldCtx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.accent.withOpacity(
                        0.5,
                      ),
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
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ADD ITEM SHEET
// Same root fix: capture Navigator before the await.
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
    _shopLog(
      'AddItemSheet',
      'dispose listId=${widget.listId} mounted=$mounted',
    );
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

    // ── ROOT FIX ─────────────────────────────────────────────────────────────
    // Capture BEFORE the await — same reason as _NewListSheetState.
    final navigator = Navigator.of(context);
    _shopLog(
      'AddItemSheet',
      '_submit start listId=${widget.listId} mounted=$mounted',
    );
    // ─────────────────────────────────────────────────────────────────────────

    try {
      await ApiService.addShoppingItem(
        widget.listId,
        name: name,
        qty: qty,
        price: price,
      );
      _shopLog('AddItemSheet', '_submit success mounted=$mounted');
      navigator.pop(true);
    } catch (e, st) {
      _shopLog(
        'AddItemSheet',
        '_submit failure listId=${widget.listId} mounted=$mounted',
        e,
        st,
      );
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
                color: borderColor,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Add Item',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Enter the item details to add it to the list.',
            style: TextStyle(fontSize: 13, color: mutedColor),
          ),
          const SizedBox(height: 20),
          _ThemedField(
            controller: _nameCtrl,
            label: 'Item name',
            hint: 'e.g. Milk 2L',
            textColor: textColor,
            mutedColor: mutedColor,
            borderColor: borderColor,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ThemedField(
                  controller: _qtyCtrl,
                  label: 'Quantity',
                  hint: '1',
                  keyboardType: TextInputType.number,
                  textColor: textColor,
                  mutedColor: mutedColor,
                  borderColor: borderColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ThemedField(
                  controller: _priceCtrl,
                  label: 'Price (KES)',
                  hint: '0',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textColor: textColor,
                  mutedColor: mutedColor,
                  borderColor: borderColor,
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            _InlineError(message: _error!),
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
// SHARED SMALL WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _ThemedField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType keyboardType;
  final Color textColor;
  final Color mutedColor;
  final Color borderColor;

  const _ThemedField({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType = TextInputType.text,
    required this.textColor,
    required this.mutedColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: mutedColor,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(fontSize: 14, color: textColor),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: mutedColor.withOpacity(0.5)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            filled: true,
            fillColor: Colors.transparent,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;
  const _InlineError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.warning_amber_rounded,
          size: 14,
          color: AppColors.danger,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(color: AppColors.danger, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _SummaryCell extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final Color mutedColor;
  final CrossAxisAlignment align;

  const _SummaryCell({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.mutedColor,
    this.align = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: align == CrossAxisAlignment.end
          ? const EdgeInsets.only(left: 12)
          : const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: mutedColor,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
