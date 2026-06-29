import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../models/group.dart';
import '../models/expense.dart';
import '../models/settlement.dart';

class LocalStorageService {
  List<Group> _groups = [];
  List<Expense> _expenses = [];
  List<Settlement> _settlements = [];

  // Use StreamControllers with initial seeded values via late init
  final _groupsController = StreamController<List<Group>>.broadcast();
  final _expensesController = StreamController<List<Expense>>.broadcast();
  final _settlementsController = StreamController<List<Settlement>>.broadcast();

  File? _dataFile;

  // A future callers can await before reading
  late final Future<void> initialized;

  LocalStorageService() {
    initialized = _init();
  }

  Future<void> _init() async {
    final dir = await getApplicationDocumentsDirectory();
    _dataFile = File('${dir.path}/splitsmart_data.json');

    if (await _dataFile!.exists()) {
      final String contents = await _dataFile!.readAsString();
      if (contents.isNotEmpty) {
        try {
          final Map<String, dynamic> data = jsonDecode(contents);
          if (data['groups'] != null) {
            _groups = (data['groups'] as List).map((e) => Group.fromJson(e)).toList();
          }
          if (data['expenses'] != null) {
            _expenses = (data['expenses'] as List).map((e) => Expense.fromJson(e)).toList();
          }
          if (data['settlements'] != null) {
            _settlements = (data['settlements'] as List).map((e) => Settlement.fromJson(e)).toList();
          }
        } catch (_) {}
      }
    }

    // Seed with demo groups + expenses on first run or if new seed is missing
    final bool hasDemoTrip = _groups.any((g) => g.id == 'demo_trip');
    if (_groups.isEmpty || !hasDemoTrip) {
      final yesterday = DateTime(2026, 6, 25);
      final todayNoon = DateTime(2026, 6, 26, 12, 0);

      const uid = 'local_user';
      const rahul = 'rahul';
      const priya = 'priya';
      const amit = 'amit';

      _groups = [
        Group(
          id: 'demo_goa',
          name: 'Goa Trip 🏖️',
          members: [uid, rahul, priya, amit],
          inviteCode: 'GOA420',
          createdAt: DateTime(2026, 6, 24),
        ),
        Group(
          id: 'demo_flat',
          name: 'BHK Flat 🏠',
          members: [uid, rahul, priya],
          inviteCode: 'FLAT01',
          createdAt: DateTime(2026, 6, 20),
        ),
        Group(
          id: 'demo_trip',
          name: 'Weekend Getaway 🚗',
          members: [uid, rahul, priya, amit],
          inviteCode: 'TRIP42',
          createdAt: DateTime(2026, 6, 25),
        ),
      ];

      _expenses = [
        // Goa Trip expenses
        Expense(
          id: 'e1', groupId: 'demo_goa', description: 'Hotel booking',
          amount: 480000, category: 'Travel', paidBy: uid,
          splitType: SplitType.equal,
          splits: [
            ExpenseSplit(userId: uid, share: 120000),
            ExpenseSplit(userId: rahul, share: 120000),
            ExpenseSplit(userId: priya, share: 120000),
            ExpenseSplit(userId: amit, share: 120000),
          ],
          date: DateTime(2026, 6, 24, 10, 0),
        ),
        Expense(
          id: 'e2', groupId: 'demo_goa', description: 'Scooter rental',
          amount: 160000, category: 'Transport', paidBy: rahul,
          splitType: SplitType.equal,
          splits: [
            ExpenseSplit(userId: uid, share: 40000),
            ExpenseSplit(userId: rahul, share: 40000),
            ExpenseSplit(userId: priya, share: 40000),
            ExpenseSplit(userId: amit, share: 40000),
          ],
          date: yesterday,
        ),
        Expense(
          id: 'e3', groupId: 'demo_goa', description: 'Beach shack dinner',
          amount: 340000, category: 'Food', paidBy: priya,
          splitType: SplitType.equal,
          splits: [
            ExpenseSplit(userId: uid, share: 85000),
            ExpenseSplit(userId: rahul, share: 85000),
            ExpenseSplit(userId: priya, share: 85000),
            ExpenseSplit(userId: amit, share: 85000),
          ],
          date: yesterday,
        ),
        Expense(
          id: 'e4', groupId: 'demo_goa', description: 'Water sports',
          amount: 280000, category: 'Entertainment', paidBy: amit,
          splitType: SplitType.equal,
          splits: [
            ExpenseSplit(userId: uid, share: 70000),
            ExpenseSplit(userId: rahul, share: 70000),
            ExpenseSplit(userId: priya, share: 70000),
            ExpenseSplit(userId: amit, share: 70000),
          ],
          date: yesterday,
        ),
        Expense(
          id: 'e5', groupId: 'demo_goa', description: 'Breakfast + chai',
          amount: 82000, category: 'Food', paidBy: uid,
          splitType: SplitType.equal,
          splits: [
            ExpenseSplit(userId: uid, share: 20500),
            ExpenseSplit(userId: rahul, share: 20500),
            ExpenseSplit(userId: priya, share: 20500),
            ExpenseSplit(userId: amit, share: 20500),
          ],
          date: todayNoon,
        ),
        // Flat expenses
        Expense(
          id: 'e6', groupId: 'demo_flat', description: 'June Rent',
          amount: 2700000, category: 'Other', paidBy: uid,
          splitType: SplitType.equal,
          splits: [
            ExpenseSplit(userId: uid, share: 900000),
            ExpenseSplit(userId: rahul, share: 900000),
            ExpenseSplit(userId: priya, share: 900000),
          ],
          date: DateTime(2026, 6, 21, 9, 0),
        ),
        Expense(
          id: 'e7', groupId: 'demo_flat', description: 'Electricity bill',
          amount: 87000, category: 'Other', paidBy: rahul,
          splitType: SplitType.equal,
          splits: [
            ExpenseSplit(userId: uid, share: 29000),
            ExpenseSplit(userId: rahul, share: 29000),
            ExpenseSplit(userId: priya, share: 29000),
          ],
          date: yesterday,
        ),
        Expense(
          id: 'e8', groupId: 'demo_flat', description: 'Swiggy order 🍕',
          amount: 135000, category: 'Food', paidBy: priya,
          splitType: SplitType.equal,
          splits: [
            ExpenseSplit(userId: uid, share: 45000),
            ExpenseSplit(userId: rahul, share: 45000),
            ExpenseSplit(userId: priya, share: 45000),
          ],
          date: todayNoon,
        ),
        // Weekend Getaway expenses (User owes Rahul)
        Expense(
          id: 'e9', groupId: 'demo_trip', description: 'Villa Booking',
          amount: 1200000, category: 'Travel', paidBy: rahul,
          splitType: SplitType.equal,
          splits: [
            ExpenseSplit(userId: uid, share: 300000),
            ExpenseSplit(userId: rahul, share: 300000),
            ExpenseSplit(userId: priya, share: 300000),
            ExpenseSplit(userId: amit, share: 300000),
          ],
          date: yesterday,
        ),
        Expense(
          id: 'e10', groupId: 'demo_trip', description: 'Fuel & Tolls',
          amount: 400000, category: 'Transport', paidBy: amit,
          splitType: SplitType.equal,
          splits: [
            ExpenseSplit(userId: uid, share: 100000),
            ExpenseSplit(userId: rahul, share: 100000),
            ExpenseSplit(userId: priya, share: 100000),
            ExpenseSplit(userId: amit, share: 100000),
          ],
          date: yesterday,
        ),
      ];

      await _saveData();
    }


    _broadcastAll();
  }

