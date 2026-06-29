import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../core/theme/neon_theme.dart';
import '../core/widgets/glass_card.dart';
import '../core/widgets/neon_button.dart';
import '../core/services/local_auth_service.dart';
import '../core/services/local_storage_service.dart';
import '../core/models/group.dart';
import '../core/models/expense.dart';
import '../core/models/settlement.dart';
import '../group/detail/group_detail_screen.dart';
import '../group/history/history_screen.dart';

// ─────────────────────── Root Shell ───────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _GroupsTab(),
      const _SplitsTab(),
      const _ActivityTab(),
      const _SettingsTab(),
    ];

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        backgroundColor: NeonTheme.background.withOpacity(0.8),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.2)),
                color: NeonTheme.primary.withOpacity(0.2),
              ),
              child: const Icon(Icons.splitscreen, color: NeonTheme.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'SplitSmart',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: NeonTheme.primary,
                    shadows: [
                      const Shadow(
                        color: Color.fromRGBO(202, 190, 255, 0.5),
                        blurRadius: 10,
                      )
                    ],
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: NeonTheme.primary),
            onPressed: () {},
          )
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      floatingActionButton: _currentIndex == 0 ? _buildFAB(context) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _GlassBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    final user = context.read<LocalAuthService>().currentUser;
    final firestore = context.read<LocalStorageService>();

    return NeonButton(
      isFloating: true,
      onPressed: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => _GroupActionSheet(user: user, firestore: firestore),
        );
      },
      child: const Icon(Icons.add, size: 32),
    );
  }
}

// ─────────────────────── Tab: Groups ───────────────────────
class _GroupsTab extends StatelessWidget {
  const _GroupsTab();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<LocalAuthService>().currentUser;
    final firestore = context.read<LocalStorageService>();

    return user == null
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _TotalBalanceHero(),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Your Groups', style: Theme.of(context).textTheme.titleMedium),
                    TextButton(
                      onPressed: () {},
                      child: const Text('View All', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                StreamBuilder<List<Group>>(
                  stream: firestore.streamUserGroups(user.id),
                  builder: (context, snapshot) {
                    final groups = snapshot.data ?? firestore.getUserGroups(user.id);
                    if (groups.isEmpty && !snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (groups.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text('No groups yet. Tap + to create one!'),
                        ),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: groups.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _GroupListItem(group: groups[index]);
                      },
                    );
                  },
                ),
                const SizedBox(height: 100),
              ],
            ),
          );
  }
}

// ─────────────────────── Tab: Splits ───────────────────────
class _SplitsTab extends StatelessWidget {
  const _SplitsTab();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<LocalAuthService>().currentUser;
    final firestore = context.read<LocalStorageService>();

    if (user == null) return const Center(child: CircularProgressIndicator());

