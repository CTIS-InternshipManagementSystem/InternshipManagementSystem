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
import 'submission_detail_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String? _selectedOption;
  final TextEditingController _bilkentIdController = TextEditingController();
  String? _uploadFilePath;
  Uint8List? _uploadFileBytes;

  // Dummy data for student submissions
  final List<Map<String, String>> _studentSubmissions = [
    {
      'semester': '2022-2023 Fall',
      'course': 'CTIS310',
      'studentName': 'John Doe',
      'bilkentId': '1110001',
      'lecturerName': 'Dr. Smith',
      'submissionStatus': 'Submitted',
      'companyEvaluation': 'Uploaded'
    },
    {
      'semester': '2022-2023 Fall',
      'course': 'CTIS290',
      'studentName': 'Jane Doe',
      'bilkentId': '1110002',
      'lecturerName': 'Dr. Brown',
      'submissionStatus': 'Not Submitted',
      'companyEvaluation': 'Not Uploaded'
    },
  ];

  List<Map<String, String>> _filteredSubmissions = [];

  final String destinationBase = "2024-2025 Spring/CTIS310/Bilgehan_Demirkaya_22002357";

  @override
  void initState() {
    super.initState();
    _filteredSubmissions = _studentSubmissions;
  }

  // Automatically filter submissions based on input.
  void _searchSubmissions() {
    final bilkentId = _bilkentIdController.text;
    setState(() {
      if (bilkentId.isEmpty) {
        _filteredSubmissions = _studentSubmissions; // Show all if input is empty.
      } else {
        _filteredSubmissions = _studentSubmissions
            .where((submission) => submission['bilkentId']?.contains(bilkentId) ?? false)
            .toList();
      }
    });
  }

  Future<void> uploadFile({String? filePath, Uint8List? fileBytes}) async {
    try {
      await Firebase.initializeApp();
      String fileName = "CompanyEvaluation_22002357_Bilgehan_Demirkaya";
      final String destinationBase = "2024-2025 Spring/CTIS310/Bilgehan_Demirkaya_22002357";
      Reference storageRef;
      if (kIsWeb) {
        if (fileBytes == null) throw Exception("No file bytes provided for web upload");
        final destination = "$destinationBase/$fileName";
        storageRef = FirebaseStorage.instance.ref(destination);
        final uploadTask = storageRef.putData(fileBytes);
        final snapshot = await uploadTask.whenComplete(() => null);
        final downloadUrl = await snapshot.ref.getDownloadURL();
        print("File uploaded successfully: $downloadUrl");
      } else {
        final file = File(filePath!);
        final destination = "$destinationBase/$fileName";
        storageRef = FirebaseStorage.instance.ref(destination);
        final uploadTask = storageRef.putFile(file);
        final snapshot = await uploadTask.whenComplete(() => null);
        final downloadUrl = await snapshot.ref.getDownloadURL();
        print("File uploaded successfully: $downloadUrl");
      }
    } catch (e) {
      print("File upload error: $e");
    }
  }

  Future<void> downloadFile(String fileName) async {
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
        print("File downloaded to: ${file.path}");
      }
    } catch (e) {
      print("Download error: $e");
    }
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

  Future<void> submitGrade(String grade, String studentName, String course) async {
    try {
      final response = await http.post(
        Uri.parse('https://example.com/submit-grade'), // Replace with your backend URL
        body: {
          'studentName': studentName,
          'grade': grade,
          'course': course,
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Grade submitted for $studentName')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit grade for $studentName')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during grade submission: $e')),
      );
    }
  }

  @override
  void dispose() {
    _bilkentIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
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
              title: const Text('Search Student'),
              value: 'Search Student',
              groupValue: _selectedOption,
              onChanged: (value) {
                setState(() {
                  _selectedOption = value;
                  _searchSubmissions(); // Automatically filter when option changes
                });
              },
            ),
            RadioListTile<String>(
              title: const Text('Uploading Company Evaluation Reports'),
              value: 'Uploading Company Evaluation Reports',
              groupValue: _selectedOption,
              onChanged: (value) {
                setState(() {
                  _selectedOption = value;
                  _searchSubmissions(); // Automatically filter when option changes
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bilkentIdController,
              decoration: const InputDecoration(
                labelText: 'Bilkent ID',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => _searchSubmissions(), // Trigger search on text change
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredSubmissions.length,
                itemBuilder: (context, index) {
                  final submission = _filteredSubmissions[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Semester: ${submission['semester']}'),
                          const SizedBox(height: 4),
                          Text('Course: ${submission['course']}'),
                          const SizedBox(height: 4),
                          Text('Student Name: ${submission['studentName']}'),
                          const SizedBox(height: 4),
                          Text('Bilkent ID: ${submission['bilkentId']}'),
                          const SizedBox(height: 4),
                          Text('Lecturer Name: ${submission['lecturerName']}'),
                          const SizedBox(height: 4),
                          Text('Submission Status: ${submission['submissionStatus']}'),
                          const SizedBox(height: 16),
                          if (_selectedOption == 'Uploading Company Evaluation Reports') ...[
                            if (submission['companyEvaluation'] == 'Uploaded') ...[
                              ElevatedButton(
                                onPressed: () {
                                  downloadFile("CompanyEvaluation_22002357_Bilgehan_Demirkaya");
                                },
                                child: const Text('Download Company Evaluation Report'),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () {
                                  // Implement delete logic
                                },
                                child: const Text('Delete Company Evaluation Report'),
                              ),
                            ] else ...[
                              ElevatedButton(
                                onPressed: () async {
                                  if (kIsWeb) {
                                    FilePickerResult? result = await FilePicker.platform.pickFiles();
                                    if (result != null) {
                                      setState(() {
                                        _uploadFileBytes = result.files.single.bytes;
                                        _uploadFilePath = result.files.single.name;
                                      });
                                    }
                                  } else {
                                    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.any);
                                    if (result != null) {
                                      setState(() {
                                        _uploadFilePath = result.files.single.path;
                                      });
                                    }
                                  }
                                },
                                child: const Text('Choose File'),
                              ),
                              if (_uploadFilePath != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text('Selected file: $_uploadFilePath'),
                                ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () async {
                                  if (kIsWeb) {
                                    if (_uploadFileBytes != null) {
                                      try {
                                        await uploadFile(fileBytes: _uploadFileBytes);
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text("Success"),
                                            content: const Text("File uploaded successfully."),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))
                                            ],
                                          ),
                                        );
                                      } catch (e) {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text("Error"),
                                            content: const Text("File not uploaded."),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))
                                            ],
                                          ),
                                        );
                                      }
                                    } else {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text("Error"),
                                          content: const Text("No file selected."),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))
                                          ],
                                        ),
                                      );
                                    }
                                  } else {
                                    if (_uploadFilePath != null) {
                                      try {
                                        await uploadFile(filePath: _uploadFilePath);
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text("Success"),
                                            content: const Text("File uploaded successfully."),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))
                                            ],
                                          ),
                                        );
                                      } catch (e) {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text("Error"),
                                            content: const Text("File not uploaded."),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))
                                            ],
                                          ),
                                        );
                                      }
                                    } else {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text("Error"),
                                          content: const Text("No file selected."),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))
                                          ],
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: const Text('Upload'),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
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
