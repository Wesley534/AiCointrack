import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/api_service.dart';

/// Bottom sheet for manually adding a transaction.
/// Used from [TransactionsPage] and optionally from the Dashboard.
class AddTransactionSheet extends StatefulWidget {
  final VoidCallback onSuccess;

  const AddTransactionSheet({super.key, required this.onSuccess});

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  String _type = 'expense';
  String _source = 'cash';
  String _category = 'General';

  bool _isSubmitting = false;
  String? _error;

  static const _categories = [
    'General',
    'Food',
    'Transport',
    'Entertainment',
    'Shopping',
    'Health',
    'Savings',
    'Income',
  ];

  static const _sources = ['cash', 'mpesa', 'bank'];

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final desc = _descCtrl.text.trim();
    if (desc.isEmpty) {
      if (mounted) {
        setState(() {
          _error = 'Description is required';
        });
      }
      return;
    }
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      if (mounted) {
        setState(() {
          _error = 'Enter a valid positive amount';
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isSubmitting = true;
        _error = null;
      });
    }

    try {
      await ApiService.recordOffchainTransaction(
        description: desc,
        amount: amount,
        source: _source,
        transactionType: _type,
        category: _category,
      );
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSuccess();
      }
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    return Container(
      color: bgColor,
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add Transaction',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          // Description
          TextField(
            controller: _descCtrl,
            style: TextStyle(color: textColor),
            decoration: _inputDec('Description', mutedColor, borderColor),
          ),
          const SizedBox(height: 12),
          // Amount
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: textColor),
            decoration: _inputDec('Amount (Ksh)', mutedColor, borderColor),
          ),
          const SizedBox(height: 12),
          // Type toggle
          Row(
            children: [
              Text('Type:', style: TextStyle(color: mutedColor, fontSize: 13)),
              const SizedBox(width: 10),
              _TypeBtn(
                label: 'Expense',
                selected: _type == 'expense',
                color: AppColors.danger,
                onTap: () => setState(() => _type = 'expense'),
              ),
              const SizedBox(width: 8),
              _TypeBtn(
                label: 'Income',
                selected: _type == 'income',
                color: AppColors.accentGreen,
                onTap: () => setState(() => _type = 'income'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Source
          DropdownButtonFormField<String>(
            value: _source,
            dropdownColor: bgColor,
            style: TextStyle(color: textColor),
            decoration: _inputDec('Source', mutedColor, borderColor),
            items: _sources
                .map(
                  (s) =>
                      DropdownMenuItem(value: s, child: Text(s.toUpperCase())),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _source = v);
            },
          ),
          const SizedBox(height: 12),
          // Category
          DropdownButtonFormField<String>(
            value: _category,
            dropdownColor: bgColor,
            style: TextStyle(color: textColor),
            decoration: _inputDec('Category', mutedColor, borderColor),
            items: _categories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _category = v);
            },
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(color: AppColors.danger, fontSize: 12),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentGreen,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Text('Add Transaction'),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDec(String label, Color mutedColor, Color borderColor) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: mutedColor),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.accentGreen),
      ),
    );
  }
}

class _TypeBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TypeBtn({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: selected ? color.withOpacity(0.15) : Colors.transparent,
          border: Border.all(
            color: selected ? color : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: selected ? color : Colors.grey,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
