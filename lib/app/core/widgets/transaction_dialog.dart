import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'custom_text_field.dart';

class TransactionDialog extends StatelessWidget {
  final String title;
  final String buttonText;
  final Function(String phone, double amount, String? description) onConfirm;
  final bool showPhone;

  const TransactionDialog({
    super.key,
    required this.title,
    required this.buttonText,
    required this.onConfirm,
    this.showPhone = true,
  });

  @override
  Widget build(BuildContext context) {
    final phoneController = TextEditingController();
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();

    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showPhone)
              CustomTextField(
                controller: phoneController,
                label: 'Numéro de téléphone',
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Veuillez entrer un numéro';
                  }
                  return null;
                },
              ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: amountController,
              label: 'Montant',
              prefixIcon: Icons.attach_money,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Veuillez entrer un montant';
                }
                final amount = double.tryParse(value!);
                if (amount == null || amount <= 0) {
                  return 'Montant invalide';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: descriptionController,
              label: 'Description (optionnel)',
              prefixIcon: Icons.description,
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            final amount = double.tryParse(amountController.text);
            if (amount != null) {
              onConfirm(
                phoneController.text,
                amount,
                descriptionController.text.isEmpty ? null : descriptionController.text,
              );
              Get.back();
            }
          },
          child: Text(buttonText),
        ),
      ],
    );
  }
} 