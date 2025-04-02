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
import 'package:provider/provider.dart';
import 'themes/Theme_provider.dart';

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
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    
    final cardBgColor = isDark ? Colors.grey[850] : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    
    final String studentName = widget.submission['studentName'] ?? 'Demo student';
    final String bilkentId = widget.submission['bilkentId'] ?? '1110002';
    final String email = widget.submission['email'] ?? 'demo.student@bilkent.edu.tr';
    final String course = widget.submission['course'] ?? 'CTIS310';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Evaluate Submission'),
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.dark_mode : Icons.light_mode,
              color: Colors.grey,
            ),
            tooltip: 'Toggle Dark Mode',
            onPressed: () {
              themeProvider.toggleTheme();
            },
          ),
        ],
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
                  color: cardBgColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Student Information", style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text("Name: ${student['name'] ?? ''}", style: TextStyle(color: textColor)),
                        Text("Bilkent ID: ${student['bilkentId'] ?? ''}", style: TextStyle(color: textColor)),
                        Text("Email: ${student['email'] ?? ''}", style: TextStyle(color: textColor)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Course Information Card
                Card(
                  elevation: 4,
                  color: cardBgColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Course Information", style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text("Course: CTIS ${courseData['code'] ?? ''}", style: TextStyle(color: textColor)),
                        Text("Year: ${courseData['year'] ?? ''}", style: TextStyle(color: textColor)),
                        Text("Semester: ${courseData['semester'] ?? ''}", style: TextStyle(color: textColor)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Assignments & Grades Card
                Card(
                  elevation: 4,
                  color: cardBgColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                                Text("${assignment['name']}", style: TextStyle(color: textColor)),
                                Text("Grade: ${assignment['grade']}", style: TextStyle(color: textColor)),
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
                  _buildCTIS310Section('Report'),
                ],
                // CTIS 290 Specific Section
                if (courseData['code'] == '290') ...[
                  _buildCTIS290Section(),
                ],
                const SizedBox(height: 16),
                // Company Evaluation Section
                Card(
                  elevation: AppStyles.cardElevation,
                  color: cardBgColor,
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
                        Text(
                          'Status: ${widget.submission['companyEvaluation'] ?? 'Not Uploaded'}',
                          style: TextStyle(color: textColor),
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
                                        bilkentId: bilkentId,
                                        name: studentName,
                                        courseId: courseData['courseId'],
                                        year: courseData['year'],
                                        semester: courseData['semester'],
                                        code: courseData['code'],
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
                                        bilkentId: bilkentId,
                                        name: studentName,
                                        courseId: courseData['courseId'],
                                        year: courseData['year'],
                                        semester: courseData['semester'],
                                        code: courseData['code'],
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

  // Show fancy centered notification for successful uploads
  void _showCenteredSuccessNotification(String fileName, int fileSize) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).clearSnackBars();
    
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Upload Success Dialog',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation1, animation2) => Container(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        );

        return ScaleTransition(
          scale: Tween<double>(begin: 0.5, end: 1.0).animate(curvedAnimation),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation),
            child: AlertDialog(
              backgroundColor: Theme.of(context).brightness == Brightness.dark 
                ? Colors.grey[850] 
                : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              content: SingleChildScrollView(
                child: Container(
                  width: 300,
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Animated checkmark
                      TweenAnimationBuilder(
                        duration: const Duration(seconds: 1),
                        tween: Tween<double>(begin: 0, end: 1),
                        builder: (context, double value, child) {
                          return Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    height: 70,
                                    width: 70,
                                    child: CircularProgressIndicator(
                                      value: 1.0,
                                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                                      strokeWidth: 3,
                                    ),
                                  ),
                                  Icon(
                                    Icons.check,
                                    color: Colors.green,
                                    size: 50 * value,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      // Success text
                      Text(
                        'Upload Successful!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.white 
                            : Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      // File details
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.insert_drive_file, color: Colors.blue),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    fileName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.storage, color: Colors.blue),
                                const SizedBox(width: 8),
                                Text('${(fileSize / 1024).toStringAsFixed(2)} KB'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Close button
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          minimumSize: const Size(150, 40),
                        ),
                        child: const Text('Done'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper method to show error dialog
  void _showErrorDialog(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).clearSnackBars();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> uploadFile({
    String? bilkentId,
    String? name,
    String? courseId,
    String? year,
    String? semester,
    String? code,
    String? filePath,
    Uint8List? fileBytes
  }) async {
    setState(() {
      _isUploading = true;
    });

    try {
      await Firebase.initializeApp();
      final String fileName = "CompanyEvaluation_${bilkentId}_$name";
      final String destinationBase = "$year $semester/CTIS$code/${name}_$bilkentId";
      final destination = "$destinationBase/$fileName";
      Reference storageRef = FirebaseStorage.instance.ref(destination);

      if (kIsWeb) {
        if (fileBytes == null) throw Exception("No file bytes provided for web upload");
        int fileSize = fileBytes!.length;
        final uploadTask = storageRef.putData(fileBytes!);
        final snapshot = await uploadTask.whenComplete(() => null);
        final downloadUrl = await snapshot.ref.getDownloadURL();
        
        // Show fancy notification instead of SnackBar
        _showCenteredSuccessNotification(fileName, fileSize);
        
        // Update in Firestore
        final bool companyEvaluationUploaded = true;
        await DBHelper.changeCompanyEvaluation(bilkentId!, courseId!, companyEvaluationUploaded);
      } else {
        if (filePath == null) throw Exception("No file path provided for mobile upload");
        final file = File(filePath!);
        int fileSize = file.lengthSync();
        final uploadTask = storageRef.putFile(file);
        final snapshot = await uploadTask.whenComplete(() => null);
        final downloadUrl = await snapshot.ref.getDownloadURL();
        
        // Show fancy notification instead of SnackBar
        _showCenteredSuccessNotification(fileName, fileSize);
        
        // Update in Firestore
        final bool companyEvaluationUploaded = true;
        await DBHelper.changeCompanyEvaluation(bilkentId!, courseId!, companyEvaluationUploaded);
      }
    } catch (e) {
      _showErrorDialog("Error during file upload: $e");
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
        SnackBar(content: Text("Download error: $e" + "destinationBase: $destinationBase/$fileName")),
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
      // Refresh the evaluation data to update the grades
      setState(() {
        evaluationData = loadEvaluationData();
      });
    }
  }

  Widget _buildCTIS310Section(String sectionTitle) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final cardBgColor = isDark ? Colors.grey[850] : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    
    return Card(
      elevation: AppStyles.cardElevation,
      color: cardBgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyles.borderRadius),
      ),
      child: Padding(
        padding: AppStyles.padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sectionTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            // Grade input
            TextFormField(
              controller: _getSectionController(sectionTitle),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Grade for $sectionTitle',
                hintText: 'Enter a grade (0-100)',
                suffixText: '%',
                border: const OutlineInputBorder(),
                labelStyle: TextStyle(color: textColor),
              ),
              style: TextStyle(color: textColor),
              inputFormatters: _gradeInputFormatters,
              validator: _validateGrade,
            ),
            AppStyles.fieldSpacing,
            ElevatedButton(
              onPressed: () async {
                // Save grade logic
                final grade = double.tryParse(_getSectionController(sectionTitle).text);
                if (grade != null) {
                  try {
                    final String bilkentId = widget.submission['bilkentId'] ?? '';
                    final String courseId = widget.submission['courseId'] ?? '';
                    await DBHelper.enterGrade(bilkentId, courseId, sectionTitle, grade);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Grade for $sectionTitle updated successfully.')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error updating grade: $e')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a valid grade.')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppStyles.buttonColor,
              ),
              child: const Text('Save Grade'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCTIS290Section() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final cardBgColor = isDark ? Colors.grey[850] : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    
    return Card(
      elevation: AppStyles.cardElevation,
      color: cardBgColor,
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
                // Instead of referencing old destinationBase, get it from snapshot or pass it in
                final data = await evaluationData;
                final student = data['student'] ?? {};
                final courseData = data['course'] ?? {};
                final destB = "${courseData['year']} ${courseData['semester']}/CTIS${courseData['code']}/${student['name']}_${student['bilkentId']}";
                downloadFile("Report_${student['bilkentId']}_${student['name']}", destB);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppStyles.buttonColor),
              child: const Text('Download Report'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _ctis290Controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Grade (0-100)',
                hintText: 'Enter a grade (0-100)',
                suffixText: '%',
                border: const OutlineInputBorder(),
                labelStyle: TextStyle(color: textColor),
              ),
              style: TextStyle(color: textColor),
              inputFormatters: _gradeInputFormatters,
              validator: _validateGrade,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                final gradeText = _ctis290Controller.text;
                _submitGrade('Report', gradeText);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppStyles.buttonColor),
              child: const Text('Submit Grade'),
            ),
          ],
        ),
      ),
    );
  }
}
