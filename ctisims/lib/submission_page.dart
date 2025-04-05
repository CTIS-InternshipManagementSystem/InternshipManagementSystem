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
import 'package:ctisims/db_helper.dart';
import 'package:provider/provider.dart';
import 'themes/Theme_provider.dart';
import 'animated_button.dart';

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
        final gradeSnapshot = await gradeData.first;
        grade = gradeSnapshot != null && gradeSnapshot['grade'] != null
            ? gradeSnapshot['grade'].toString()
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

  // Add a wrapper to make sure Firebase doesn't show SnackBars during initialization
  Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      // Handle initialization errors but don't show SnackBars
      print('Firebase initialization error: $e');
    }
  }

  // Updated upload section file method with real Firebase implementation showing dialog
  Future<void> _uploadSectionFile(String sectionTitle, String destinationBase) async {
    if (_sectionFileBytes[sectionTitle] == null && (_sectionFilePaths[sectionTitle] == null || !kIsWeb)) {
      _showErrorSnackBar('Please select a file for $sectionTitle first');
      return;
    }

    setState(() {
      _sectionUploading[sectionTitle] = true;
    });

    try {
      // Show uploading progress SnackBar
      final fileName = _sectionFilePaths[sectionTitle]?.split('/').last ?? '$sectionTitle file';
      _showUploadingSnackBar(fileName);

      // REAL FIREBASE UPLOAD CODE
      await _initializeFirebase();
      String uploadFileName = "${sectionTitle}_${widget.submission['bilkentId']}_${widget.submission['name']}";
      final destination = "$destinationBase/$uploadFileName";
      Reference storageRef = FirebaseStorage.instance.ref(destination);
      String downloadUrl = '';
      int fileSize = 0;
      
      if (kIsWeb) {
        if (_sectionFileBytes[sectionTitle] == null) throw Exception("No file selected for $sectionTitle");
        fileSize = _sectionFileBytes[sectionTitle]!.length;
        final uploadTask = storageRef.putData(_sectionFileBytes[sectionTitle]!);
        final snapshot = await uploadTask.whenComplete(() => null);
        downloadUrl = await snapshot.ref.getDownloadURL();
        // IMPORTANT: DON'T show the default SnackBar
      } else {
        if (_sectionFilePaths[sectionTitle] == null) throw Exception("No file selected for $sectionTitle");
        final file = File(_sectionFilePaths[sectionTitle]!);
        fileSize = file.lengthSync();
        final uploadTask = storageRef.putFile(file);
        final snapshot = await uploadTask.whenComplete(() => null);
        downloadUrl = await snapshot.ref.getDownloadURL();
        // IMPORTANT: DON'T show the default SnackBar
      }
      
      // FORCE CLEAR any SnackBars before showing our dialog
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).clearSnackBars();
      
      // Show fancy centered success notification
      _showCenteredSuccessNotification(fileName, fileSize);

      setState(() {
        _sectionUploading[sectionTitle] = false;
        _sectionFilePaths[sectionTitle] = null;
        _sectionFileBytes[sectionTitle] = null;
      });
    } catch (e) {
      _showErrorSnackBar('Error uploading $sectionTitle: ${e.toString()}');
      setState(() {
        _sectionUploading[sectionTitle] = false;
      });
    }
  }

  // Show a fancy centered notification for successful uploads
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

  Widget _buildCTIS310Section(String title) {
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
                child: Text('Selected file: ${_sectionFilePaths[title]}',
                  style: TextStyle(color: textColor),
                ),
              ),
            const SizedBox(height: 8),
            // Upload button for this section
            AnimatedButton(
              label: 'Upload $title',
              icon: Icons.cloud_upload,
              onPressed: () async {
                final data = await evaluationData;
                final student = data['student'] ?? {};
                final courseData = data['course'] ?? {};
                final destB = "${courseData['year']} ${courseData['semester']}/CTIS${courseData['code']}/${student['name']}_${student['bilkentId']}";
                await _uploadSectionFile(title, destB);
              },
              isLoading: _sectionUploading[title] ?? false,
              color: AppStyles.buttonColor,
              animationType: AnimationType.scale,
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
                await _chooseSectionFile('Report');
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppStyles.buttonColor),
              child: const Text('Choose File for Report'),
            ),
            if (_sectionFilePaths['Report'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('Selected file: ${_sectionFilePaths['Report']}',
                  style: TextStyle(color: textColor),
                ),
              ),
            const SizedBox(height: 8),
            AnimatedButton(
              label: 'Upload Report',
              icon: Icons.cloud_upload,
              onPressed: () async {
                final data = await evaluationData;
                final student = data['student'] ?? {};
                final courseData = data['course'] ?? {};
                final destB = "${courseData['year']} ${courseData['semester']}/CTIS${courseData['code']}/${student['name']}_${student['bilkentId']}";
                await _uploadSectionFile('Report', destB);
              },
              isLoading: _sectionUploading['Report'] ?? false,
              color: AppStyles.buttonColor,
              animationType: AnimationType.scale,
            ),
          ],
        ),
      ),
    );
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
        title: const Text('Student Submission'),
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

  // Helper method to show the uploading SnackBar
  void _showUploadingSnackBar(String fileName) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.upload_file, color: Colors.white),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Uploading $fileName',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // Helper method to show error SnackBar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Upload Failed',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    message,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // Override the DBHelper.uploadSubmission method to use our new dialog
  static Future<void> uploadSubmissionOverride(String destination, String fileName, Uint8List fileBytes) async {
    // This would typically call the original implementation
    // But instead, we'll prevent it from showing its own SnackBar
    // await DBHelper.uploadSubmission(destination, fileName, fileBytes);
    
    // No SnackBar here - we'll handle this in our _uploadSectionFile method
  }
}