    final allExpenses = firestore.getUserExpenses(user.id);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        Text('All Your Splits', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        if (allExpenses.isEmpty)
          GlassCard(
            padding: const EdgeInsets.all(32),
            child: const Center(
              child: Text('No splits yet. Add an expense inside a group!'),
            ),
          )
        else
          ...allExpenses.map((exp) {
            final isPayer = exp.paidBy == user.id;
            final mySplit = exp.splits.firstWhere((s) => s.userId == user.id, orElse: () => ExpenseSplit(userId: user.id, share: 0));
            final myShare = mySplit.share;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: NeonTheme.surfaceContainerHigh,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _categoryIcon(exp.category),
                        color: NeonTheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(exp.description, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                          Text(
                            isPayer ? 'You paid ₹${(exp.amount / 100).toStringAsFixed(0)}' : 'Your share: ₹${(myShare / 100).toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      isPayer ? '+₹${((exp.amount - myShare) / 100).toStringAsFixed(0)}' : '-₹${(myShare / 100).toStringAsFixed(0)}',
                      style: TextStyle(
                        color: isPayer ? NeonTheme.secondary : NeonTheme.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  IconData _categoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'food': return Icons.restaurant;
      case 'transport': return Icons.directions_car;
      case 'accommodation': return Icons.hotel;
      case 'entertainment': return Icons.movie;
      default: return Icons.receipt;
    }
  }
}

// ─────────────────────── Tab: Activity (History) ───────────────────────
class _ActivityTab extends StatelessWidget {
  const _ActivityTab();

  @override
  Widget build(BuildContext context) {
    return const HistoryScreen();
  }
}

// ─────────────────────── Group Action Sheet ───────────────────────
class _GroupActionSheet extends StatefulWidget {
  final dynamic user;
  final LocalStorageService firestore;
  const _GroupActionSheet({required this.user, required this.firestore});

  @override
  State<_GroupActionSheet> createState() => _GroupActionSheetState();
}

class _GroupActionSheetState extends State<_GroupActionSheet> {
  bool _showCreate = false;
  bool _showJoin = false;
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: NeonTheme.surfaceContainer.withOpacity(0.9),
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
          ),
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 40,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 20),
                if (!_showCreate && !_showJoin) ...[
                  Text('ADD A GROUP', style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: NeonTheme.onSurfaceVariant, letterSpacing: 2)),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: NeonButton(
                      isPrimary: true,
                      onPressed: () => setState(() => _showCreate = true),
                      child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.group_add),
                        SizedBox(width: 10),
                        Text('Create New Group', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: NeonButton(
                      isPrimary: false,
                      onPressed: () => setState(() => _showJoin = true),
                      child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.login),
                        SizedBox(width: 10),
                        Text('Join with Invite Code', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ]),
                    ),
                  ),
                ] else if (_showCreate) ...[
                  Text('CREATE GROUP', style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: NeonTheme.onSurfaceVariant, letterSpacing: 2)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameCtrl,
                    autofocus: true,
                    style: const TextStyle(color: NeonTheme.onBackground),
                    decoration: const InputDecoration(
                      hintText: 'Group name (e.g. Goa Trip)',
                      hintStyle: TextStyle(color: NeonTheme.onSurfaceVariant),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: NeonTheme.primary)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: NeonTheme.primary, width: 2)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: NeonButton(
                      isPrimary: true,
                      onPressed: () {
                        if (_nameCtrl.text.trim().isEmpty || widget.user == null) return;
                        final newGroup = Group(
                          id: const Uuid().v4(),
                          name: _nameCtrl.text.trim(),
                          inviteCode: const Uuid().v4().substring(0, 6).toUpperCase(),
                          members: [widget.user.id],
                          createdAt: DateTime.now(),
                        );
                        widget.firestore.createGroup(newGroup);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('✅ "${newGroup.name}" created! Invite code: ${newGroup.inviteCode}')),
                        );
                      },
                      child: const Text('Create Group', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ] else if (_showJoin) ...[
                  Text('JOIN GROUP', style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: NeonTheme.onSurfaceVariant, letterSpacing: 2)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _codeCtrl,
                    autofocus: true,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(color: NeonTheme.onBackground, letterSpacing: 4, fontSize: 22, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      hintText: 'XXXXXX',
                      hintStyle: TextStyle(color: NeonTheme.onSurfaceVariant, letterSpacing: 4),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: NeonTheme.primary)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: NeonTheme.primary, width: 2)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: NeonButton(
                      isPrimary: true,
                      onPressed: () {
                        final code = _codeCtrl.text.trim().toUpperCase();
                        if (code.isEmpty || widget.user == null) return;
                        final joined = widget.firestore.joinGroupByCode(code, widget.user.id);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(joined ? '✅ Joined the group!' : '❌ No group found with code "$code"')),
                        );
                      },
                      child: const Text('Join Group', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}


