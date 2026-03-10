import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/theme_provider.dart';
import 'budget_page.dart';
import 'transactions_page.dart';
import 'shopping_pages.dart';
import 'savings_closeout_pages.dart';
import 'settings_page.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

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

  Map<String, dynamic> _dashboardData = {};
  List<TransactionExample> _recentTransactions = [];
  Map<String, dynamic> _walletData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.fetchDashboardSummary(),
        ApiService.fetchTransactions(limit: 5),
        ApiService.getWalletBalance().catchError((_) => <String, dynamic>{}),
      ]);
      if (mounted) {
        setState(() {
          _dashboardData = results[0] as Map<String, dynamic>;
          _recentTransactions = results[1] as List<TransactionExample>;
          _walletData = results[2] as Map<String, dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Dashboard load error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (shouldLogout == true && mounted) {
      try {
        await AuthService.signOut();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error signing out: $e')));
        }
      }
    }
  }

  void _showProfileMenu() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
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
                      colors: [AppColors.accentGreen, AppColors.purple],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      widget.userName.isNotEmpty
                          ? widget.userName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
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
                Navigator.pop(ctx);
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
                onChanged: (_) {
                  Provider.of<ThemeProvider>(
                    context,
                    listen: false,
                  ).toggleTheme();
                  Navigator.pop(ctx);
                },
                activeThumbColor: AppColors.accentGreen,
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.danger),
              title: const Text(
                'Sign Out',
                style: TextStyle(color: AppColors.danger),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _handleLogout();
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

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
      case 2:
        body = const TransactionsPage();
      case 3:
        body = const ShoppingListsPage();
      case 4:
        body = const SavingsPage();
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
                  colors: [AppColors.accentGreen, AppColors.purple],
                ),
              ),
              child: Center(
                child: Text(
                  widget.userName.isNotEmpty
                      ? widget.userName[0].toUpperCase()
                      : 'U',
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
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
            onPressed: () => Provider.of<ThemeProvider>(
              context,
              listen: false,
            ).toggleTheme(),
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

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _greetingText() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning,';
    if (h < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  static String _fmt(double v) {
    if (v >= 1000) {
      final s = v.toStringAsFixed(0);
      final buf = StringBuffer();
      int c = 0;
      for (int i = s.length - 1; i >= 0; i--) {
        buf.write(s[i]);
        c++;
        if (c % 3 == 0 && i != 0) buf.write(',');
      }
      return buf.toString().split('').reversed.join();
    }
    return v.toStringAsFixed(0);
  }

  static String _monthName(int m) {
    const mn = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return mn[m];
  }

  Widget _pillSmall(String text, [Color? c]) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          color: c ?? (isDark ? AppColors.darkMuted : AppColors.lightMuted),
        ),
      ),
    );
  }

  Widget _cardAction(
    bool isDark,
    String icon,
    String label,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkText : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom Nav ─────────────────────────────────────────────────────────────

  Widget _buildBottomNavBar(Color cc, Color bc, Color tc, Color mc) {
    final items = [
      {'icon': '🏠', 'label': 'Home', 'id': 0},
      {'icon': '📊', 'label': 'Budget', 'id': 1},
      {'icon': '💸', 'label': 'Transactions', 'id': 2},
      {'icon': '🛒', 'label': 'Shopping', 'id': 3},
      {'icon': '🎯', 'label': 'Savings', 'id': 4},
    ];
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: bc)),
        color: cc,
      ),
      padding: const EdgeInsets.only(bottom: 20, top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((i) {
          return GestureDetector(
            onTap: () {
              final idx = i['id'] as int;
              if (idx == 0 && _currentNavIndex == 0) _loadDashboardData();
              setState(() => _currentNavIndex = idx);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  i['icon'].toString(),
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 3),
                Text(
                  i['label'].toString(),
                  style: TextStyle(
                    fontSize: 9,
                    color: _currentNavIndex == i['id']
                        ? AppColors.accentGreen
                        : mc,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Dashboard Body ─────────────────────────────────────────────────────────

  Widget _buildDashboardBody({
    required Color bgColor,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color mutedColor,
  }) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final d = _dashboardData;
    final fts = (d['free_to_spend'] ?? d['freeToSpend'] ?? 0).toDouble();
    final variance = (d['variance'] ?? 0).toDouble();
    final mp = (d['month_progress'] ?? d['monthProgress'] ?? 0).toDouble();
    final ai = (d['ai_insight'] ?? d['aiInsight']) as String?;

    final walletKes = (_walletData['kes'] ?? 0).toDouble();
    final walletUsdc = (_walletData['usdc'] ?? 0).toDouble();

    final now = DateTime.now();
    final dim = DateTime(now.year, now.month + 1, 0).day;
    final mn = _monthName(now.month);

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      color: AppColors.accentGreen,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 20, bottom: 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _greetingText(),
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
            ),
            const SizedBox(height: 20),

            // Wallet Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          AppColors.purple.withValues(alpha: 0.15),
                          AppColors.accentGreen.withValues(alpha: 0.1),
                        ]
                      : [AppColors.accentGreen, const Color(0xFF00C48C)],
                ),
                border: Border.all(
                  color: isDark
                      ? AppColors.purple.withValues(alpha: 0.3)
                      : Colors.transparent,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Wallet',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? mutedColor
                          : Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Ksh ${_fmt(walletKes)}',
                    style: TextStyle(
                      fontFamily: 'Syne',
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: isDark ? textColor : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${walletUsdc.toStringAsFixed(2)} USDC on Base',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? mutedColor
                          : Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Free to spend
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'FREE TO SPEND',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? mutedColor
                                  : Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ksh ${_fmt(fts)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark ? textColor : Colors.white,
                            ),
                          ),
                        ],
                      ),
                      _pillSmall(
                        variance >= 0
                            ? '+Ksh ${_fmt(variance)}'
                            : '-Ksh ${_fmt(variance.abs())}',
                        isDark
                            ? AppColors.accentGreen
                            : AppColors.lightCardWhite,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Month progress
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Month progress',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? mutedColor
                              : Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                      Text(
                        '$mn ${now.day} / $dim',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? mutedColor
                              : Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: mp > 0 ? mp : now.day / dim,
                      minHeight: 4,
                      backgroundColor: isDark
                          ? borderColor
                          : Colors.white.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation(
                        isDark ? AppColors.accentGreen : Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _cardAction(isDark, '↑', 'Send', () {}),
                      _cardAction(isDark, '↓', 'Deposit', () {}),
                      _cardAction(isDark, '💰', 'Save', () {}),
                      _cardAction(isDark, '🏦', 'Withdraw', () {}),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // AI Insight
            if (ai != null && ai.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? AppColors.purple.withValues(alpha: 0.3)
                        : AppColors.purple.withValues(alpha: 0.25),
                  ),
                  color: isDark
                      ? AppColors.purple.withValues(alpha: 0.15)
                      : AppColors.purple.withValues(alpha: 0.05),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Insight',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ai,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: isDark
                                  ? mutedColor
                                  : AppColors.cardPurpleText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Recent Transactions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildRecentTx(textColor, mutedColor, borderColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTx(Color tc, Color mc, Color bc) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_recentTransactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        width: double.infinity,
        child: Center(
          child: Text(
            'No transactions yet',
            style: TextStyle(color: mc, fontSize: 14),
          ),
        ),
      );
    }

    return Column(
      children: _recentTransactions.map((t) {
        final amtString = t.amount.replaceAll('+', '').replaceAll('-', '');
        final isPositive = t.amount.startsWith('+');

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isDark ? AppColors.darkCard : AppColors.lightCardWhite,
            border: Border.all(color: bc),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.description,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: tc,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _pillSmall(
                          t.source == 'chain'
                              ? 'Onchain'
                              : (t.source == 'auto' ? 'Auto-logged' : 'Manual'),
                          t.source == 'chain' ? AppColors.accentGreen : null,
                        ),
                        const SizedBox(width: 8),
                        Text(t.date, style: TextStyle(fontSize: 11, color: mc)),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                '${isPositive ? '+' : '-'}$amtString',
                style: TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isPositive ? AppColors.accentGreen : AppColors.danger,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
