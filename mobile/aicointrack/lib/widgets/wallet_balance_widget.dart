import 'package:flutter/material.dart';
import '../services/wallet_balance_service.dart';
import '../config/theme.dart';

/// Widget that displays real-time wallet balances from Base Sepolia
/// Demonstrates usage of WalletBalanceService
class WalletBalanceWidget extends StatefulWidget {
  final String walletAddress;
  final bool showRefreshButton;

  const WalletBalanceWidget({
    super.key,
    required this.walletAddress,
    this.showRefreshButton = true,
  });

  @override
  State<WalletBalanceWidget> createState() => _WalletBalanceWidgetState();
}

class _WalletBalanceWidgetState extends State<WalletBalanceWidget> {
  static const String _logTag = '[WalletBalanceWidget]';

  late final WalletBalanceService _balanceService;
  Map<String, dynamic>? _balances;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _balanceService = WalletBalanceService();
    _loadBalances();
  }

  Future<void> _loadBalances() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      debugPrint('$_logTag loading balances for ${widget.walletAddress}');
      final balances = await _balanceService.getWalletBalances(
        widget.walletAddress,
      );

      if (mounted) {
        setState(() {
          _balances = balances;
          _isLoading = false;
        });
        debugPrint('$_logTag balances loaded: $balances');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
        debugPrint('$_logTag error: $e');
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
        borderRadius: BorderRadius.circular(16),
        color: bgColor,
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and refresh button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Base Sepolia Wallet',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: mutedColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.walletAddress.length > 18
                        ? '${widget.walletAddress.substring(0, 8)}...${widget.walletAddress.substring(widget.walletAddress.length - 6)}'
                        : widget.walletAddress,
                    style: TextStyle(
                      fontSize: 12,
                      color: mutedColor,
                      fontFamily: 'Courier',
                    ),
                  ),
                ],
              ),
              if (widget.showRefreshButton)
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _isLoading ? null : _loadBalances,
                  tooltip: 'Refresh balances',
                )
            ],
          ),
          const SizedBox(height: 16),

          // Loading state
          if (_isLoading)
            Center(
              child: Column(
                children: [
                  const CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.accent),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Fetching balances...',
                    style: TextStyle(color: mutedColor, fontSize: 12),
                  ),
                ],
              ),
            ),

          // Error state
          if (_error != null && !_isLoading)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: AppColors.danger.withOpacity(0.1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Error fetching balances',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.danger,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _error!.length > 100
                        ? '${_error!.substring(0, 100)}...'
                        : _error!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.danger.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),

          // Balances display
          if (_balances != null && !_isLoading) ...[
            // ETH Balance
            _buildBalanceRow(
              label: 'ETH Balance',
              value: '${_balances!['eth_formatted']} ETH',
              rawValue: _balances!['eth'] as double,
              icon: '⟠',
              color: AppColors.warning,
              textColor: textColor,
              mutedColor: mutedColor,
            ),
            const SizedBox(height: 12),
            Divider(color: borderColor, height: 1),
            const SizedBox(height: 12),

            // USDC Balance
            _buildBalanceRow(
              label: 'USDC Balance',
              value: '${_balances!['usdc_formatted']} USDC',
              rawValue: _balances!['usdc'] as double,
              icon: '⊙',
              color: AppColors.accent,
              textColor: textColor,
              mutedColor: mutedColor,
            ),
            const SizedBox(height: 12),

            // Network info
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: isDark ? AppColors.darkBg : AppColors.lightBg2,
              ),
              child: Row(
                children: [
                  Text(
                    '🔗',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Base Sepolia (Chain ID: 84532)',
                    style: TextStyle(
                      fontSize: 11,
                      color: mutedColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBalanceRow({
    required String label,
    required String value,
    required double rawValue,
    required String icon,
    required Color color,
    required Color textColor,
    required Color mutedColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: mutedColor,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  icon,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 6),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    fontFamily: 'Courier',
                  ),
                ),
              ],
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: color.withOpacity(0.1),
          ),
          child: Text(
            rawValue.toStringAsFixed(6),
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontFamily: 'Courier',
            ),
          ),
        ),
      ],
    );
  }
}
