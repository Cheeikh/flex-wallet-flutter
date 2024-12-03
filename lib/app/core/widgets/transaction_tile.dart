import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/transaction_model.dart';
import 'package:get/get.dart';
import '../../modules/auth/controllers/auth_controller.dart';
import '../../data/models/user_model.dart';
import '../../services/user_service.dart';
import '../../modules/client/controllers/client_controller.dart';

class TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onCancel;
  final VoidCallback? onTap;
  final String? currentUserId;

  const TransactionTile({
    Key? key,
    required this.transaction,
    this.onCancel,
    this.onTap,
    this.currentUserId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA');
    final isSender = transaction.fromUserId == currentUserId;

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: _getStatusColor(transaction.status).withOpacity(0.1),
        child: Icon(
          _getStatusIcon(transaction.status),
          color: _getStatusColor(transaction.status),
        ),
      ),
      title: Row(
        children: [
          Icon(
            isSender ? Icons.arrow_upward : Icons.arrow_downward,
            size: 16,
            color: isSender ? Colors.red : Colors.green,
          ),
          const SizedBox(width: 8),
          Text(
            currencyFormat.format(transaction.amount),
            style: TextStyle(
              color: isSender ? Colors.red : Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (transaction.status == TransactionStatus.failed)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(
                Icons.error,
                color: Colors.red,
                size: 16,
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(DateFormat.yMMMd().add_jm().format(transaction.createdAt)),
          if (transaction.description?.isNotEmpty ?? false)
            Text(
              transaction.description!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          if (transaction.status == TransactionStatus.failed)
            Text(
              transaction.failureReason ?? 'Erreur inconnue',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
        ],
      ),
      trailing: _buildTrailingWidget(),
    );
  }

  Widget? _buildTrailingWidget() {
    if (transaction.status == TransactionStatus.failed && transaction.retryCount < 3) {
      return IconButton(
        icon: const Icon(Icons.refresh),
        color: Colors.blue,
        onPressed: () => Get.find<ClientController>().retryFailedTransfer(
          transaction.id,
          transaction.toUserId,
        ),
        tooltip: 'Réessayer',
      );
    }
    
    if (transaction.canBeCanceled && 
        transaction.status != TransactionStatus.canceled &&
        transaction.status != TransactionStatus.failed) {
      return IconButton(
        icon: const Icon(Icons.cancel),
        color: Colors.red,
        onPressed: onCancel,
        tooltip: 'Annuler',
      );
    }

    return null;
  }

  Color _getStatusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.success:
        return Colors.green;
      case TransactionStatus.failed:
        return Colors.red;
      case TransactionStatus.pending:
        return Colors.orange;
      case TransactionStatus.retrying:
        return Colors.blue;
      case TransactionStatus.canceled:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.success:
        return Icons.check_circle;
      case TransactionStatus.failed:
        return Icons.error;
      case TransactionStatus.pending:
        return Icons.hourglass_empty;
      case TransactionStatus.retrying:
        return Icons.refresh;
      case TransactionStatus.canceled:
        return Icons.cancel;
    }
  }
}

extension TransactionStatusX on TransactionStatus {
  bool get isFinal => this == TransactionStatus.success || 
                      this == TransactionStatus.canceled;
} 