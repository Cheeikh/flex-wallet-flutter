import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

class PhoneCompletionView extends GetView<AuthController> {
  final String? name;
  final String? email;
  final String? photoUrl;
  final bool isFacebookLogin;

  const PhoneCompletionView({
    super.key,
    this.name,
    this.email,
    this.photoUrl,
    this.isFacebookLogin = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compléter votre profil'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: controller.phoneFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (photoUrl != null)
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(photoUrl!),
                  ),
                const SizedBox(height: 24),
                Text(
                  'Bienvenue $name !',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Pour finaliser votre inscription, veuillez entrer votre numéro de téléphone',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: controller.phoneController,
                  decoration: InputDecoration(
                    labelText: 'Numéro de téléphone',
                    prefixIcon: const Icon(Icons.phone),
                    hintText: '+221XXXXXXXXX',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: controller.validatePhone,
                ),
                const SizedBox(height: 24),
                Obx(() => ElevatedButton(
                      onPressed: controller.isLoading.value
                          ? null
                          : () => isFacebookLogin
                              ? controller.completeFacebookSignIn(
                                  phone: controller.phoneController.text,
                                )
                              : controller.completeGoogleSignIn(
                                  phone: controller.phoneController.text,
                                ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: controller.isLoading.value
                          ? const CircularProgressIndicator()
                          : const Text('Continuer'),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 