abstract class Routes {
  Routes._();

  /// AUTH
  static const LOGIN = '/login';
  static const REGISTER = '/register';
  static const FORGOT_PASSWORD = '/forgot-password';
  static const RESET_PASSWORD = '/reset-password';

  /// DASHBOARD
  static const HOME = '/home';

  /// GESTION
  static const SPACES = '/spaces';
  static const EQUIPMENTS = '/equipments';
  static const USERS = '/users';
  static const RESERVATIONS = '/reservations';
  static const MY_RESERVATIONS = '/my-reservations';
  static const ASSOCIATIONS = '/associations';
  static const PAYMENTS = '/payments';
  static const PROFESSIONAL_SUBSCRIPTIONS = '/professional-subscriptions';
  static const FORMATIONS = '/formations';
  static const SESSIONS = '/sessions';
  static const DEVOIRS = '/devoirs';
  static const TEACHER_STUDENTS = '/teacher-students';
  static const ASSOCIATION_MEMBERS = '/association-members';
  static const ASSOCIATION_BUDGET_USAGE = '/association-budget-usage';
  static const COMMUNICATION = '/communication';
  static const NOTIFICATIONS = '/notifications';
  static const CREATE_SPACE = '/create-space';
  static const STUDENT_SPACES = '/student-spaces';

  /// PLAN — une seule constante, utilisée partout
  static const PLAN = '/plan';

  /// AUTRES
  static const PROFILE = '/profile';
  static const USER_DETAILS = '/user-details';
  static const SETTINGS = '/settings';
  static const ABOUT = '/about';
}
