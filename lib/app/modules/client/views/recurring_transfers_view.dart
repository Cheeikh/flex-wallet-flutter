import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import '../controllers/client_controller.dart';
import '../../../data/models/recurring_transfer_model.dart';
import '../../../routes/app_pages.dart';

class RecurringTransfersView extends GetView<ClientController> {
  const RecurringTransfersView({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transferts récurrents'),
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.recurringTransfers.isEmpty) {
          return Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 800),
                      tween: Tween(begin: 0, end: 1),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Opacity(
                            opacity: value,
                            child: Icon(
                              Icons.repeat_rounded,
                              size: 120,
                              color: Colors.grey[400],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Aucun transfert récurrent',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Programmez des transferts automatiques',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => Get.toNamed(Routes.CREATE_RECURRING_TRANSFER),
                      icon: const Icon(Icons.add),
                      label: const Text('Créer un transfert récurrent'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.refreshData(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.recurringTransfers.length,
            itemBuilder: (context, index) {
              final transfer = controller.recurringTransfers[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildTransferCard(context, transfer, currencyFormat),
              );
            },
          ),
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(Routes.CREATE_RECURRING_TRANSFER),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau transfert'),
        elevation: 4,
      ),
    );
  }

  Widget _buildTransferCard(
    BuildContext context,
    RecurringTransferModel transfer,
    NumberFormat currencyFormat,
  ) {
    return Obx(() {
      final isActive = controller.recurringTransfers
          .firstWhere((t) => t.id == transfer.id)
          .isActive;

      return Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: () => _showTransferDetails(context, transfer, currencyFormat),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.repeat,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currencyFormat.format(transfer.amount),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            'Vers: ${transfer.toPhone}',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: isActive,
                      onChanged: (value) => controller.toggleRecurringTransfer(transfer.id),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoChip(
                      context,
                      Icons.calendar_today,
                      transfer.frequency.name.capitalizeFirst!,
                    ),
                    _buildInfoChip(
                      context,
                      Icons.update,
                      'Prochain: ${DateFormat.yMMMd().format(transfer.getNextExecutionDate())}',
                    ),
                  ],
                ),
                if (transfer.description?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 12),
                  Text(
                    transfer.description!,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  DateTime _calculateNextExecution(RecurringTransferModel transfer) {
    final lastExecution = transfer.lastExecuted ?? transfer.startDate;
    
    switch (transfer.frequency) {
      case RecurringFrequency.daily:
        return lastExecution.add(const Duration(days: 1));
      case RecurringFrequency.weekly:
        return lastExecution.add(const Duration(days: 7));
      case RecurringFrequency.monthly:
        return DateTime(
          lastExecution.year,
          lastExecution.month + 1,
          lastExecution.day,
        );
      case RecurringFrequency.yearly:
        return DateTime(
          lastExecution.year + 1,
          lastExecution.month,
          lastExecution.day,
        );
    }
  }

  void _toggleTransferStatus(RecurringTransferModel transfer) {
    Get.dialog(
      AlertDialog(
        title: Text(
          transfer.isActive ? 'Désactiver le transfert' : 'Activer le transfert',
        ),
        content: Text(
          transfer.isActive
              ? 'Voulez-vous désactiver ce transfert récurrent ?'
              : 'Voulez-vous réactiver ce transfert récurrent ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.toggleRecurringTransfer(transfer.id);
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: transfer.isActive ? Colors.red : Colors.green,
            ),
            child: Text(transfer.isActive ? 'Désactiver' : 'Activer'),
          ),
        ],
      ),
    );
  }

  void _showTransferDetails(
    BuildContext context,
    RecurringTransferModel transfer,
    NumberFormat currencyFormat,
  ) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Détails du transfert',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDetailRow('Montant', currencyFormat.format(transfer.amount)),
            _buildDetailRow('Destinataire', transfer.toPhone),
            _buildDetailRow('Fréquence', transfer.frequency.name.capitalizeFirst!),
            _buildDetailRow('Date de début', DateFormat.yMMMd().format(transfer.startDate)),
            if (transfer.endDate != null)
              _buildDetailRow('Date de fin', DateFormat.yMMMd().format(transfer.endDate!)),
            if (transfer.lastExecuted != null)
              _buildDetailRow('Dernière exécution', DateFormat.yMMMd().format(transfer.lastExecuted!)),
            if (transfer.description?.isNotEmpty ?? false)
              _buildDetailRow('Description', transfer.description!),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _confirmDeleteTransfer(transfer),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Supprimer'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Get.back();
                      _toggleTransferStatus(transfer);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: transfer.isActive ? Colors.red : Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(transfer.isActive ? 'Désactiver' : 'Activer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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

  void _confirmDeleteTransfer(RecurringTransferModel transfer) {
    Get.back(); // Fermer la bottom sheet des détails
    Get.dialog(
      AlertDialog(
        title: const Text('Supprimer le transfert'),
        content: const Text(
          'Voulez-vous vraiment supprimer ce transfert récurrent ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.deleteRecurringTransfer(transfer.id);
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
} 