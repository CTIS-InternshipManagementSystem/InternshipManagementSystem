import 'package:sembast/sembast.dart';
import '../database.dart';
import '../models/submission.dart';

class SubmissionService {
  final _submissionStore = stringMapStoreFactory.store('submissions');

  Future<void> saveSubmission(Submission submission) async {
    final db = await DatabaseHelper().database;
    await _submissionStore.record(submission.id).put(db, submission.toMap());
  }

  Future<Submission?> getSubmission(String id) async {
    final db = await DatabaseHelper().database;
    final record = await _submissionStore.record(id).get(db);
    if (record != null) {
      return Submission.fromMap(record);
    }
    return null;
  }

  Future<int> createSubmission(
    String id,
    String studentId,
    String assignmentId,
    String comments,
    DateTime submittedAt,
  ) async {
    final newSubmission = Submission(
      id: id,
      studentId: studentId,
      assignmentId: assignmentId,
      comments: comments,
      submittedAt: submittedAt,
    );
    await saveSubmission(newSubmission);
    return 200; // Başarılı işlem için 200 döndürüyoruz
  }

  Future<List<Map<String, dynamic>>> getSubmissionsByAssignment(
    String assignmentId,
  ) async {
    final db = await DatabaseHelper().database;
    final finder = Finder(filter: Filter.equals('assignmentId', assignmentId));
    final recordSnapshots = await _submissionStore.find(db, finder: finder);
    return recordSnapshots.map((snapshot) => snapshot.value).toList();
  }

  Future<int> submit310(
    String bilkentId,
    String comments,
    String assignmentId,
  ) async {
    final id =
        DateTime.now().millisecondsSinceEpoch
            .toString(); // Benzersiz ID oluşturma
    final submittedAt = DateTime.now();
    return await createSubmission(
      id,
      bilkentId,
      assignmentId,
      comments,
      submittedAt,
    );
  }

  Future<int> submit290(String bilkentId, String comments) async {
    final id =
        DateTime.now().millisecondsSinceEpoch
            .toString(); // Benzersiz ID oluşturma
    final assignmentId = 'report'; // CTIS290 için sabit assignmentId
    final submittedAt = DateTime.now();
    return await createSubmission(
      id,
      bilkentId,
      assignmentId,
      comments,
      submittedAt,
    );
  }
}
