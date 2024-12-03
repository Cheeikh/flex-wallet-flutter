import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../data/models/transaction_model.dart';
import '../../modules/client/controllers/client_controller.dart';
import 'transaction_tile.dart';

class TransactionList extends StatelessWidget {
  final List<TransactionModel> transactions;
  final String emptyMessage;
  final bool showFilters;
  final String selectedFilter;
  final ValueChanged<String?>? onFilterChanged;

  const TransactionList({
    super.key,
    required this.transactions,
    this.emptyMessage = 'Aucune transaction',
    this.showFilters = true,
    this.selectedFilter = 'all',
    this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (showFilters) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transactions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                DropdownButton<String>(
                  value: selectedFilter,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Tout')),
                    DropdownMenuItem(value: 'today', child: Text('Aujourd\'hui')),
                    DropdownMenuItem(value: 'week', child: Text('Cette semaine')),
                    DropdownMenuItem(value: 'month', child: Text('Ce mois')),
                  ],
                  onChanged: onFilterChanged,
                ),
              ],
            ),
          ),
          const Divider(),
        ],
        Expanded(
          child: ListView.separated(
            itemCount: transactions.length,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              String? dateHeader;
              
              if (index == 0 || !_isSameDay(transactions[index - 1].createdAt, transaction.createdAt)) {
                dateHeader = DateFormat.yMMMd().format(transaction.createdAt);
              }
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (dateHeader != null) ...[
                    if (index != 0) const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        dateHeader,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  TransactionTile(
                    transaction: transaction,
                    onCancel: () => Get.find<ClientController>().cancelTransaction(transaction.id),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
} 