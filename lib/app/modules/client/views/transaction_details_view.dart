import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/transaction_model.dart';
import 'package:intl/intl.dart';
import '../controllers/client_controller.dart';

class TransactionDetailsView extends GetView<ClientController> {
  final TransactionModel transaction;
  final String heroTag;
  final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA');

  TransactionDetailsView({
    super.key,
    required this.transaction,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de la transaction'),
      ),
      body: Hero(
        tag: heroTag,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusCard(context),
              const SizedBox(height: 24),
              _buildTransactionDetails(context),
              if (transaction.status == TransactionStatus.failed)
                _buildFailureDetails(context),
              if (_canRetry())
                _buildRetryButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getStatusColor(transaction.status).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getStatusIcon(transaction.status),
                color: _getStatusColor(transaction.status),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getStatusText(transaction.status),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(transaction.status),
                    ),
                  ),
                  if (transaction.status == TransactionStatus.failed)
                    Text(
                      transaction.failureReason ?? 'Erreur inconnue',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionDetails(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Montant', currencyFormat.format(transaction.amount)),
            _buildDetailRow('Date', DateFormat.yMMMd().add_Hm().format(transaction.createdAt)),
            _buildDetailRow('Type', _getTransactionTypeText(transaction.type)),
            if (transaction.description?.isNotEmpty ?? false)
              _buildDetailRow('Description', transaction.description!),
            if (transaction.retryCount > 0)
              _buildDetailRow('Tentatives', '${transaction.retryCount}'),
            if (transaction.lastRetryAt != null)
              _buildDetailRow('Dernière tentative', 
                DateFormat.yMMMd().add_Hm().format(transaction.lastRetryAt!)),
          ],
        ),
      ),
    );
  }

  Widget _buildFailureDetails(BuildContext context) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Détails de l\'échec',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(transaction.failureReason ?? 'Erreur inconnue'),
          ],
        ),
      ),
    );
  }

  Widget _buildRetryButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _retryTransfer(context),
          icon: const Icon(Icons.refresh),
          label: const Text('Réessayer le transfert'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.green,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  bool _canRetry() {
    return transaction.status == TransactionStatus.failed && 
           (transaction.retryCount ?? 0) < 3;
  }

  Future<void> _retryTransfer(BuildContext context) async {
    try {
      await controller.retryFailedTransfer(
        transaction.id,
        transaction.toUserId,
      );
      Get.back(result: true);
      Get.snackbar(
        'Succès',
        'Le transfert a été relancé',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de relancer le transfert',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
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

  String _getStatusText(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.success:
        return 'Transfert réussi';
      case TransactionStatus.failed:
        return 'Échec du transfert';
      case TransactionStatus.pending:
        return 'En attente';
      case TransactionStatus.retrying:
        return 'Relance en cours';
      case TransactionStatus.canceled:
        return 'Annulé';
    }
  }

  String _getTransactionTypeText(TransactionType type) {
    switch (type) {
      case TransactionType.transfer:
        return 'Transfert';
      case TransactionType.deposit:
        return 'Dépôt';
      case TransactionType.withdrawal:
        return 'Retrait';
      case TransactionType.canceledTransfer:
        return 'Transfert annulé';
      case TransactionType.recurringTransfer:
        return 'Transfert programmé';
    }
  }
} 