  Future<void> _saveData() async {
    if (_dataFile == null) return;
    final Map<String, dynamic> data = {
      'groups': _groups.map((e) => e.toJson()).toList(),
      'expenses': _expenses.map((e) => e.toJson()).toList(),
      'settlements': _settlements.map((e) => e.toJson()).toList(),
    };
    await _dataFile!.writeAsString(jsonEncode(data));
  }

  void _broadcastAll() {
    if (!_groupsController.isClosed) _groupsController.add(List.from(_groups));
    if (!_expensesController.isClosed) _expensesController.add(List.from(_expenses));
    if (!_settlementsController.isClosed) _settlementsController.add(List.from(_settlements));
  }

  // --- Groups ---

  Stream<List<Group>> streamUserGroups(String userId) {
    // Immediately emit current state whenever someone listens
    Future.microtask(_broadcastAll);
    return _groupsController.stream
        .map((groups) => groups.where((g) => g.members.contains(userId)).toList());
  }

  List<Group> getUserGroups(String userId) {
    return _groups.where((g) => g.members.contains(userId)).toList();
  }

  Future<void> createGroup(Group group) async {
    _groups.add(group);
    await _saveData();
    _broadcastAll();
  }

  bool joinGroupByCode(String code, String userId) {
    final idx = _groups.indexWhere(
        (g) => g.inviteCode.toUpperCase() == code.toUpperCase());
    if (idx == -1) return false;
    final g = _groups[idx];
    if (!g.members.contains(userId)) {
      _groups[idx] = Group(
        id: g.id,
        name: g.name,
        inviteCode: g.inviteCode,
        members: [...g.members, userId],
        currency: g.currency,
        createdAt: g.createdAt,
      );
      _saveData();
      _broadcastAll();
    }
    return true;
  }

  // --- Expenses ---

  Stream<List<Expense>> streamGroupExpenses(String groupId) {
    Future.microtask(_broadcastAll);
    return _expensesController.stream
        .map((expenses) => expenses.where((e) => e.groupId == groupId).toList());
  }

  List<Expense> getGroupExpenses(String groupId) {
    return _expenses.where((e) => e.groupId == groupId).toList();
  }

  List<Expense> getUserExpenses(String userId) {
    return _expenses.where((e) => e.paidBy == userId || e.splits.any((s) => s.userId == userId)).toList();
  }

  Future<void> addExpense(Expense expense) async {
    _expenses.add(expense);
    await _saveData();
    _broadcastAll();
  }

  // --- Settlements ---

  Stream<List<Settlement>> streamGroupSettlements(String groupId) {
    Future.microtask(_broadcastAll);
    return _settlementsController.stream
        .map((settlements) => settlements.where((s) => s.groupId == groupId).toList());
  }

  Future<void> addSettlement(Settlement settlement) async {
    _settlements.add(settlement);
    await _saveData();
    _broadcastAll();
  }

  Future<void> confirmSettlement(String settlementId, String txnRef) async {
    final index = _settlements.indexWhere((s) => s.id == settlementId);
    if (index != -1) {
      final old = _settlements[index];
      _settlements[index] = Settlement(
        id: old.id,
        groupId: old.groupId,
        fromUserId: old.fromUserId,
        toUserId: old.toUserId,
        amount: old.amount,
        status: 'confirmed',
        upiTxnRef: txnRef,
        createdAt: old.createdAt,
      );
      await _saveData();
      _broadcastAll();
    }
  }

  void dispose() {
    _groupsController.close();
    _expensesController.close();
    _settlementsController.close();
  }
}
