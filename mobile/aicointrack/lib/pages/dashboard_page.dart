import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/theme_provider.dart';
import 'budget_page.dart';
import 'transactions_page.dart';
import 'shopping_pages.dart';
import 'savings_closeout_pages.dart';
import '../services/auth_service.dart';
import 'login_page.dart';

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
            style: TextButton.styleFrom(
              foregroundColor: AppColors.danger,
            ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: $e')),
        );
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
                      colors: [AppColors.accentGreen, AppColors.purple],
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
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Settings screen coming soon (placeholder only).'),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: const Text('Theme'),
              subtitle: Text(
                isDark ? 'Dark' : 'Light',
              ),
              trailing: Switch(
                value: isDark,
                onChanged: (value) {
                  Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
                  Navigator.pop(context);
                },
                activeColor: AppColors.accentGreen,
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
                  colors: [AppColors.accentGreen, AppColors.purple],
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
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  // TODO: Implement notifications page
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notifications coming soon'),
                    ),
                  );
                },
              ),
              // Notification badge
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: const Text(
                    '3',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          // Search icon
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Search coming soon'),
                ),
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
      bottomNavigationBar: _buildBottomNavBar(cardColor, borderColor, textColor, mutedColor),
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
    Color borderColor,
    {Color? lightCardBg, Color? lightCardText}
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? cardColor : (lightCardBg ?? cardColor);
    final textCol = isDark ? textColor : (lightCardText ?? textColor);
    final mutedCol = isDark ? mutedColor : (lightCardText ?? mutedColor);
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: bgColor,
        border: Border.all(color: isDark ? borderColor : Colors.transparent),
      ),
      padding: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: mutedCol,
            ),
          ),
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

  List<Widget> _buildRecentTransactions(
    Color textColor,
    Color mutedColor,
    Color borderColor,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final transactions = [
      {
        'desc': 'Uber – CBD to Westlands',
        'cat': '🚗 Transport',
        'amt': '-Ksh 350',
        'source': 'auto'
      },
      {
        'desc': 'Quickmart Supermarket',
        'cat': '🛒 Food',
        'amt': '-Ksh 1,840',
        'source': 'auto'
      },
      {
        'desc': 'MiniSend – Received',
        'cat': '💸 Income',
        'amt': '+Ksh 5,000',
        'source': 'chain'
      },
    ];

    final transactionWidgets = transactions
        .map(
          (t) => Column(
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
                              t['cat'].toString().split(' ')[0],
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
                                t['desc'].toString(),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: textColor,
                                ),
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    t['cat'].toString().split(' ').skip(1).join(' '),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: mutedColor,
                                    ),
                                  ),
                                  if (t['source'] == 'auto')
                                    Padding(
                                      padding: EdgeInsets.only(left: 6),
                                      child: _buildPillSmall('Auto-logged'),
                                    ),
                                  if (t['source'] == 'chain')
                                    Padding(
                                      padding: EdgeInsets.only(left: 6),
                                      child: _buildPillSmall('Onchain',
                                          AppColors.accentGreen),
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
                    t['amt'].toString(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: t['amt'].toString().startsWith('+')
                          ? AppColors.accentGreen
                          : AppColors.danger,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Divider(height: 1, color: borderColor),
              SizedBox(height: 10),
            ],
          ),
        )
        .toList();

    // Wrap transactions in a card container
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
          children: transactionWidgets,
        ),
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
        style: TextStyle(
          fontSize: 9,
          color: color ?? textColorSmall,
        ),
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
        border: Border(
          top: BorderSide(color: borderColor),
        ),
        color: cardColor,
      ),
      padding: EdgeInsets.only(bottom: 20, top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: navItems
            .map(
              (item) => GestureDetector(
                onTap: () {
                  setState(() {
                    _currentNavIndex = item['id'] as int;
                  });
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item['icon'].toString(),
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 3),
                    Text(
                      item['label'].toString(),
                      style: TextStyle(
                        fontSize: 9,
                        color: _currentNavIndex == item['id']
                            ? AppColors.accentGreen
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
                        style: TextStyle(
                          color: mutedColor,
                          fontSize: 12,
                        ),
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
                    colors: bgColor == AppColors.darkBg
                        ? [
                            AppColors.purple.withOpacity(0.13),
                            AppColors.accentGreen.withOpacity(0.07),
                          ]
                        : [
                            AppColors.accentGreen,
                            AppColors.purple,
                          ],
                  ),
                  border: Border.all(
                    color: bgColor == AppColors.darkBg
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
                        color: bgColor == AppColors.darkBg
                            ? mutedColor
                            : Colors.white.withOpacity(0.85),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ksh 24,500',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildPill(
                      '✓ +Ksh 2,300 vs last month',
                      AppColors.lightCardWhite,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Month progress',
                          style:
                              TextStyle(fontSize: 12, color: mutedColor),
                        ),
                        Text(
                          'March 8 / 31',
                          style:
                              TextStyle(fontSize: 12, color: mutedColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: 0.26,
                        minHeight: 4,
                        backgroundColor: borderColor,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(
                          AppColors.accentGreen,
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
                  _buildStatCard(
                    'Total Budget',
                    'Ksh 85,000',
                    textColor,
                    mutedColor,
                    cardColor,
                    borderColor,
                    lightCardBg: AppColors.lightCardBlue,
                    lightCardText: AppColors.cardBlueText,
                  ),
                  _buildStatCard(
                    'Spent So Far',
                    'Ksh 60,500',
                    textColor,
                    mutedColor,
                    cardColor,
                    borderColor,
                    lightCardBg: AppColors.lightCardGold,
                    lightCardText: AppColors.cardGoldText,
                  ),
                  _buildStatCard(
                    'Saved',
                    'Ksh 17,000',
                    AppColors.accentGreen,
                    mutedColor,
                    cardColor,
                    borderColor,
                    lightCardBg: AppColors.lightCardGreen,
                    lightCardText: AppColors.cardGreenText,
                  ),
                  _buildStatCard(
                    'Shopping',
                    '3 lists',
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
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: textColor,
                        ),
                        children: const [
                          TextSpan(
                            text:
                                "You're on track this month! Food spending is ",
                          ),
                          TextSpan(
                            text: '18% over budget',
                            style: TextStyle(color: AppColors.warning),
                          ),
                          TextSpan(
                            text:
                                '. Reduce dining out by Ksh 800 to stay in the green.',
                          ),
                        ],
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
              ..._buildRecentTransactions(
                textColor,
                mutedColor,
                borderColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
