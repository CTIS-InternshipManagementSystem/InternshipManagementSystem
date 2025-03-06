import 'package:sembast/sembast.dart';
import '../database.dart';
import '../models/deadline.dart';

class DeadlineService {
  final _deadlineStore = stringMapStoreFactory.store('deadlines');

  Future<void> saveDeadline(Deadline deadline) async {
    final db = await DatabaseHelper().database;
    await _deadlineStore.record(deadline.id).put(db, deadline.toMap());
  }

  Future<Deadline?> getDeadline(String id) async {
    final db = await DatabaseHelper().database;
    final record = await _deadlineStore.record(id).get(db);
    if (record != null) {
      return Deadline.fromMap(record);
    }
    return null;
  }

  Future<int> createDeadline(
    String id,
    String courseId,
    String assignmentName,
    DateTime deadline,
  ) async {
    final newDeadline = Deadline(
      id: id,
      courseId: courseId,
      assignmentName: assignmentName,
      deadline: deadline,
    );
    await saveDeadline(newDeadline);
    return 200; // Başarılı işlem için 200 döndürüyoruz
  }

  Future<List<Map<String, dynamic>>> getDeadlinesByCourse(
    String courseId,
  ) async {
    final db = await DatabaseHelper().database;
    final finder = Finder(filter: Filter.equals('courseId', courseId));
    final recordSnapshots = await _deadlineStore.find(db, finder: finder);
    return recordSnapshots.map((snapshot) => snapshot.value).toList();
  }
}
