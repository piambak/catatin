// lib/models/transaction_model.dart

import 'package:flutter/material.dart';

// ── Kategori transaksi ────────────────────────────────────────────────────────

class TxCategoryData {
  final String id;
  final String name;
  final String type; // INCOME | EXPENSE
  final bool taxRelevant;
  final bool isCogs;
  final String icon;
  final String color;

  const TxCategoryData({
    required this.id,
    required this.name,
    required this.type,
    required this.taxRelevant,
    required this.isCogs,
    required this.icon,
    required this.color,
  });

  bool get isIncome => type == 'INCOME';

  factory TxCategoryData.fromJson(Map<String, dynamic> j) => TxCategoryData(
        id: j['id'] as String,
        name: j['name'] as String,
        type: j['type'] as String,
        taxRelevant: j['tax_relevant'] as bool? ?? false,
        isCogs: j['is_cogs'] as bool? ?? false,
        icon: j['icon'] as String? ?? '💰',
        color: j['color'] as String? ?? '#6B7280',
      );

  Color get flutterColor {
    try {
      return Color(int.parse('FF${color.replaceFirst('#', '')}', radix: 16));
    } catch (_) {
      return const Color(0xFF6B7280);
    }
  }
}

// ── Transaksi ─────────────────────────────────────────────────────────────────

class TxData {
  final String id;
  final String businessId;
  final DateTime date;
  final String type;
  final double amount;
  final TxCategoryData category;
  final String? description;
  final String paymentMethod;
  final String? receiptNote;
  final DateTime createdAt;
  final bool isFavorite;

  const TxData({
    required this.id,
    required this.businessId,
    required this.date,
    required this.type,
    required this.amount,
    required this.category,
    this.description,
    required this.paymentMethod,
    this.receiptNote,
    required this.createdAt,
    this.isFavorite = false,
  });

  bool get isIncome => type == 'INCOME';

  TxData copyWith({double? amount, bool? isFavorite}) => TxData(
        id: id,
        businessId: businessId,
        date: date,
        type: type,
        amount: amount ?? this.amount,
        category: category,
        description: description,
        paymentMethod: paymentMethod,
        receiptNote: receiptNote,
        createdAt: createdAt,
        isFavorite: isFavorite ?? this.isFavorite,
      );

  factory TxData.fromJson(Map<String, dynamic> j) => TxData(
        id: j['id'] as String,
        businessId: j['business_id'] as String,
        date: DateTime.parse(j['date'] as String),
        type: j['type'] as String,
        amount: (j['amount'] as num).toDouble(),
        category:
            TxCategoryData.fromJson(j['category'] as Map<String, dynamic>),
        description: j['description'] as String?,
        paymentMethod: j['payment_method'] as String? ?? 'CASH',
        receiptNote: j['receipt_note'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}

// ── Input transaksi ───────────────────────────────────────────────────────────

/// Data yang dikirim saat membuat transaksi baru.
class TransactionDraft {
  final String businessId;

  /// Format `YYYY-MM-DD`.
  final String date;
  final String type; // INCOME | EXPENSE
  final double amount;
  final String categoryId;
  final String? description;
  final String paymentMethod;
  final String? receiptNote;

  const TransactionDraft({
    required this.businessId,
    required this.date,
    required this.type,
    required this.amount,
    required this.categoryId,
    this.description,
    required this.paymentMethod,
    this.receiptNote,
  });

  Map<String, dynamic> toJson() => {
        'business_id': businessId,
        'date': date,
        'type': type,
        'amount': amount,
        'category_id': categoryId,
        'description': description,
        'payment_method': paymentMethod,
        'receipt_note': receiptNote,
      };
}

// ── Ringkasan bulanan ─────────────────────────────────────────────────────────

class TxSummary {
  final double income;
  final double expense;
  final double profit;
  final int count;

  const TxSummary({
    required this.income,
    required this.expense,
    required this.profit,
    required this.count,
  });

  factory TxSummary.fromList(List<TxData> txs) {
    double inc = 0, exp = 0;
    for (final t in txs) {
      if (t.isIncome) {
        inc += t.amount;
      } else {
        exp += t.amount;
      }
    }
    return TxSummary(
        income: inc, expense: exp, profit: inc - exp, count: txs.length);
  }
}

// ── Metode pembayaran ─────────────────────────────────────────────────────────

class PaymentMethodData {
  final String value;
  final String label;
  final String icon;

  const PaymentMethodData({
    required this.value,
    required this.label,
    required this.icon,
  });

  static const all = [
    PaymentMethodData(value: 'CASH', label: 'Tunai', icon: '💵'),
    PaymentMethodData(value: 'TRANSFER', label: 'Transfer', icon: '🏦'),
    PaymentMethodData(value: 'QRIS', label: 'QRIS', icon: '📱'),
    PaymentMethodData(value: 'KARTU_DEBIT', label: 'Debit', icon: '💳'),
    PaymentMethodData(value: 'KARTU_KREDIT', label: 'Kredit', icon: '💳'),
    PaymentMethodData(value: 'COD', label: 'COD', icon: '📦'),
    PaymentMethodData(value: 'OTHER', label: 'Lainnya', icon: '·'),
  ];
}
