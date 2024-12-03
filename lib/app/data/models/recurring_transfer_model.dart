import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' show TimeOfDay;

enum RecurringFrequency {
  daily,
  weekly,
  monthly,
  yearly
}

class RecurringTransferModel {
  final String id;
  final String fromUserId;
  final String toPhone;
  final double amount;
  final RecurringFrequency frequency;
  final DateTime startDate;
  final TimeOfDay executionTime;
  final DateTime? endDate;
  final String? description;
  final DateTime? lastExecuted;
  final bool isActive;
  final DateTime createdAt;

  RecurringTransferModel({
    required this.id,
    required this.fromUserId,
    required this.toPhone,
    required this.amount,
    required this.frequency,
    required this.startDate,
    required this.executionTime,
    this.endDate,
    this.description,
    this.lastExecuted,
    this.isActive = true,
    DateTime? createdAt,
  }) : this.createdAt = createdAt ?? DateTime.now();

  factory RecurringTransferModel.fromMap(Map<String, dynamic> map) {
    return RecurringTransferModel(
      id: map['id'] ?? '',
      fromUserId: map['fromUserId'] ?? '',
      toPhone: map['toPhone'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      frequency: RecurringFrequency.values.firstWhere(
        (e) => e.toString() == 'RecurringFrequency.${map['frequency']}',
        orElse: () => RecurringFrequency.monthly,
      ),
      startDate: (map['startDate'] as Timestamp).toDate(),
      executionTime: TimeOfDay(
        hour: map['executionTime']['hour'] ?? 0,
        minute: map['executionTime']['minute'] ?? 0,
      ),
      endDate: map['endDate'] != null ? (map['endDate'] as Timestamp).toDate() : null,
      description: map['description'],
      lastExecuted: map['lastExecuted'] != null ? (map['lastExecuted'] as Timestamp).toDate() : null,
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt'] != null ? (map['createdAt'] as Timestamp).toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fromUserId': fromUserId,
      'toPhone': toPhone,
      'amount': amount,
      'frequency': frequency.toString().split('.').last,
      'startDate': Timestamp.fromDate(startDate),
      'executionTime': {
        'hour': executionTime.hour,
        'minute': executionTime.minute,
      },
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'description': description,
      'lastExecuted': lastExecuted != null ? Timestamp.fromDate(lastExecuted!) : null,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory RecurringTransferModel.fromFirestore(DocumentSnapshot doc) {
    return RecurringTransferModel.fromMap(doc.data() as Map<String, dynamic>);
  }

  bool shouldExecute(DateTime now) {
    if (!isActive) return false;
    
    if (endDate != null && now.isAfter(endDate!)) {
      return false;
    }

    if (now.isBefore(startDate)) {
      return false;
    }

    if (now.hour != executionTime.hour || now.minute != executionTime.minute) {
      return false;
    }

    final lastExec = lastExecuted ?? startDate;
    
    switch (frequency) {
      case RecurringFrequency.daily:
        return now.difference(lastExec).inDays >= 1;
      case RecurringFrequency.weekly:
        return now.difference(lastExec).inDays >= 7;
      case RecurringFrequency.monthly:
        final nextExecution = DateTime(
          lastExec.year,
          lastExec.month + 1,
          lastExec.day,
          executionTime.hour,
          executionTime.minute,
        );
        return now.isAfter(nextExecution);
      case RecurringFrequency.yearly:
        final nextExecution = DateTime(
          lastExec.year + 1,
          lastExec.month,
          lastExec.day,
          executionTime.hour,
          executionTime.minute,
        );
        return now.isAfter(nextExecution);
    }
  }

  DateTime getNextExecutionDate() {
    final now = DateTime.now();
    final lastExec = lastExecuted ?? startDate;
    
    switch (frequency) {
      case RecurringFrequency.daily:
        return DateTime(
          lastExec.year,
          lastExec.month,
          lastExec.day + 1,
          executionTime.hour,
          executionTime.minute,
        );
      case RecurringFrequency.weekly:
        return DateTime(
          lastExec.year,
          lastExec.month,
          lastExec.day + 7,
          executionTime.hour,
          executionTime.minute,
        );
      case RecurringFrequency.monthly:
        return DateTime(
          lastExec.year,
          lastExec.month + 1,
          lastExec.day,
          executionTime.hour,
          executionTime.minute,
        );
      case RecurringFrequency.yearly:
        return DateTime(
          lastExec.year + 1,
          lastExec.month,
          lastExec.day,
          executionTime.hour,
          executionTime.minute,
        );
    }
  }
} 