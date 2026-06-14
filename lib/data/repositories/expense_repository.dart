import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hotel_management_system/core/local/offline_local_read_service.dart';
import 'package:hotel_management_system/core/utils/offline_firestore_write_queue_service.dart';
import 'package:hotel_management_system/data/models/expense_model.dart';

class ExpenseRepository {
  final String businessId;
  final String branchId;
  final FirebaseFirestore _firestore;

  ExpenseRepository({
    required this.businessId,
    required this.branchId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _expensesCollection =>
      _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('branches')
          .doc(branchId)
          .collection('expenses');

  DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
      final ms = int.tryParse(value);
      if (ms != null) return DateTime.fromMillisecondsSinceEpoch(ms);
    }
    return null;
  }

  String _businessDayIdFromStart(DateTime startAt) {
    final y = startAt.year.toString().padLeft(4, '0');
    final m = startAt.month.toString().padLeft(2, '0');
    final d = startAt.day.toString().padLeft(2, '0');
    final h = startAt.hour.toString().padLeft(2, '0');
    final min = startAt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d-$h$min';
  }

  DateTime _fixedBusinessDayStartAtUtc([DateTime? now]) {
    final localNow = (now ?? DateTime.now()).toLocal();
    final fourAmToday = DateTime(
      localNow.year,
      localNow.month,
      localNow.day,
      4,
      0,
      0,
    );

    final startLocal = localNow.isBefore(fourAmToday)
        ? fourAmToday.subtract(const Duration(days: 1))
        : fourAmToday;

    return startLocal.toUtc();
  }

  Future<List<ExpenseModel>> getExpensesByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final snapshot = await _expensesCollection
        .where('expenseDate', isGreaterThanOrEqualTo: startDate)
        .where('expenseDate', isLessThanOrEqualTo: endDate)
        .orderBy('expenseDate', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => ExpenseModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<List<ExpenseModel>> getAllExpenses() async {
    // Cloud-first strategy: prefer cloud when online, fall back to local when offline
    try {
      // Try to load from cloud first
      final snapshot = await _expensesCollection
          .orderBy('expenseDate', descending: true)
          .get();

      final expenses = snapshot.docs
          .map((doc) => ExpenseModel.fromMap(doc.data(), doc.id))
          .toList();

      return expenses;
    } catch (e) {
      // If cloud read fails (offline), fall back to local
      debugPrint('Cloud read failed, using local cache: $e');
      final localRows = await OfflineLocalReadService.instance
          .getBranchCollection(
            businessId: businessId,
            branchId: branchId,
            collectionName: 'expenses',
          );

      if (localRows.isEmpty) {
        return [];
      }

      return localRows
          .map(
            (doc) => ExpenseModel.fromMap(
              doc,
              (doc['__documentId'] ?? '').toString(),
            ),
          )
          .toList();
    }
  }

  Future<ExpenseModel> addExpense(ExpenseModel expense) async {
    final docRef = _expensesCollection.doc(
      expense.id.isEmpty ? null : expense.id,
    );
    final currentDayStartAt = _fixedBusinessDayStartAtUtc();
    final toSave = expense.copyWith(
      id: docRef.id,
      businessDayStartAt: currentDayStartAt,
      businessDayId: _businessDayIdFromStart(currentDayStartAt),
      createdAt: expense.createdAt,
      updatedAt: DateTime.now(),
    );

    await OfflineFirestoreWriteQueueService.instance.setOrQueue(
      documentPath:
          'businesses/$businessId/branches/$branchId/expenses/${docRef.id}',
      data: toSave.toMap(),
      merge: false,
    );
    return toSave;
  }

  Future<List<ExpenseModel>> getCurrentBusinessDayExpenses(
    DateTime businessDayStartAt,
  ) async {
    final businessDayEndAt = businessDayStartAt.add(const Duration(days: 1));

    final localRows = await OfflineLocalReadService.instance
        .getBranchCollection(
          businessId: businessId,
          branchId: branchId,
          collectionName: 'expenses',
        );
    if (localRows.isNotEmpty) {
      return localRows
          .map(
            (doc) => ExpenseModel.fromMap(
              doc,
              (doc['__documentId'] ?? '').toString(),
            ),
          )
          .where((expense) {
            final marker = expense.businessDayStartAt;
            if (marker != null) {
              return marker.millisecondsSinceEpoch ==
                  businessDayStartAt.millisecondsSinceEpoch;
            }
            return !expense.expenseDate.isBefore(businessDayStartAt) &&
                expense.expenseDate.isBefore(businessDayEndAt);
          })
          .toList();
    }

    final snapshot = await _expensesCollection
        .where('businessDayStartAt', isEqualTo: businessDayStartAt)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final expenses = snapshot.docs
          .map((doc) => ExpenseModel.fromMap(doc.data(), doc.id))
          .toList();
      expenses.sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
      return expenses;
    }

    final fallbackSnapshot = await _expensesCollection
        .where('expenseDate', isGreaterThanOrEqualTo: businessDayStartAt)
        .where('expenseDate', isLessThan: businessDayEndAt)
        .orderBy('expenseDate', descending: true)
        .get();
    return fallbackSnapshot.docs
        .map((doc) => ExpenseModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    await OfflineFirestoreWriteQueueService.instance.setOrQueue(
      documentPath:
          'businesses/$businessId/branches/$branchId/expenses/${expense.id}',
      data: expense.copyWith(updatedAt: DateTime.now()).toMap(),
      merge: true,
    );
  }

  Future<void> deleteExpense(String expenseId) async {
    await OfflineFirestoreWriteQueueService.instance.deleteOrQueue(
      documentPath:
          'businesses/$businessId/branches/$branchId/expenses/$expenseId',
    );
  }
}
