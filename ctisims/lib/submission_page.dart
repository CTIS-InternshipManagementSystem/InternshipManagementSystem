import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_core/firebase_core.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:html' as html;
import 'package:ctisims/dbHelper.dart';

// Centralized styling constants
class AppStyles {
  static const primaryColor = Colors.orange;
  static const buttonColor = Colors.blue;
  static const cardElevation = 4.0;
  static const borderRadius = 16.0;
  static const padding = EdgeInsets.all(16.0);
  static const fieldSpacing = SizedBox(height: 8);
}

class SubmissionPage extends StatefulWidget {
  final Map<String, String> submission;

  const SubmissionPage({super.key, required this.submission});

  @override
  _SubmissionPageState createState() => _SubmissionPageState();
}

class _SubmissionPageState extends State<SubmissionPage> {
  // File data for Company Evaluation section
  String? _filePath;
  Uint8List? _fileBytes;
  bool _isUploading = false;

  // File data maps for other sections (e.g. CTIS310, CTIS290)
  Map<String, String?> _sectionFilePaths = {};
  Map<String, Uint8List?> _sectionFileBytes = {};
  Map<String, bool> _sectionUploading = {};

  late Future<Map<String, dynamic>> evaluationData;
  
  @override
  void initState() {
    super.initState();
    evaluationData = loadEvaluationData();
  }
  
