import 'package:get/get.dart';
import '../core/utils/validators.dart';

class ValidationService extends GetxService {
  String? validatePhone(String? value) => Validators.validatePhone(value);
  String? validateAmount(String? value) => Validators.validateAmount(value);
  String? validatePassword(String? value) => Validators.validatePassword(value);

  bool isValidTransfer({
    required String phone,
    required String amount,
    required double currentBalance,
  }) {
    if (validatePhone(phone) != null) return false;
    
    final amountValue = double.tryParse(amount);
    if (amountValue == null || amountValue <= 0) return false;
    if (amountValue > currentBalance) return false;
    
    return true;
  }
} 