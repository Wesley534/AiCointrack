import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/api_service.dart';

/// Shopping lists overview page.
class ShoppingListsPage extends StatefulWidget {
  const ShoppingListsPage({super.key});

  @override
  State<ShoppingListsPage> createState() => _ShoppingListsPageState();
}

class _ShoppingListsPageState extends State<ShoppingListsPage> {
  late Future<List<ShoppingListExample>> _listsFuture;

  @override
  void initState() {
    super.initState();
    _listsFuture = ApiService.fetchShoppingLists();
  }

  void _refresh() {
    setState(() {
      _listsFuture = ApiService.fetchShoppingLists();
    });
  }

  void _showAddListModal(BuildContext context) {
    final nameController = TextEditingController();
    final budgetController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkBg
          : AppColors.lightBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'New Shopping List',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkText
                      : AppColors.lightText,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'List Name (e.g. Weekly Groceries)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: budgetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Budget (KES)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentGreen,
                    foregroundColor: AppColors.darkBg,
                  ),
                  onPressed: () async {
                    final budget = double.tryParse(budgetController.text);
                    final name = nameController.text.trim();
                    if (budget == null || name.isEmpty) return;

                    Navigator.pop(ctx);
                    try {
                      await ApiService.createShoppingList(
                        name: name,
                        budget: budget,
                      );
                      _refresh();
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
                  child: const Text('Create List'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
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

    return Container(
      color: bgColor,
      child: FutureBuilder<List<ShoppingListExample>>(
        future: _listsFuture,
        builder: (context, snapshot) {
          final lists = snapshot.data ?? [];
          final isLoading = snapshot.connectionState == ConnectionState.waiting;

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
                    OutlinedButton(
                      onPressed: () => _showAddListModal(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accentGreen,
                        side: BorderSide(color: borderColor),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        '+ New List',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (lists.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Center(
                      child: Text(
                        'No shopping lists yet.',
                        style: TextStyle(color: mutedColor),
                      ),
                    ),
                  )
                else
                  Column(
                    children: lists.map((l) {
                      final pct = l.budget > 0
                          ? (l.total / l.budget).clamp(0, 1)
                          : 0;
                      Color barColor;
                      Color border;
                      switch (l.status) {
                        case 'red':
                          barColor = AppColors.danger;
                          border = AppColors.danger.withOpacity(0.3);
                          break;
                        case 'yellow':
                          barColor = AppColors.warning;
                          border = AppColors.warning.withOpacity(0.3);
                          break;
                        default:
                          barColor = AppColors.accentGreen;
                          border = borderColor;
                      }
                      return GestureDetector(
                        onTap: () {
                          if (l.id != null) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ShoppingDetailPage(listId: l.id!, listName: l.name),
                              ),
                            );
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    l.name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: textColor,
                                    ),
                                  ),
                                  _StatusPill(list: l),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(99),
                                child: LinearProgressIndicator(
                                  value: pct.toDouble(),
                                  minHeight: 6,
                                  backgroundColor: borderColor,
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
                                    'Est. Ksh ${l.total.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: mutedColor,
                                    ),
                                  ),
                                  Text(
                                    'Budget: Ksh ${l.budget.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: mutedColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Detail page for a single shopping list.
class ShoppingDetailPage extends StatefulWidget {
  final int listId;
  final String listName;

  const ShoppingDetailPage({super.key, required this.listId, required this.listName});

  @override
  State<ShoppingDetailPage> createState() => _ShoppingDetailPageState();
}

class _ShoppingDetailPageState extends State<ShoppingDetailPage> {
  late Future<ShoppingDetailExample> _detailFuture;

  @override
  void initState() {
    super.initState();
    _detailFuture = ApiService.fetchShoppingListById(widget.listId);
  }

  void _refresh() {
    setState(() {
      _detailFuture = ApiService.fetchShoppingListById(widget.listId);
    });
  }

  void _showAddItemModal(BuildContext context) {
    final nameController = TextEditingController();
    final qtyController = TextEditingController(text: '1');
    final priceController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkBg
          : AppColors.lightBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20, right: 20, top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Item',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkText : AppColors.lightText,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Item Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: qtyController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Qty',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Price (KES)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentGreen,
                    foregroundColor: AppColors.darkBg,
                  ),
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final qty = int.tryParse(qtyController.text) ?? 1;
                    final price = double.tryParse(priceController.text);
                    if (name.isEmpty || price == null) return;

                    Navigator.pop(ctx);
                    try {
                      await ApiService.addShoppingItem(
                        widget.listId,
                        name: name,
                        qty: qty,
                        price: price,
                      );
                      _refresh();
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Add Item'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
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

    return Scaffold(
      backgroundColor: bgColor,
      body: FutureBuilder<ShoppingDetailExample>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading list', style: TextStyle(color: mutedColor)),
            );
          }
          final detail = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        color: mutedColor,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          detail.title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        color: AppColors.accentGreen,
                        onPressed: () => _showAddItemModal(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TOTAL ESTIMATED',
                              style: TextStyle(fontSize: 11, color: mutedColor),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Ksh ${detail.total.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'BUDGET REMAINING',
                              style: TextStyle(fontSize: 11, color: mutedColor),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Ksh ${detail.remaining.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.accentGreen,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (detail.items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          'No items yet. Tap + to add one.',
                          style: TextStyle(color: mutedColor),
                        ),
                      ),
                    )
                  else
                    ...detail.items.map(
                      (item) => Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: cardColor,
                                      border: Border.all(color: borderColor),
                                    ),
                                    child: const Center(child: Text('☐')),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: TextStyle(fontSize: 13, color: textColor),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Qty: ${item.qty}',
                                        style: TextStyle(fontSize: 11, color: mutedColor),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Text(
                                'Ksh ${item.price.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Divider(height: 1, color: borderColor),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: implement checkout → log as expenses
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Checkout coming soon!')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentGreen,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('✓ Checkout → Log as Expenses'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final ShoppingListExample list;

  const _StatusPill({required this.list});

  @override
  Widget build(BuildContext context) {
    Color border;
    Color bg;
    Color fg;
    switch (list.status) {
      case 'red':
        border = AppColors.danger.withOpacity(0.3);
        bg = AppColors.danger.withOpacity(0.1);
        fg = AppColors.danger;
        break;
      case 'yellow':
        border = AppColors.warning.withOpacity(0.3);
        bg = AppColors.warning.withOpacity(0.1);
        fg = AppColors.warning;
        break;
      default:
        border = AppColors.accentGreen.withOpacity(0.3);
        bg = AppColors.accentGreen.withOpacity(0.1);
        fg = AppColors.accentGreen;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        color: bg,
        border: Border.all(color: border),
      ),
      child: Text(
        '${list.items} items',
        style: TextStyle(fontSize: 11, color: fg),
      ),
    );
  }
}
