class Validators {
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ce champ est requis';
    }
    if (!RegExp(r'^\d{9}$').hasMatch(value)) {
      return 'Numéro de téléphone invalide';
    }
    return null;
  }

  static String? validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ce champ est requis';
    }
    final amount = double.tryParse(value);
    if (amount == null || amount <= 0) {
      return 'Montant invalide';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ce champ est requis';
    }
    if (value.length < 6) {
      return 'Le mot de passe doit contenir au moins 6 caractères';
    }
    return null;
  }
} 