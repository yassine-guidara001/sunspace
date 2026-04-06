import 'package:flutter/material.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/professional_profile_controller.dart';
import 'package:get/get.dart';

import 'custom_sidebar.dart';
import 'dashboard_topbar.dart';

class ProfessionalProfileView extends GetView<ProfessionalProfileController> {
  const ProfessionalProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF0F8),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final showSidebar = constraints.maxWidth >= 1080;

          return Row(
            children: [
              if (showSidebar) const CustomSidebar(),
              Expanded(
                child: Column(
                  children: [
                    const DashboardTopBar(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(22, 22, 22, 26),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 950),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildHeroCard(context),
                                const SizedBox(height: 20),
                                _buildBodyCards(context),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 860;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x160F172A),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 84,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0B6BFF), Color(0xFF7EA3DE)],
                ),
              ),
              child: const Align(
                alignment: Alignment.topLeft,
                child: Text(
                  'ESPACE PROFESSIONNEL',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildAvatarBlock(),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Obx(
                      () => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  controller.username,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF111827),
                                    fontSize: 38,
                                    fontWeight: FontWeight.w800,
                                    height: 1,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.verified_user_rounded,
                                  size: 20, color: Color(0xFF0B6BFF)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            controller.email,
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!compact) _buildProfileActionButton(),
                ],
              ),
            ),
            if (compact)
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _buildProfileActionButton(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarBlock() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 86,
          height: 86,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Icon(Icons.person_outline,
              size: 42, color: Color(0xFF9CA3AF)),
        ),
        Positioned(
          right: -6,
          bottom: -6,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFF0B6BFF),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(Icons.photo_camera_outlined,
                size: 14, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileActionButton() {
    return Obx(
      () => ElevatedButton(
        onPressed: controller.isSaving.value
            ? null
            : controller.onProfileActionPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0B6BFF),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          controller.isSaving.value
              ? 'Enregistrement...'
              : (controller.isEditing.value
                  ? 'Enregistrer'
                  : 'Modifier le profil'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildBodyCards(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 820;

        final aboutCard = _buildAboutCard();
        final detailsCard = _buildDetailsCard();

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              aboutCard,
              const SizedBox(height: 14),
              detailsCard,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 35, child: aboutCard),
            const SizedBox(width: 14),
            Expanded(flex: 65, child: detailsCard),
          ],
        );
      },
    );
  }

  Widget _buildAboutCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A propos',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 14),
            _infoTile(
              icon: Icons.workspace_premium_outlined,
              label: 'SPECIALITE',
              value: controller.specialization,
              iconBg: const Color(0xFFE9F2FF),
              iconColor: const Color(0xFF0B6BFF),
            ),
            const SizedBox(height: 8),
            _infoTile(
              icon: Icons.business_outlined,
              label: 'ORGANISATION',
              value: controller.organization,
              iconBg: const Color(0xFFF3F4F6),
              iconColor: const Color(0xFF9CA3AF),
            ),
            const SizedBox(height: 8),
            _infoTile(
              icon: Icons.calendar_month_outlined,
              label: 'MEMBRE DEPUIS',
              value: controller.joinedSince,
              iconBg: const Color(0xFFFFF4E8),
              iconColor: const Color(0xFFF59E0B),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE7F0FF),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Status',
                style: TextStyle(
                  color: Color(0xFF0B6BFF),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              controller.roleLabel,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Votre profil est visible par les organisateurs d\'espaces et les instructeurs de formations.',
              style: TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
    required Color iconBg,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 17, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Informations detaillées',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Mettez a jour vos informations pour une meilleure experience.',
                  style: TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Obx(
              () {
                final editable = controller.isEditing.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isNarrow = constraints.maxWidth < 520;
                        if (isNarrow) {
                          return Column(
                            children: [
                              _ProfileField(
                                label: 'NUMERO DE TELEPHONE',
                                hint: '+216 --- ---',
                                icon: Icons.phone_outlined,
                                controller: controller.phoneController,
                                enabled: editable,
                              ),
                              const SizedBox(height: 10),
                              _ProfileField(
                                label: 'ENTREPRISE / ORGANISATION',
                                hint: 'Nom de votre entreprise',
                                icon: Icons.business_outlined,
                                controller: controller.organizationController,
                                enabled: editable,
                              ),
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(
                              child: _ProfileField(
                                label: 'NUMERO DE TELEPHONE',
                                hint: '+216 --- ---',
                                icon: Icons.phone_outlined,
                                controller: controller.phoneController,
                                enabled: editable,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _ProfileField(
                                label: 'ENTREPRISE / ORGANISATION',
                                hint: 'Nom de votre entreprise',
                                icon: Icons.business_outlined,
                                controller: controller.organizationController,
                                enabled: editable,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    _ProfileField(
                      label: 'SPECIALISATION PROFESSIONNELLE',
                      hint:
                          'Ex: Consultant RH, Developpeur Senior, Freelance...',
                      icon: Icons.school_outlined,
                      controller: controller.specializationController,
                      enabled: editable,
                    ),
                    const SizedBox(height: 10),
                    _ProfileTextArea(
                      label: 'BIOGRAPHIE / RESUME',
                      hint:
                          'Decrivez brievement votre parcours et vos expertises...',
                      controller: controller.biographyController,
                      enabled: editable,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    required this.enabled,
  });

  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF111827),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFFAFBFD),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Icon(icon, size: 16, color: const Color(0xFF9CA3AF)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: enabled,
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 12,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  style: const TextStyle(
                    color: Color(0xFF374151),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileTextArea extends StatelessWidget {
  const _ProfileTextArea({
    required this.label,
    required this.hint,
    required this.controller,
    required this.enabled,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF111827),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 140,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFFAFBFD),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextField(
            controller: controller,
            enabled: enabled,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 12,
              ),
              border: InputBorder.none,
            ),
            style: const TextStyle(
              color: Color(0xFF374151),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
