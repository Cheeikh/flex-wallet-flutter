import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/client_controller.dart';
import '../../../data/models/recurring_transfer_model.dart';

class CreateRecurringTransferView extends GetView<ClientController> {
  const CreateRecurringTransferView({super.key});

  @override
  Widget build(BuildContext context) {
    final phoneController = TextEditingController();
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    final selectedFrequency = RecurringFrequency.monthly.obs;
    final startDate = DateTime.now().obs;
    final startTime = TimeOfDay.now().obs;
    final endDate = Rxn<DateTime>();
    final formKey = GlobalKey<FormState>();
    final RxBool isPhoneValid = false.obs;
    final RxBool isAmountValid = false.obs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau transfert récurrent'),
        elevation: 0,
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // En-tête explicatif
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.blue,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Programmez des transferts automatiques',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Les transferts seront effectués automatiquement à l\'heure spécifiée selon la fréquence choisie',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Champ téléphone
            TextFormField(
              controller: phoneController,
              decoration: InputDecoration(
                labelText: 'Numéro de téléphone',
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: Obx(() => isPhoneValid.value
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : const SizedBox.shrink()),
              ),
              keyboardType: TextInputType.phone,
              onChanged: (value) {
                isPhoneValid.value = value.length >= 9;
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer un numéro';
                }
                if (value.length < 9) {
                  return 'Numéro invalide';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Champ montant
            TextFormField(
              controller: amountController,
              decoration: InputDecoration(
                labelText: 'Montant',
                prefixIcon: const Icon(Icons.attach_money),
                suffixText: 'FCFA',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: Obx(() => isAmountValid.value
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : const SizedBox.shrink()),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              onChanged: (value) {
                final amount = double.tryParse(value);
                isAmountValid.value = amount != null && amount > 0;
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer un montant';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Montant invalide';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Sélection de la fréquence
            Text(
              'Fréquence',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildFrequencySelector(selectedFrequency),
            const SizedBox(height: 24),

            // Sélection des dates et heures
            Text(
              'Programmation',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Date de début
                    _buildDateSelector(
                      context,
                      'Date de début',
                      startDate.value,
                      (date) => startDate.value = date,
                      Icons.calendar_today,
                      Colors.blue,
                    ),
                    const Divider(height: 24),
                    // Heure d'exécution
                    _buildTimeSelector(
                      context: context,
                      label: "Heure d'exécution",
                      value: startTime.value,
                      onSelect: (time) => startTime.value = time,
                      icon: Icons.access_time,
                      color: Colors.orange,
                    ),
                    const Divider(height: 24),
                    // Date de fin (optionnelle)
                    _buildDateSelector(
                      context,
                      'Date de fin (optionnel)',
                      endDate.value,
                      (date) => endDate.value = date,
                      Icons.event_available,
                      Colors.green,
                      optional: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: 'Description (optionnel)',
                prefixIcon: const Icon(Icons.description),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: 'Ex: Loyer mensuel',
              ),
              maxLines: 2,
              maxLength: 100,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Obx(() => ElevatedButton(
            onPressed: (controller.isLoading.value || !isPhoneValid.value || !isAmountValid.value)
                ? null
                : () {
                    if (formKey.currentState!.validate()) {
                      // Combiner la date et l'heure
                      final startDateTime = DateTime(
                        startDate.value.year,
                        startDate.value.month,
                        startDate.value.day,
                        startTime.value.hour,
                        startTime.value.minute,
                      );
                      
                      controller.createRecurringTransfer(
                        toPhone: phoneController.text,
                        amount: double.parse(amountController.text),
                        frequency: selectedFrequency.value,
                        startDate: startDateTime,
                        executionTime: startTime.value,
                        endDate: endDate.value,
                        description: descriptionController.text,
                      );
                    }
                  },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: controller.isLoading.value
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Créer le transfert récurrent'),
          )),
        ),
      ),
    );
  }

  Widget _buildFrequencySelector(Rx<RecurringFrequency> selectedFrequency) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.5,
      physics: const NeverScrollableScrollPhysics(),
      children: RecurringFrequency.values.map((frequency) {
        return Obx(() {
          final isSelected = selectedFrequency.value == frequency;
          return InkWell(
            onTap: () => selectedFrequency.value = frequency,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(Get.context!).primaryColor
                      : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
                color: isSelected
                    ? Theme.of(Get.context!).primaryColor.withOpacity(0.1)
                    : null,
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getFrequencyIcon(frequency),
                      color: isSelected
                          ? Theme.of(Get.context!).primaryColor
                          : Colors.grey[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getFrequencyLabel(frequency),
                      style: TextStyle(
                        color: isSelected
                            ? Theme.of(Get.context!).primaryColor
                            : Colors.grey[600],
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      }).toList(),
    );
  }

  Widget _buildDateSelector(
    BuildContext context,
    String label,
    DateTime? value,
    Function(DateTime) onSelect,
    IconData icon,
    Color color, {
    bool optional = false,
  }) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
        );
        if (date != null) {
          onSelect(date);
        }
      },
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value != null
                      ? DateFormat.yMMMd().format(value)
                      : optional
                          ? 'Non définie'
                          : 'Sélectionner une date',
                  style: TextStyle(
                    fontWeight: value != null ? FontWeight.bold : FontWeight.normal,
                    color: value != null ? null : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: Colors.grey[400],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSelector({
    required BuildContext context,
    required String label,
    required TimeOfDay value,
    required Function(TimeOfDay) onSelect,
    required IconData icon,
    required Color color,
  }) {
    return InkWell(
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: value,
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                timePickerTheme: TimePickerThemeData(
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  hourMinuteShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  dayPeriodShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              child: child!,
            );
          },
        );
        if (time != null) {
          onSelect(time);
        }
      },
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.format(context),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: Colors.grey[400],
          ),
        ],
      ),
    );
  }

  IconData _getFrequencyIcon(RecurringFrequency frequency) {
    switch (frequency) {
      case RecurringFrequency.daily:
        return Icons.today;
      case RecurringFrequency.weekly:
        return Icons.view_week;
      case RecurringFrequency.monthly:
        return Icons.calendar_view_month;
      case RecurringFrequency.yearly:
        return Icons.calendar_today;
    }
  }

  String _getFrequencyLabel(RecurringFrequency frequency) {
    switch (frequency) {
      case RecurringFrequency.daily:
        return 'Quotidien';
      case RecurringFrequency.weekly:
        return 'Hebdo';
      case RecurringFrequency.monthly:
        return 'Mensuel';
      case RecurringFrequency.yearly:
        return 'Annuel';
    }
  }
} 