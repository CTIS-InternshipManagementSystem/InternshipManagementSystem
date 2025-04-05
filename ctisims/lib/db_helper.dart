import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class DBHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Temel Firestore işlemleri

  /// Yeni belge ekler ve [DocumentReference] döner.
  static Future<DocumentReference> insert(
    String collection,
    Map<String, dynamic> data,
  ) async {
    return await _firestore.collection(collection).add(data);
  }

  /// Belirtilen koleksiyondaki tüm belgeleri getirir.
  static Future<List<Map<String, dynamic>>> query(String collection) async {
    final QuerySnapshot snapshot =
        await _firestore.collection(collection).get();
    return snapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
        .toList();
  }

  /// Belirtilen belgeyi günceller.
  static Future<void> update(
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) async {
    await _firestore.collection(collection).doc(docId).update(data);
  }

  /// Belirtilen belgeyi siler.
  static Future<void> delete(String collection, String docId) async {
    await _firestore.collection(collection).doc(docId).delete();
  }

  // --- Kullanıcı İşlemleri ---

  /// Login: Email'e göre User koleksiyonundan eşleşen kullanıcıyı getirir.
  static Future<Map<String, dynamic>> login(String email) async {
    final snapshot =
        await _firestore
            .collection('User')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();
    if (snapshot.docs.isNotEmpty) {
      final user = snapshot.docs.first.data();
      return {
        'role': user['role'],
        'bilkentId': user['bilkentId'],
        'username': user['name'],
      };
    }
    throw Exception('Login failed');
  }

  /// Yeni kullanıcı ekler.
  static Future<void> addUser(
    String name,
    String email,
    String bilkentId,
    String role,
    String supervisor,
  ) async {
    // Check if email is unique
    final emailSnapshot =
        await _firestore
            .collection('User')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();
    if (emailSnapshot.docs.isNotEmpty) {
      throw Exception('Email already exists');
    }

    // Check if bilkentId is unique
    final bilkentIdSnapshot =
        await _firestore
            .collection('User')
            .where('bilkentId', isEqualTo: bilkentId)
            .limit(1)
            .get();
    if (bilkentIdSnapshot.docs.isNotEmpty) {
      throw Exception('Bilkent ID already exists');
    }

    // Add new user
    await _firestore.collection('User').add({
      'name': name,
      'email': email,
      'bilkentId': bilkentId,
      'role': role,
      'supervisorId': supervisor,
    });
  }

  /// Belirtilen bilkentId'ye sahip kullanıcıyı getirir.
  static Future<Map<String, dynamic>> getStudentInfo(String bilkentId) async {
    debugPrint("Getting student info for bilkentId: $bilkentId");

    try {
      final snapshot =
          await _firestore
              .collection('User')
              .where('bilkentId', isEqualTo: bilkentId)
              .limit(1)
              .get();

      if (snapshot.docs.isNotEmpty) {
        final userData = snapshot.docs.first.data();
        debugPrint("Found student: ${userData['name']}");
        return {'id': snapshot.docs.first.id, ...userData};
      }

      debugPrint("No student found with bilkentId: $bilkentId");
      // Return a default map with placeholder values instead of throwing exception
      return {
        'id': bilkentId,
        'name': 'Unknown Student ($bilkentId)',
        'email': '',
        'bilkentId': bilkentId,
        'role': 'Student',
      };
    } catch (e) {
      debugPrint("Error getting student info: $e");
      // Return a default map in case of error
      return {
        'id': bilkentId,
        'name': 'Error retrieving student',
        'email': '',
        'bilkentId': bilkentId,
        'role': 'Student',
      };
    }
  }

  //Get all students
  static Future<List<Map<String, dynamic>>> getAllStudents() async {
    final snapshot =
        await _firestore
            .collection('User')
            .where('role', isEqualTo: 'Student')
            .get();
    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    }
    throw Exception('Failed to fetch student info');
  }

  // --- Course İşlemleri ---

  /// Tüm kursları getirir.
  static Future<List<Map<String, dynamic>>> getAllCourses() async {
    final snapshot = await _firestore.collection('Course').get();
    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    }
    throw Exception('Failed to fetch course info');
  }

  /// Aktif (isActive: true) kursları getirir.
  static Future<List<Map<String, dynamic>>> getCourseForStudent(
    String bilkentId,
  ) async {
    List<String> courseIds = [];
    final snapshot2 =
        await _firestore
            .collection('StudentCourses')
            .where('bilkentId', isEqualTo: bilkentId)
            .where('isActive', isEqualTo: true)
            .get();
    if (snapshot2.docs.isNotEmpty) {
      for (var doc in snapshot2.docs) {
        print(
          'Document data: ${doc.data()}',
        ); // Hata ayıklama için belge verilerini yazdırın
        if (doc.data().containsKey('courseId')) {
          courseIds.add(doc.data()['courseId'].toString());
        } else {
          print('courseId not found in document: ${doc.id}');
        }
      }
    } else {
      print('No documents found for bilkentId: $bilkentId and isActive: true');
    }

    debugPrint("CourseIds: $courseIds");

    final snapshot =
        await _firestore
            .collection('Course')
            .where('isActive', isEqualTo: true)
            .where('courseId', whereIn: courseIds)
            .get();
    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    }
    throw Exception('Failed to fetch active course info');
  }

  /// Belirtilen courseCode için aktif kursu (Course koleksiyonunda) getirir.
  static Future<DocumentSnapshot?> getActiveCourseDoc(String code) async {
    final snapshot =
        await _firestore
            .collection('Course')
            .where('code', isEqualTo: code)
            .where('isActive', isEqualTo: true)
            .limit(1)
            .get();

    if (snapshot.docs.isNotEmpty) {
      debugPrint("Found active course with code: $code");
      return snapshot.docs.first;
    }

    debugPrint(
      "No active course found for code: $code. Found ${snapshot.size} courses",
    );

    // Get all courses for debugging
    final allCourses = await _firestore.collection('Course').get();
    debugPrint("All courses (${allCourses.docs.length}):");
    for (var doc in allCourses.docs) {
      final data = doc.data();
      debugPrint("Course: code=${data['code']}, isActive=${data['isActive']}");
    }

    return null;
  }

  /// Kursu pasif hale getirir (isActive: false).
  static Future<void> deactiveCourse(String courseId) async {
    await _firestore.collection('Course').doc(courseId).update({
      'isActive': false,
    });
    await _firestore
        .collection('StudentCourses')
        .where('courseId', isEqualTo: courseId)
        .get()
        .then((value) {
          for (var doc in value.docs) {
            doc.reference.update({'isActive': false});
          }
        });
  }

  /// Creates a new course and automatically creates assignments.
  /// Parameters:
  ///   course: Either "CTIS310" or "CTIS290"
  ///   year: e.g. "2020-2021", "2022-2023", etc.
  ///   semester: e.g. "Fall" or "Spring"
  ///   isActive: should be true when creating a new course.
  static Future<void> createCourse(
    String course,
    String year,
    String semester,
    bool isActive,
  ) async {
    // Use numeric course code: if course is "CTIS310", code becomes "310"; if "CTIS290", becomes "290".
    final String numericCode =
        course.startsWith("CTIS") ? course.substring(4) : course;
    //Check is there any isActive true course
    final QuerySnapshot activeCourses =
        await _firestore
            .collection('Course')
            .where('isActive', isEqualTo: true)
            .where('code', isEqualTo: numericCode)
            .get();
    if (activeCourses.docs.isNotEmpty) {
      if (isActive)
        throw Exception(
          "There is already an active course. Deactivate it first.",
        );
    }

    // Check for duplicate course in the same year and semester.
    final QuerySnapshot duplicate =
        await _firestore
            .collection('Course')
            .where('year', isEqualTo: year)
            .where('semester', isEqualTo: semester)
            .where('code', isEqualTo: numericCode)
            .get();
    if (duplicate.docs.isNotEmpty) {
      throw Exception(
        "A course with code $course for $year $semester already exists.",
      );
    }
    // Create a new course document.
    final DocumentReference newCourse = _firestore.collection('Course').doc();
    await newCourse.set({
      'code': numericCode,
      'year': year,
      'semester': semester,
      'isActive': isActive,
      // Specific courseId assigned as string: "1" for CTIS310, "2" for CTIS290.
      'courseId': newCourse.id,
    });
    // Automatically create assignments for the course.
    if (numericCode == "290") {
      // Create Report assignment for CTIS290.
      final DocumentReference newAssignment =
          _firestore.collection('Assignment').doc();
      await newAssignment.set({
        'courseCode': "290",
        'courseId': newCourse.id,
        // Deadline: 23 April 2025 at 22:45:00 UTC+3 = UTC 19:45:00.
        'deadline': Timestamp.fromDate(DateTime.utc(2025, 4, 23, 19, 45, 0)),
        'name': "Report",
        'id': newAssignment.id,
      });
    } else if (numericCode == "310") {
      // Create Follow Up 1 assignment for CTIS310.
      for (int i = 1; i <= 5; i++) {
        final DocumentReference newAssignment =
            _firestore.collection('Assignment').doc();
        await newAssignment.set({
          'courseCode': "310",
          'courseId': newCourse.id,
          // Deadline: 30 days apart for each follow up.
          'deadline': Timestamp.fromDate(
            DateTime.now().toUtc().add(Duration(days: 20 * i)),
          ),
          'name': "Follow Up $i",
          'id': newAssignment.id,
        });
      }
      final DocumentReference newAssignment =
          _firestore.collection('Assignment').doc();
      await newAssignment.set({
        'courseCode': "310",
        'courseId': newCourse.id,
        // Deadline: 30 days apart for each follow up.
        'deadline': Timestamp.fromDate(
          DateTime.now().toUtc().add(Duration(days: 120)),
        ),
        'name': "Report",
        'id': newAssignment.id,
      });
      // Additional assignments (e.g., Follow Up 2, etc.) can be created here if desired.
    }
  }

  // --- Assignment İşlemleri ---

  /// Verilen courseCode'e sahip aktif kursu bulup, ilgili Assignment belgesinde
  /// [assignmentName] eşleşen kaydın deadline'ını günceller.
  static Future<void> changeDeadlineSettings(
    String courseCode,
    String assignmentName,
    DateTime deadline,
  ) async {
    final courseDoc = await getActiveCourseDoc(courseCode);
    if (courseDoc == null) {
      throw Exception('No active course found for code $courseCode');
    }
    final courseId =
        (courseDoc.data() as Map<String, dynamic>)['courseId'].toString();
    final snapshot =
        await _firestore
            .collection('Assignment')
            .where('courseId', isEqualTo: courseId)
            .where('name', isEqualTo: assignmentName)
            .limit(1)
            .get();
    if (snapshot.docs.isNotEmpty) {
      await snapshot.docs.first.reference.update({
        'deadline': Timestamp.fromDate(deadline),
      });
    } else {
      throw Exception('Failed to find assignment for changing deadline');
    }
  }

  /// Aktif kursa ait Assignment'ları getirir.
  static Future<List<Map<String, dynamic>>> getActiveCourseAssignments(
    String code,
  ) async {
    final courseDoc = await getActiveCourseDoc(code);
    if (courseDoc == null) {
      return [];
    }
    final courseId =
        (courseDoc.data() as Map<String, dynamic>)['courseId'].toString();
    final snapshot =
        await _firestore
            .collection('Assignment')
            .where('courseId', isEqualTo: courseId)
            .get();
    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    }
    return [];
  }

  /// Streams current deadlines for CTIS 310.
  static Stream<List<Map<String, dynamic>>> streamCurrentDeadline310() async* {
    final courseDoc = await getActiveCourseDoc("310");
    if (courseDoc == null) {
      yield [];
      return;
    }
    final courseId =
        (courseDoc.data() as Map<String, dynamic>)['courseId'].toString();
    yield* _firestore
        .collection('Assignment')
        .where('courseId', isEqualTo: courseId)
        .where('courseCode', isEqualTo: '310')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => {
                      'id': doc.id,
                      ...doc.data() as Map<String, dynamic>,
                    },
                  )
                  .toList(),
        );
  }

  /// Streams current deadlines for CTIS 290.
  static Stream<List<Map<String, dynamic>>> streamCurrentDeadline290() async* {
    final courseDoc = await getActiveCourseDoc("290");
    if (courseDoc == null) {
      yield [];
      return;
    }
    final courseId =
        (courseDoc.data() as Map<String, dynamic>)['courseId'].toString();
    yield* _firestore
        .collection('Assignment')
        .where('courseId', isEqualTo: courseId)
        .where('courseCode', isEqualTo: '290')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => {
                      'id': doc.id,
                      ...doc.data() as Map<String, dynamic>,
                    },
                  )
                  .toList(),
        );
  }

  // --- Grade İşlemleri ---

  //Get all grades according to course with student name and id
  static Future<Map<String, dynamic>> getAllGradesWithStudentInfo(
    String courseId,
  ) async {
    debugPrint("Getting grades for courseId: $courseId");

    try {
      // First, check if the courseId is valid by looking it up in the Course collection
      final courseSnapshot =
          await _firestore
              .collection('Course')
              .where('courseId', isEqualTo: courseId)
              .limit(1)
              .get();

      if (courseSnapshot.docs.isEmpty) {
        debugPrint("Warning: No course found with courseId: $courseId");

        // Try to get course by document ID as fallback
        final courseDocSnapshot =
            await _firestore.collection('Course').doc(courseId).get();

        if (courseDocSnapshot.exists) {
          final courseData = courseDocSnapshot.data()!;
          debugPrint(
            "Found course by document ID: ${courseData['code']} (${courseData['year']} ${courseData['semester']})",
          );
          // Continue with the document ID approach
        } else {
          debugPrint(
            "Error: Could not find course with ID: $courseId (not even as document ID)",
          );
          return {'grades': {}, 'error': 'Course not found'};
        }
      } else {
        final courseData = courseSnapshot.docs.first.data();
        debugPrint(
          "Found course: ${courseData['code']} (${courseData['year']} ${courseData['semester']})",
        );
      }

      // Now query for grades with this courseId
      final snapshot =
          await _firestore
              .collection('Grade')
              .where('courseId', isEqualTo: courseId)
              .get();

      debugPrint(
        "Found ${snapshot.docs.length} grade documents for courseId: $courseId",
      );

      if (snapshot.docs.isEmpty) {
        // If we don't find any grades with this ID, try another approach
        // Maybe the courseId is stored as the document ID in the Grade collection
        final altSnapshot = await _firestore.collection('Grade').get();

        debugPrint(
          "Searching among all ${altSnapshot.docs.length} grade documents",
        );

        // Filter manually
        final matchingDocs =
            altSnapshot.docs.where((doc) {
              final data = doc.data();
              return data['courseId'] == courseId;
            }).toList();

        if (matchingDocs.isNotEmpty) {
          debugPrint(
            "Found ${matchingDocs.length} matching grade documents after manual filtering",
          );

          Map<String, Map<String, dynamic>> grades = {};
          for (var doc in matchingDocs) {
            final data = doc.data();
            debugPrint("Processing grade document: ${doc.id}, data: $data");

            try {
              final student = await getStudentInfo(data['bilkentId']);
              debugPrint(
                "Retrieved student info: ${student['name']} (${student['bilkentId']})",
              );

              // Use bilkentId as the map key
              final bilkentId = student['bilkentId'];
              grades[bilkentId] ??= {'name': student['name'], 'grades': {}};

              // Process the assignment
              await _processAssignmentAndGrade(grades, student, data);
            } catch (e) {
              debugPrint("Error processing grade document: $e");
            }
          }

          debugPrint("Returning grades for ${grades.length} students");
          return {'grades': grades};
        } else {
          debugPrint(
            "No grades found for courseId: $courseId even after manual filtering",
          );
          return {'grades': {}};
        }
      }

      Map<String, Map<String, dynamic>> grades = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        debugPrint("Processing grade document: ${doc.id}, data: $data");

        try {
          final student = await getStudentInfo(data['bilkentId']);
          debugPrint(
            "Retrieved student info: ${student['name']} (${student['bilkentId']})",
          );

          // Use bilkentId as the map key
          final bilkentId = student['bilkentId'];
          grades[bilkentId] ??= {'name': student['name'], 'grades': {}};

          // Process the assignment
          await _processAssignmentAndGrade(grades, student, data);
        } catch (e) {
          debugPrint("Error processing grade document: $e");
        }
      }

      debugPrint("Returning grades for ${grades.length} students");
      return {'grades': grades};
    } catch (e) {
      debugPrint("Error in getAllGradesWithStudentInfo: $e");
      return {'grades': {}, 'error': e.toString()};
    }
  }

  // Helper method to process assignment and grade data
  static Future<void> _processAssignmentAndGrade(
    Map<String, Map<String, dynamic>> grades,
    Map<String, dynamic> student,
    Map<String, dynamic> data,
  ) async {
    // Attempt to fetch the assignment document
    final assignmentId = data['assignmentId'];
    final assignmentDoc =
        await _firestore.collection('Assignment').doc(assignmentId).get();

    String assignmentName;
    if (assignmentDoc.exists) {
      final assignmentData = assignmentDoc.data()!;
      assignmentName = assignmentData['name'] as String;
      debugPrint("Found assignment: $assignmentName");
    } else {
      debugPrint(
        "Assignment document not found for ID: $assignmentId, using ID as fallback",
      );

      // Fallback: Try to determine assignment name based on assignmentId
      if (assignmentId == "1") {
        assignmentName = "Follow Up 1";
      } else if (assignmentId == "2") {
        assignmentName = "Follow Up 2";
      } else if (assignmentId == "3") {
        assignmentName = "Follow Up 3";
      } else if (assignmentId == "4") {
        assignmentName = "Follow Up 4";
      } else if (assignmentId == "5") {
        assignmentName = "Follow Up 5";
      } else if (assignmentId == "6" ||
          assignmentId.toLowerCase() == "report") {
        assignmentName = "Report";
      } else if (assignmentId.toLowerCase().contains("company")) {
        assignmentName = "Company Evaluation";
      } else {
        // If we can't determine the name, use the ID with a prefix
        assignmentName = "Assignment $assignmentId";
      }

      debugPrint("Using fallback assignment name: $assignmentName");
    }

    final grade = data['grade'];
    debugPrint("Assignment: $assignmentName, Grade: $grade");

    // Use bilkentId as the key instead of Firestore document ID
    final bilkentId = student['bilkentId'];
    grades[bilkentId] ??= {'name': student['name'], 'grades': {}};
    grades[bilkentId]!['grades'][assignmentName] = grade;
  }

  /// Yeni not ekler (Grade koleksiyonu).
  static Future<void> enterGrade(
    String bilkentId,
    String courseId,
    String assignmentName,
    double grade,
  ) async {
    final assignments = await getAssignmentwithName(assignmentName, courseId);
    Map<String, dynamic> assignment;
    if (assignments.isEmpty) {
      if (assignmentName == "Company Evaluation") {
        // Create new assignment document for Company Evaluation if it doesn't exist.
        DocumentReference newAssignment = _firestore.collection('Assignment').doc();
        await newAssignment.set({
          'courseId': courseId,
          'name': assignmentName,
          'deadline': Timestamp.now(), // default deadline
          'courseCode': courseId,      // fallback value
          'id': newAssignment.id,
        });
        assignment = {'id': newAssignment.id};
      } else {
        throw Exception('Assignment not found for name: $assignmentName and courseId: $courseId');
      }
    } else {
      assignment = assignments.first;
    }
    
    // Look for an existing Grade document for this student and assignment.
    final gradeSnapshot = await _firestore
        .collection('Grade')
        .where('bilkentId', isEqualTo: bilkentId)
        .where('courseId', isEqualTo: courseId)
        .where('assignmentId', isEqualTo: assignment['id'])
        .limit(1)
        .get();
    
    if (gradeSnapshot.docs.isNotEmpty) {
      await gradeSnapshot.docs.first.reference.update({
        'grade': grade,
      });
    } else {
      await _firestore.collection('Grade').add({
        'bilkentId': bilkentId,
        'courseId': courseId,
        'assignmentId': assignment['id'],
        'grade': grade,
      });
    }
  }

  /// Belirtilen kursa ait tüm notları getirir.
  static Future<Map<String, dynamic>> getAllGrades(String courseId) async {
    final snapshot =
        await _firestore
            .collection('Grade')
            .where('courseId', isEqualTo: courseId)
            .get();
    if (snapshot.docs.isNotEmpty) {
      Map<String, Map<String, dynamic>> grades = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final student = await getStudentInfo(data['bilkentId']);
        final assignmentDoc =
            await _firestore
                .collection('Assignment')
                .doc(data['assignmentId'])
                .get();
        if (assignmentDoc.exists) {
          final assignmentData = assignmentDoc.data()!;
          final assignmentName = assignmentData['name'] as String;
          grades[student['id']] ??= {'name': student['name'], 'grades': {}};
          grades[student['id']]!['grades'][assignmentName] = data['grade'];
        }
      }
      return {'grades': grades};
    }
    throw Exception('Failed to fetch grade info');
  }

  // --- StudentCourses İşlemleri ---

  //Change company Evaluation
  static Future<void> changeCompanyEvaluation(
    String bilkentId,
    String courseId,
    bool companyEvaluationUploaded,
  ) async {
    await _firestore
        .collection('StudentCourses')
        .where('courseId', isEqualTo: courseId)
        .where('bilkentId', isEqualTo: bilkentId)
        .limit(1)
        .get()
        .then((value) {
          if (value.docs.isNotEmpty) {
            value.docs.first.reference.update({
              'companyEvaluationUploaded': companyEvaluationUploaded,
            });
          }
        });
  }

  /// Belirtilen kursa kayıtlı studentCourseları getir
  static Future<List<Map<String, dynamic>>> getStudentsFromCourses(
    String courseId,
  ) async {
    final snapshot =
        await _firestore
            .collection('StudentCourses')
            .where('courseId', isEqualTo: courseId)
            .get();
    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    }
    // Return empty list if no documents found
    return [];
  }

  static Future<List<Map<String, dynamic>>>
  getStudentCoursesWithCourseInfo() async {
    final studentCoursesSnapshot =
        await _firestore.collection('StudentCourses').get();
    List<Map<String, dynamic>> studentCoursesWithCourseInfo = [];

    for (var doc in studentCoursesSnapshot.docs) {
      final studentCourseData = doc.data();
      final courseId = studentCourseData['courseId'];

      final courseSnapshot =
          await _firestore
              .collection('Course')
              .where('courseId', isEqualTo: courseId)
              .limit(1)
              .get();

      if (courseSnapshot.docs.isNotEmpty) {
        final courseData = courseSnapshot.docs.first.data();
        studentCoursesWithCourseInfo.add({
          'name': studentCourseData['name'],
          'bilkentId': studentCourseData['bilkentId'],
          'companyEvaluationUploaded':
              studentCourseData['companyEvaluationUploaded'],
          'course': {
            'code': courseData['code'],
            'courseId': courseData['courseId'],
            'isActive': courseData['isActive'],
            'semester': courseData['semester'],
            'year': courseData['year'],
          },
        });
      }
    }

    return studentCoursesWithCourseInfo;
  }

  //Add student to StudentCourses
  static Future<void> addStudentToCourse(
    String bilkentId,
    String courseId,
    String name,
  ) async {
    final existingAssignment =
        await _firestore
            .collection('StudentCourses')
            .where('bilkentId', isEqualTo: bilkentId)
            .where('courseId', isEqualTo: courseId)
            .limit(1)
            .get();

    if (existingAssignment.docs.isNotEmpty) {
      throw Exception("User is already assigned to that course.");
    }

    bool isActive = false;
    final courseSnapshot =
        await _firestore
            .collection('Course')
            .where('courseId', isEqualTo: courseId)
            .limit(1)
            .get();

    if (courseSnapshot.docs.isNotEmpty) {
      isActive = courseSnapshot.docs.first.data()['isActive'];
    }
    final courseStudentDoc =
        await _firestore.collection('StudentCourses').doc();
    await courseStudentDoc.set({
      'id': courseStudentDoc.id,
      'bilkentId': bilkentId,
      'courseId': courseId,
      'name': name,
      'companyEvaluationUploaded': false,
      'isActive': isActive,
    });
  }

  // --- Submissions İşlemleri ---

  /// submit310: Course için (courseCode "310") yeni Submission ekler.
  static Future<void> submit310(
    String bilkentId,
    String comments,
    String assignmentId,
  ) async {
    await _firestore.collection('Submissions').add({
      'courseId': '310', // courseCode olarak
      'bilkentId': bilkentId,
      'assignmentId': assignmentId,
      'comments': comments,
      'submittedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// submit290: Course için (courseCode "290") yeni Submission ekler.
  static Future<void> submit290(
    String bilkentId,
    String comments,
    String assignmentId,
  ) async {
    await _firestore.collection('Submissions').add({
      'courseId': '290', // courseCode olarak
      'bilkentId': bilkentId,
      'assignmentId': assignmentId,
      'comments': comments,
      'submittedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // --- getCurrentDetails ---

  /// Verilen courseCode için aktif kurs ve ilişkili Assignment'ları getirir.
  static Future<Map<String, dynamic>> getCurrentDetails(
    String courseCode,
  ) async {
    final courseDoc = await getActiveCourseDoc(courseCode);
    if (courseDoc == null) {
      throw Exception('No active course found for code $courseCode');
    }
    final courseId =
        (courseDoc.data() as Map<String, dynamic>)['courseId'].toString();
    final assignmentsSnapshot =
        await _firestore
            .collection('Assignment')
            .where('courseId', isEqualTo: courseId)
            .get();
    List<Map<String, dynamic>> assignments =
        assignmentsSnapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
            .toList();

    return {
      'course': {'id': courseId, ...courseDoc.data() as Map<String, dynamic>},
      'assignments': assignments,
    };
  }

  // Get course info by courseId
  static Future<Map<String, dynamic>> getCourseInfo(String courseId) async {
    final doc =
        await _firestore
            .collection('Course')
            .where('courseId', isEqualTo: courseId)
            .limit(1)
            .get();
    if (doc.docs.isNotEmpty) {
      return doc.docs.first.data() as Map<String, dynamic>;
    }
    throw Exception("Course not found");
  }

  // Get assignments for a given courseId
  static Future<List<Map<String, dynamic>>> getAssignments(
    String courseId,
  ) async {
    final snapshot =
        await _firestore
            .collection('Assignment')
            .where('courseId', isEqualTo: courseId)
            .get();
    return snapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
        .toList();
  }

  static Future<List<Map<String, dynamic>>> getAssignmentwithName(
    String name,
    String courseId,
  ) async {
    final snapshot =
        await _firestore
            .collection('Assignment')
            .where('name', isEqualTo: name)
            .where('courseId', isEqualTo: courseId)
            .get();
    return snapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
        .toList();
  }

  // Get grade for a given student and assignment
  static Stream<Map<String, dynamic>?> getGrade(
    String bilkentId,
    String assignmentId,
    String courseId,
  ) {
    return _firestore
        .collection('Grade')
        .where('bilkentId', isEqualTo: bilkentId)
        .where('assignmentId', isEqualTo: assignmentId)
        .where('courseId', isEqualTo: courseId)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            return {
              'id': snapshot.docs.first.id,
              ...?snapshot.docs.first.data() as Map<String, dynamic>?,
            };
          }
          return null;
        });
  }
}
