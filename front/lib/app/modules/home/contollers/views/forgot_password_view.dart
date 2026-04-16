import 'package:flutter/material.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/password_recovery_controller.dart';
import 'package:get/get.dart';

class ForgotPasswordView extends GetView<PasswordRecoveryController> {
  const ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE5E9F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Obx(
                  () => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _Header(
                        icon: Icons.lock_reset_rounded,
                        title: 'Mot de passe oublié',
                        subtitle:
                            'Recevez un lien sécurisé pour réinitialiser votre mot de passe.',
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Adresse email',
                        style: TextStyle(
                          color: Color(0xFF334155),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: controller.emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _inputDecoration(
                          hintText: 'vous@exemple.com',
                          icon: Icons.mail_outline_rounded,
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (controller.errorMessage.value.isNotEmpty)
                        _MessageBox(
                          text: controller.errorMessage.value,
                          background: const Color(0xFFFFF1F2),
                          foreground: const Color(0xFFB91C1C),
                          border: const Color(0xFFFECACA),
                        ),
                      if (controller.infoMessage.value.isNotEmpty) ...[
                        _MessageBox(
                          text: controller.infoMessage.value,
                          background: const Color(0xFFF0FDF4),
                          foreground: const Color(0xFF166534),
                          border: const Color(0xFFBBF7D0),
                        ),
                        const SizedBox(height: 10),
                      ],
                      Obx(
                        () => SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: controller.isSendingResetLink.value
                                ? null
                                : controller.sendResetLink,
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: const Color(0xFF0066FF),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: controller.isSendingResetLink.value
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Envoyer le lien',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => Get.back(),
                        child: const Text('Retour à la connexion'),
                      ),
                      if (controller.debugResetUrl.value.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Text(
                          'Lien de test local',
                          style: TextStyle(
                            color: Colors.blueGrey.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        SelectableText(
                          controller.debugResetUrl.value,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 20),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF0066FF), width: 1.2),
      ),
    );
  }
}

class ResetPasswordView extends GetView<PasswordRecoveryController> {
  const ResetPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE5E9F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Obx(
                  () => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _Header(
                        icon: Icons.key_rounded,
                        title: 'Réinitialiser le mot de passe',
                        subtitle: 'Créez un nouveau mot de passe sécurisé.',
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Token de réinitialisation',
                        style: TextStyle(
                          color: Color(0xFF334155),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: controller.tokenController,
                        decoration: _inputDecoration(
                          hintText: 'Token reçu par email',
                          icon: Icons.confirmation_number_outlined,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Nouveau mot de passe',
                        style: TextStyle(
                          color: Color(0xFF334155),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Obx(
                        () => TextField(
                          controller: controller.newPasswordController,
                          obscureText: controller.obscureNewPassword.value,
                          decoration: _inputDecoration(
                            hintText: 'Entrez votre nouveau mot de passe',
                            icon: Icons.lock_outline_rounded,
                            suffixIcon: IconButton(
                              onPressed: controller.toggleNewPasswordVisibility,
                              icon: Icon(
                                controller.obscureNewPassword.value
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Confirmer le mot de passe',
                        style: TextStyle(
                          color: Color(0xFF334155),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Obx(
                        () => TextField(
                          controller: controller.confirmPasswordController,
                          obscureText: controller.obscureConfirmPassword.value,
                          decoration: _inputDecoration(
                            hintText: 'Confirmez le nouveau mot de passe',
                            icon: Icons.lock_reset_outlined,
                            suffixIcon: IconButton(
                              onPressed:
                                  controller.toggleConfirmPasswordVisibility,
                              icon: Icon(
                                controller.obscureConfirmPassword.value
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (controller.errorMessage.value.isNotEmpty)
                        _MessageBox(
                          text: controller.errorMessage.value,
                          background: const Color(0xFFFFF1F2),
                          foreground: const Color(0xFFB91C1C),
                          border: const Color(0xFFFECACA),
                        ),
                      if (controller.infoMessage.value.isNotEmpty) ...[
                        _MessageBox(
                          text: controller.infoMessage.value,
                          background: const Color(0xFFF0FDF4),
                          foreground: const Color(0xFF166534),
                          border: const Color(0xFFBBF7D0),
                        ),
                        const SizedBox(height: 10),
                      ],
                      Obx(
                        () => SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: controller.isResettingPassword.value
                                ? null
                                : controller.resetPassword,
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: const Color(0xFF0066FF),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: controller.isResettingPassword.value
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Réinitialiser',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => Get.back(),
                        child: const Text('Retour'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF0066FF), width: 1.2),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _Header({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF7CB9FF), Color(0xFF3B82F6)],
            ),
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w400,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _MessageBox extends StatelessWidget {
  final String text;
  final Color background;
  final Color foreground;
  final Color border;

  const _MessageBox({
    required this.text,
    required this.background,
    required this.foreground,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}
