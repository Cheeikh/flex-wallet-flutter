import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../../../routes/app_pages.dart';
import '../models/user_role.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final authController = Get.find<AuthController>();
    
    // Si l'utilisateur n'est pas connecté, rediriger vers la page de login
    if (authController.currentUser == null) {
      return const RouteSettings(name: Routes.login);
    }
    
    // Si l'utilisateur est sur la page de login et est déjà connecté,
    // rediriger vers le dashboard approprié selon son rôle
    if (route == Routes.login && authController.currentUser != null) {
      switch (authController.currentUser?.role) {
        case UserRole.client:
          return const RouteSettings(name: Routes.clientDashboard);
        case UserRole.distributor:
          return const RouteSettings(name: Routes.distributorDashboard);
        default:
          return const RouteSettings(name: Routes.login);
      }
    }
    
    return null;
  }

  @override
  GetPage? onPageCalled(GetPage? page) {
    return page;
  }

  @override
  List<Bindings>? onBindingsStart(List<Bindings>? bindings) {
    return bindings;
  }

  @override
  Widget onPageBuilt(Widget page) {
    return page;
  }

  @override
  void onPageDispose() {}
} 