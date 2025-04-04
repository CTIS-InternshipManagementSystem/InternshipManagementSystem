import 'package:ctisims/evaluate_page.dart';
import 'package:flutter/material.dart';
import 'package:ctisims/dbHelper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:html' as html;
import 'package:provider/provider.dart';
import 'themes/Theme_provider.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String? _selectedOption;
  final TextEditingController _bilkentIdController = TextEditingController();
  Map<String, String?> _uploadFilePaths = {};
  Map<String, Uint8List?> _uploadFileBytes = {};
  Map<String, bool> _isUploading = {}; // Track upload state per student

  Future<List<Map<String, dynamic>>>? _futureStudentCourses;

  @override
  void initState() {
    super.initState();
    _futureStudentCourses = DBHelper.getStudentCoursesWithCourseInfo();
    _bilkentIdController.addListener(() => _searchSubmissions(_bilkentIdController.text));
  }

  void _searchSubmissions(String query) {
    setState(() {
      _futureStudentCourses = DBHelper.getStudentCoursesWithCourseInfo().then((submissions) {
        if (query.isEmpty) {
          return submissions;
        } else {
          return submissions.where((submission) => 
            submission['bilkentId'].toString().startsWith(query)).toList();
        }
      });
    });
  }

  void _updateFilteredSubmissions() {
    setState(() {
      _futureStudentCourses = DBHelper.getStudentCoursesWithCourseInfo();
    });
  }

  // Show fancy centered notification for successful operations (upload/delete)
  void _showCenteredSuccessNotification(String operation, String fileName, {int? fileSize}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).clearSnackBars();
    
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Success Dialog',
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
                        operation == 'upload' ? 'Upload Successful!' : 'File Deleted Successfully!',
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
                            if (fileSize != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.storage, color: Colors.blue),
                                  const SizedBox(width: 8),
                                  Text('${(fileSize / 1024).toStringAsFixed(2)} KB'),
                                ],
                              ),
                            ],
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

  Future<void> uploadFile(String bilkentId, String name, String courseId, String year, String semester, String code) async {
    setState(() {
      _isUploading[bilkentId] = true;
    });

    try {
      await Firebase.initializeApp();
      final String fileName = "CompanyEvaluation_${bilkentId}_$name";
      final String destinationBase = "$year $semester/CTIS$code/${name}_$bilkentId";
      Reference storageRef;
      int fileSize = 0;

      if (kIsWeb) {
        if (_uploadFileBytes[bilkentId] == null) throw Exception("No file bytes provided for web upload");
        fileSize = _uploadFileBytes[bilkentId]!.length;
        final destination = "$destinationBase/$fileName";
        storageRef = FirebaseStorage.instance.ref(destination);
        final uploadTask = storageRef.putData(_uploadFileBytes[bilkentId]!);
        final snapshot = await uploadTask.whenComplete(() => null);
        final downloadUrl = await snapshot.ref.getDownloadURL();
        
        // Show fancy dialog instead of SnackBar
        _showCenteredSuccessNotification('upload', fileName, fileSize: fileSize);
        
        // Update company evaluation status
        await DBHelper.changeCompanyEvaluation(bilkentId, courseId, true);
        _updateFilteredSubmissions();
      } else {
        if (_uploadFilePaths[bilkentId] == null) throw Exception("No file path provided for mobile upload");
        final file = File(_uploadFilePaths[bilkentId]!);
        fileSize = file.lengthSync();
        final destination = "$destinationBase/$fileName";
        storageRef = FirebaseStorage.instance.ref(destination);
        final uploadTask = storageRef.putFile(file);
        final snapshot = await uploadTask.whenComplete(() => null);
        final downloadUrl = await snapshot.ref.getDownloadURL();
        
        // Show fancy dialog instead of SnackBar
        _showCenteredSuccessNotification('upload', fileName, fileSize: fileSize);
        
        // Update company evaluation status
        await DBHelper.changeCompanyEvaluation(bilkentId, courseId, true);
        _updateFilteredSubmissions();
      }
    } catch (e) {
      _showErrorDialog("Error during file upload: $e");
    } finally {
      setState(() {
        _isUploading[bilkentId] = false;
        _uploadFilePaths[bilkentId] = null;
        _uploadFileBytes[bilkentId] = null;
      });
    }
  }

  // Show download success notification
  void _showDownloadSuccessNotification(String fileName, String path) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).clearSnackBars();
    
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Download Success Dialog',
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
                      // Animated download icon
                      TweenAnimationBuilder(
                        duration: const Duration(seconds: 1),
                        tween: Tween<double>(begin: 0, end: 1),
                        builder: (context, double value, child) {
                          return Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
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
                                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                                      strokeWidth: 3,
                                    ),
                                  ),
                                  Icon(
                                    Icons.download_done,
                                    color: Colors.blue,
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
                        'Download Complete!',
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
                                const Icon(Icons.folder, color: Colors.blue),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    path,
                                    style: const TextStyle(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
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
                          backgroundColor: Colors.blue,
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

  Future<void> downloadFile(String bilkentId, String name, String year, String semester, String code) async {
    try {
      final String fileName = "CompanyEvaluation_${bilkentId}_$name";
      final String destinationBase = "$year $semester/CTIS$code/${name}_$bilkentId";
      final destination = "$destinationBase/$fileName";
      
      final ref = FirebaseStorage.instance.ref(destination);
      final downloadUrl = await ref.getDownloadURL();
      
      if (kIsWeb) {
        html.AnchorElement anchor = html.AnchorElement(href: downloadUrl);
        anchor.download = fileName;
        anchor.click();
        _showDownloadSuccessNotification(fileName, "Downloaded to your device");
      } else {
        final response = await http.get(Uri.parse(downloadUrl));
        final Directory appDocDir = await getApplicationDocumentsDirectory();
        final File file = File('${appDocDir.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);
        _showDownloadSuccessNotification(fileName, file.path);
      }
    } catch (e) {
      _showErrorDialog("Download error: $e");
    }
  }

  Future<void> deleteFile(String bilkentId, String name, String courseId, String year, String semester, String code) async {
    try {
      final String fileName = "CompanyEvaluation_${bilkentId}_$name";
      final String destinationBase = "$year $semester/CTIS$code/${name}_$bilkentId";
      final destination = "$destinationBase/$fileName";
      
      final ref = FirebaseStorage.instance.ref(destination);
      await ref.delete();
      
      // Update company evaluation status
      await DBHelper.changeCompanyEvaluation(bilkentId, courseId, false);
      
      // Show fancy dialog instead of SnackBar
      _showCenteredSuccessNotification('delete', fileName);
      
      _updateFilteredSubmissions();
    } catch (e) {
      _showErrorDialog("File deletion error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    
    final cardBgColor = isDark ? Colors.grey[850] : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Section
            Card(
              elevation: 4,
              color: cardBgColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select an option:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    RadioListTile<String>(
                      title: Text('Search Student', style: TextStyle(color: textColor)),
                      value: 'Search Student',
                      groupValue: _selectedOption,
                      onChanged: (value) {
                        setState(() {
                          _selectedOption = value;
                          _updateFilteredSubmissions();
                        });
                      },
                    ),
                    RadioListTile<String>(
                      title: Text('Uploading Company Evaluation Reports', style: TextStyle(color: textColor)),
                      value: 'Uploading Company Evaluation Reports',
                      groupValue: _selectedOption,
                      onChanged: (value) {
                        setState(() {
                          _selectedOption = value;
                          _updateFilteredSubmissions();
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _bilkentIdController,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: 'Bilkent ID',
                        labelStyle: TextStyle(color: textColor.withOpacity(0.8)),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _futureStudentCourses,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("No students found"));
                  }
                  
                  final studentCourses = snapshot.data!;
                  return ListView.builder(
                    itemCount: studentCourses.length,
                    itemBuilder: (context, index) {
                      final submission = studentCourses[index];
                      final course = submission['course'];
                      final bilkentId = submission['bilkentId'] ?? '';
                      final name = submission['name'] ?? '';
                      final courseId = course['courseId'] ?? '';
                      final year = course['year'] ?? '';
                      final semester = course['semester'] ?? '';
                      final code = course['code'] ?? '';
                      final companyEvaluationUploaded = submission['companyEvaluationUploaded'] ?? false;
                      
                      return Card(
                        elevation: 2,
                        color: cardBgColor,
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Year: $year', style: TextStyle(color: textColor)),
                              const SizedBox(height: 4),
                              Text('Semester: $semester', style: TextStyle(color: textColor)),
                              const SizedBox(height: 4),
                              Text('Course: CTIS $code', style: TextStyle(color: textColor)),
                              const SizedBox(height: 4),
                              Text('Student Name: $name', style: TextStyle(color: textColor)),
                              const SizedBox(height: 4),
                              Text('Bilkent ID: $bilkentId', style: TextStyle(color: textColor)),
                              const SizedBox(height: 4),
                              Text('Company Evaluation Uploaded: $companyEvaluationUploaded', style: TextStyle(color: textColor)),
                              const SizedBox(height: 16),
                              
                              if (_selectedOption == 'Uploading Company Evaluation Reports') ...[
                                if (companyEvaluationUploaded) ...[
                                  ElevatedButton(
                                    onPressed: () => downloadFile(bilkentId, name, year, semester, code),
                                    child: const Text('Download Company Evaluation Report'),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: () => deleteFile(bilkentId, name, courseId, year, semester, code),
                                    child: const Text('Delete Company Evaluation Report'),
                                  ),
                                ] else ...[
                                  ElevatedButton(
                                    onPressed: () async {
                                      if (kIsWeb) {
                                        FilePickerResult? result = await FilePicker.platform.pickFiles();
                                        if (result != null) {
                                          setState(() {
                                            _uploadFileBytes[bilkentId] = result.files.single.bytes;
                                            _uploadFilePaths[bilkentId] = result.files.single.name;
                                          });
                                        }
                                      } else {
                                        FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.any);
                                        if (result != null) {
                                          setState(() {
                                            _uploadFilePaths[bilkentId] = result.files.single.path;
                                          });
                                        }
                                      }
                                    },
                                    child: const Text('Choose File'),
                                  ),
                                  if (_uploadFilePaths[bilkentId] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text('Selected file: ${_uploadFilePaths[bilkentId]}'),
                                    ),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: _isUploading[bilkentId] == true 
                                      ? null 
                                      : () => uploadFile(bilkentId, name, courseId, year, semester, code),
                                    child: _isUploading[bilkentId] == true
                                      ? const CircularProgressIndicator()
                                      : const Text('Upload'),
                                  ),
                                ],
                              ],
                              
                              if (_selectedOption == 'Search Student') ...[
                                ElevatedButton(
                                  onPressed: () {
                                    final submissionMap = {
                                      'bilkentId': bilkentId,
                                      'courseId': courseId,
                                      'studentName': name,
                                      'email': submission['email'] ?? '',
                                      'course': 'CTIS$code',
                                      'companyEvaluation': companyEvaluationUploaded ? 'Uploaded' : 'Not Uploaded'
                                    };
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EvaluatePage(
                                          submission: submissionMap.map((k, v) => MapEntry(k, v.toString())),
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text('View Submission'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
