import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app/core/services/firebase_service.dart';
import 'app/routes/app_pages.dart';
import 'firebase_options.dart';
import 'app/modules/auth/controllers/auth_controller.dart';
import 'package:get_storage/get_storage.dart';
import 'app/services/theme_service.dart';
import 'app/services/connectivity_service.dart';
import 'app/core/bindings/initial_binding.dart';

Future<void> initServices() async {
  await GetStorage.init();
  Get.put(ThemeService(), permanent: true);
  Get.put(ConnectivityService(), permanent: true);
}

Future<void> initializeFirebase() async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('Firebase initialisé avec succès');
    }
  } catch (e) {
    print('Erreur lors de l\'initialisation de Firebase: $e');
    rethrow;
  }
}

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialisation de Firebase
    await initializeFirebase();
    
    // Initialisation des services
    await initServices();
    
    // Injection du contrôleur d'authentification
    Get.put(AuthController(), permanent: true);

    // Récupération du service de thème
    final themeService = Get.find<ThemeService>();
    
    runApp(
      GetMaterialApp(
        title: "FlexWallet",
        initialBinding: InitialBinding(),
        initialRoute: AppPages.INITIAL,
        getPages: AppPages.routes,
        debugShowCheckedModeBanner: false,
        theme: themeService.lightTheme,
        darkTheme: themeService.darkTheme,
        themeMode: themeService.themeMode,
      ),
    );
  } catch (e, stackTrace) {
    print('Erreur dans main: $e');
    print('Stack trace: $stackTrace');
  }
}
