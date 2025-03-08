import 'dart:io';
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

class EvaluatePage extends StatefulWidget {
  final Map<String, String> submission;

  const EvaluatePage({super.key, required this.submission});

  @override
  _EvaluatePageState createState() => _EvaluatePageState();
}

class _EvaluatePageState extends State<EvaluatePage> {
  final GlobalKey<FormState> _gradeFormKey = GlobalKey<FormState>();

  // Map for CTIS310 section controllers
  final Map<String, TextEditingController> _sectionControllers = {};

  // Separate controller for CTIS290 section
  final TextEditingController _ctis290Controller = TextEditingController();

  final TextEditingController _companyEvaluationController = TextEditingController();

  String? _filePath;
  Uint8List? _fileBytes;
  bool _isUploading = false;
  bool _isDownloading = false;

  // Custom inputFormatters for grade inputs:
  final List<TextInputFormatter> _gradeInputFormatters = [
    // Allow digits and an optional decimal point
    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
    // Block input if the parsed number is greater than 100.
    TextInputFormatter.withFunction((oldValue, newValue) {
      try {
        if (newValue.text.isEmpty) return newValue;
        final double val = double.parse(newValue.text);
        if (val > 100) return oldValue;
        return newValue;
      } catch (e) {
        return newValue;
      }
    })
  ];

  // Helper to return a TextEditingController for a given CTIS310 section title.
  TextEditingController _getSectionController(String sectionTitle) {
    if (!_sectionControllers.containsKey(sectionTitle)) {
      _sectionControllers[sectionTitle] = TextEditingController();
    }
    return _sectionControllers[sectionTitle]!;
  }

