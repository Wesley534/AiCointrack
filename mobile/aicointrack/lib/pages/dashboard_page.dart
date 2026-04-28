import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/pending_transactions_service.dart';
import '../utils/formatters.dart';
import '../widgets/design_system.dart';
import 'budget_page.dart';
import 'login_page.dart';
import 'pending_transactions_page.dart';
import 'savings_closeout_pages.dart';
import 'settings_page.dart';
import 'shopping_pages.dart';
import 'transactions_page.dart';

class DashboardPage extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String? photoUrl;
  final Map<String, dynamic>? userData;

  const DashboardPage({
    super.key,
    required this.userName,
    required this.userEmail,
    this.photoUrl,
    this.userData,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentNavIndex = 0;
  bool _summaryLoading = true;
  String? _summaryError;
  Map<String, dynamic> _summary = {};
  List<Map<String, dynamic>> _budgetCategories = [];
  List<Map<String, dynamic>> _recentTransactions = [];
  List<Map<String, dynamic>> _shoppingLists = [];
  List<Map<String, dynamic>> _savingsGoals = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _summaryLoading = true;
      _summaryError = null;
    });

    try {
      final topLevel = await Future.wait<dynamic>([
        ApiService.fetchDashboardSummaryFromApi(),
        ApiService.fetchWalletBalance(),
      ]);
      final detail = await Future.wait<dynamic>([
        ApiService.fetchCurrentBudget(),
        ApiService.fetchTransactions(limit: 4),
        ApiService.fetchShoppingListsFromApi(),
        ApiService.fetchSavingsGoalsFromApi(),
      ]);

      if (!mounted) return;
      setState(() {
        _summary = {
          ...(topLevel[0] as Map<String, dynamic>),
          ...(topLevel[1] as Map<String, dynamic>),
        };
        _budgetCategories = (detail[0] as List).cast<Map<String, dynamic>>();
        _recentTransactions = (detail[1] as List).cast<Map<String, dynamic>>();
        _shoppingLists = (detail[2] as List).cast<Map<String, dynamic>>();
        _savingsGoals = (detail[3] as List).cast<Map<String, dynamic>>();
        _summaryLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _summaryError = e.toString().replaceFirst('Exception: ', '');
        _summaryLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !mounted) return;

    try {
      await AuthService.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error signing out: $e')));
    }
  }

  void _showProfileMenu() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                _Avatar(name: widget.userName, size: 56),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.userName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.userEmail,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Account & app settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const SettingsPage()));
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
              ),
              title: const Text('Theme'),
              subtitle: Text(isDark ? 'Dark mode' : 'Light mode'),
              trailing: Switch(
                value: isDark,
                onChanged: (_) {
                  Provider.of<ThemeProvider>(
                    context,
                    listen: false,
                  ).toggleTheme();
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.logout, color: AppColors.danger),
              title: const Text(
                'Sign out',
                style: TextStyle(color: AppColors.danger),
              ),
              onTap: _handleLogout,
            ),
          ],
        ),
      ),
    );
  }

  double _readDouble(Iterable<String> keys, [Map<String, dynamic>? source]) {
    final map = source ?? _summary;
    for (final key in keys) {
      final value = map[key];
      if (value is num) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed != null) return parsed;
      }
    }
    return 0;
  }

  double get _budgetPlannedTotal => _budgetCategories.fold<double>(
    0,
    (sum, item) => sum + ((item['planned'] ?? 0) as num).toDouble(),
  );

  double get _budgetActualTotal => _budgetCategories.fold<double>(
    0,
    (sum, item) => sum + ((item['actual'] ?? 0) as num).toDouble(),
  );

  double get _savedTotal => _savingsGoals.fold<double>(
    0,
    (sum, item) => sum + ((item['saved'] ?? 0) as num).toDouble(),
  );

  Widget _buildBody() {
    switch (_currentNavIndex) {
      case 1:
        return const BudgetPage();
      case 2:
        return const TransactionsPage();
      case 3:
        return const ShoppingListsPage();
      case 4:
        return const SavingsPage();
      default:
        return _buildDashboardHome();
    }
  }

  Widget _buildDashboardHome() {
    final walletValue = _readDouble([
      'wallet_balance',
      'walletBalance',
      'balance',
      'total_balance',
      'totalBalance',
    ]);
    final fiatValue = _readDouble([
      'fiat_balance',
      'fiatBalance',
      'cash_balance',
    ]);
    final cryptoValue = _readDouble(['crypto_balance', 'cryptoBalance']);
    final monthlyDelta = _readDouble([
      'change_percent',
      'monthly_change',
      'variance',
    ]);
    final shoppingBudget = _shoppingLists.fold<double>(
      0,
      (sum, item) => sum + ((item['budget'] ?? 0) as num).toDouble(),
    );
    final shoppingItems = _shoppingLists.fold<int>(
      0,
      (sum, item) =>
          sum +
          (((item['items_count'] ?? item['item_count']) ?? 0) as num).toInt(),
    );

    if (_summaryLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_summaryError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: AppColors.danger,
                size: 46,
              ),
              const SizedBox(height: 12),
              Text(
                _summaryError!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadDashboardData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return AppPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppGlassCard(
            padding: const EdgeInsets.all(24),
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
                          Text(
                            'Total Balance',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            Formatters.formatKes(walletValue),
                            style: Theme.of(context).textTheme.displayMedium,
                          ),
                        ],
                      ),
                    ),
                    AppPill(
                      label: monthlyDelta == 0
                          ? 'Stable'
                          : '${monthlyDelta >= 0 ? '+' : ''}${monthlyDelta.toStringAsFixed(1)}%',
                      color: monthlyDelta >= 0
                          ? AppColors.positive
                          : AppColors.danger,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _LegendValue(
                        label: 'Fiat',
                        value: Formatters.formatKes(fiatValue),
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _LegendValue(
                        label: 'Crypto',
                        value: Formatters.formatKes(cryptoValue),
                        color: AppColors.positive,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _BentoCard(
                  title: 'Budgets',
                  subtitle: _budgetPlannedTotal == 0
                      ? 'No categories yet'
                      : '${((_budgetActualTotal / _budgetPlannedTotal).clamp(0, 1) * 100).toStringAsFixed(0)}% used',
                  icon: Icons.leaderboard_rounded,
                  iconColor: AppColors.purple,
                  iconBg: AppColors.amberBg.withValues(alpha: 0.6),
                  footer: LinearProgressIndicator(
                    value: _budgetPlannedTotal == 0
                        ? 0
                        : (_budgetActualTotal / _budgetPlannedTotal).clamp(
                            0,
                            1,
                          ),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(999),
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.accent,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _BentoCard(
                  title: 'Shopping',
                  subtitle: shoppingItems == 0
                      ? 'Nothing queued'
                      : '$shoppingItems items tracked',
                  icon: Icons.receipt_long_rounded,
                  iconColor: AppColors.positive,
                  iconBg: AppColors.greenBg.withValues(alpha: 0.32),
                  footer: Text(
                    shoppingBudget == 0
                        ? 'Create a list'
                        : 'Budget ${Formatters.formatKes(shoppingBudget)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              AppMetricTile(
                label: 'Budget left',
                value: Formatters.formatKes(
                  (_budgetPlannedTotal - _budgetActualTotal).clamp(
                    0,
                    double.infinity,
                  ),
                ),
                tint: AppColors.accent,
              ),
              const SizedBox(width: 12),
              AppMetricTile(
                label: 'Saved',
                value: Formatters.formatKes(_savedTotal),
                tint: AppColors.positive,
              ),
            ],
          ),
          const SizedBox(height: 24),
          AppSectionTitle(
            title: 'Recent Activity',
            action: TextButton(
              onPressed: () => setState(() => _currentNavIndex = 2),
              child: const Text('View all'),
            ),
          ),
          const SizedBox(height: 12),
          if (_recentTransactions.isEmpty)
            const AppGlassCard(
              child: Text(
                'No transactions yet. Your latest activity will appear here.',
              ),
            )
          else
            ..._recentTransactions.map(_buildActivityCard),
          const SizedBox(height: 24),
          AppSectionTitle(title: 'Insights'),
          const SizedBox(height: 12),
          AppGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppPill(label: _buildInsight(), color: AppColors.purple),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _InsightTile(
                        title: 'Savings goals',
                        value: '${_savingsGoals.length}',
                        caption: _savingsGoals.isEmpty
                            ? 'No goals yet'
                            : 'Active plans',
                        tint: AppColors.positive,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InsightTile(
                        title: 'Shopping lists',
                        value: '${_shoppingLists.length}',
                        caption: shoppingItems == 0
                            ? 'Awaiting items'
                            : '$shoppingItems items',
                        tint: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> item) {
    final source = (item['source'] ?? '').toString().toLowerCase();
    final isIncome =
        (item['transaction_type'] ?? 'expense').toString().toLowerCase() ==
        'income';
    final amount = ((item['amount'] ?? 0) as num).toDouble();

    IconData icon;
    Color bg;
    Color fg;
    switch (source) {
      case 'onchain':
        icon = Icons.currency_bitcoin_rounded;
        bg = AppColors.indigoBg.withValues(alpha: 0.45);
        fg = AppColors.accent;
        break;
      case 'bank':
        icon = Icons.account_balance_rounded;
        bg = AppColors.amberBg.withValues(alpha: 0.55);
        fg = AppColors.purple;
        break;
      case 'mpesa':
        icon = Icons.sms_rounded;
        bg = AppColors.greenBg.withValues(alpha: 0.28);
        fg = AppColors.positive;
        break;
      default:
        icon = Icons.payments_outlined;
        bg = AppColors.indigoBg.withValues(alpha: 0.35);
        fg = AppColors.lightText;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppGlassCard(
        radius: 24,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            AppIconBadge(icon: icon, background: bg, foreground: fg),
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
                  Text(
                    '${Formatters.formatDate(item['created_at']?.toString())} · ${source.isEmpty ? 'manual' : source}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${isIncome ? '+' : '-'}${Formatters.formatKes(amount)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isIncome ? AppColors.positive : AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildInsight() {
    final overspent = _budgetCategories.where((item) {
      final planned = ((item['planned'] ?? 0) as num).toDouble();
      final actual = ((item['actual'] ?? 0) as num).toDouble();
      return actual > planned && planned > 0;
    }).toList();

    if (overspent.isEmpty) {
      return 'You are tracking well across budgets this month.';
    }

    overspent.sort((a, b) {
      final aOver =
          ((a['actual'] ?? 0) as num).toDouble() -
          ((a['planned'] ?? 0) as num).toDouble();
      final bOver =
          ((b['actual'] ?? 0) as num).toDouble() -
          ((b['planned'] ?? 0) as num).toDouble();
      return bOver.compareTo(aOver);
    });

    final worst = overspent.first;
    final label = (worst['label'] ?? 'A category').toString();
    final overBy =
        (((worst['actual'] ?? 0) as num).toDouble() -
        ((worst['planned'] ?? 0) as num).toDouble());
    return '$label is over plan by ${Formatters.formatKes(overBy)}.';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('AiCoinTrack'),
        leadingWidth: 64,
        leading: Center(
          child: GestureDetector(
            onTap: _showProfileMenu,
            child: _Avatar(name: widget.userName),
          ),
        ),
        actions: [
          ValueListenableBuilder<int>(
            valueListenable: pendingCountNotifier,
            builder: (context, count, _) => Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PendingTransactionsPage(),
                      ),
                    );
                  },
                ),
                if (count > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        count > 9 ? '9+' : '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
            onPressed: () {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: SafeArea(
        top: false,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surface.withValues(alpha: isDark ? 0.96 : 0.98),
            border: Border(
              top: BorderSide(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.12),
              ),
            ),
          ),
          child: NavigationBar(
            selectedIndex: _currentNavIndex,
            onDestinationSelected: (value) =>
                setState(() => _currentNavIndex = value),
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            indicatorColor: AppColors.accentBg,
            height: 72,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.leaderboard_outlined),
                selectedIcon: Icon(Icons.leaderboard_rounded),
                label: 'Budget',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long_rounded),
                label: 'Activity',
              ),
              NavigationDestination(
                icon: Icon(Icons.shopping_bag_outlined),
                selectedIcon: Icon(Icons.shopping_bag_rounded),
                label: 'Shopping',
              ),
              NavigationDestination(
                icon: Icon(Icons.savings_outlined),
                selectedIcon: Icon(Icons.savings_rounded),
                label: 'Savings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.size = 40});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.accent, Color(0xFF6CF8BB)],
        ),
        borderRadius: BorderRadius.circular(size / 2),
      ),
      alignment: Alignment.center,
      child: Text(
        name.isEmpty ? 'A' : name[0].toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _LegendValue extends StatelessWidget {
  const _LegendValue({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 2),
              Text(value, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _BentoCard extends StatelessWidget {
  const _BentoCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.footer,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    return AppGlassCard(
      radius: 28,
      padding: const EdgeInsets.all(18),
      child: SizedBox(
        height: 164,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppIconBadge(icon: icon, background: iconBg, foreground: iconColor),
            const Spacer(),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            footer,
          ],
        ),
      ),
    );
  }
}

class _InsightTile extends StatelessWidget {
  const _InsightTile({
    required this.title,
    required this.value,
    required this.caption,
    required this.tint,
  });

  final String title;
  final String value;
  final String caption;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tint.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: tint),
          ),
          const SizedBox(height: 4),
          Text(caption, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
