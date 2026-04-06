class TeacherStudentModel {
  const TeacherStudentModel({
    required this.enrollmentId,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.courseName,
    required this.progressPercent,
    required this.enrolledAt,
  });

  final String enrollmentId;
  final int studentId;
  final String studentName;
  final String studentEmail;
  final String courseName;
  final int progressPercent;
  final DateTime? enrolledAt;
}
