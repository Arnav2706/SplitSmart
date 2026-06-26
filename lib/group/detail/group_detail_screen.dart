import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/neon_theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/neon_button.dart';
import '../../core/models/group.dart';
import '../../core/models/expense.dart';
import '../../core/services/local_storage_service.dart';
import '../expense/add_expense_screen.dart';
import '../balances/settle_up_screen.dart';
import '../history/history_screen.dart';

class GroupDetailScreen extends StatefulWidget {
  final Group group;
  const GroupDetailScreen({super.key, required this.group});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.group;

    return Scaffold(
      backgroundColor: NeonTheme.background,
      appBar: AppBar(
        backgroundColor: NeonTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: NeonTheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(group.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: NeonTheme.primary)),
            Text('${group.members.length} members',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: NeonTheme.onSurfaceVariant)),
          ],
        ),
        centerTitle: true,
        actions: [
          // Share invite code
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GlassCard(
              borderRadius: 20,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              onTap: () => _showInviteSheet(context, group),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_add, color: NeonTheme.secondary, size: 16),
                  const SizedBox(width: 4),
                  Text(group.inviteCode,
                      style: const TextStyle(color: NeonTheme.secondary, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: NeonTheme.primary,
          indicatorWeight: 2,
          labelColor: NeonTheme.primary,
          unselectedLabelColor: NeonTheme.onSurfaceVariant,
          tabs: const [
            Tab(text: 'Expenses'),
            Tab(text: 'Balances'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ExpensesTab(group: group),
          SettleUpScreen(group: group),
          HistoryScreen(filterGroup: group),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) {
          if (_tabController.index != 0) return const SizedBox.shrink();
          return NeonButton(
            isFloating: true,
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => AddExpenseScreen(group: group))),
            child: const Icon(Icons.add, size: 28),
          );
        },
      ),
    );
  }

  void _showInviteSheet(BuildContext context, Group group) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              decoration: BoxDecoration(
                color: NeonTheme.surfaceContainer.withOpacity(0.9),
                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
              ),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 24),
                  Text('INVITE SOMEONE', style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: NeonTheme.onSurfaceVariant, letterSpacing: 2)),
                  const SizedBox(height: 24),
                  // Big code display
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: NeonTheme.primary.withOpacity(0.4)),
                      color: NeonTheme.primary.withOpacity(0.1),
                    ),
                    child: Column(
                      children: [
                        Text('Invite Code', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: NeonTheme.onSurfaceVariant)),
                        const SizedBox(height: 8),
                        Text(
                          group.inviteCode,
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            color: NeonTheme.primary,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 8,
                            shadows: [const Shadow(color: Color.fromRGBO(202, 190, 255, 0.6), blurRadius: 20)],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Share this code. Anyone who enters it can join the group.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: NeonTheme.onSurfaceVariant)),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: NeonButton(
                      isPrimary: true,
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Invite code: ${group.inviteCode} — share it with friends!')),
                        );
                      },
                      child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.share),
                        SizedBox(width: 8),
                        Text('Share Invite Code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Expenses Tab ───
class _ExpensesTab extends StatelessWidget {
  final Group group;
  const _ExpensesTab({required this.group});

  @override
  Widget build(BuildContext context) {
    final firestore = Provider.of<LocalStorageService>(context, listen: false);

    return StreamBuilder<List<Expense>>(
      stream: firestore.streamGroupExpenses(group.id),
      builder: (context, snapshot) {
        final expenses = snapshot.data ?? firestore.getGroupExpenses(group.id);
        final sorted = List<Expense>.from(expenses)..sort((a, b) => b.date.compareTo(a.date));

        if (sorted.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.receipt_long, size: 72, color: NeonTheme.surfaceContainerHigh),
                const SizedBox(height: 16),
                Text('No expenses yet', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: NeonTheme.onSurfaceVariant)),
                const SizedBox(height: 8),
                Text('Tap + to add the first one!', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: NeonTheme.onSurfaceVariant)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: sorted.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final exp = sorted[i];
            return GlassCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: NeonTheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_catIcon(exp.category), color: NeonTheme.primary, size: 20),
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
                        Text(
                          'Paid by ${exp.paidBy == 'local_user' ? 'You' : exp.paidBy.substring(0, 5)} • ${exp.date.day}/${exp.date.month}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: NeonTheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('₹${(exp.amount / 100).toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: NeonTheme.primary, fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: NeonTheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(exp.category, style: const TextStyle(fontSize: 10, color: NeonTheme.onSurfaceVariant)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  IconData _catIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'food': return Icons.restaurant;
      case 'transport': return Icons.directions_car;
      case 'groceries': return Icons.shopping_cart;
      case 'travel': return Icons.flight;
      case 'entertainment': return Icons.movie;
      default: return Icons.receipt;
    }
  }
}
