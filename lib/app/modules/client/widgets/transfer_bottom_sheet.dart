import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/client_controller.dart';

class TransferBottomSheet extends StatefulWidget {
  const TransferBottomSheet({super.key});

  @override
  State<TransferBottomSheet> createState() => _TransferBottomSheetState();
}

class _TransferBottomSheetState extends State<TransferBottomSheet> {
  final controller = Get.find<ClientController>();
  final phoneControllers = <TextEditingController>[TextEditingController()];
  final amountController = TextEditingController();
  final descriptionController = TextEditingController();
  bool isMultiTransfer = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Nouveau transfert',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text('Transfert multiple'),
              value: isMultiTransfer,
              onChanged: (value) {
                setState(() {
                  isMultiTransfer = value;
                  if (!value) {
                    phoneControllers.removeRange(1, phoneControllers.length);
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            ...phoneControllers.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: entry.value,
                        decoration: InputDecoration(
                          labelText: isMultiTransfer
                              ? 'Numéro ${entry.key + 1}'
                              : 'Numéro de téléphone',
                          prefixIcon: const Icon(Icons.phone),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                    if (isMultiTransfer && entry.key > 0)
                      IconButton(
                        icon: const Icon(Icons.remove_circle),
                        onPressed: () {
                          setState(() {
                            phoneControllers.removeAt(entry.key);
                          });
                        },
                      ),
                  ],
                ),
              );
            }),
            if (isMultiTransfer)
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    phoneControllers.add(TextEditingController());
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text('Ajouter un numéro'),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              decoration: InputDecoration(
                labelText: isMultiTransfer
                    ? 'Montant par personne'
                    : 'Montant',
                prefixIcon: const Icon(Icons.attach_money),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: 'Description (optionnel)',
                prefixIcon: const Icon(Icons.description),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleTransfer,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Transférer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleTransfer() {
    final amount = double.tryParse(amountController.text);
    if (amount == null) {
      Get.snackbar('Erreur', 'Montant invalide');
      return;
    }

    if (isMultiTransfer) {
      final phones = phoneControllers
          .map((c) => c.text.trim())
          .where((phone) => phone.isNotEmpty)
          .toList();
      
      if (phones.isEmpty) {
        Get.snackbar('Erreur', 'Veuillez entrer au moins un numéro');
        return;
      }

      controller.multiTransfer(
        phones: phones,
        amount: amount,
        description: descriptionController.text,
      );
    } else {
      controller.transfer(
        toPhone: phoneControllers.first.text,
        amount: amount,
        description: descriptionController.text,
      );
    }
    Get.back();
  }

  @override
  void dispose() {
    for (var controller in phoneControllers) {
      controller.dispose();
    }
    amountController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
} 