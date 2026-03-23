import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';
import '../services/pending_transactions_service.dart';
import 'budget_page.dart';
import 'pending_transactions_page.dart';
import 'transactions_page.dart';
import 'shopping_pages.dart';
import 'savings_closeout_pages.dart';
import '../services/auth_service.dart';
import 'login_page.dart';
import 'settings_page.dart';
import '../utils/formatters.dart';

class DashboardPage extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String? photoUrl;
  final Map<String, dynamic>? userData;

  const DashboardPage({
    Key? key,
    required this.userName,
    required this.userEmail,
    this.photoUrl,
    this.userData,
  }) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentNavIndex = 0;
  Map<String, dynamic> _summary = {};
  bool _summaryLoading = true;
  String? _summaryError;
  List<dynamic> _budgetCategories = [];
  List<dynamic> _recentTransactions = [];
  List<dynamic> _shoppingLists = [];
  List<dynamic> _savingsGoals = [];

  void _setNavIndex(int index) {
    if (!mounted) return;
    setState(() {
      _currentNavIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    if (mounted) {
      setState(() {
        _summaryLoading = true;
        _summaryError = null;
      });
    }

    try {
      final results = await Future.wait<dynamic>([
        ApiService.fetchDashboardSummaryFromApi(),
        ApiService.fetchWalletBalance(),
      ]);
      final summary = {
        ...(results[0] as Map<String, dynamic>),
        ...(results[1] as Map<String, dynamic>),
      };
      final detailResults = await Future.wait<dynamic>([
        ApiService.fetchCurrentBudget(),
        ApiService.fetchTransactions(limit: 3),
        ApiService.fetchShoppingListsFromApi(),
        ApiService.fetchSavingsGoalsFromApi(),
      ]);
      if (mounted) {
        setState(() {
          _summary = summary;
          _budgetCategories = detailResults[0] as List<dynamic>;
          _recentTransactions = detailResults[1] as List<dynamic>;
          _shoppingLists = detailResults[2] as List<dynamic>;
          _savingsGoals = detailResults[3] as List<dynamic>;
          _summaryLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _summaryError = e.toString().replaceFirst('Exception: ', '');
          _summaryLoading = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      try {
        await AuthService.signOut();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error signing out: $e')));
      }
    }
  }

  void _showProfileMenu() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.accent, AppColors.purple],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      widget.userName.isNotEmpty
                          ? widget.userName[0].toUpperCase()
                          : 'J',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.userName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        widget.userEmail,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkMuted
                              : AppColors.lightMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ListTile(
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
              leading: const Icon(Icons.palette_outlined),
              title: const Text('Theme'),
              subtitle: Text(isDark ? 'Dark' : 'Light'),
              trailing: Switch(
                value: isDark,
                onChanged: (value) {
                  Provider.of<ThemeProvider>(
                    context,
                    listen: false,
                  ).toggleTheme();
                  Navigator.pop(context);
                },
                activeColor: AppColors.accent,
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.danger),
              title: const Text(
                'Sign Out',
                style: TextStyle(color: AppColors.danger),
              ),
              onTap: _handleLogout,
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

    Widget body;
    switch (_currentNavIndex) {
      case 1:
        body = const BudgetPage();
        break;
      case 2:
        body = const TransactionsPage();
        break;
      case 3:
        body = const ShoppingListsPage();
        break;
      case 4:
        body = const SavingsPage();
        break;
      default:
        body = _buildDashboardBody(
          bgColor: bgColor,
          cardColor: cardColor,
          borderColor: borderColor,
          textColor: textColor,
          mutedColor: mutedColor,
        );
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        leading: GestureDetector(
          onTap: _showProfileMenu,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.accent, AppColors.purple],
                ),
              ),
              child: Center(
                child: Text(
                  widget.userName.isNotEmpty
                      ? widget.userName[0].toUpperCase()
                      : 'J',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ),
        ),
        title: const Text('AiCoinTrack'),
        elevation: 0,
        actions: [
          // Notifications icon with badge
          ValueListenableBuilder<int>(
            valueListenable: pendingCountNotifier,
            builder: (context, count, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PendingTransactionsPage(),
                      ),
                    ),
                  ),
                  if (count > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          count > 9 ? '9+' : '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          // Search icon
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search coming soon')),
              );
            },
          ),
          // Theme toggle icon
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
            onPressed: () {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            },
          ),
        ],
      ),
      body: body,
      bottomNavigationBar: _buildBottomNavBar(
        cardColor,
        borderColor,
        textColor,
        mutedColor,
      ),
    );
  }

  Widget _buildPill(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.25)),
        color: color.withOpacity(0.1),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    Color textColor,
    Color mutedColor,
    Color cardColor,
    Color borderColor, {
    Color? lightCardBg,
    Color? lightCardText,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? cardColor : (lightCardBg ?? cardColor);
    final textCol = isDark ? textColor : (lightCardText ?? textColor);
    final mutedCol = isDark ? mutedColor : (lightCardText ?? mutedColor);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: bgColor,
        border: isDark
            ? Border(
                left: BorderSide(
                  color: AppColors.accent.withOpacity(0.4),
                  width: 3,
                ),
              )
            : Border.all(color: Colors.transparent),
      ),
      padding: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: mutedCol)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textCol,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonBox({
    double height = 18,
    double? width,
    double radius = 10,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
            .withOpacity(0.8),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  double _budgetTotalPlanned() {
    return _budgetCategories.fold<double>(0.0, (sum, item) {
      final category = Map<String, dynamic>.from(item as Map);
      return sum + ((category['planned'] ?? 0) as num).toDouble();
    });
  }

  double _budgetTotalActual() {
    return _budgetCategories.fold<double>(0.0, (sum, item) {
      final category = Map<String, dynamic>.from(item as Map);
      return sum + ((category['actual'] ?? 0) as num).toDouble();
    });
  }

  double _totalSaved() {
    return _savingsGoals.fold<double>(0.0, (sum, item) {
      final goal = Map<String, dynamic>.from(item as Map);
      return sum + ((goal['saved'] ?? 0) as num).toDouble();
    });
  }

  String _transactionEmoji(String source) {
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

  String _transactionAmount(Map<String, dynamic> tx) {
    final amount = ((tx['amount'] ?? 0) as num).toDouble();
    final type = (tx['transaction_type'] ?? 'expense').toString().toLowerCase();
    return '${type == 'income' ? '+' : '-'}${Formatters.formatKes(amount)}';
  }

  Color _transactionColor(Map<String, dynamic> tx) {
    final type = (tx['transaction_type'] ?? 'expense').toString().toLowerCase();
    return type == 'income' ? AppColors.positive : AppColors.danger;
  }

  String _buildInsight(List categories) {
    final sorted =
        categories
            .where(
              (c) => ((c['actual'] ?? 0) as num) > ((c['planned'] ?? 0) as num),
            )
            .toList()
          ..sort((a, b) {
            final aDiff =
                (((a['actual'] ?? 0) as num) - ((a['planned'] ?? 0) as num))
                    .toDouble();
            final bDiff =
                (((b['actual'] ?? 0) as num) - ((b['planned'] ?? 0) as num))
                    .toDouble();
            return bDiff.compareTo(aDiff);
          });

    if (sorted.isEmpty) {
      return "You're on track this month! Great work staying within budget.";
    }

    final worst = Map<String, dynamic>.from(sorted.first as Map);
    final overBy =
        ((((worst['actual'] ?? 0) as num) - ((worst['planned'] ?? 0) as num))
            .toDouble());
    return "You're on track this month! ${worst['label']} spending is over budget by ${Formatters.formatKes(overBy)}. Consider reducing spending in this category.";
  }

  List<Widget> _buildRecentTransactions(
    Color textColor,
    Color mutedColor,
    Color borderColor,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_summaryLoading) {
      return [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isDark ? AppColors.darkCard : AppColors.lightCardWhite,
            border: Border.all(
              color: isDark ? borderColor : Colors.transparent,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: List.generate(
              3,
              (_) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    _buildSkeletonBox(height: 36, width: 36),
                    const SizedBox(width: 10),
                    Expanded(child: _buildSkeletonBox(height: 14)),
                    const SizedBox(width: 10),
                    _buildSkeletonBox(height: 14, width: 60),
                  ],
                ),
              ),
            ),
          ),
        ),
      ];
    }

    final transactionWidgets = _recentTransactions.map((raw) {
      final t = Map<String, dynamic>.from(raw as Map);
      final source = (t['source'] ?? '').toString();
      final isAutoLogged = source != 'onchain' && source != 'cash';
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor),
                        color: isDark
                            ? AppColors.darkCard
                            : AppColors.lightCardBlack,
                      ),
                      child: Center(
                        child: Text(
                          _transactionEmoji(source),
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (t['description'] ?? 'Transaction').toString(),
                            style: TextStyle(fontSize: 13, color: textColor),
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                Formatters.formatDate(
                                  t['created_at']?.toString(),
                                ),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: mutedColor,
                                ),
                              ),
                              if (isAutoLogged)
                                Padding(
                                  padding: EdgeInsets.only(left: 6),
                                  child: _buildPillSmall('Auto-logged'),
                                ),
                              if (source == 'onchain')
                                Padding(
                                  padding: EdgeInsets.only(left: 6),
                                  child: _buildPillSmall(
                                    'Onchain',
                                    AppColors.accent,
                                  ),
                                ),
                              if (source == 'cash')
                                Padding(
                                  padding: EdgeInsets.only(left: 6),
                                  child: _buildPillSmall('Manual'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _transactionAmount(t),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _transactionColor(t),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Divider(height: 1, color: borderColor),
          SizedBox(height: 10),
        ],
      );
    }).toList();

    // Wrap transactions in a card container
    return [
      Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isDark ? AppColors.darkCard : AppColors.lightCardWhite,
          border: Border.all(color: isDark ? borderColor : Colors.transparent),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(children: transactionWidgets),
      ),
    ];
  }

  Widget _buildPillSmall(String text, [Color? color]) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColorSmall = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: bgColor,
        border: Border.all(color: borderColor),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 9, color: color ?? textColorSmall),
      ),
    );
  }

  Widget _buildBottomNavBar(
    Color cardColor,
    Color borderColor,
    Color textColor,
    Color mutedColor,
  ) {
    final navItems = [
      {'icon': '🏠', 'label': 'Home', 'id': 0},
      {'icon': '📊', 'label': 'Budget', 'id': 1},
      {'icon': '💸', 'label': 'Transactions', 'id': 2},
      {'icon': '🛒', 'label': 'Shopping', 'id': 3},
      {'icon': '🎯', 'label': 'Savings', 'id': 4},
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: borderColor)),
        color: cardColor,
      ),
      padding: EdgeInsets.only(bottom: 20, top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: navItems
            .map(
              (item) => GestureDetector(
                onTap: () => _setNavIndex(item['id'] as int),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item['icon'].toString(),
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item['label'].toString(),
                      style: TextStyle(
                        fontSize: 9,
                        color: _currentNavIndex == item['id']
                            ? AppColors.accent
                            : mutedColor,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildDashboardBody({
    required Color bgColor,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color mutedColor,
  }) {
    if (_summaryError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 48),
            const SizedBox(height: 12),
            Text(
              _summaryError!,
              style: TextStyle(color: mutedColor, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDashboardData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final totalBudget = _budgetTotalPlanned();
    final totalActual = _budgetTotalActual();
    final freeToSpend =
        ((_summary['freeToSpend'] ?? _summary['balance'] ?? 0) as num)
            .toDouble();
    final variance = ((_summary['variance'] ?? 0) as num).toDouble();
    final monthProgress = ((_summary['monthProgress'] ?? 0) as num).toDouble();
    final totalSaved = _totalSaved();
    final insight = _buildInsight(
      _budgetCategories.cast<Map<String, dynamic>>(),
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heroTextColor = isDark ? AppColors.darkText : Colors.white;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good morning,',
                        style: TextStyle(color: mutedColor, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.userName} 👋',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            AppColors.accent.withOpacity(0.15),
                            AppColors.purple.withOpacity(0.08),
                          ]
                        : [AppColors.accent, AppColors.accentDim],
                  ),
                  border: Border.all(
                    color: isDark
                        ? AppColors.purple.withOpacity(0.27)
                        : Colors.transparent,
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FREE TO SPEND',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? heroTextColor.withOpacity(0.85)
                            : heroTextColor.withOpacity(0.85),
                      ),
                    ),
                    const SizedBox(height: 4),
                    _summaryLoading
                        ? _buildSkeletonBox(height: 36, width: 180, radius: 12)
                        : Text(
                            Formatters.formatKes(freeToSpend),
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              color: heroTextColor,
                            ),
                          ),
                    const SizedBox(height: 8),
                    _summaryLoading
                        ? _buildSkeletonBox(height: 28, width: 180, radius: 999)
                        : _buildPill(
                            '✓ ${variance >= 0 ? '+' : '-'}${Formatters.formatKes(variance.abs())} vs last month',
                            AppColors.lightCardWhite,
                          ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Month progress',
                          style: TextStyle(fontSize: 12, color: heroTextColor),
                        ),
                        Text(
                          'March 8 / 31',
                          style: TextStyle(fontSize: 12, color: heroTextColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: _summaryLoading ? 0.0 : monthProgress,
                        minHeight: 4,
                        backgroundColor: borderColor,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.2,
                children: [
                  _summaryLoading
                      ? _buildSkeletonBox(height: 120, radius: 16)
                      : _buildStatCard(
                          'Total Budget',
                          Formatters.formatKes(totalBudget),
                          textColor,
                          mutedColor,
                          cardColor,
                          borderColor,
                          lightCardBg: AppColors.lightCardBlue,
                          lightCardText: AppColors.cardBlueText,
                        ),
                  _summaryLoading
                      ? _buildSkeletonBox(height: 120, radius: 16)
                      : _buildStatCard(
                          'Spent So Far',
                          Formatters.formatKes(totalActual),
                          textColor,
                          mutedColor,
                          cardColor,
                          borderColor,
                          lightCardBg: AppColors.lightCardGold,
                          lightCardText: AppColors.cardGoldText,
                        ),
                  _summaryLoading
                      ? _buildSkeletonBox(height: 120, radius: 16)
                      : _buildStatCard(
                          'Saved',
                          Formatters.formatKes(totalSaved),
                          AppColors.accent,
                          mutedColor,
                          cardColor,
                          borderColor,
                          lightCardBg: AppColors.lightCardGreen,
                          lightCardText: AppColors.cardGreenText,
                        ),
                  _summaryLoading
                      ? _buildSkeletonBox(height: 120, radius: 16)
                      : _buildStatCard(
                          'Shopping',
                          '${_shoppingLists.length} lists',
                          textColor,
                          mutedColor,
                          cardColor,
                          borderColor,
                          lightCardBg: AppColors.lightCardPurple,
                          lightCardText: AppColors.cardPurpleText,
                        ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: bgColor == AppColors.darkBg
                        ? AppColors.purple.withOpacity(0.25)
                        : AppColors.purple.withOpacity(0.15),
                  ),
                  color: bgColor == AppColors.darkBg
                      ? AppColors.purple.withOpacity(0.08)
                      : AppColors.lightCardPurple,
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🤖 AI INSIGHT',
                      style: TextStyle(
                        fontSize: 11,
                        color: bgColor == AppColors.darkBg
                            ? AppColors.purple
                            : AppColors.cardPurpleText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _summaryLoading
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSkeletonBox(height: 14),
                              const SizedBox(height: 6),
                              _buildSkeletonBox(height: 14, width: 220),
                            ],
                          )
                        : Text(
                            insight,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: textColor,
                            ),
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Recent Transactions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 10),
              if (!_summaryLoading && _recentTransactions.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: bgColor == AppColors.darkBg
                        ? AppColors.darkCard
                        : AppColors.lightCardWhite,
                    border: Border.all(
                      color: bgColor == AppColors.darkBg
                          ? borderColor
                          : Colors.transparent,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text('💸', style: TextStyle(fontSize: 32)),
                      const SizedBox(height: 12),
                      Text(
                        'No transactions yet',
                        style: TextStyle(color: mutedColor, fontSize: 14),
                      ),
                    ],
                  ),
                )
              else
                ..._buildRecentTransactions(textColor, mutedColor, borderColor),
            ],
          ),
        ),
      ),
    );
  }
}
