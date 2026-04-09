import 'package:flutter_getx_app/app/modules/home/contollers/equipment_controller.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/course_controller.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/user_controller.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/training_sessions_controller.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/professional_formations_controller.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/professional_profile_controller.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/reservations_controller.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/notifications_controller.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/associations_controller.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/teacher_students_controller.dart';
import 'package:flutter_getx_app/app/modules/reservation/reserver%20espace%20screen.dart';
import 'package:flutter_getx_app/controllers/assignments_controller.dart';
import 'package:flutter_getx_app/app/data/services/associations_service.dart';
import 'package:flutter_getx_app/app/data/services/teacher_students_service.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/views/equipments_view.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/views/courses_view.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/views/dashboard_view.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/views/home_view.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/views/my_reservations_view.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/views/reservations_view.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/views/associations_view.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/views/payments_view.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/views/professional_profile_view.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/views/professional_subscriptions_view.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/views/teacher_students_view.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/views/association_members_view.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/views/association_budget_usage_view.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/association_budget_controller.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/settings_controller.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/views/settings_view.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/views/user_view.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/views/sessions_view.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/views/notifications_page.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/views/communication_view.dart';
import 'package:flutter_getx_app/views/assignments/assignments_list_page.dart';
import 'package:flutter_getx_app/app/modules/spaces/controllers/spaces_controller.dart';
import 'package:flutter_getx_app/app/modules/spaces/views/spaces_view.dart';
import 'package:flutter_getx_app/app/modules/spaces/views/create_space_view.dart';
import 'package:flutter_getx_app/app/modules/spaces/views/student_floor_plan_page.dart';

import 'package:get/get.dart';

// Pages Auth
import 'package:flutter_getx_app/pages/login_page.dart';
import 'package:flutter_getx_app/pages/registre_page.dart';

import 'app_routes.dart';

// Controllers
import 'package:flutter_getx_app/app/modules/home/contollers/home_controller.dart';

