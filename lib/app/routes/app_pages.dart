import 'package:get/get.dart';

import '../modules/auth/bindings/auth_binding.dart';
import '../modules/auth/views/login_view.dart';
import '../modules/auth/views/register_view.dart';
import '../modules/client/bindings/client_binding.dart';
import '../modules/client/views/dashboard_view.dart';
import '../modules/distributor/bindings/distributor_binding.dart';
import '../modules/distributor/views/distributor_dashboard_view.dart';
import '../modules/client/views/recurring_transfers_view.dart';
import '../modules/notifications/bindings/notifications_binding.dart';
import '../modules/notifications/views/notifications_view.dart';
import '../modules/auth/middlewares/auth_middleware.dart';
import '../modules/client/views/create_recurring_transfer_view.dart';
import '../modules/auth/views/phone_completion_view.dart';

abstract class Routes {
  Routes._();

  static const login = '/login';
  static const register = '/register';
  static const clientDashboard = '/client/dashboard';
  static const distributorDashboard = '/distributor/dashboard';
  static const recurringTransfers = '/recurring-transfers';
  static const notifications = '/notifications';
  static const CREATE_RECURRING_TRANSFER = '/create-recurring-transfer';
  static const PHONE_COMPLETION = '/phone-completion';
}

class AppPages {
  AppPages._();

  static const INITIAL = Routes.login;

  static final routes = [
    GetPage(
      name: Routes.login,
      page: () => const LoginView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: Routes.register,
      page: () => const RegisterView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: Routes.clientDashboard,
      page: () => const DashboardView(),
      binding: ClientBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.distributorDashboard,
      page: () => const DistributorDashboardView(),
      binding: DistributorBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.recurringTransfers,
      page: () => const RecurringTransfersView(),
      binding: ClientBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.notifications,
      page: () => const NotificationsView(),
      binding: NotificationsBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.CREATE_RECURRING_TRANSFER,
      page: () => const CreateRecurringTransferView(),
      binding: ClientBinding(),
    ),
    GetPage(
      name: Routes.PHONE_COMPLETION,
      page: () => const PhoneCompletionView(),
      binding: AuthBinding(),
    ),
  ];
}