// ─────────────────────── Tab: Settings ───────────────────────
class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context) {
    final user = context.read<LocalAuthService>().currentUser;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      children: [
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: NeonTheme.primary.withOpacity(0.2),
                  border: Border.all(color: NeonTheme.primary.withOpacity(0.4)),
                ),
                child: const Icon(Icons.person, color: NeonTheme.primary, size: 28),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user?.name ?? 'Local User', style: Theme.of(context).textTheme.titleMedium),
                  Text(user?.upiId ?? '', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Preferences', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: NeonTheme.onSurfaceVariant, letterSpacing: 1.5)),
        const SizedBox(height: 12),
        _buildSettingItem(context, Icons.currency_rupee, 'Currency', 'INR — Indian Rupee'),
        _buildSettingItem(context, Icons.notifications, 'Notifications', 'Enabled'),
        _buildSettingItem(context, Icons.dark_mode, 'Theme', 'Dark (Neon Protocol)'),
        const SizedBox(height: 24),
        Text('Data', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: NeonTheme.onSurfaceVariant, letterSpacing: 1.5)),
        const SizedBox(height: 12),
        _buildSettingItem(context, Icons.storage, 'Storage', 'Local device only'),
        _buildSettingItem(context, Icons.info, 'Version', '1.0.0'),
      ],
    );
  }

  Widget _buildSettingItem(BuildContext context, IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: NeonTheme.primary, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: NeonTheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────── Total Balance Hero ───────────────────────
class _TotalBalanceHero extends StatelessWidget {
  const _TotalBalanceHero();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<LocalAuthService>().currentUser;
    final firestore = context.read<LocalStorageService>();

    if (user == null) return const SizedBox.shrink();

    final expenses = firestore.getUserExpenses(user.id);
    int totalBalance = 0;
    for (var e in expenses) {
      if (e.paidBy == user.id) totalBalance += e.amount;
      for (var s in e.splits) {
        if (s.userId == user.id) totalBalance -= s.share;
      }
    }

    final isPositive = totalBalance >= 0;
    final displayAmount = '₹${(totalBalance.abs() / 100).toStringAsFixed(0)}';

    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      borderRadius: 24,
      child: Column(
        children: [
          Text(
            'NET BALANCE',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: NeonTheme.onSurfaceVariant, letterSpacing: 2),
          ),
          const SizedBox(height: 8),
          Text(
            displayAmount,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: isPositive ? NeonTheme.secondary : NeonTheme.error,
                  shadows: [
                    Shadow(
                      color: (isPositive ? NeonTheme.secondary : NeonTheme.error).withOpacity(0.6),
                      blurRadius: 12,
                    )
                  ],
                ),
          ),
          const SizedBox(height: 4),
          Text(
            totalBalance == 0 ? 'All settled up!' : (isPositive ? 'Overall, people owe you' : 'Overall, you owe'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: NeonTheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: NeonButton(
                  isPrimary: false,
                  onPressed: () {},
                  child: const Text('Remind All', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────── Group List Item ───────────────────────
class _GroupListItem extends StatelessWidget {
  final Group group;
  const _GroupListItem({required this.group});

  @override
  Widget build(BuildContext context) {
    final firestore = Provider.of<LocalStorageService>(context, listen: false);
    final user = Provider.of<LocalAuthService>(context, listen: false).currentUser;

    return GlassCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GroupDetailScreen(group: group)),
        );
      },
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: NeonTheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: const Icon(Icons.group, color: NeonTheme.primaryContainer),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.name,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                StreamBuilder<List<Expense>>(
                  stream: firestore.streamGroupExpenses(group.id),
                  builder: (context, expSnap) {
                    return StreamBuilder<List<Settlement>>(
                      stream: firestore.streamGroupSettlements(group.id),
                      builder: (context, setSnap) {
                        // Use sync data if stream not yet emitted
                        final expenses = expSnap.data ?? firestore.getGroupExpenses(group.id);
                        final settlements = setSnap.data ?? [];

                        int myBalance = 0;
                        if (user != null) {
                          for (var e in expenses) {
                            if (e.paidBy == user.id) myBalance += e.amount.toInt();
                            for (var s in e.splits) {
                              if (s.userId == user.id) myBalance -= s.share.toInt();
                            }
                          }
                          for (var s in settlements) {
                            if (s.status == 'confirmed') {
                              if (s.fromUserId == user.id) myBalance += s.amount.toInt();
                              if (s.toUserId == user.id) myBalance -= s.amount.toInt();
                            }
                          }
                        }

                        final isOwe = myBalance < 0;
                        final color = myBalance == 0 ? Colors.grey : (isOwe ? NeonTheme.error : NeonTheme.secondary);
                        final text = myBalance == 0
                            ? 'Settled up'
                            : (isOwe ? 'You owe ₹${(-myBalance / 100).toStringAsFixed(0)}' : 'You get ₹${(myBalance / 100).toStringAsFixed(0)}');

                        return Row(
                          children: [
                            Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
                            const SizedBox(width: 6),
                            Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color)),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          Text(
            '${group.members.length} members',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: NeonTheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────── Bottom Nav ───────────────────────
class _GlassBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _GlassBottomNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          color: NeonTheme.surfaceContainer.withOpacity(0.6),
          padding: const EdgeInsets.only(bottom: 24, top: 12, left: 16, right: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(context, 0, Icons.home, 'Home'),
              _buildNavItem(context, 1, Icons.account_balance_wallet, 'Splits'),
              _buildNavItem(context, 2, Icons.receipt_long, 'Activity'),
              _buildNavItem(context, 3, Icons.settings, 'Settings'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon, String label) {
    final isActive = currentIndex == index;
    final color = isActive ? NeonTheme.secondary : NeonTheme.onSurfaceVariant.withOpacity(0.7);
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, shadows: isActive ? [Shadow(color: NeonTheme.secondary.withOpacity(0.6), blurRadius: 8)] : []),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
