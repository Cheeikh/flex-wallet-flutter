import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/client_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../data/models/qr_code_data.dart';
import '../../../routes/app_pages.dart';
import '../../../services/theme_service.dart';
import '../../../services/connectivity_service.dart';
import 'widgets/transfer_bottom_sheet.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/widgets/transaction_tile.dart';
import 'package:lottie/lottie.dart';
import '../../../modules/client/views/transaction_details_view.dart';

class DashboardView extends GetView<ClientController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA');
    
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Obx(() {
        if (!Get.find<ConnectivityService>().isConnected) {
          return _buildNoConnectionView();
        }
        
        return RefreshIndicator(
          onRefresh: () => controller.refreshData(),
          child: CustomScrollView(
            slivers: [
              // En-tête avec carte de solde
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBalanceCard(context, currencyFormat),
                      const SizedBox(height: 24),
                      _buildQuickActions(context),
                      const SizedBox(height: 24),
                      _buildTransactionsHeader(context),
                    ],
                  ),
                ),
              ),
              // Liste des transactions avec effet de chargement
              _buildTransactionsList(context, currencyFormat),
            ],
          ),
        );
      }),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tableau de bord'),
          Obx(() => Text(
            controller.authController.currentUser?.name ?? '',
            style: Theme.of(context).textTheme.bodySmall,
          )),
        ],
      ),
      actions: [
        // Badge de notifications amélioré
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: IconButton(
            onPressed: () => Get.toNamed(Routes.notifications),
            icon: Badge(
              label: Obx(() => Text(
                '${controller.unreadNotifications.value}',
                style: const TextStyle(color: Colors.white),
              )),
              isLabelVisible: controller.unreadNotifications.value > 0,
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
        ),
        // Bouton de thème avec animation
        IconButton(
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return RotationTransition(
                turns: animation,
                child: child,
              );
            },
            child: Icon(
              Get.find<ThemeService>().isDarkMode
                ? Icons.light_mode
                : Icons.dark_mode,
              key: ValueKey<bool>(Get.find<ThemeService>().isDarkMode),
            ),
          ),
          onPressed: () => Get.find<ThemeService>().toggleTheme(),
        ),
        // Menu plus élégant
        Theme(
          data: Theme.of(context).copyWith(
            popupMenuTheme: PopupMenuThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          child: _buildPopupMenu(context),
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

  Widget _buildNoConnectionView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.network(
            'https://assets9.lottiefiles.com/packages/lf20_qpwbukxf.json',
            width: 200,
            height: 200,
          ),
          const SizedBox(height: 16),
          const Text(
            'Pas de connexion internet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => controller.refreshData(),
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, NumberFormat currencyFormat) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Solde disponible',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
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
              const SizedBox(height: 12),
              Obx(() => AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: Text(
                  controller.isBalanceVisible.value
                      ? currencyFormat.format(controller.balance.value)
                      : '••••••',
                  key: ValueKey<bool>(controller.isBalanceVisible.value),
                  style: const TextStyle(
                    fontSize: 32,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )),
              const SizedBox(height: 8),
              Obx(() => AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: Text(
                  controller.balanceVariation.value >= 0 
                      ? '+${currencyFormat.format(controller.balanceVariation.value)}'
                      : currencyFormat.format(controller.balanceVariation.value),
                  style: TextStyle(
                    color: controller.balanceVariation.value >= 0 
                        ? Colors.green[100]
                        : Colors.red[100],
                    fontSize: 16,
                  ),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions rapides',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildQuickActionButton(
              context,
              icon: Icons.qr_code_scanner,
              label: 'Scanner',
              onTap: () => _showQRScanner(context),
            ),
            _buildQuickActionButton(
              context,
              icon: Icons.qr_code,
              label: 'Mon QR',
              onTap: () => _showQRCode(context),
            ),
            _buildQuickActionButton(
              context,
              icon: Icons.repeat,
              label: 'Récurrents',
              onTap: () => Get.toNamed(Routes.recurringTransfers),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.25,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).primaryColor.withOpacity(0.2),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Theme.of(context).primaryColor),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionsHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Transactions',
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
            onChanged: (String? value) {
              if (value != null) {
                controller.filterTransactions(value);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsList(BuildContext context, NumberFormat currencyFormat) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const SliverFillRemaining(
          child: Center(child: CircularProgressIndicator()),
        );
      }

      if (controller.transactions.isEmpty) {
        return SliverFillRemaining(
          child: Center(
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
          ),
        );
      }

      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final transaction = controller.transactions[index];
            return Hero(
              tag: 'transaction-${transaction.id}-$index',
              child: Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: TransactionTile(
                  transaction: transaction,
                  onCancel: () => controller.cancelTransaction(transaction.id),
                  onTap: () async {
                    final shouldRefresh = await Get.to<bool>(
                      () => TransactionDetailsView(
                        transaction: transaction,
                        heroTag: 'transaction-${transaction.id}-$index',
                      ),
                      transition: Transition.rightToLeft,
                    );
                    if (shouldRefresh == true) {
                      controller.cancelTransaction(transaction.id);
                    }
                  },
                ),
              ),
            );
          },
          childCount: controller.transactions.length,
        ),
      );
    });
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _showBottomSheet(context),
      icon: const Icon(Icons.send),
      label: const Text('Transférer'),
      backgroundColor: Theme.of(context).primaryColor,
    );
  }

  void _handleMenuSelection(String value, BuildContext context) {
    switch (value) {
      case 'recurring':
        Get.toNamed(Routes.recurringTransfers);
        break;
      case 'qr':
        _showQRCode(context);
        break;
      case 'logout':
        _showLogoutConfirmation();
        break;
    }
  }

  void _showBottomSheet(BuildContext context) {
    Get.bottomSheet(
      TransferBottomSheet(),
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );
  }

  void _showQRCode(BuildContext context) {
    final currentUser = Get.find<AuthController>().currentUser;
    if (currentUser == null) {
      Get.snackbar(
        'Erreur',
        'Utilisateur non connecté',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final qrData = QRCodeData(
      userId: currentUser.uid,
      phone: currentUser.phone ?? '',
      name: currentUser.name ?? '',
      timestamp: DateTime.now(),
    );

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // En-tête avec bouton de fermeture
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mon QR Code',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Carte contenant le QR code
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Avatar et nom
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      child: Text(
                        currentUser.name?.substring(0, 1).toUpperCase() ?? '?',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      currentUser.name ?? '',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      currentUser.phone ?? '',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // QR Code
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                          width: 0.5,
                        ),
                      ),
                      child: QrImageView(
                        data: qrData.toJson(),
                        version: QrVersions.auto,
                        size: 200.0,
                        backgroundColor: Colors.white,
                        errorCorrectionLevel: QrErrorCorrectLevel.H,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Instructions
            Text(
              'Partagez ce QR code pour recevoir un transfert',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 16),
            
            // Bouton de partage (optionnel)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // Implémenter le partage du QR code
                  Get.snackbar(
                    'Info',
                    'Fonctionnalité de partage à venir',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
                icon: const Icon(Icons.share),
                label: const Text('Partager mon QR code'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
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

  void _showQRScanner(BuildContext context) {
    Get.bottomSheet(
      Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // En-tête amélioré
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Scanner un QR Code',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            
            // Zone de scan avec overlay
            Expanded(
              child: Stack(
                children: [
                  MobileScanner(
                    onDetect: (capture) {
                      final List<Barcode> barcodes = capture.barcodes;
                      for (final barcode in barcodes) {
                        try {
                          final qrData = QRCodeData.fromJson(barcode.rawValue ?? '');
                          // Au lieu d'ouvrir une popup, on met à jour les contrôleurs
                          controller.setTransferRecipient(qrData);
                          Get.back();
                          _showBottomSheet(context);
                        } catch (e) {
                          Get.snackbar(
                            'Erreur',
                            'QR Code invalide',
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                          );
                        }
                      }
                    },
                  ),
                  // Overlay de scan
                  Center(
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).primaryColor,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.qr_code_scanner,
                            size: 50,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Placez le QR code dans le cadre',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Instructions en bas
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Scannez le QR code d\'un autre utilisateur pour effectuer un transfert',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  PopupMenuButton _buildPopupMenu(BuildContext context) {
    return PopupMenuButton(
      icon: const Icon(Icons.more_vert),
      offset: const Offset(0, 40),
      itemBuilder: (context) => [
        _buildPopupMenuItem('recurring', Icons.repeat, 'Transferts récurrents'),
        _buildPopupMenuItem('qr', Icons.qr_code, 'Mon QR Code'),
        _buildPopupMenuItem('logout', Icons.logout, 'Déconnexion'),
      ],
      onSelected: (value) => _handleMenuSelection(value, context),
    );
  }
} 