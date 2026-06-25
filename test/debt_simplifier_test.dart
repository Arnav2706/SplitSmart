import 'package:flutter_test/flutter_test.dart';
import 'package:splitsmart/core/debt_engine/debt_simplifier.dart';
import 'package:splitsmart/core/models/expense.dart';

void main() {
  group('DebtSimplifier', () {
    test('Simplifies equal split among 3 people correctly', () {
      final expenses = [
        Expense(
          id: '1',
          groupId: 'g1',
          description: 'Dinner',
          amount: 30000, // 300 INR
          category: 'Food',
          paidBy: 'A',
          splitType: SplitType.equal,
          splits: [
            ExpenseSplit(userId: 'A', share: 0),
            ExpenseSplit(userId: 'B', share: 0),
            ExpenseSplit(userId: 'C', share: 0),
          ],
          date: DateTime.now(),
        ),
      ];

      final settlements = DebtSimplifier.simplifyDebts(expenses, 'g1');

      expect(settlements.length, 2);
      
      // B owes A 100
      final bSettle = settlements.firstWhere((s) => s.fromUserId == 'B');
      expect(bSettle.toUserId, 'A');
      expect(bSettle.amount, 10000);

      // C owes A 100
      final cSettle = settlements.firstWhere((s) => s.fromUserId == 'C');
      expect(cSettle.toUserId, 'A');
      expect(cSettle.amount, 10000);
    });

    test('Complex cycle reduces to minimum transactions', () {
      // A pays 300 for A, B, C (A: +200, B: -100, C: -100)
      // B pays 300 for A, B, C (B: +200, A: -100, C: -100) -> Net: A: +100, B: +100, C: -200
      final expenses = [
        Expense(
          id: '1',
          groupId: 'g1',
          description: 'Expense 1',
          amount: 30000,
          category: 'Misc',
          paidBy: 'A',
          splitType: SplitType.equal,
          splits: [
            ExpenseSplit(userId: 'A', share: 0),
            ExpenseSplit(userId: 'B', share: 0),
            ExpenseSplit(userId: 'C', share: 0),
          ],
          date: DateTime.now(),
        ),
        Expense(
          id: '2',
          groupId: 'g1',
          description: 'Expense 2',
          amount: 30000,
          category: 'Misc',
          paidBy: 'B',
          splitType: SplitType.equal,
          splits: [
            ExpenseSplit(userId: 'A', share: 0),
            ExpenseSplit(userId: 'B', share: 0),
            ExpenseSplit(userId: 'C', share: 0),
          ],
          date: DateTime.now(),
        ),
      ];

      final settlements = DebtSimplifier.simplifyDebts(expenses, 'g1');

      // C should owe A 100 and B 100.
      expect(settlements.length, 2);
      
      for (var s in settlements) {
        expect(s.fromUserId, 'C');
        expect(s.amount, 10000);
        expect(s.toUserId == 'A' || s.toUserId == 'B', true);
      }
    });
  });
}
