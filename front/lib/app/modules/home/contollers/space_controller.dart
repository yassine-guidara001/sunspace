import 'package:get/get.dart';

class Space {
  final int id;
  final String name;
  final String type;
  final String location;
  final int capacity;
  final double hourlyRate;
  final double dailyRate;
  final double monthlyRate;
  final String status;
  final String description;
  final int reservations;

  Space({
    required this.id,
    required this.name,
    required this.type,
    required this.location,
    required this.capacity,
    required this.hourlyRate,
    required this.dailyRate,
    required this.monthlyRate,
    required this.status,
    this.description = '',
    this.reservations = 0,
  });
}

class SpaceController extends GetxController {
  final spaces = <Space>[].obs;
  final _allSpaces = <Space>[];
  final isLoading = false.obs;
  final searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchSpaces();
  }

  void fetchSpaces() {
    isLoading.value = true;
    _allSpaces.clear();
    spaces.value = List.from(_allSpaces);
    isLoading.value = false;
  }

  void addSpace(Space space) {
    _allSpaces.add(space);
    searchSpaces(searchQuery.value);
  }

  void updateSpace(Space space) {
    int index = _allSpaces.indexWhere((s) => s.id == space.id);
    if (index != -1) {
      _allSpaces[index] = space;
      searchSpaces(searchQuery.value);
    }
  }

  void deleteSpace(int id) {
    _allSpaces.removeWhere((s) => s.id == id);
    searchSpaces(searchQuery.value);
  }

  void searchSpaces(String query) {
    searchQuery.value = query;
    if (query.isEmpty) {
      spaces.value = List.from(_allSpaces);
    } else {
      spaces.value = _allSpaces
          .where((s) =>
              s.name.toLowerCase().contains(query.toLowerCase()) ||
              s.location.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }
}
