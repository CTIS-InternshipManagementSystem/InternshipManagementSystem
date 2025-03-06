import 'package:sembast/sembast.dart';
import '../database.dart';
import '../models/assignment.dart';

class AssignmentService {
  final _assignmentStore = stringMapStoreFactory.store('assignments');

  Future<void> saveAssignment(Assignment assignment) async {
    final db = await DatabaseHelper().database;
    await _assignmentStore.record(assignment.id).put(db, assignment.toMap());
  }

  Future<Assignment?> getAssignment(String id) async {
    final db = await DatabaseHelper().database;
    final record = await _assignmentStore.record(id).get(db);
    if (record != null) {
      return Assignment.fromMap(record);
    }
    return null;
  }

  Future<int> createAssignment(
    String id,
    String courseId,
    String name,
    DateTime deadline,
  ) async {
    final newAssignment = Assignment(
      id: id,
      courseId: courseId,
      name: name,
      deadline: deadline,
    );
    await saveAssignment(newAssignment);
    return 200; // Başarılı işlem için 200 döndürüyoruz
  }

  Future<List<Map<String, dynamic>>> getAssignmentsByCourse(
    String courseId,
  ) async {
    final db = await DatabaseHelper().database;
    final finder = Finder(filter: Filter.equals('courseId', courseId));
    final recordSnapshots = await _assignmentStore.find(db, finder: finder);
    return recordSnapshots.map((snapshot) => snapshot.value).toList();
  }
}