class AppPages {
  static final routes = [
    // ── Auth ────────────────────────────────────────────────────────────────
    GetPage(name: Routes.LOGIN, page: () => LoginPage()),
    GetPage(name: Routes.REGISTER, page: () => const RegisterPage()),

    // ── Dashboard ────────────────────────────────────────────────────────────
    GetPage(
      name: Routes.HOME,
      page: () => const DashboardView(),
      binding: BindingsBuilder(() {
        Get.put(HomeController(), permanent: true);
      }),
    ),

    // ── Réserver un espace ───────────────────────────────────────────────────
    // 🔁 Pour calibrer les zones : remplace ReserverEspaceScreen() par le
    //    Scaffold avec FloorPlanCalibrator() ci-dessous, puis remet après.
    GetPage(
      name: Routes.PLAN,
      page: () => const ReserverEspaceScreen(), // ← Production
      //page: () => _calibratorPage(),            // ← Calibration (décommente si besoin)
      binding: BindingsBuilder(() {
        Get.put(HomeController(), permanent: true);
      }),
    ),

    // ── Spaces ───────────────────────────────────────────────────────────────
    GetPage(
      name: Routes.SPACES,
      page: () => SpacesView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<SpaceController>(() => SpaceController(), fenix: true);
        Get.put(HomeController(), permanent: true);
      }),
    ),
    GetPage(
      name: Routes.CREATE_SPACE,
      page: () => const CreateSpaceView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<SpaceController>(() => SpaceController(), fenix: true);
      }),
    ),
    GetPage(
      name: Routes.STUDENT_SPACES,
      page: () => const StudentFloorPlanPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<SpaceController>(() => SpaceController(), fenix: true);
        Get.put(HomeController(), permanent: true);
      }),
    ),
    GetPage(
      name: Routes.EQUIPMENTS,
      page: () => EquipmentsView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => EquipmentController());
        Get.put(HomeController(), permanent: true);
      }),
    ),
    GetPage(
      name: Routes.MY_RESERVATIONS,
      page: () => const MyReservationsView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => ReservationsController(), fenix: true);
        Get.put(HomeController(), permanent: true);
      }),
    ),
    GetPage(
      name: Routes.RESERVATIONS,
      page: () => const ReservationsView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => ReservationsController(), fenix: true);
        Get.put(HomeController(), permanent: true);
      }),
    ),
    GetPage(
      name: Routes.ASSOCIATIONS,
      page: () => const AssociationsView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<AssociationsService>(
          () => AssociationsService(),
          fenix: true,
        );
        Get.lazyPut<AssociationsController>(
          () => AssociationsController(),
          fenix: true,
        );
        Get.put(HomeController(), permanent: true);
      }),
    ),
    GetPage(
      name: Routes.PAYMENTS,
      page: () => const PaymentsView(),
      binding: BindingsBuilder(() {
        Get.put(HomeController(), permanent: true);
      }),
    ),
    GetPage(
      name: Routes.PROFESSIONAL_SUBSCRIPTIONS,
      page: () => const ProfessionalSubscriptionsView(),
      binding: BindingsBuilder(() {
        Get.put(HomeController(), permanent: true);
      }),
    ),
    GetPage(
      name: Routes.PROFILE,
      page: () => const ProfessionalProfileView(),
      binding: BindingsBuilder(() {
        Get.put(HomeController(), permanent: true);
        Get.lazyPut<ProfessionalProfileController>(
          () => ProfessionalProfileController(),
          fenix: true,
        );
      }),
    ),
    GetPage(
      name: Routes.USERS,
      page: () => UserView(),
      binding: BindingsBuilder(() {
        Get.put(UserController(), permanent: true);
      }),
    ),
    GetPage(
      name: Routes.FORMATIONS,
      page: () => const CoursesView(),
      binding: BindingsBuilder(() {
        Get.put(HomeController(), permanent: true);
        Get.put(CourseController(), permanent: true);
        Get.lazyPut<ProfessionalFormationsController>(
          () => ProfessionalFormationsController(),
          fenix: true,
        );
      }),
    ),
    GetPage(
      name: Routes.SESSIONS,
      page: () => const SessionsView(),
      binding: BindingsBuilder(() {
        Get.put(HomeController(), permanent: true);
        Get.lazyPut<TrainingSessionsController>(
          () => TrainingSessionsController(),
          fenix: true,
        );
      }),
    ),
    GetPage(
      name: Routes.TEACHER_STUDENTS,
      page: () => const TeacherStudentsView(),
      binding: BindingsBuilder(() {
        Get.put(HomeController(), permanent: true);
        Get.lazyPut<TeacherStudentsService>(
          () => TeacherStudentsService(),
          fenix: true,
        );
        Get.lazyPut<TeacherStudentsController>(
          () => TeacherStudentsController(),
          fenix: true,
        );
      }),
    ),
    GetPage(
      name: Routes.ASSOCIATION_MEMBERS,
      page: () => const AssociationMembersView(),
      binding: BindingsBuilder(() {
        Get.put(HomeController(), permanent: true);
      }),
    ),
    GetPage(
      name: Routes.ASSOCIATION_BUDGET_USAGE,
      page: () => const AssociationBudgetUsageView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<AssociationsService>(
          () => AssociationsService(),
          fenix: true,
        );
        Get.lazyPut<AssociationBudgetController>(
          () => AssociationBudgetController(),
          fenix: true,
        );
        Get.put(HomeController(), permanent: true);
      }),
    ),
    GetPage(
      name: Routes.DEVOIRS,
      page: () => const AssignmentsListPage(),
      binding: BindingsBuilder(() {
        Get.put(HomeController(), permanent: true);
        Get.lazyPut<AssignmentsController>(
          () => AssignmentsController(),
          fenix: true,
        );
      }),
    ),
    GetPage(
      name: Routes.SETTINGS,
      page: () => const SettingsView(),
      binding: BindingsBuilder(() {
        Get.put(HomeController(), permanent: true);
        Get.lazyPut<SettingsController>(
          () => SettingsController(),
          fenix: true,
        );
      }),
    ),
    GetPage(
      name: Routes.COMMUNICATION,
      page: () => const CommunicationView(),
      binding: BindingsBuilder(() {
        Get.put(HomeController(), permanent: true);
      }),
    ),
    GetPage(
      name: Routes.NOTIFICATIONS,
      page: () => const NotificationsPage(),
      binding: BindingsBuilder(() {
        Get.put(HomeController(), permanent: true);
        if (!Get.isRegistered<NotificationsController>()) {
          Get.put(NotificationsController(), permanent: true);
        }
      }),
    ),
  ];
}