  // Validator function for grade inputs.
  String? _validateGrade(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a grade';
    }
    final double? grade = double.tryParse(value);
    if (grade == null) {
      return 'Please enter a valid number';
    }
    if (grade < 0 || grade > 100) {
      return 'Grade must be between 0 and 100';
    }
    return null;
  }

  @override
  void dispose() {
    for (var controller in _sectionControllers.values) {
      controller.dispose();
    }
    _ctis290Controller.dispose();
    _companyEvaluationController.dispose();
    super.dispose();
  }

  late Future<Map<String, dynamic>> evaluationData;
  
  @override
  void initState() {
    super.initState();
    evaluationData = loadEvaluationData();
  }
  
  Future<Map<String, dynamic>> loadEvaluationData() async {
    // Extract bilkentId and courseId from the submission map.
    final String bilkentId = widget.submission['bilkentId'] ?? '';
    final String courseId = widget.submission['courseId'] ?? '';
    // Get student info using DBHelper.getStudentInfo (or getUserInfo if available)
    final student = await DBHelper.getStudentInfo(bilkentId);
    // Get course info (expects to return fields: year, semester, code)
    final course = await DBHelper.getCourseInfo(courseId);
    // Get assignments for the course using DBHelper.getAssignments
    final assignments = await DBHelper.getAssignments(courseId);
    List<Map<String, dynamic>> assignmentsWithGrade = [];
    for (var assignment in assignments) {
      // Use the assignment's id to fetch corresponding grade from the Grade collection.
      // For instance, if assignment['id'] == "3" and a Grade document exists with
      // { assignmentId: "3", bilkentId: "22002357", courseId: "1", grade: 85 },
      // then that grade (85) is returned; otherwise, "not graded" is set.
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
  Widget build(BuildContext context) {
    final String studentName = widget.submission['studentName'] ?? 'Demo student';
    final String bilkentId = widget.submission['bilkentId'] ?? '1110002';
    final String email = widget.submission['email'] ?? 'demo.student@bilkent.edu.tr';
    final String course = widget.submission['course'] ?? 'CTIS310';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Evaluate Submission'),
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
          final destinationBase = "${year}_${semester}/CTIS$code/${studentName}_$bilkentId";
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
                // Assignments & Grades Card
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
                // Existing grade input and file upload sections can remain below if needed
                // ...existing code...
                // CTIS 310 Specific Sections
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
                  _buildCTIS310Section('Reports'),
                ],
                // CTIS 290 Specific Section
                if (courseData['code'] == '290') ...[
                  _buildCTIS290Section(),
                ],
                const SizedBox(height: 16),
                // Company Evaluation Section
                Card(
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
                          'Company Evaluation',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () async {
                            // File picker for web and mobile with semantic label
                            if (kIsWeb) {
                              FilePickerResult? result = await FilePicker.platform.pickFiles();
                              if (result != null) {
                                setState(() {
                                  _fileBytes = result.files.single.bytes;
                                  _filePath = result.files.single.name;
                                });
                              }
                            } else {
                              FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.any);
                              if (result != null) {
                                setState(() {
                                  _filePath = result.files.single.path;
                                });
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppStyles.buttonColor,
                          ),
                          child: const Text('Choose File'),
                        ),
                        if (_filePath != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text('Selected file: $_filePath'),
                          ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _isUploading
                              ? null
                              : () async {
                                  if (kIsWeb) {
                                    if (_fileBytes != null) {
                                      await uploadFile(
                                        destinationBase: destinationBase,
                                        fileBytes: _fileBytes
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("No file selected.")),
                                      );
                                    }
                                  } else {
                                    if (_filePath != null) {
                                      await uploadFile(
                                        destinationBase: destinationBase,
                                        filePath: _filePath
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("No file selected.")),
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppStyles.buttonColor,
                          ),
                          child: _isUploading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Upload Company Evaluation'),
                        ),
                        const SizedBox(height: 8),
                        Form(
                          key: _gradeFormKey,
                          child: TextFormField(
                            controller: _companyEvaluationController,
                            decoration: const InputDecoration(
                              labelText: 'Grade (0-100)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: _gradeInputFormatters,
                            validator: _validateGrade,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            final gradeText = _companyEvaluationController.text;
                            _submitGrade('Company Evaluation', gradeText);
                          },
                          child: Text('Submit Grade'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

    Future<void> uploadFile({
    required String destinationBase,
    String? filePath,
    Uint8List? fileBytes
  }) async {
    setState(() {
      _isUploading = true;
    });
    try {
      await Firebase.initializeApp();
      String fileName;
      Reference storageRef;
      if (kIsWeb) {
        if (fileBytes == null) throw Exception("No file bytes provided for web upload");
        fileName = "CompanyEvaluation_${widget.submission['bilkentId']}_${widget.submission['studentName']}";
        final destination = "$destinationBase/$fileName";
        storageRef = FirebaseStorage.instance.ref(destination);
        final uploadTask = storageRef.putData(fileBytes);
        final snapshot = await uploadTask.whenComplete(() => null);
        final downloadUrl = await snapshot.ref.getDownloadURL();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("File uploaded successfully: $downloadUrl")),
        );
      } else {
        final file = File(filePath!);
        fileName = "CompanyEvaluation_${widget.submission['bilkentId']}_${widget.submission['studentName']}";
        final destination = "$destinationBase/$fileName";
        storageRef = FirebaseStorage.instance.ref(destination);
        final uploadTask = storageRef.putFile(file);
        final snapshot = await uploadTask.whenComplete(() => null);
        final downloadUrl = await snapshot.ref.getDownloadURL();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("File uploaded successfully: $downloadUrl")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error during file upload: $e")),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> downloadFile(String fileName, String destinationBase) async {
    setState(() {
      _isDownloading = true;
    });
    try {
      final String destination = "$destinationBase/$fileName";
      final ref = FirebaseStorage.instance.ref(destination);
      final downloadUrl = await ref.getDownloadURL();
      if (kIsWeb) {
        html.AnchorElement anchor = html.AnchorElement(href: downloadUrl);
        anchor.download = fileName;
        anchor.click();
      } else {
        final response = await http.get(Uri.parse(downloadUrl));
        final Directory appDocDir = await getApplicationDocumentsDirectory();
        final File file = File('${appDocDir.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("File downloaded to: ${file.path}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Download error: $e")),
      );
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  Future<void> _submitGrades() async {
    final data = await evaluationData;
    final student = data['student'] ?? {};
    final courseData = data['course'] ?? {};
    final bilkentId = student['bilkentId'] ?? '';
    final courseId = courseData['courseId']?.toString() ?? '';
  
    if (_gradeFormKey.currentState?.validate() ?? false) {
      // Submit Company Evaluation grade
      final companyEvalGrade = double.parse(_companyEvaluationController.text);
      await DBHelper.enterGrade(bilkentId, courseId, 'Company Evaluation', companyEvalGrade);
      
      if (courseData['code'] == '310') {
        const assignments = [
          'Follow Up 1',
          'Follow Up 2',
          'Follow Up 3',
          'Follow Up 4',
          'Follow Up 5',
          'Report'
        ];
        for (final assignmentName in assignments) {
          final gradeText = _sectionControllers[assignmentName]?.text ?? '';
          if (gradeText.isNotEmpty) {
            await DBHelper.enterGrade(bilkentId, courseId, assignmentName, double.parse(gradeText));
          }
        }
      } else if (courseData['code'] == '290') {
        final gradeText = _ctis290Controller.text;
        if (gradeText.isNotEmpty) {
          await DBHelper.enterGrade(bilkentId, courseId, 'Report', double.parse(gradeText));
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Grades submitted successfully!')),
      );
    }
  }

  Future<void> _submitGrade(String assignmentName, String gradeText) async {
    final data = await evaluationData;
    final student = data['student'] ?? {};
    final courseData = data['course'] ?? {};
    final bilkentId = student['bilkentId'] ?? '';
    final courseId = courseData['courseId']?.toString() ?? '';

    if (gradeText.isNotEmpty) {
      final grade = double.parse(gradeText);
      await DBHelper.enterGrade(bilkentId, courseId, assignmentName, grade);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$assignmentName grade submitted successfully!')),
      );
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
            ElevatedButton(
              onPressed: () async {
                // Instead of referencing old destinationBase, get it from snapshot or pass it in
                final data = await evaluationData;
                final student = data['student'] ?? {};
                final courseData = data['course'] ?? {};
                final destB = "${courseData['year']}_${courseData['semester']}/CTIS${courseData['code']}/${student['name']}_${student['bilkentId']}";
                downloadFile("CompanyEvaluation_${student['bilkentId']}_${student['name']}", destB);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppStyles.buttonColor),
              child: Text('Download $title'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _getSectionController(title),
              decoration: const InputDecoration(
                labelText: 'Grade (0-100)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: _gradeInputFormatters,
              validator: _validateGrade,
            ),
            ElevatedButton(
              onPressed: () {
                final gradeText = _sectionControllers[title]?.text ?? '';
                _submitGrade(title, gradeText);
              },
              child: Text('Submit Grade'),
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
              'Reports about an internship',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                // Instead of referencing old destinationBase, get it from snapshot or pass it in
                final data = await evaluationData;
                final student = data['student'] ?? {};
                final courseData = data['course'] ?? {};
                final destB = "${courseData['year']}_${courseData['semester']}/CTIS${courseData['code']}/${student['name']}_${student['bilkentId']}";
                downloadFile("CompanyEvaluation_${student['bilkentId']}_${student['name']}", destB);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppStyles.buttonColor),
              child: const Text('Download Report'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _ctis290Controller,
              decoration: const InputDecoration(
                labelText: 'Grade (0-100)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: _gradeInputFormatters,
              validator: _validateGrade,
            ),
            ElevatedButton(
              onPressed: () {
                final gradeText = _ctis290Controller.text;
                _submitGrade('Report', gradeText);
              },
              child: Text('Submit Grade'),
            ),
          ],
        ),
      ),
    );
  }
}
