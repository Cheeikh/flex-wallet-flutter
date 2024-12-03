import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../controllers/auth_controller.dart';
import '../models/user_role.dart';

class RegisterView extends GetView<AuthController> {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: controller.registerFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo et titre avec animation
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 800),
                    tween: Tween(begin: 0, end: 1),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        Hero(
                          tag: 'app_logo',
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).primaryColor.withOpacity(0.1),
                            ),
                            child: Icon(
                              Icons.account_balance_wallet,
                              size: 64,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Créer un compte',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Formulaire avec animation
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 1000),
                    tween: Tween(begin: 0, end: 1),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: 0.8 + (0.2 * value),
                        child: Opacity(
                          opacity: value,
                          child: child,
                        ),
                      );
                    },
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildNameField(),
                            const SizedBox(height: 16),
                            _buildPhoneField(),
                            const SizedBox(height: 16),
                            _buildPasswordField(),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Bouton d'inscription
                  Obx(() => ElevatedButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : () => _handleRegister(),
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
                        : const Text('S\'inscrire'),
                  )),
                  const SizedBox(height: 24),

                  // Séparateur
                  _buildDivider(),
                  const SizedBox(height: 24),

                  // Boutons sociaux
                  _buildSocialButtons(),
                  const SizedBox(height: 24),

                  // Lien de connexion
                  TextButton(
                    onPressed: () => Get.back(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: RichText(
                      text: TextSpan(
                        text: 'Déjà un compte ? ',
                        style: TextStyle(color: Colors.grey[600]),
                        children: [
                          TextSpan(
                            text: 'Se connecter',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: controller.nameController,
      decoration: InputDecoration(
        labelText: 'Nom complet',
        prefixIcon: const Icon(Icons.person),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Get.theme.primaryColor),
        ),
      ),
      validator: (value) {
        if (value?.isEmpty ?? true) {
          return 'Veuillez entrer votre nom';
        }
        return null;
      },
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      controller: controller.phoneController,
      decoration: InputDecoration(
        labelText: 'Numéro de téléphone',
        prefixIcon: const Icon(Icons.phone),
        hintText: '+221XXXXXXXXX',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Get.theme.primaryColor),
        ),
      ),
      keyboardType: TextInputType.phone,
      validator: controller.validatePhone,
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildPasswordField() {
    return Obx(() => TextFormField(
      controller: controller.passwordController,
      decoration: InputDecoration(
        labelText: 'Mot de passe',
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(
            controller.isPasswordVisible.value
                ? Icons.visibility
                : Icons.visibility_off,
          ),
          onPressed: controller.togglePasswordVisibility,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Get.theme.primaryColor),
        ),
      ),
      obscureText: !controller.isPasswordVisible.value,
      validator: (value) {
        if (value?.isEmpty ?? true) {
          return 'Veuillez entrer un mot de passe';
        }
        if ((value?.length ?? 0) < 6) {
          return 'Le mot de passe doit contenir au moins 6 caractères';
        }
        return null;
      },
      textInputAction: TextInputAction.done,
    ));
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey.shade400)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OU',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey.shade400)),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildSocialButton(
            icon: FontAwesomeIcons.google,
            label: 'Google',
            onPressed: () => controller.signInWithGoogle(),
            color: Colors.red,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSocialButton(
            icon: FontAwesomeIcons.facebook,
            label: 'Facebook',
            onPressed: () => controller.signInWithFacebook(),
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: FaIcon(icon, size: 18, color: color),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: color),
        ),
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: color.withOpacity(0.5)),
        ),
      ),
    );
  }

  void _handleRegister() {
    if (controller.registerFormKey.currentState!.validate()) {
      controller.register(
        name: controller.nameController.text,
        phone: controller.phoneController.text,
        password: controller.passwordController.text,
        role: UserRole.client,
      );
    }
  }
} 