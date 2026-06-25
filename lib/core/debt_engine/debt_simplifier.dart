import 'package:uuid/uuid.dart';

import '../models/expense.dart';
import '../models/settlement.dart';

/// Represents a balance node in the max-heap.
class _BalanceNode implements Comparable<_BalanceNode> {
  final String userId;
  final int balance;

  _BalanceNode(this.userId, this.balance);

  @override
  int compareTo(_BalanceNode other) {
    // For a max-heap based on absolute value, we want the largest absolute value to come first
    return balance.abs().compareTo(other.balance.abs());
  }
}

class DebtSimplifier {
  /// Simplifies a list of expenses into the minimum number of settlements.
  /// 
  /// Steps:
  /// 1. Calculate net balances for each user based on expenses and split types.
  /// 2. Separate into creditors (balance > 0) and debtors (balance < 0).
  /// 3. Sort both lists by absolute balance descending.
  /// 4. Greedily match the largest debtor with the largest creditor.
  static List<Settlement> simplifyDebts(List<Expense> expenses, String groupId) {
    // Step 1: Compute net balances
    final Map<String, int> netBalances = {};

    for (var expense in expenses) {
      // Add the paid amount to the payer's balance
      netBalances[expense.paidBy] = (netBalances[expense.paidBy] ?? 0) + expense.amount;

      // Deduct the share from each participant
      if (expense.splitType == SplitType.equal) {
        final share = expense.amount ~/ expense.splits.length;
        int remainder = expense.amount % expense.splits.length;

        for (var split in expense.splits) {
          int amountToDeduct = share;
          if (remainder > 0) {
            amountToDeduct += 1;
            remainder -= 1;
          }
          netBalances[split.userId] = (netBalances[split.userId] ?? 0) - amountToDeduct;
        }
      } else if (expense.splitType == SplitType.exact) {
        for (var split in expense.splits) {
          netBalances[split.userId] = (netBalances[split.userId] ?? 0) - split.share;
        }
      } else if (expense.splitType == SplitType.percentage) {
        for (var split in expense.splits) {
          final share = (expense.amount * split.share) ~/ 100;
          netBalances[split.userId] = (netBalances[split.userId] ?? 0) - share;
        }
      } else if (expense.splitType == SplitType.shares) {
        int totalShares = expense.splits.fold(0, (sum, s) => sum + s.share);
        if (totalShares > 0) {
          for (var split in expense.splits) {
            final share = (expense.amount * split.share) ~/ totalShares;
            netBalances[split.userId] = (netBalances[split.userId] ?? 0) - share;
          }
        }
      }
    }

    // Step 2: Separate into creditors and debtors
    List<_BalanceNode> creditors = [];
    List<_BalanceNode> debtors = [];

    netBalances.forEach((userId, balance) {
      if (balance > 0) {
        creditors.add(_BalanceNode(userId, balance));
      } else if (balance < 0) {
        debtors.add(_BalanceNode(userId, balance));
      }
    });

    // Step 3 & 4: Match largest debtors with largest creditors
    List<Settlement> settlements = [];
    final uuid = Uuid();

    while (creditors.isNotEmpty && debtors.isNotEmpty) {
      // Sort to get largest absolute balances first (simulate max-heap)
      creditors.sort((a, b) => b.balance.compareTo(a.balance));
      debtors.sort((a, b) => b.balance.abs().compareTo(a.balance.abs()));

      var maxCreditor = creditors.first;
      var maxDebtor = debtors.first;

      creditors.removeAt(0);
      debtors.removeAt(0);

      // Settle the minimum of the two
      int settleAmount = maxCreditor.balance < maxDebtor.balance.abs() 
          ? maxCreditor.balance 
          : maxDebtor.balance.abs();

      settlements.add(Settlement(
        id: uuid.v4(),
        groupId: groupId,
        fromUserId: maxDebtor.userId,
        toUserId: maxCreditor.userId,
        amount: settleAmount,
        createdAt: DateTime.now(),
      ));

      // Update remaining balances
      int remainingCreditor = maxCreditor.balance - settleAmount;
      int remainingDebtor = maxDebtor.balance + settleAmount;

      if (remainingCreditor > 0) {
        creditors.add(_BalanceNode(maxCreditor.userId, remainingCreditor));
      }
      if (remainingDebtor < 0) {
        debtors.add(_BalanceNode(maxDebtor.userId, remainingDebtor));
      }
    }

    return settlements;
  }
}
