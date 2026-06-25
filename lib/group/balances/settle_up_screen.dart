import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/neon_theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/neon_button.dart';
import '../../core/models/group.dart';
import '../../core/models/settlement.dart';
import '../../core/models/expense.dart';
import '../../core/services/local_storage_service.dart';
import '../../core/services/local_auth_service.dart';
import '../../core/debt_engine/debt_simplifier.dart';
import '../../core/upi/upi_service.dart';
import '../../core/export/export_service.dart';

// ─── Settle Up Screen (embedded inside GroupDetailScreen tabs) ───
class SettleUpScreen extends StatelessWidget {
  final Group group;
  const SettleUpScreen({super.key, required this.group});

  String _shortId(String id) {
    if (id == 'local_user') return 'You';
    if (id.length > 8) return id.substring(0, 8);
    return id;
  }

  int _calculateRawDebts(List<Expense> expenses) {
    final Set<String> pairs = {};
    for (var e in expenses) {
      for (var s in e.splits) {
        if (s.userId != e.paidBy) {
          pairs.add('${e.paidBy}-${s.userId}');
        }
      }
    }
    return pairs.length;
  }

  Widget _statPill(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(text,
          textAlign: TextAlign.center,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firestore = Provider.of<LocalStorageService>(context, listen: false);
    final user = Provider.of<LocalAuthService>(context, listen: false).currentUser;

    return StreamBuilder<List<Expense>>(
      stream: firestore.streamGroupExpenses(group.id),
      builder: (context, expSnap) {
        final expenses = expSnap.data ?? firestore.getGroupExpenses(group.id);
        final rawDebts = _calculateRawDebts(expenses);
        final simplified = DebtSimplifier.simplifyDebts(expenses, group.id);
        final myDebts = simplified
            .where((s) => s.fromUserId == user?.id || s.toUserId == user?.id)
            .toList();
        final reduction = rawDebts == 0 ? 0 : ((1 - simplified.length / rawDebts) * 100).round();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            // ─── Debt Simplification Engine card ───
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: NeonTheme.primary, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('DEBT SIMPLIFICATION ENGINE',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: NeonTheme.primary, letterSpacing: 1.5)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _statPill(context, '$rawDebts raw debts', NeonTheme.error)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.arrow_forward, color: NeonTheme.primary),
                      ),
                      Expanded(child: _statPill(context, '${simplified.length} optimised', NeonTheme.secondary)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    simplified.isEmpty
                        ? 'Everyone is settled up! 🎉'
                        : 'Reduced by $reduction% — minimum transactions',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: NeonTheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ─── Export button ───
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              onTap: () => _showExportSheet(context, firestore, simplified),
              child: Row(
                children: [
                  const Icon(Icons.download, color: NeonTheme.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Export Ledger', style: Theme.of(context).textTheme.titleSmall),
                        Text('PDF or CSV', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: NeonTheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: NeonTheme.onSurfaceVariant),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ─── My debts ───
            if (myDebts.isEmpty)
              GlassCard(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle, color: NeonTheme.secondary, size: 48),
                    const SizedBox(height: 12),
                    Text("You're all settled up!",
                        style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              )
            else ...[
              Text('YOUR SETTLEMENTS',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: NeonTheme.onSurfaceVariant, letterSpacing: 1.5)),
              const SizedBox(height: 12),
              ...myDebts.map((s) {
                final isOwe = s.fromUserId == user?.id;
                final otherId = isOwe ? s.toUserId : s.fromUserId;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassCard(
                    onTap: isOwe ? () => _showSettleSheet(context, s, otherId, firestore) : null,
                    child: Row(
                      children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            color: (isOwe ? NeonTheme.error : NeonTheme.secondary).withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isOwe ? Icons.arrow_outward : Icons.arrow_downward,
                            color: isOwe ? NeonTheme.error : NeonTheme.secondary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isOwe ? 'You owe ${_shortId(otherId)}' : '${_shortId(otherId)} owes you',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                isOwe ? 'Tap to settle via UPI' : 'Waiting for their payment',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '₹${(s.amount / 100).toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: isOwe ? NeonTheme.error : NeonTheme.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],

            // ─── All group settlements ───
            if (simplified.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('ALL GROUP SETTLEMENTS',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: NeonTheme.onSurfaceVariant, letterSpacing: 1.5)),
              const SizedBox(height: 12),
              ...simplified.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Text(_shortId(s.fromUserId),
                          style: const TextStyle(color: NeonTheme.error, fontWeight: FontWeight.bold)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.arrow_forward, size: 16, color: NeonTheme.onSurfaceVariant),
                      ),
                      Text(_shortId(s.toUserId),
                          style: const TextStyle(color: NeonTheme.secondary, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Text('₹${(s.amount / 100).toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              )),
            ],
          ],
        );
      },
    );
  }

  void _showSettleSheet(BuildContext context, Settlement settlement, String toUserId, LocalStorageService firestore) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SettleSheet(settlement: settlement, toUserId: toUserId, firestore: firestore, group: group),
    );
  }

  void _showExportSheet(BuildContext context, LocalStorageService firestore, List<Settlement> simplified) {
    final expenses = firestore.getGroupExpenses(group.id);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExportSheet(group: group, expenses: expenses, settlements: simplified),
    );
  }
}

// ─────────────────────── Settle Sheet ───────────────────────
class _SettleSheet extends StatefulWidget {
  final Settlement settlement;
  final String toUserId;
  final LocalStorageService firestore;
  final Group group;
  const _SettleSheet({required this.settlement, required this.toUserId, required this.firestore, required this.group});

  @override
  State<_SettleSheet> createState() => _SettleSheetState();
}

class _SettleSheetState extends State<_SettleSheet> {
  bool _launching = false;

  void _launchUpi() {
    setState(() => _launching = true);
    UpiService.initiatePayment(
      payeeUpiId: '${widget.toUserId}@okicici',
      payeeName: widget.toUserId,
      amount: widget.settlement.amount / 100.0,
      transactionNote: 'SplitSmart | ${widget.group.name}',
    ).then((launched) {
      if (!mounted) return;
      setState(() => _launching = false);
      if (launched) {
        _showConfirmDialog(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No UPI app found. Install GPay, PhonePe, or Paytm.')),
        );
      }
    });
  }

  void _markCash() {
    widget.firestore.addSettlement(Settlement(
      id: const Uuid().v4(),
      groupId: widget.group.id,
      fromUserId: widget.settlement.fromUserId,
      toUserId: widget.settlement.toUserId,
      amount: widget.settlement.amount,
      status: 'confirmed',
      createdAt: DateTime.now(),
    ));
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Marked as paid in cash!')),
    );
  }

  void _showConfirmDialog(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: NeonTheme.surfaceContainerHigh,
        title: const Text('Payment Complete?', style: TextStyle(color: Colors.white)),
        content: const Text('Did you complete the UPI payment?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              widget.firestore.addSettlement(Settlement(
                id: const Uuid().v4(),
                groupId: widget.group.id,
                fromUserId: widget.settlement.fromUserId,
                toUserId: widget.settlement.toUserId,
                amount: widget.settlement.amount,
                status: 'confirmed',
                createdAt: DateTime.now(),
              ));
              Navigator.pop(ctx);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('✅ Settlement confirmed!')),
              );
            },
            child: const Text('Yes, paid!', style: TextStyle(color: NeonTheme.secondary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _upiApp(String name, IconData icon, Color bg, Color fg) {
    return Column(
      children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color: bg, shape: BoxShape.circle,
            border: Border.all(color: Colors.white12),
          ),
          child: Icon(icon, color: fg, size: 24),
        ),
        const SizedBox(height: 6),
        Text(name, style: const TextStyle(fontSize: 11, color: NeonTheme.onSurfaceVariant)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: NeonTheme.surfaceContainer.withOpacity(0.85),
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.15))),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              Text('SETTLE UP',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(color: NeonTheme.onSurfaceVariant, letterSpacing: 2)),
              const SizedBox(height: 12),
              Text('₹${(widget.settlement.amount / 100).toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: NeonTheme.primary,
                    shadows: [const Shadow(color: Color.fromRGBO(202, 190, 255, 0.8), blurRadius: 20)],
                  )),
              const SizedBox(height: 8),
              Text('to ${widget.toUserId}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: NeonTheme.onSurfaceVariant)),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _upiApp('GPay', Icons.g_mobiledata, Colors.white, Colors.black),
                  _upiApp('PhonePe', Icons.phone_android, const Color(0xFF5f259f), Colors.white),
                  _upiApp('Paytm', Icons.currency_rupee, const Color(0xFF002970), Colors.white),
                  _upiApp('BHIM', Icons.account_balance, const Color(0xFF1a237e), Colors.white),
                ],
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: NeonButton(
                  isPrimary: true,
                  onPressed: _launching ? null : _launchUpi,
                  child: _launching
                      ? const SizedBox(height: 20, width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.bolt, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Open UPI App', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _markCash,
                child: const Text('Mark as paid in cash', style: TextStyle(color: NeonTheme.onSurfaceVariant)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────── Export Sheet ───────────────────────
class _ExportSheet extends StatefulWidget {
  final Group group;
  final List<Expense> expenses;
  final List<Settlement> settlements;
  const _ExportSheet({required this.group, required this.expenses, required this.settlements});

  @override
  State<_ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends State<_ExportSheet> {
  bool _loading = false;

  void _export(bool isPdf) {
    setState(() => _loading = true);
    final future = isPdf
        ? ExportService.generatePdf(group: widget.group, expenses: widget.expenses, settlements: widget.settlements)
        : ExportService.generateCsv(group: widget.group, expenses: widget.expenses);

    future.then((path) {
      Share.shareXFiles(
        [XFile(path)],
        subject: 'SplitSmart — ${widget.group.name} ${isPdf ? "PDF" : "CSV"}',
      );
      if (mounted) setState(() => _loading = false);
    }).catchError((e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    });
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
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Text('EXPORT LEDGER',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(color: NeonTheme.onSurfaceVariant, letterSpacing: 2)),
              const SizedBox(height: 8),
              Text('${widget.expenses.length} expenses • ${widget.group.members.length} members',
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 24),
              if (_loading)
                const Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())
              else ...[
                SizedBox(
                  width: double.infinity,
                  child: NeonButton(
                    isPrimary: true,
                    onPressed: () => _export(true),
                    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.picture_as_pdf),
                      SizedBox(width: 10),
                      Text('Export as PDF', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ]),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: NeonButton(
                    isPrimary: false,
                    onPressed: () => _export(false),
                    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.table_chart),
                      SizedBox(width: 10),
                      Text('Export as CSV', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ]),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
