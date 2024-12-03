import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/distributor_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../data/models/qr_code_data.dart';
import '../../../data/models/transaction_model.dart';

class DistributorDashboardView extends GetView<DistributorController> {
  const DistributorDashboardView({super.key});

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA');
    
    return Scaffold(
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: () => controller.refreshData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBalanceCard(context, currencyFormat),
                const SizedBox(height: 24),
                _buildActionGrid(context),
                const SizedBox(height: 24),
                _buildTransactionsSection(context, currencyFormat),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tableau de bord Distributeur'),
          Obx(() => Text(
            controller.authController.currentUser?.name ?? '',
            style: Get.textTheme.bodySmall,
          )),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.qr_code_scanner),
          onPressed: () => _showQRScanner(Get.context!),
        ),
        PopupMenuButton(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) => [
            _buildPopupMenuItem(
              'profile',
              Icons.person,
              'Mon profil',
            ),
            _buildPopupMenuItem(
              'stats',
              Icons.analytics,
              'Statistiques',
            ),
            _buildPopupMenuItem(
              'logout',
              Icons.logout,
              'Déconnexion',
            ),
          ],
          onSelected: _handleMenuSelection,
        ),
      ],
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(String value, IconData icon, String text) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, NumberFormat currencyFormat) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Solde disponible',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  IconButton(
                    onPressed: controller.toggleBalanceVisibility,
                    icon: Obx(() => Icon(
                      controller.isBalanceVisible.value
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.white,
                    )),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Obx(() => AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: Text(
                  controller.isBalanceVisible.value
                      ? currencyFormat.format(controller.balance.value)
                      : '••••••',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildActionCard(
          context,
          icon: Icons.add_circle,
          title: 'Dépôt',
          color: Colors.green,
          onTap: () => _showDepositDialog(context),
        ),
        _buildActionCard(
          context,
          icon: Icons.remove_circle,
          title: 'Retrait',
          color: Colors.red,
          onTap: () => _showWithdrawDialog(context),
        ),
        _buildActionCard(
          context,
          icon: Icons.update,
          title: 'Déplafonner',
          color: Colors.blue,
          onTap: () => _showLimitUpdateDialog(context),
        ),
        _buildActionCard(
          context,
          icon: Icons.qr_code_scanner,
          title: 'Scanner QR',
          color: Colors.purple,
          onTap: () => _showQRScanner(context),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDepositDialog(BuildContext context) {
    final phoneController = TextEditingController();
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final RxBool isPhoneValid = false.obs;
    final RxBool isAmountValid = false.obs;

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.only(
          top: 24,
          left: 24,
          right: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Nouveau dépôt',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Champ téléphone avec recherche de contacts
                TextFormField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: 'Numéro de téléphone du client',
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
                
                // Champ montant avec formatage
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
                const SizedBox(height: 16),
                
                // Champ description
                TextFormField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description (optionnel)',
                    prefixIcon: const Icon(Icons.description),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    hintText: 'Ex: Dépôt mensuel',
                  ),
                  maxLines: 2,
                  maxLength: 100,
                ),
                const SizedBox(height: 24),
                
                // Bouton de validation
                SizedBox(
                  width: double.infinity,
                  child: Obx(() => ElevatedButton(
                    onPressed: (controller.isLoading.value || !isPhoneValid.value || !isAmountValid.value)
                        ? null
                        : () async {
                            if (formKey.currentState!.validate()) {
                              try {
                                await controller.deposit(
                                  userPhone: phoneController.text,
                                  amount: double.parse(amountController.text),
                                  description: descriptionController.text,
                                );
                                Get.back();
                                _showSuccessAnimation(context, 'Dépôt', Colors.green);
                              } catch (e) {
                                Get.snackbar(
                                  'Erreur',
                                  'Le dépôt a échoué',
                                  backgroundColor: Colors.red,
                                  colorText: Colors.white,
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: controller.isLoading.value
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Effectuer le dépôt'),
                  )),
                ),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showSuccessAnimation(BuildContext context, String operation, Color color) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.network(
                'https://assets10.lottiefiles.com/packages/lf20_success.json',
                width: 200,
                height: 200,
                repeat: false,
              ),
              Text(
                '$operation réussi !',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('OK'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showWithdrawDialog(BuildContext context) {
    final phoneController = TextEditingController();
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final RxBool isPhoneValid = false.obs;
    final RxBool isAmountValid = false.obs;

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.only(
          top: 24,
          left: 24,
          right: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Nouveau retrait',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Champ téléphone avec recherche de contacts
                TextFormField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: 'Numéro de téléphone du client',
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
                
                // Champ montant avec formatage
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
                const SizedBox(height: 16),
                
                // Champ description
                TextFormField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description (optionnel)',
                    prefixIcon: const Icon(Icons.description),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    hintText: 'Ex: Retrait mensuel',
                  ),
                  maxLines: 2,
                  maxLength: 100,
                ),
                const SizedBox(height: 24),
                
                // Bouton de validation
                SizedBox(
                  width: double.infinity,
                  child: Obx(() => ElevatedButton(
                    onPressed: (controller.isLoading.value || !isPhoneValid.value || !isAmountValid.value)
                        ? null
                        : () async {
                            if (formKey.currentState!.validate()) {
                              try {
                                await controller.withdraw(
                                  userPhone: phoneController.text,
                                  amount: double.parse(amountController.text),
                                  description: descriptionController.text,
                                );
                                Get.back();
                                _showSuccessAnimation(context, 'Retrait', Colors.red);
                              } catch (e) {
                                Get.snackbar(
                                  'Erreur',
                                  'Le retrait a échoué',
                                  backgroundColor: Colors.red,
                                  colorText: Colors.white,
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: controller.isLoading.value
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Effectuer le retrait'),
                  )),
                ),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showQRScanner(BuildContext context) {
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
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Scanner un QR Code',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: MobileScanner(
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  for (final barcode in barcodes) {
                    try {
                      final qrData = QRCodeData.fromJson(barcode.rawValue ?? '');
                      Get.back();
                      _showTransactionDialog(context, qrData);
                    } catch (e) {
                      Get.snackbar(
                        'Erreur',
                        'QR Code invalide',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.red,
                        colorText: Colors.white,
                      );
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      enableDrag: false,
    );
  }

  void _showTransactionDialog(BuildContext context, QRCodeData qrData) {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    final limitController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final RxBool isAmountValid = false.obs;
    final RxBool showLimitUpdate = false.obs;
    final RxDouble currentLimit = 0.0.obs;
    final RxBool isLoadingUserData = true.obs;

    // Charger les données actuelles de l'utilisateur
    _firestore
        .collection('users')
        .where('phone', isEqualTo: qrData.phone)
        .get()
        .then((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final userData = snapshot.docs.first.data();
        currentLimit.value = (userData['maxTransactionLimit'] ?? 0.0).toDouble();
        final initialLimit = (userData['initialTransactionLimit'] ?? 500000.0).toDouble();
        limitController.text = initialLimit.toString(); // Pré-remplir avec la limite initiale
      }
      isLoadingUserData.value = false;
    });

    Get.bottomSheet(
      Container(
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
              children: [
                // En-tête avec informations client
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      radius: 30,
                      child: Text(
                        qrData.name[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            qrData.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            qrData.phone,
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                          Obx(() => isLoadingUserData.value
                            ? const SizedBox(
                                height: 2,
                                child: LinearProgressIndicator(),
                              )
                            : Text(
                                'Plafond restant: ${NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA').format(currentLimit.value)}',
                                style: TextStyle(
                                  color: currentLimit.value > 0 ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Section de déplafonnement
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.trending_up, color: Colors.blue[700]),
                            const SizedBox(width: 8),
                            Text(
                              'Déplafonnement',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                            const Spacer(),
                            Switch(
                              value: showLimitUpdate.value,
                              onChanged: (value) => showLimitUpdate.value = value,
                              activeColor: Colors.blue,
                            ),
                          ],
                        ),
                        if (showLimitUpdate.value) ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: limitController,
                            decoration: InputDecoration(
                              labelText: 'Nouvelle limite',
                              prefixIcon: const Icon(Icons.trending_up),
                              suffixText: 'FCFA',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              helperText: 'Limite maximale recommandée: 500,000 FCFA',
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: showLimitUpdate.value
                              ? (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Veuillez entrer une limite';
                                  }
                                  final limit = double.tryParse(value);
                                  if (limit == null || limit <= 0) {
                                    return 'Limite invalide';
                                  }
                                  return null;
                                }
                              : null,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Section transaction
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.swap_horiz, color: Colors.green[700]),
                            const SizedBox(width: 8),
                            Text(
                              'Transaction',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: amountController,
                          decoration: InputDecoration(
                            labelText: 'Montant',
                            prefixIcon: const Icon(Icons.attach_money),
                            suffixText: 'FCFA',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: descriptionController,
                          decoration: InputDecoration(
                            labelText: 'Description (optionnel)',
                            prefixIcon: const Icon(Icons.description),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            hintText: 'Ex: Dépôt/Retrait',
                          ),
                          maxLines: 2,
                          maxLength: 100,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Boutons d'action
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: !isAmountValid.value
                            ? null
                            : () => _executeTransaction(
                                  context,
                                  qrData,
                                  amountController,
                                  descriptionController,
                                  limitController,
                                  showLimitUpdate.value,
                                  formKey,
                                  TransactionType.deposit,
                                ),
                        icon: const Icon(Icons.add_circle),
                        label: const Text('Dépôt'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: !isAmountValid.value
                            ? null
                            : () => _executeTransaction(
                                  context,
                                  qrData,
                                  amountController,
                                  descriptionController,
                                  limitController,
                                  showLimitUpdate.value,
                                  formKey,
                                  TransactionType.withdrawal,
                                ),
                        icon: const Icon(Icons.remove_circle),
                        label: const Text('Retrait'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Future<void> _executeTransaction(
    BuildContext context,
    QRCodeData qrData,
    TextEditingController amountController,
    TextEditingController descriptionController,
    TextEditingController limitController,
    bool showLimitUpdate,
    GlobalKey<FormState> formKey,
    TransactionType type,
  ) async {
    if (!formKey.currentState!.validate()) return;

    try {
      if (showLimitUpdate && limitController.text.isNotEmpty) {
        await controller.updateUserLimit(
          userPhone: qrData.phone,
          newLimit: double.parse(limitController.text),
        );
      }

      if (type == TransactionType.deposit) {
        await controller.deposit(
          userPhone: qrData.phone,
          amount: double.parse(amountController.text),
          description: descriptionController.text,
        );
      } else {
        await controller.withdraw(
          userPhone: qrData.phone,
          amount: double.parse(amountController.text),
          description: descriptionController.text,
        );
      }

      Get.back();
      _showSuccessAnimation(
        context,
        type == TransactionType.deposit ? 'Dépôt' : 'Retrait',
        type == TransactionType.deposit ? Colors.green : Colors.red,
      );
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'L\'opération a échoué: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _showLimitUpdateDialog(BuildContext context) {
    final phoneController = TextEditingController();
    final limitController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final RxBool isPhoneValid = false.obs;
    final RxBool isLimitValid = false.obs;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Mise à jour de la limite',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: 'Numéro de téléphone du client',
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
                TextFormField(
                  controller: limitController,
                  decoration: InputDecoration(
                    labelText: 'Nouvelle limite',
                    prefixIcon: const Icon(Icons.attach_money),
                    suffixText: 'FCFA',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: Obx(() => isLimitValid.value
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const SizedBox.shrink()),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  onChanged: (value) {
                    final limit = double.tryParse(value);
                    isLimitValid.value = limit != null && limit > 0;
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer une limite';
                    }
                    final limit = double.tryParse(value);
                    if (limit == null || limit <= 0) {
                      return 'Limite invalide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Annuler'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Obx(() => ElevatedButton(
                        onPressed: (controller.isLoading.value || !isPhoneValid.value || !isLimitValid.value)
                            ? null
                            : () async {
                                if (formKey.currentState!.validate()) {
                                  try {
                                    await controller.updateUserLimit(
                                      userPhone: phoneController.text,
                                      newLimit: double.parse(limitController.text),
                                    );
                                    Get.back();
                                    _showSuccessAnimation(
                                      context,
                                      'Mise à jour de la limite',
                                      Colors.blue,
                                    );
                                  } catch (e) {
                                    Get.snackbar(
                                      'Erreur',
                                      'La mise à jour a échoué',
                                      backgroundColor: Colors.red,
                                      colorText: Colors.white,
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: controller.isLoading.value
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('Mettre à jour'),
                      )),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionsSection(BuildContext context, NumberFormat currencyFormat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Transactions récentes',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: DropdownButton<String>(
                value: controller.selectedFilter.value,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('Tout')),
                  DropdownMenuItem(value: 'today', child: Text('Aujourd\'hui')),
                  DropdownMenuItem(value: 'week', child: Text('Cette semaine')),
                  DropdownMenuItem(value: 'month', child: Text('Ce mois')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    controller.filterTransactions(value);
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.transactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune transaction',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.transactions.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final transaction = controller.transactions[index];
              final isDeposit = transaction.type == TransactionType.deposit;
              
              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (isDeposit ? Colors.green : Colors.red).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isDeposit ? Icons.add : Icons.remove,
                    color: isDeposit ? Colors.green : Colors.red,
                  ),
                ),
                title: Text(
                  '${isDeposit ? '+' : '-'} ${currencyFormat.format(transaction.amount)}',
                  style: TextStyle(
                    color: isDeposit ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(transaction.toUserId),
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(transaction.createdAt),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    transaction.type.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ],
    );
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'profile':
        // TODO: Implémenter la navigation vers le profil
        break;
      case 'stats':
        // TODO: Implémenter la navigation vers les statistiques
        break;
      case 'logout':
        _showLogoutConfirmation();
        break;
    }
  }

  void _showLogoutConfirmation() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.logout,
                size: 48,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Déconnexion',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Voulez-vous vraiment vous déconnecter ?',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        Get.find<AuthController>().logout();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Déconnexion'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 