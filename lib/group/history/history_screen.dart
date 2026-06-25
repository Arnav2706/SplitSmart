import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/neon_theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/models/expense.dart';
import '../../core/models/group.dart';
import '../../core/services/local_storage_service.dart';
import '../../core/services/local_auth_service.dart';

class HistoryScreen extends StatefulWidget {
  final Group? filterGroup;
  const HistoryScreen({super.key, this.filterGroup});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _searchQuery = '';
  String? _selectedCategory;
  final _searchCtrl = TextEditingController();

  static const _categories = ['All', 'Food', 'Transport', 'Groceries', 'Travel', 'Entertainment', 'Other'];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firestore = Provider.of<LocalStorageService>(context, listen: false);
    final user = Provider.of<LocalAuthService>(context, listen: false).currentUser;
    final groups = firestore.getUserGroups(user?.id ?? '');
    final groupMap = {for (var g in groups) g.id: g};

    List<Expense> all = widget.filterGroup != null
        ? firestore.getGroupExpenses(widget.filterGroup!.id)
        : firestore.getUserExpenses(user?.id ?? '');

    // Apply search
    if (_searchQuery.isNotEmpty) {
      all = all.where((e) =>
          e.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.category.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    // Apply category filter
    if (_selectedCategory != null && _selectedCategory != 'All') {
      all = all.where((e) => e.category == _selectedCategory).toList();
    }

    // Sort newest first
    all.sort((a, b) => b.date.compareTo(a.date));

    final isEmbedded = widget.filterGroup != null;

    return Scaffold(
      backgroundColor: isEmbedded ? Colors.transparent : NeonTheme.background,
      appBar: isEmbedded ? null : AppBar(
        backgroundColor: NeonTheme.background,
        title: Text('Expense History', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: NeonTheme.primary)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, isEmbedded ? 0 : 8, 16, 0),
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.search, color: NeonTheme.onSurfaceVariant, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      style: const TextStyle(color: NeonTheme.onBackground, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Search expenses…',
                        hintStyle: TextStyle(color: NeonTheme.onSurfaceVariant),
                        border: InputBorder.none,
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); },
                      child: const Icon(Icons.close, color: NeonTheme.onSurfaceVariant, size: 18),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Category filter chips
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final cat = _categories[i];
                final isActive = (_selectedCategory == null && cat == 'All') ||
                    _selectedCategory == cat ||
                    (cat == 'All' && _selectedCategory == null);
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat == 'All' ? null : cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive ? NeonTheme.primary.withOpacity(0.2) : NeonTheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive ? NeonTheme.primary : Colors.white.withOpacity(0.06),
                      ),
                    ),
                    child: Text(cat,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isActive ? NeonTheme.primary : NeonTheme.onSurfaceVariant,
                        )),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('${all.length} expense${all.length == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: NeonTheme.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Expense list
          Expanded(
            child: all.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.receipt_long, size: 64, color: NeonTheme.surfaceContainerHigh),
                        const SizedBox(height: 12),
                        Text('No expenses found', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: NeonTheme.onSurfaceVariant)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: all.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final exp = all[i];
                      final isPayer = exp.paidBy == user?.id;
                      final mySplit = exp.splits.firstWhere((s) => s.userId == user?.id,
                          orElse: () => ExpenseSplit(userId: '', share: 0));
                      final groupName = groupMap[exp.groupId]?.name ?? exp.groupId;

                      return GlassCard(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 42, height: 42,
                              decoration: BoxDecoration(
                                color: NeonTheme.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(_categoryIcon(exp.category), color: NeonTheme.primary, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(exp.description,
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                                      maxLines: 1, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 2),
                                  Text('$groupName • ${_formatDate(exp.date)}',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: NeonTheme.onSurfaceVariant),
                                      maxLines: 1),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₹${(exp.amount / 100).toStringAsFixed(0)}',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: NeonTheme.primary, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  isPayer
                                      ? '+₹${((exp.amount - mySplit.share) / 100).toStringAsFixed(0)}'
                                      : '-₹${(mySplit.share / 100).toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isPayer ? NeonTheme.secondary : NeonTheme.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  IconData _categoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'food': return Icons.restaurant;
      case 'transport': return Icons.directions_car;
      case 'groceries': return Icons.shopping_cart;
      case 'travel': return Icons.flight;
      case 'entertainment': return Icons.movie;
      default: return Icons.receipt;
    }
  }

  String _formatDate(DateTime d) {
    return '${d.day}/${d.month}/${d.year}';
  }
}
