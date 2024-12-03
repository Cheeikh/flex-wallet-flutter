import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionStatus {
  pending,
  success,
  failed,
  retrying,
  canceled
}

enum TransactionType {
  transfer,
  deposit,
  withdrawal,
  canceledTransfer,
  recurringTransfer
}

class TransactionModel {
  final String id;
  final String fromUserId;
  final String toUserId;
  final double amount;
  final TransactionType type;
  final DateTime createdAt;
  final String? description;
  final bool isCancelable;
  final DateTime? cancelableUntil;
  final DateTime? canceledAt;
  final TransactionStatus status;
  final String? failureReason;
  final int retryCount;
  final DateTime? lastRetryAt;

  TransactionModel({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.amount,
    required this.type,
    required this.createdAt,
    this.description,
    this.isCancelable = true,
    this.cancelableUntil,
    this.canceledAt,
    this.status = TransactionStatus.pending,
    this.failureReason,
    this.retryCount = 0,
    this.lastRetryAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'amount': amount,
      'type': type.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'description': description,
      'isCancelable': isCancelable,
      'cancelableUntil': cancelableUntil != null ? Timestamp.fromDate(cancelableUntil!) : null,
      'canceledAt': canceledAt != null ? Timestamp.fromDate(canceledAt!) : null,
      'status': status.toString().split('.').last,
      'failureReason': failureReason,
      'retryCount': retryCount,
      'lastRetryAt': lastRetryAt != null ? Timestamp.fromDate(lastRetryAt!) : null,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] ?? '',
      fromUserId: map['fromUserId'] ?? '',
      toUserId: map['toUserId'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      type: TransactionType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => TransactionType.transfer,
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      description: map['description'],
      isCancelable: map['isCancelable'] ?? true,
      cancelableUntil: map['cancelableUntil'] != null ? (map['cancelableUntil'] as Timestamp).toDate() : null,
      canceledAt: map['canceledAt'] != null ? (map['canceledAt'] as Timestamp).toDate() : null,
      status: TransactionStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => TransactionStatus.pending,
      ),
      failureReason: map['failureReason'],
      retryCount: map['retryCount'] ?? 0,
      lastRetryAt: map['lastRetryAt'] != null ? (map['lastRetryAt'] as Timestamp).toDate() : null,
    );
  }

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    return TransactionModel.fromMap(doc.data() as Map<String, dynamic>);
  }

  bool get canBeCanceled {
    if (!isCancelable) return false;
    if (cancelableUntil == null) return true;
    return DateTime.now().isBefore(cancelableUntil!);
  }
} 