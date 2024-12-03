import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:lottie/lottie.dart';
import '../../controllers/client_controller.dart';
import 'package:intl/intl.dart';
import 'package:get_storage/get_storage.dart';
import 'dart:convert';
import '../../../auth/controllers/auth_controller.dart';

class TransferBottomSheet extends GetView<ClientController> {
  TransferBottomSheet({super.key});

  final formKey = GlobalKey<FormState>();
  final phoneController = TextEditingController();
  final amountController = TextEditingController();
  final descriptionController = TextEditingController();
  final selectedContacts = <Contact>[].obs;
  final phoneText = ''.obs;
  final amountText = ''.obs;
  final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA');

  @override
  Widget build(BuildContext context) {
    phoneController.addListener(() {
      phoneText.value = phoneController.text;
    });

    amountController.addListener(() {
      amountText.value = amountController.text;
    });

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
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),
              _buildBalanceInfo(context),
              const SizedBox(height: 24),
              
              // Champ de saisie manuelle du numéro
              _buildPhoneField(context),
              const SizedBox(height: 8),
              
              // Texte "OU"
              Center(
                child: Text(
                  'OU',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              
              // Liste des contacts sélectionnés
              _buildSelectedContacts(),
              
              // Bouton d'ajout de contact
              _buildAddContactButton(context),
              const SizedBox(height: 16),
              
              _buildAmountField(),
              const SizedBox(height: 16),
              _buildDescriptionField(),
              const SizedBox(height: 24),
              
              _buildTransferButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transfert groupé',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Obx(() => Text(
              '${selectedContacts.length} ${selectedContacts.length <= 1 ? 'destinataire' : 'destinataires'}',
              style: Theme.of(context).textTheme.bodySmall,
            )),
          ],
        ),
        IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.close),
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.account_balance_wallet,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Solde disponible',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Obx(() => Text(
                currencyFormat.format(controller.balance.value),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneField(BuildContext context) {
    final currentUserPhone = Get.find<AuthController>().currentUser?.phone ?? '';
    
    return TextFormField(
      controller: phoneController,
      decoration: InputDecoration(
        labelText: 'Numéro de téléphone',
        hintText: 'Ex: 77 123 45 67',
        prefixIcon: const Icon(Icons.phone),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        suffixIcon: Obx(() => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (phoneText.value.isNotEmpty)
              SizedBox(
                width: 40,
                child: IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    phoneController.clear();
                    phoneText.value = '';
                  },
                ),
              ),
            SizedBox(
              width: 40,
              child: IconButton(
                icon: const Icon(Icons.contacts, size: 20),
                onPressed: () => _showContactPicker(context),
              ),
            ),
          ],
        )),
      ),
      keyboardType: TextInputType.phone,
      onChanged: (value) {
        phoneText.value = value;
        if (value.isNotEmpty) {
          selectedContacts.clear();
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          if (selectedContacts.isEmpty) {
            return 'Veuillez entrer un numéro ou sélectionner un contact';
          }
        } else if (value.length < 9) {
          return 'Numéro invalide';
        } else if (value == currentUserPhone) {
          return 'Vous ne pouvez pas transférer à votre propre numéro';
        }
        return null;
      },
    );
  }

  Widget _buildSelectedContacts() {
    return Obx(() => selectedContacts.isEmpty
      ? const SizedBox.shrink()
      : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contacts sélectionnés',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 90,
              margin: const EdgeInsets.only(bottom: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: selectedContacts.length,
                itemBuilder: (context, index) {
                  final contact = selectedContacts[index];
                  return _buildContactChip(contact);
                },
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildContactChip(Contact contact) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: Theme.of(Get.context!).primaryColor.withOpacity(0.1),
                child: Text(
                  contact.displayName[0].toUpperCase(),
                  style: TextStyle(
                    color: Theme.of(Get.context!).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    selectedContacts.remove(contact);
                    HapticFeedback.lightImpact();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(Get.context!).scaffoldBackgroundColor,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            contact.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildAddContactButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _showContactPicker(context),
      icon: const Icon(Icons.person_add),
      label: const Text('Ajouter des destinataires'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _showContactPicker(BuildContext context) async {
    // Charger les contacts si ce n'est pas déjà fait
    if (controller.registeredContacts.isEmpty) {
      await controller.loadRegisteredContacts();
    }

    Get.bottomSheet(
      Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sélectionner des contacts',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Obx(() => Text(
                        '${controller.registeredContacts.length} contacts inscrits',
                        style: Theme.of(context).textTheme.bodySmall,
                      )),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            
            // Switch pour afficher tous les contacts
            Obx(() => SwitchListTile(
              title: const Text('Afficher tous les contacts'),
              subtitle: Text(
                controller.isLoadingContacts.value
                    ? 'Chargement...'
                    : 'Affiche actuellement : ${controller.showAllContacts.value ? "Tous les contacts" : "Contacts inscrits uniquement"}',
              ),
              value: controller.showAllContacts.value,
              onChanged: (value) {
                controller.showAllContacts.value = value;
              },
            )),

            // Barre de recherche
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Rechercher un contact...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) => controller.searchQuery.value = value,
              ),
            ),

            const SizedBox(height: 8),

            // Liste des contacts
            Expanded(
              child: Obx(() {
                if (controller.isLoadingContacts.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                final contacts = controller.showAllContacts.value
                    ? controller.allContacts
                    : controller.registeredContacts;

                final filteredContacts = contacts.where((contact) {
                  final query = controller.searchQuery.value.toLowerCase();
                  return contact.displayName.toLowerCase().contains(query) ||
                      contact.phones.any((phone) => phone.number.contains(query));
                }).toList();

                return ListView.builder(
                  itemCount: filteredContacts.length,
                  itemBuilder: (context, index) {
                    final contact = filteredContacts[index];
                    final isRegistered = controller.registeredContacts
                        .any((c) => c.id == contact.id);
                    final isSelected = selectedContacts.contains(contact);

                    return ListTile(
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                            child: Text(contact.displayName[0].toUpperCase()),
                          ),
                          if (isRegistered)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Theme.of(context).scaffoldBackgroundColor,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.check,
                                  size: 10,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      title: Text(
                        contact.displayName,
                        style: TextStyle(
                          fontWeight: isRegistered ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(contact.phones.first.number),
                          if (!isRegistered)
                            Text(
                              'Non inscrit',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                      trailing: Checkbox(
                        value: isSelected,
                        onChanged: (bool? value) {
                          if (value == true) {
                            selectedContacts.add(contact);
                          } else {
                            selectedContacts.remove(contact);
                          }
                          HapticFeedback.selectionClick();
                        },
                      ),
                      onTap: () {
                        if (isSelected) {
                          selectedContacts.remove(contact);
                        } else {
                          selectedContacts.add(contact);
                        }
                        HapticFeedback.selectionClick();
                      },
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: amountController,
      decoration: InputDecoration(
        labelText: 'Montant',
        prefixIcon: const Icon(Icons.attach_money),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        suffixText: 'FCFA',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      onChanged: (value) {
        amountText.value = value;
      },
      validator: (value) => _validateAmount(value, controller.balance.value),
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: descriptionController,
      decoration: InputDecoration(
        labelText: 'Description (optionnel)',
        prefixIcon: const Icon(Icons.description),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        hintText: 'Ex: Remboursement déjeuner',
      ),
      maxLines: 2,
      maxLength: 100,
    );
  }

  Widget _buildTransferButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Obx(() {
        // Validation du montant
        final amount = double.tryParse(amountText.value);
        final isAmountValid = amount != null && amount > 0;

        // Validation du numéro
        final hasManualNumber = phoneText.value.length >= 9;
        final hasSelectedContacts = selectedContacts.isNotEmpty;
        final hasRecipient = hasManualNumber || hasSelectedContacts;

        // Activation du bouton
        final canTransfer = isAmountValid && hasRecipient && !controller.isLoading.value;

        return ElevatedButton(
          onPressed: canTransfer
              ? () => _handleTransfer(
                  context,
                  formKey,
                  selectedContacts,
                  amountController,
                  descriptionController,
                )
              : null,
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
              : const Text('Transférer'),
        );
      }),
    );
  }

  String? _validateAmount(String? value, double balance) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer un montant';
    }
    final amount = double.tryParse(value);
    if (amount == null || amount <= 0) {
      return 'Montant invalide';
    }
    if (amount > balance) {
      return 'Solde insuffisant';
    }
    return null;
  }

  Future<void> _handleTransfer(
    BuildContext context,
    GlobalKey<FormState> formKey,
    RxList<Contact> selectedContacts,
    TextEditingController amountController,
    TextEditingController descriptionController,
  ) async {
    final currentUserPhone = Get.find<AuthController>().currentUser?.phone ?? '';
    
    if (formKey.currentState!.validate()) {
      final amount = double.parse(amountController.text);
      List<String> phones = [];

      if (phoneController.text.isNotEmpty) {
        // Vérifier si ce n'est pas le numéro de l'utilisateur actuel
        if (phoneController.text == currentUserPhone) {
          Get.snackbar(
            'Erreur',
            'Vous ne pouvez pas transférer à votre propre numéro',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return;
        }
        phones.add(phoneController.text);
      }

      if (selectedContacts.isNotEmpty) {
        // Filtrer les contacts pour exclure le numéro de l'utilisateur actuel
        final validContacts = selectedContacts.where((contact) => 
          contact.phones.first.number != currentUserPhone
        ).toList();

        if (validContacts.length != selectedContacts.length) {
          Get.snackbar(
            'Attention',
            'Votre numéro a été exclu des destinataires',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
          );
        }

        phones.addAll(validContacts
            .map((contact) => contact.phones.first.number)
            .toList());
      }

      if (phones.isEmpty) {
        Get.snackbar(
          'Erreur',
          'Veuillez entrer au moins un numéro de téléphone',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      try {
        // Fermer d'abord la bottom sheet
        Get.back();
        
        // Effectuer le transfert
        await controller.multiTransfer(
          phones: phones,
          amount: amount,
          description: descriptionController.text,
        );
        
        // Afficher le message de succès
        Get.snackbar(
          '',
          '',
          titleText: Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              const Text(
                'Transfert réussi !',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          messageText: Text(
            'Transfert de ${currencyFormat.format(amount)} effectué',
            style: const TextStyle(color: Colors.white),
          ),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.green,
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.all(8),
          borderRadius: 12,
          isDismissible: true,
          dismissDirection: DismissDirection.horizontal,
          forwardAnimationCurve: Curves.easeOutBack,
        );
      } catch (e) {
        Get.snackbar(
          'Erreur',
          'Le transfert a échoué',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          margin: const EdgeInsets.all(8),
          borderRadius: 12,
        );
      }
    }
  }
} 