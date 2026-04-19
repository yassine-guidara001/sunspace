import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_getx_app/app/data/models/course_model.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/course_controller.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/views/association_formations_page.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/home_controller.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/views/professional_formations_page.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/views/student_course_access_page.dart';
import 'package:flutter_getx_app/app/routes/app_routes.dart';
import 'package:get/get.dart';

import 'custom_sidebar.dart';

class CoursesView extends GetView<CourseController> {
  const CoursesView({super.key});

  static const int _studentMyCoursesMenuIndex = 13;
  static const int _studentCatalogMenuIndex = 15;
  static const int _professionalFormationsMenuIndex = 20;
  static const int _associationFormationsMenuIndex = 23;

  HomeController get _homeController => Get.find<HomeController>();

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 920;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Row(
        children: [
          const CustomSidebar(),
          Expanded(
            child: Obx(() {
              final selectedMenu = _homeController.selectedMenu.value;
              final isStudentMyCourses =
                  selectedMenu == _studentMyCoursesMenuIndex;
              final isStudentCatalog = selectedMenu == _studentCatalogMenuIndex;
              final isProfessionalFormations =
                  selectedMenu == _professionalFormationsMenuIndex;
              final isAssociationFormations =
                  selectedMenu == _associationFormationsMenuIndex;

              if (isStudentMyCourses) {
                return _buildStudentMyCoursesView();
              }

              if (isStudentCatalog) {
                return _buildStudentCatalogView();
              }

              if (isProfessionalFormations) {
                return Column(
                  children: [
                    _buildTopBar(context, isCompact),
                    const Expanded(
                      child: ProfessionalFormationsPage(),
                    ),
                  ],
                );
              }

              if (isAssociationFormations) {
                return Column(
                  children: [
                    _buildTopBar(context, isCompact),
                    const Expanded(
                      child: AssociationFormationsPage(),
                    ),
                  ],
                );
              }

              return Column(
                children: [
                  _buildTopBar(context, isCompact),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(isCompact ? 16 : 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(context),
                          const SizedBox(height: 18),
                          _buildSearchBar(),
                          const SizedBox(height: 16),
                          _buildCoursesTable(context),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentMyCoursesView() {
    return Column(
      children: [
        _buildTopBar(
            Get.context!, MediaQuery.of(Get.context!).size.width < 920),
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(
                MediaQuery.of(Get.context!).size.width < 920 ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.menu_book_rounded,
                        color: Color(0xFF2563EB), size: 30),
                    SizedBox(width: 10),
                    Text(
                      'Mes Formations',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                        height: 1,
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Retrouvez ici tous les cours auxquels vous êtes inscrit.',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(child: _buildStudentMyCoursesContent()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentMyCoursesContent() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final enrolledCourses = controller.studentMyCourses;
      if (enrolledCourses.isEmpty) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFD6DEE8)),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFDCEAFE),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: Color(0xFF2563EB),
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Vous n'avez pas encore de cours",
                    style: TextStyle(
                      color: Color(0xFF111827),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Explorez notre catalogue pour trouver la formation\nqui vous convient et commencez à apprendre dès\naujourd\'hui.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    height: 40,
                    child: ElevatedButton(
                      onPressed: _openStudentCatalog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                      ),
                      child: const Text(
                        'Voir le catalogue',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      return SingleChildScrollView(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 980;
            final cardWidth =
                isWide ? (constraints.maxWidth - 24) / 2 : constraints.maxWidth;

            return Wrap(
              spacing: 24,
              runSpacing: 20,
              children: enrolledCourses
                  .map((course) => SizedBox(
                        width: cardWidth,
                        child: _buildStudentMyCourseCard(course),
                      ))
                  .toList(),
            );
          },
        ),
      );
    });
  }

  Widget _buildStudentMyCourseCard(Course course) {
    final progressPercent = controller.studentCourseProgressPercent(course);
    final progressValue = (progressPercent / 100).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              course.level.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF2563EB),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            course.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Icon(Icons.access_time_outlined,
                  size: 14, color: Color(0xFF9CA3AF)),
              SizedBox(width: 4),
              Text(
                '0h',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 11),
              ),
              SizedBox(width: 14),
              Icon(Icons.layers_outlined, size: 14, color: Color(0xFF9CA3AF)),
              SizedBox(width: 4),
              Text(
                '0 Modules',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Text(
                'Progression',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '$progressPercent%',
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Stack(
            children: [
              Container(
                height: 4,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progressValue,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 38,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Get.to(() => StudentCourseAccessPage(course: course));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0C62FF),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Continuer  >',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openStudentCatalog() async {
    _homeController.selectedMenu.value = _studentCatalogMenuIndex;
    await controller.refreshStudentCatalog();

    if (Get.currentRoute != Routes.FORMATIONS) {
      Get.toNamed(Routes.FORMATIONS);
    }
  }

  Widget _buildStudentCatalogView() {
    return Column(
      children: [
        _buildTopBar(
            Get.context!, MediaQuery.of(Get.context!).size.width < 920),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(
                MediaQuery.of(Get.context!).size.width < 920 ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStudentCatalogHeader(),
                const SizedBox(height: 18),
                _buildSearchBar(
                  hintText: 'Rechercher une formation...',
                ),
                const SizedBox(height: 16),
                Obx(
                  () => Text(
                    '${controller.studentCatalogCourses.length} cours disponibles',
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildCatalogCards(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentCatalogHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.school_outlined,
                  color: Color(0xFF2563EB),
                  size: 30,
                ),
                SizedBox(width: 10),
                Text(
                  'Catalogue de Cours',
                  style: TextStyle(
                    height: 1,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Explorez notre vaste sélection de formations pour booster vos compétences.',
              style: TextStyle(
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Row(
            children: [
              Icon(Icons.grid_view_rounded, color: Color(0xFF2563EB), size: 16),
              SizedBox(width: 12),
              Icon(Icons.view_list_rounded, color: Color(0xFF64748B), size: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCatalogCards() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: CircularProgressIndicator()),
        );
      }

      final courses = controller.studentCatalogCourses;
      if (courses.isEmpty) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 42),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Text(
            'Aucune formation disponible',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }

      return LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 980;
          final cardWidth =
              isWide ? (constraints.maxWidth - 24) / 2 : constraints.maxWidth;

          return Wrap(
            spacing: 24,
            runSpacing: 20,
            children: courses
                .map(
                  (course) => SizedBox(
                    width: cardWidth,
                    child: _buildCatalogCard(context, course),
                  ),
                )
                .toList(),
          );
        },
      );
    });
  }

  Widget _buildCatalogCard(BuildContext context, Course course) {
    final isEnrolled = controller.isEnrolledIn(course);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD6DEE8)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Text(
            course.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          Divider(
            height: 1,
            color: const Color(0xFFCBD5E1).withValues(alpha: 0.65),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 32,
            child: ElevatedButton(
              onPressed: () {
                if (isEnrolled) {
                  Get.to(() => StudentCourseAccessPage(course: course));
                  return;
                }
                _showEnrollmentPaymentDialog(context, course);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isEnrolled
                    ? const Color(0xFF22C55E)
                    : const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: Text(
                _buildCatalogActionLabel(course, isEnrolled: isEnrolled),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _buildCatalogActionLabel(Course course, {required bool isEnrolled}) {
    if (isEnrolled) {
      return 'Accéder';
    }

    if (course.price <= 0) {
      return 'S\'inscrire - Gratuit';
    }

    return 'S\'inscrire - ${course.price.toStringAsFixed(0)} DT';
  }

  void _showEnrollmentPaymentDialog(BuildContext context, Course course) {
    final cardholderController = TextEditingController();
    final cardNumberController = TextEditingController();
    final yearController = TextEditingController();
    final expiryController = TextEditingController();
    final cvcController = TextEditingController();
    final emailController = TextEditingController();
    var sendEmailReceipt = true;

    final amountLabel = '${course.price.toStringAsFixed(3)} TND';

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: const Color(0xFFF3F4F6),
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 390),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildGatewayLogoHeader(),
                          const SizedBox(height: 12),
                          const Text(
                            'Paiement sécurisé',
                            style: TextStyle(
                              color: Color(0xFF111827),
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Inscription à la formation : ${course.title}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF374151),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: cardNumberController,
                            autofillHints: const <String>[],
                            enableSuggestions: false,
                            autocorrect: false,
                            keyboardType: TextInputType.number,
                            inputFormatters: [_CardNumberTextInputFormatter()],
                            decoration: _paymentInputDecoration(
                              'Numéro de la carte',
                              prefixIcon: const Icon(Icons.credit_card,
                                  color: Color(0xFF9CA3AF), size: 18),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: expiryController,
                                  autofillHints: const <String>[],
                                  enableSuggestions: false,
                                  autocorrect: false,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    _ExpiryDateTextInputFormatter()
                                  ],
                                  decoration: _paymentInputDecoration('Mois'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: yearController,
                                  autofillHints: const <String>[],
                                  enableSuggestions: false,
                                  autocorrect: false,
                                  decoration: _paymentInputDecoration('Année'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: cvcController,
                                  autofillHints: const <String>[],
                                  enableSuggestions: false,
                                  autocorrect: false,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(3),
                                  ],
                                  obscureText: true,
                                  obscuringCharacter: '•',
                                  decoration:
                                      _paymentInputDecoration('Code de sûreté'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: cardholderController,
                            autofillHints: const <String>[],
                            enableSuggestions: false,
                            autocorrect: false,
                            decoration:
                                _paymentInputDecoration('Le nom du détenteur'),
                          ),
                          const SizedBox(height: 10),
                          InkWell(
                            onTap: () => setState(
                                () => sendEmailReceipt = !sendEmailReceipt),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: Checkbox(
                                    value: sendEmailReceipt,
                                    onChanged: (value) => setState(() =>
                                        sendEmailReceipt = value ?? false),
                                    activeColor: const Color(0xFF0B5FB3),
                                    checkColor: Colors.white,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    side: const BorderSide(
                                        color: Color(0xFF9CA3AF), width: 1),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'Adresse e-mail',
                                  style: TextStyle(
                                    color: Color(0xFF374151),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: emailController,
                            autofillHints: const <String>[],
                            enableSuggestions: false,
                            autocorrect: false,
                            enabled: sendEmailReceipt,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _paymentInputDecoration(''),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: Obx(
                              () => ElevatedButton(
                                onPressed: controller
                                        .isProcessingEnrollment.value
                                    ? null
                                    : () async {
                                        Navigator.of(dialogContext).pop();
                                        final success = await controller
                                            .enrollInCourseWithPayment(course);
                                        if (!success) return;
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0B5FB3),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                child: controller.isProcessingEnrollment.value
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        'Paiement $amountLabel',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 18,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          _buildGatewayFooterBrands(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      cardholderController.dispose();
      cardNumberController.dispose();
      yearController.dispose();
      expiryController.dispose();
      cvcController.dispose();
      emailController.dispose();
    });
  }

  InputDecoration _paymentInputDecoration(String hintText,
      {Widget? prefixIcon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: Color(0xFF9CA3AF),
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: const Color(0xFFFFFFFF),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xFF0B5FB3), width: 1.2),
      ),
    );
  }

  Widget _buildGatewayLogoHeader() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: const LinearGradient(
              colors: [Color(0xFFF97316), Color(0xFFDC2626), Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Icon(Icons.credit_card, color: Colors.white, size: 17),
        ),
        const SizedBox(width: 8),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ClicToPay.com.tn',
              style: TextStyle(
                color: Color(0xFF0B4FA2),
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            Text(
              'by Monétique Tunisie',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGatewayFooterBrands() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 16, color: Color(0xFF9CA3AF)),
            SizedBox(width: 6),
            Text(
              'Paiement sécurisé',
              style: TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        _mastercardBrandChip(),
        _paymentChip(label: 'VISA', color: const Color(0xFF1E3A8A)),
        _paymentChip(label: 'C-Cash', color: const Color(0xFF6B7280)),
        _paymentChip(label: 'e-DINAR', color: const Color(0xFF6B7280)),
      ],
    );
  }

  Widget _paymentChip({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFD1D5DB)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _mastercardBrandChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFD1D5DB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 18,
            height: 12,
            child: Stack(
              children: const [
                Positioned(
                  left: 0,
                  child: CircleAvatar(
                    radius: 6,
                    backgroundColor: Color(0xFFEA4335),
                  ),
                ),
                Positioned(
                  right: 0,
                  child: CircleAvatar(
                    radius: 6,
                    backgroundColor: Color(0xFFF59E0B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          const Text(
            'mastercard',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, bool isCompact) {
    if (_homeController.currentUsername.value == 'Utilisateur' &&
        _homeController.currentEmail.value.trim().isEmpty) {
      Future.microtask(
          () => _homeController.refreshCurrentUserIdentity(force: false));
    }

    final displayName = _homeController.currentUsername.value.trim().isEmpty ||
            _homeController.currentUsername.value == 'Utilisateur'
        ? (_homeController.currentEmail.value.trim().isNotEmpty
            ? _homeController.currentEmail.value.trim()
            : 'Utilisateur')
        : _homeController.currentUsername.value.trim();

    final displayInitial = displayName.isNotEmpty
        ? displayName.substring(0, 1).toUpperCase()
        : 'U';

    return Container(
      height: isCompact ? 60 : 70,
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          if (isCompact) ...[
            IconButton(
              tooltip: 'Menu',
              onPressed: () => CustomSidebar.openDrawerMenu(context),
              icon: const Icon(Icons.menu, color: Color(0xFF475569)),
            ),
          ] else
            SizedBox(
              width: 300,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Rechercher...',
                  hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                  isDense: true,
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          const Spacer(),
          IconButton(
            tooltip: 'Notifications',
            onPressed: () {
              _homeController.selectedMenu.value = -1;
              if (Get.currentRoute != Routes.NOTIFICATIONS) {
                Get.toNamed(Routes.NOTIFICATIONS);
              }
            },
            icon: const Icon(Icons.notifications_none,
                color: Color(0xFF475569), size: 20),
          ),
          CircleAvatar(
            radius: 14,
            backgroundColor: Color(0xFFE2E8F0),
            child: Text(
              displayInitial,
              style: const TextStyle(
                color: Color(0xFF2563EB),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          if (!isCompact) ...[
            const SizedBox(width: 8),
            Text(
              displayName,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.menu_book_outlined,
                    color: Color(0xFF2563EB), size: 28),
                SizedBox(width: 10),
                Text(
                  'Mes Formations',
                  style: TextStyle(
                    height: 1,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Gérez vos cours, modules et leçons',
              style: TextStyle(
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        SizedBox(
          height: 42,
          child: ElevatedButton.icon(
            onPressed: () => _showCourseDialog(context),
            icon: const Icon(Icons.add, size: 18, color: Colors.white),
            label: const Text('Nouveau Cours'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0066D9),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar({String hintText = 'Rechercher un cours...'}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        onChanged: controller.setSearch,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0xFF9CA3AF),
          ),
          prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
          isDense: true,
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
      ),
    );
  }

  Widget _buildCoursesTable(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Obx(() {
        if (controller.isLoading.value) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final courses = controller.filteredCourses;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Row(
                children: const [
                  Expanded(flex: 3, child: _HeaderCell('Titre')),
                  Expanded(flex: 2, child: _HeaderCell('Niveau')),
                  Expanded(flex: 2, child: _HeaderCell('Prix')),
                  Expanded(flex: 2, child: _HeaderCell('Statut')),
                  Expanded(flex: 2, child: _HeaderCell('Créé le')),
                  Expanded(flex: 1, child: _HeaderCell('Actions')),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
            if (courses.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Text(
                  'Aucun cours trouvé',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: courses.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
                itemBuilder: (_, index) =>
                    _buildCourseRow(context, courses[index]),
              ),
          ],
        );
      }),
    );
  }

  Widget _buildCourseRow(BuildContext context, Course course) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              course.title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(course.level,
                style: const TextStyle(color: Color(0xFF475569))),
          ),
          Expanded(
            flex: 2,
            child: Text('${course.price.toStringAsFixed(2)} TND',
                style: const TextStyle(color: Color(0xFF475569))),
          ),
          Expanded(flex: 2, child: _buildStatusBadge(course.status)),
          Expanded(
            flex: 2,
            child: Text(_formatDate(course.createdAt),
                style: const TextStyle(color: Color(0xFF475569))),
          ),
          Expanded(
            flex: 1,
            child: Row(
              children: [
                IconButton(
                  onPressed: () => _showCourseDialog(context, course: course),
                  icon: const Icon(Icons.edit_outlined,
                      size: 18, color: Colors.grey),
                ),
                IconButton(
                  onPressed: () => _confirmDelete(course),
                  icon: const Icon(Icons.delete_outline,
                      size: 18, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final isPublished = status.toLowerCase() == 'publié';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPublished ? const Color(0xFFF0FDF4) : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              isPublished ? const Color(0xFFDCFCE7) : const Color(0xFFFED7AA),
        ),
      ),
      child: Text(
        status,
        style: TextStyle(
          color:
              isPublished ? const Color(0xFF166534) : const Color(0xFF9A3412),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showCourseDialog(BuildContext context, {Course? course}) {
    final isEdit = course != null;
    final titleController = TextEditingController(text: course?.title ?? '');
    final descriptionController =
        TextEditingController(text: course?.description ?? '');
    final priceController =
        TextEditingController(text: course != null ? '${course.price}' : '0');
    String selectedLevel = course?.level ?? 'Débutant';
    String selectedStatus = course?.status ?? 'Brouillon';

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: StatefulBuilder(builder: (context, setState) {
            return Container(
              width: 430,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEdit ? 'Modifier le cours' : 'Créer un nouveau cours',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close,
                            size: 16, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Remplissez les détails ci-dessous pour enregistrer le cours.',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Titre du cours', style: _LabelStyle()),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleController,
                    decoration: _dialogInputDecoration('Titre du cours...'),
                  ),
                  const SizedBox(height: 10),
                  const Text('Description', style: _LabelStyle()),
                  const SizedBox(height: 6),
                  TextField(
                    controller: descriptionController,
                    maxLines: 2,
                    decoration:
                        _dialogInputDecoration('Description du cours...'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Niveau', style: _LabelStyle()),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: selectedLevel,
                              items: const [
                                DropdownMenuItem(
                                    value: 'Débutant', child: Text('Débutant')),
                                DropdownMenuItem(
                                    value: 'Intermédiaire',
                                    child: Text('Intermédiaire')),
                                DropdownMenuItem(
                                    value: 'Avancé', child: Text('Avancé')),
                              ],
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() => selectedLevel = v);
                                }
                              },
                              decoration: _dialogInputDecoration(null),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Prix (TND)', style: _LabelStyle()),
                            const SizedBox(height: 6),
                            TextField(
                              controller: priceController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: _dialogInputDecoration('0').copyWith(
                                suffixIcon: SizedBox(
                                  width: 26,
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          final current = int.tryParse(
                                                  priceController.text
                                                      .trim()) ??
                                              0;
                                          priceController.text =
                                              (current + 10).toString();
                                          setState(() {});
                                        },
                                        child: const Icon(
                                          Icons.keyboard_arrow_up,
                                          size: 14,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () {
                                          final current = int.tryParse(
                                                  priceController.text
                                                      .trim()) ??
                                              0;
                                          final next = current - 10;
                                          priceController.text =
                                              (next < 0 ? 0 : next).toString();
                                          setState(() {});
                                        },
                                        child: const Icon(
                                          Icons.keyboard_arrow_down,
                                          size: 14,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text('Statut', style: _LabelStyle()),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 160,
                    child: DropdownButtonFormField<String>(
                      value: selectedStatus,
                      items: const [
                        DropdownMenuItem(
                            value: 'Brouillon', child: Text('Brouillon')),
                        DropdownMenuItem(
                            value: 'Publié', child: Text('Publié')),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => selectedStatus = v);
                        }
                      },
                      decoration: _dialogInputDecoration(null),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      height: 34,
                      child: ElevatedButton(
                        onPressed: () {
                          final parsedPrice =
                              double.tryParse(priceController.text.trim()) ?? 0;
                          final payload = Course(
                            id: isEdit ? course.id : 0,
                            documentId: isEdit ? course.documentId : '',
                            title: titleController.text.trim(),
                            description: descriptionController.text.trim(),
                            level: selectedLevel,
                            price: parsedPrice,
                            status: selectedStatus,
                            createdAt:
                                isEdit ? course.createdAt : DateTime.now(),
                          );

                          if (isEdit) {
                            controller.editCourse(payload);
                          } else {
                            controller.addCourse(payload);
                          }

                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0066D9),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: Text(
                          isEdit ? 'Mettre à jour' : 'Créer le cours',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }

  void _confirmDelete(Course course) {
    Get.dialog(
      AlertDialog(
        title: const Text('Confirmation'),
        content: Text('Supprimer le cours "${course.title}" ?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.removeCourse(course);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  InputDecoration _dialogInputDecoration(String? hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: Color(0xFF9CA3AF),
      ),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }
}

class _CardNumberTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final trimmed = digits.length > 16 ? digits.substring(0, 16) : digits;

    final buffer = StringBuffer();
    for (var index = 0; index < trimmed.length; index++) {
      buffer.write(trimmed[index]);
      final isGroupBreak = (index + 1) % 4 == 0 && index + 1 != trimmed.length;
      if (isGroupBreak) {
        buffer.write(' ');
      }
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _ExpiryDateTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final trimmed = digits.length > 4 ? digits.substring(0, 4) : digits;

    var formatted = trimmed;
    if (trimmed.length > 2) {
      formatted = '${trimmed.substring(0, 2)}/${trimmed.substring(2)}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;
  const _HeaderCell(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        color: Color(0xFF0F172A),
      ),
    );
  }
}

class _LabelStyle extends TextStyle {
  const _LabelStyle()
      : super(
          fontWeight: FontWeight.w600,
          color: const Color(0xFF111827),
        );
}
