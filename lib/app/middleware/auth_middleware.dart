import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../modules/auth/controllers/auth_controller.dart';
import '../routes/app_pages.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final authController = Get.find<AuthController>();
    
    if (authController.currentUser == null &&
        route != Routes.login &&
        route != Routes.register) {
      return const RouteSettings(name: Routes.login);
    }
    
    return null;
  }
} 