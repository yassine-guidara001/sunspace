import 'package:flutter_getx_app/app/data/models/teacher_student_model.dart';
import 'package:flutter_getx_app/app/data/services/teacher_students_service.dart';
import 'package:get/get.dart';

class TeacherStudentsController extends GetxController {
  TeacherStudentsController({TeacherStudentsService? service})
      : _service = service ?? Get.find<TeacherStudentsService>();

  final TeacherStudentsService _service;

  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final searchQuery = ''.obs;
  final students = <TeacherStudentModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadStudents();
  }

  Future<void> loadStudents() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final result = await _service.loadTeacherStudents();
      students.assignAll(result);
    } catch (e) {
      errorMessage.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  void updateSearch(String value) {
    searchQuery.value = value.trim().toLowerCase();
  }

  List<TeacherStudentModel> get filteredStudents {
    final q = searchQuery.value;
    if (q.isEmpty) return students;

    return students.where((row) {
      final haystack =
          '${row.studentName} ${row.studentEmail} ${row.courseName}'
              .toLowerCase();
      return haystack.contains(q);
    }).toList();
  }
}
