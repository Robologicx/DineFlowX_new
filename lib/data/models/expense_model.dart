import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseModel {
  final String id;
  final String title;
  final String category;
  final double amount;
  final String? note;
  final DateTime expenseDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ExpenseModel({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    this.note,
    required this.expenseDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ExpenseModel.fromMap(Map<String, dynamic> data, String docId) {
    DateTime toDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.now();
    }

    return ExpenseModel(
      id: docId,
      title: (data['title'] ?? '').toString(),
      category: (data['category'] ?? 'General').toString(),
      amount: (data['amount'] ?? 0).toDouble(),
      note: data['note']?.toString(),
      expenseDate: toDate(data['expenseDate']),
      createdAt: toDate(data['createdAt']),
      updatedAt: toDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'category': category,
      'amount': amount,
      'note': note,
      'expenseDate': expenseDate,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  ExpenseModel copyWith({
    String? id,
    String? title,
    String? category,
    double? amount,
    String? note,
    DateTime? expenseDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      expenseDate: expenseDate ?? this.expenseDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
