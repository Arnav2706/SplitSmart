import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/neon_theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/neon_button.dart';
import '../../core/models/group.dart';
import '../../core/models/expense.dart';
import '../../core/services/local_storage_service.dart';
import '../../core/services/local_auth_service.dart';

class AddExpenseScreen extends StatefulWidget {
  final Group group;
  const AddExpenseScreen({super.key, required this.group});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  String _amountString = '';
  String _selectedCategory = 'Food';
  final TextEditingController _noteController = TextEditingController();

  void _onNumpadTap(String value) {
    setState(() {
      if (value == 'backspace') {
        if (_amountString.isNotEmpty) {
          _amountString = _amountString.substring(0, _amountString.length - 1);
        }
      } else {
        if (value == '.' && _amountString.contains('.')) return;
        if (value == '.' && _amountString.isEmpty) { _amountString = '0'; }
        if (_amountString == '0' && value != '.') _amountString = '';
        // Max 7 digits before decimal
        final parts = _amountString.split('.');
        if (parts.length == 2 && parts[1].length >= 2) return; // max 2 decimal places
        if (parts[0].length >= 7 && !_amountString.contains('.')) return;
        _amountString += value;
      }
    });
  }

  void _submit() {
    if (_amountString.isEmpty) return;
    final amountDouble = double.tryParse(_amountString) ?? 0.0;
    if (amountDouble <= 0) return;
    final amountPaise = (amountDouble * 100).round();

    final user = Provider.of<LocalAuthService>(context, listen: false).currentUser;
    if (user == null) return;

    final members = widget.group.members;
    final splitShare = amountPaise ~/ members.length;
    final splits = members.map((m) => ExpenseSplit(userId: m, share: splitShare)).toList();

    final expense = Expense(
      id: const Uuid().v4(),
      groupId: widget.group.id,
      description: _noteController.text.trim().isEmpty ? _selectedCategory : _noteController.text.trim(),
      amount: amountPaise,
      category: _selectedCategory,
      paidBy: user.id,
      splitType: SplitType.equal,
      splits: splits,
      date: DateTime.now(),
    );

    Provider.of<LocalStorageService>(context, listen: false).addExpense(expense);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final displayAmount = _amountString.isEmpty ? '0' : _amountString;

    return Scaffold(
      backgroundColor: NeonTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: NeonTheme.onSurfaceVariant),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.group.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: NeonTheme.primary),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ─── Top section: Amount + Meta ───
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    // Amount display
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'How much?',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: NeonTheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '₹',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: NeonTheme.secondary),
                              ),
                              const SizedBox(width: 4),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 280),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    displayAmount,
                                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                          color: NeonTheme.secondary,
                                          shadows: [const Shadow(color: Color.fromRGBO(65, 232, 120, 0.5), blurRadius: 20)],
                                        ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 3,
                            width: 80,
                            decoration: BoxDecoration(
                              color: NeonTheme.secondary,
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: const [BoxShadow(color: Color.fromRGBO(65, 232, 120, 0.3), blurRadius: 8)],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Note Input
                    GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.edit_note, color: NeonTheme.onSurfaceVariant, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _noteController,
                              style: const TextStyle(color: NeonTheme.onBackground),
                              decoration: const InputDecoration(
                                hintText: 'What was this for? (e.g. Dinner)',
                                hintStyle: TextStyle(color: NeonTheme.onSurfaceVariant),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Category chips
                    Text(
                      'CATEGORY',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: NeonTheme.onSurfaceVariant, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _buildCategoryChip('Food', Icons.restaurant),
                        _buildCategoryChip('Transport', Icons.local_taxi),
                        _buildCategoryChip('Groceries', Icons.shopping_cart),
                        _buildCategoryChip('Travel', Icons.flight),
                        _buildCategoryChip('Entertainment', Icons.movie),
                        _buildCategoryChip('Other', Icons.receipt),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Split info row
                    GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.group, color: NeonTheme.primary, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Split equally among ${widget.group.members.length} members',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          if (_amountString.isNotEmpty && (double.tryParse(_amountString) ?? 0) > 0)
                            Text(
                              '₹${((double.tryParse(_amountString)! * 100).round() ~/ widget.group.members.length / 100).toStringAsFixed(0)} each',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: NeonTheme.primary, fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ─── Bottom: Numpad + Confirm ───
            Container(
              decoration: BoxDecoration(
                color: NeonTheme.surfaceContainer.withOpacity(0.8),
                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
              ),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildNumpad(),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: NeonButton(
                      onPressed: _amountString.isNotEmpty ? _submit : null,
                      isPrimary: true,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Confirm Expense', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          SizedBox(width: 8),
                          Icon(Icons.check_circle, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, IconData icon) {
    final isSelected = _selectedCategory == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? NeonTheme.secondary.withOpacity(0.15) : NeonTheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? NeonTheme.secondary : Colors.white.withOpacity(0.06),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? NeonTheme.secondary : NeonTheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? NeonTheme.secondary : NeonTheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumpad() {
    final keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '.', '0', 'backspace'];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.8,
        crossAxisSpacing: 8,
        mainAxisSpacing: 4,
      ),
      itemCount: keys.length,
      itemBuilder: (context, index) {
        final key = keys[index];
        return GestureDetector(
          onTap: () => _onNumpadTap(key),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
            child: key == 'backspace'
                ? const Icon(Icons.backspace_outlined, color: NeonTheme.onSurfaceVariant, size: 22)
                : Text(
                    key,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: NeonTheme.onBackground,
                        ),
                  ),
          ),
        );
      },
    );
  }
}