  Future<Map<String, dynamic>> loadEvaluationData() async {
    final String bilkentId = widget.submission['bilkentId'] ?? '';
    final String courseId = widget.submission['courseId'] ?? '';
    final student = await DBHelper.getStudentInfo(bilkentId);
    final course = await DBHelper.getCourseInfo(courseId);
    final assignments = await DBHelper.getAssignments(courseId);
    List<Map<String, dynamic>> assignmentsWithGrade = [];
    for (var assignment in assignments) {
      String grade;
      try {
        final gradeData = await DBHelper.getGrade(bilkentId, assignment['id'], courseId);
        grade = gradeData != null && gradeData['grade'] != null
            ? gradeData['grade'].toString()
            : "not graded";
      } catch (e) {
        grade = "not graded";
      }
      assignmentsWithGrade.add({
        'name': assignment['name'],
        'grade': grade,
      });
    }
    return {
      'student': student,
      'course': course,
      'assignments': assignmentsWithGrade,
    };
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Helper function to choose file for a specific section
  Future<void> _chooseSectionFile(String sectionTitle) async {
    if (kIsWeb) {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null) {
        setState(() {
          _sectionFileBytes[sectionTitle] = result.files.single.bytes;
          _sectionFilePaths[sectionTitle] = result.files.single.name;
        });
      }
    } else {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.any);
      if (result != null) {
        setState(() {
          _sectionFilePaths[sectionTitle] = result.files.single.path;
        });
      }
    }
  }

  // Helper function to upload file for a specific section
  Future<void> _uploadSectionFile(String sectionTitle, String destinationBase) async {
    setState(() {
      _sectionUploading[sectionTitle] = true;
    });
    try {
      await Firebase.initializeApp();
      String fileName = "${sectionTitle}_${widget.submission['bilkentId']}_${widget.submission['name']}";
      final destination = "$destinationBase/$fileName";
      Reference storageRef = FirebaseStorage.instance.ref(destination);
      if (kIsWeb) {
        if (_sectionFileBytes[sectionTitle] == null) throw Exception("No file selected for $sectionTitle");
        final uploadTask = storageRef.putData(_sectionFileBytes[sectionTitle]!);
        final snapshot = await uploadTask.whenComplete(() => null);
        final downloadUrl = await snapshot.ref.getDownloadURL();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("File uploaded successfully: $downloadUrl")),
        );
      } else {
        if (_sectionFilePaths[sectionTitle] == null) throw Exception("No file selected for $sectionTitle");
        final file = File(_sectionFilePaths[sectionTitle]!);
        final uploadTask = storageRef.putFile(file);
        final snapshot = await uploadTask.whenComplete(() => null);
        final downloadUrl = await snapshot.ref.getDownloadURL();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("File uploaded successfully: $downloadUrl")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error during file upload for $sectionTitle: $e")),
      );
    } finally {
      setState(() {
        _sectionUploading[sectionTitle] = false;
      });
    }
  }

  Widget _buildCTIS310Section(String title) {
    return Card(
      elevation: AppStyles.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyles.borderRadius),
      ),
      child: Padding(
        padding: AppStyles.padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            // Choose file button for this section
            ElevatedButton(
              onPressed: () async {
                await _chooseSectionFile(title);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppStyles.buttonColor),
              child: Text('Choose File for $title'),
            ),
            if (_sectionFilePaths[title] != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('Selected file: ${_sectionFilePaths[title]}'),
              ),
            const SizedBox(height: 8),
            // Upload button for this section
            ElevatedButton(
              onPressed: (_sectionUploading[title] ?? false)
                  ? null
                  : () async {
                      final data = await evaluationData;
                      final student = data['student'] ?? {};
                      final courseData = data['course'] ?? {};
                      final destB = "${courseData['year']} ${courseData['semester']}/CTIS${courseData['code']}/${student['name']}_${student['bilkentId']}";
                      await _uploadSectionFile(title, destB);
                    },
              style: ElevatedButton.styleFrom(backgroundColor: AppStyles.buttonColor),
              child: (_sectionUploading[title] ?? false)
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      ),
                    )
                  : Text('Upload $title'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCTIS290Section() {
    return Card(
      elevation: AppStyles.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyles.borderRadius),
      ),
      child: Padding(
        padding: AppStyles.padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Report',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                await _chooseSectionFile('Report');
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppStyles.buttonColor),
              child: const Text('Choose File for Report'),
            ),
            if (_sectionFilePaths['Report'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('Selected file: ${_sectionFilePaths['Report']}'),
              ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: (_sectionUploading['Report'] ?? false)
                  ? null
                  : () async {
                      final data = await evaluationData;
                      final student = data['student'] ?? {};
                      final courseData = data['course'] ?? {};
                      final destB = "${courseData['year']} ${courseData['semester']}/CTIS${courseData['code']}/${student['name']}_${student['bilkentId']}";
                      await _uploadSectionFile('Report', destB);
                    },
              style: ElevatedButton.styleFrom(backgroundColor: AppStyles.buttonColor),
              child: (_sectionUploading['Report'] ?? false)
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Upload Report'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String studentName = widget.submission['name'] ?? 'Demo student';
    final String bilkentId = widget.submission['bilkentId'] ?? '1110002';
    final String email = widget.submission['email'] ?? 'demo.student@bilkent.edu.tr';
    final String course = widget.submission['course'] ?? 'CTIS310';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Submission Page'),
        backgroundColor: AppStyles.primaryColor,
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: evaluationData,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final student = snapshot.data!['student'] ?? {};
          final courseData = snapshot.data!['course'] ?? {};
          final studentName = student['name'] ?? 'Unknown';
          final bilkentId = student['bilkentId'] ?? '0000000';
          final year = courseData['year'] ?? '2024';
          final semester = courseData['semester'] ?? 'Fall';
          final code = courseData['code'] ?? '310';
          final destinationBase = "${year} ${semester}/CTIS$code/${studentName}_$bilkentId";
          final List assignments = snapshot.data!['assignments'];
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Student Information Card
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Student Information", style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text("Name: ${student['name'] ?? ''}"),
                        Text("Bilkent ID: ${student['bilkentId'] ?? ''}"),
                        Text("Email: ${student['email'] ?? ''}"),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Course Information Card
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Course Information", style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text("Course: CTIS ${courseData['code'] ?? ''}"),
                        Text("Year: ${courseData['year'] ?? ''}"),
                        Text("Semester: ${courseData['semester'] ?? ''}"),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Assignments & Grades Card (grades bilgileri gösteriliyor)
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Assignments", style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        ...assignments.map((assignment) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("${assignment['name']}"),
                                Text("Grade: ${assignment['grade']}"),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // CTIS 310 Specific Sections (grade giriş alanı kaldırılarak upload işlemi eklendi)
                if (courseData['code'] == '310') ...[
                  _buildCTIS310Section('Follow Up 1'),
                  const SizedBox(height: 16),
                  _buildCTIS310Section('Follow Up 2'),
                  const SizedBox(height: 16),
                  _buildCTIS310Section('Follow Up 3'),
                  const SizedBox(height: 16),
                  _buildCTIS310Section('Follow Up 4'),
                  const SizedBox(height: 16),
                  _buildCTIS310Section('Follow Up 5'),
                  const SizedBox(height: 16),
                  _buildCTIS310Section('Report'),
                ],
                // CTIS 290 Specific Section (grade alanı kaldırılarak upload işlemi eklendi)
                if (courseData['code'] == '290') ...[
                  _buildCTIS290Section(),
                ],
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}
