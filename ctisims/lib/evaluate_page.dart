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

  final String destinationBase = "2024-2025 Spring/CTIS310/Bilgehan_Demirkaya_22002357";

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

  Future<void> uploadFile({String? filePath, Uint8List? fileBytes}) async {
    setState(() {
      _isUploading = true;
    });
    try {
      await Firebase.initializeApp();
      String fileName;
      Reference storageRef;
      if (kIsWeb) {
        if (fileBytes == null) throw Exception("No file bytes provided for web upload");
        fileName = "CompanyEvaluation_22002357_Bilgehan_Demirkaya";
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
        fileName = "CompanyEvaluation_22002357_Bilgehan_Demirkaya";
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

  Future<void> downloadFile(String fileName) async {
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
      body: SingleChildScrollView(
        padding: AppStyles.padding,
        child: AnimatedOpacity(
          opacity: 1.0,
          duration: const Duration(milliseconds: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Student Information Section
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
                        'Student Information',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text('Name: $studentName'),
                      const SizedBox(height: 4),
                      Text('Bilkent ID: $bilkentId'),
                      const SizedBox(height: 4),
                      Text('Email: $email'),
                      const SizedBox(height: 4),
                      Text('Course: $course'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // CTIS 310 Specific Sections
              if (course == 'CTIS310') ...[
                _buildCTIS310Section('Follow Up1'),
                const SizedBox(height: 16),
                _buildCTIS310Section('Follow Up2'),
                const SizedBox(height: 16),
                _buildCTIS310Section('Follow Up3'),
                const SizedBox(height: 16),
                _buildCTIS310Section('Follow Up4'),
                const SizedBox(height: 16),
                _buildCTIS310Section('Follow Up5'),
                const SizedBox(height: 16),
                _buildCTIS310Section('Reports about an internship'),
              ],
              // CTIS 290 Specific Section
              if (course == 'CTIS290') ...[
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
                                    await uploadFile(fileBytes: _fileBytes);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("No file selected.")),
                                    );
                                  }
                                } else {
                                  if (_filePath != null) {
                                    await uploadFile(filePath: _filePath);
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
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
              onPressed: () {
                downloadFile("CompanyEvaluation_22002357_Bilgehan_Demirkaya");
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
              onPressed: () {
                downloadFile("CompanyEvaluation_22002357_Bilgehan_Demirkaya");
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
          ],
        ),
      ),
    );
  }
}
