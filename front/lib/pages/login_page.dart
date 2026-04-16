import 'package:flutter/material.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/auth_controller.dart';
import 'package:flutter_getx_app/app/routes/app_routes.dart';
import 'package:get/get.dart';

class LoginPage extends StatelessWidget {
  LoginPage({super.key});

  final AuthController controller = Get.put(AuthController());

  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FA),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 40),
                    child: Container(
                      width: 420,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 48),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E9F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF7CB9FF),
                                    Color(0xFF3B82F6)
                                  ],
                                ),
                              ),
                              child: const Center(
                                child: Text(
                                  'S',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 32),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'SUNSPACE',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Color(0xFF1E293B),
                                fontWeight: FontWeight.w800,
                                fontSize: 24,
                                letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Connexion à votre compte',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w400,
                                fontSize: 14),
                          ),
                          const SizedBox(height: 32),
                          const Text(
                            'Adresse email',
                            style: TextStyle(
                                color: Color(0xFF334155),
                                fontWeight: FontWeight.w600,
                                fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          _LoginInput(
                            controller: emailCtrl,
                            hintText: 'vous@exemple.com',
                            icon: Icons.mail_outline_rounded,
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Mot de passe',
                                style: TextStyle(
                                    color: Color(0xFF334155),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14),
                              ),
                              GestureDetector(
                                onTap: () =>
                                    Get.toNamed(Routes.FORGOT_PASSWORD),
                                child: const Text(
                                  'Mot de passe oublié?',
                                  style: TextStyle(
                                      color: Color(0xFF0066FF),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _LoginInput(
                            controller: passwordCtrl,
                            hintText: '••••••••',
                            icon: Icons.lock_outline_rounded,
                            obscureText: true,
                          ),
                          const SizedBox(height: 24),
                          Obx(() => SizedBox(
                                height: 48,
                                child: controller.isLoading.value
                                    ? const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Color(0xFF0066FF)),
                                        ),
                                      )
                                    : ElevatedButton(
                                        onPressed: () {
                                          controller.loginUser(
                                              emailCtrl.text.trim(),
                                              passwordCtrl.text.trim());
                                        },
                                        style: ElevatedButton.styleFrom(
                                          elevation: 0,
                                          backgroundColor:
                                              const Color(0xFF0066FF),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8)),
                                        ),
                                        child: const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text('Se connecter',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 16)),
                                            SizedBox(width: 8),
                                            Icon(Icons.arrow_forward, size: 18),
                                          ],
                                        ),
                                      ),
                              )),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                  child: Divider(
                                      color:
                                          Colors.grey.withValues(alpha: 0.2))),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text('ou',
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 12)),
                              ),
                              Expanded(
                                  child: Divider(
                                      color:
                                          Colors.grey.withValues(alpha: 0.2))),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Center(
                            child: GestureDetector(
                              onTap: () => Get.toNamed('/register'),
                              child: const Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                        text: 'Pas encore de compte? ',
                                        style: TextStyle(
                                            color: Color(0xFF64748B),
                                            fontSize: 14)),
                                    TextSpan(
                                        text: 'S\'inscrire',
                                        style: TextStyle(
                                            color: Color(0xFF0066FF),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14)),
                                  ],
                                ),
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
          },
        ),
      ),
    );
  }
}

class _LoginInput extends StatelessWidget {
  const _LoginInput({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(
          color: Color(0xFF1E293B),
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(
            icon,
            size: 20,
            color: const Color(0xFF94A3B8),
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}
