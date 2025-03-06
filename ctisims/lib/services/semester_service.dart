import 'package:sembast/sembast.dart';
import '../database.dart';
import '../models/semester.dart';

class SemesterService {
  final _semesterStore = stringMapStoreFactory.store('semesters');

  Future<void> saveSemester(Semester semester) async {
    final db = await DatabaseHelper().database;
    await _semesterStore.record(semester.id).put(db, semester.toMap());
  }

  Future<Semester?> getSemester(String id) async {
    final db = await DatabaseHelper().database;
    final record = await _semesterStore.record(id).get(db);
    if (record != null) {
      return Semester.fromMap(record);
    }
    return null;
  }

  Future<int> createSemester(String id, String year, String semester) async {
    final newSemester = Semester(id: id, year: year, semester: semester);
    await saveSemester(newSemester);
    return 200; // Başarılı işlem için 200 döndürüyoruz
  }

  Future<Semester?> getActiveSemester() async {
    final db = await DatabaseHelper().database;
    final finder = Finder(
      sortOrders: [SortOrder('year', false), SortOrder('semester', false)],
      limit: 1,
    );
    final recordSnapshot = await _semesterStore.findFirst(db, finder: finder);
    if (recordSnapshot != null) {
      return Semester.fromMap(recordSnapshot.value);
    }
    return null;
  }

  Future<List<Semester>> getAllSemesters() async {
    final db = await DatabaseHelper().database;
    final recordSnapshots = await _semesterStore.find(db);
    return recordSnapshots.map((snapshot) => Semester.fromMap(snapshot.value)).toList();
  }
}
