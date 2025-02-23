import 'dart:io';
// Add import for Uint8List support on web
import 'dart:typed_data';
import 'package:firebase_core/firebase_core.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
// For web downloads, you may use:
import 'dart:html' as html;

class EvaluatePage extends StatefulWidget {
  final Map<String, String> submission;

  const EvaluatePage({Key? key, required this.submission}) : super(key: key);

  @override
  _EvaluatePageState createState() => _EvaluatePageState();
}

class _EvaluatePageState extends State<EvaluatePage> {
  final TextEditingController _evaluationController = TextEditingController();
  final TextEditingController _companyEvaluationController = TextEditingController();

  String? _filePath;
  // New field for web file bytes
  Uint8List? _fileBytes;

  final String destinationBase = "2024-2025 Spring/CTIS310/Bilgehan_Demirkaya_22002357";

  // Updated uploadFile function accepting filePath (mobile) or fileBytes (web)
  Future<void> uploadFile({String? filePath, Uint8List? fileBytes}) async {
    try {
      await Firebase.initializeApp();
      String fileName;
      Reference storageRef;
      if (kIsWeb) {
        if (fileBytes == null) throw Exception("No file bytes provided for web upload");
        // Use a dummy file name with timestamp and call putData
        fileName = "CompanyEvaluation_22002357_Bilgehan_Demirkaya";
        final destination = "$destinationBase/$fileName";
        storageRef = FirebaseStorage.instance.ref(destination);
        final uploadTask = storageRef.putData(fileBytes);
        final snapshot = await uploadTask.whenComplete(() => null);
        final downloadUrl = await snapshot.ref.getDownloadURL();
        print("Dosya başarıyla yüklendi: $downloadUrl");
      } else {
        final file = File(filePath!);
        fileName = "CompanyEvaluation_22002357_Bilgehan_Demirkaya";
        final destination = "$destinationBase/$fileName";
        storageRef = FirebaseStorage.instance.ref(destination);
        final uploadTask = storageRef.putFile(file);
        final snapshot = await uploadTask.whenComplete(() => null);
        final downloadUrl = await snapshot.ref.getDownloadURL();
        print("Dosya başarıyla yüklendi: $downloadUrl");
      }
    } catch (e) {
      print("Dosya yükleme sırasında bir hata oluştu: $e");
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

  @override
  Widget build(BuildContext context) {
    final String? studentName = widget.submission['studentName'] ?? 'Demo student';
    final String? bilkentId = widget.submission['bilkentId'] ?? '1110002';
    final String? email = widget.submission['email'] ?? 'demo.student@bilkent.edu.tr';
    final String? course = widget.submission['course'] ?? 'CTIS310';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Evaluate Submission'),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Student Information Section
            Card(
              elevation: 2,
              child: Padding(
              padding: const EdgeInsets.all(16.0),
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
              _buildCTIS310Section('Follow Up2'),
              _buildCTIS310Section('Follow Up3'),
              _buildCTIS310Section('Follow Up4'),
              _buildCTIS310Section('Follow Up5'),
              _buildCTIS310Section('Reports about an internship'),
            ],

            // CTIS 290 Specific Section
            if (course == 'CTIS290') ...[
              _buildCTIS290Section(),
            ],

            // Company Evaluation Section
            Card(
              elevation: 2,
              child: Padding(
              padding: const EdgeInsets.all(16.0),
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
                    // Updated file picker logic for web and mobile
                    if (kIsWeb) {
                      FilePickerResult? result = await FilePicker.platform.pickFiles();
                      if (result != null) {
                        setState(() {
                          _fileBytes = result.files.single.bytes;
                          // Optionally store a dummy filePath for consistency
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
                  child: const Text('Choose File'),
                ),
                // New widget to display selected file name
                if (_filePath != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text('Seçilen dosya: $_filePath'),
                  ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () async {
                    if (kIsWeb) {
                      if (_fileBytes != null) {
                        try {
                          await uploadFile(fileBytes: _fileBytes);
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Success"),
                              content: const Text("File uploaded successfully."),
                              actions: [
                                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("OK"))
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
                                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("OK"))
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
                              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("OK"))
                            ],
                          ),
                        );
                      }
                    } else {
                      if (_filePath != null) {
                        try {
                          await uploadFile(filePath: _filePath);
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Success"),
                              content: const Text("File uploaded successfully."),
                              actions: [
                                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("OK"))
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
                                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("OK"))
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
                              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("OK"))
                            ],
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Upload Company Evaluation'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _companyEvaluationController,
                  decoration: const InputDecoration(
                  labelText: 'Grade (0-100)',
                  border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                ],
              ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCTIS310Section(String title) {
    final String fileName = title.replaceAll(' ', '_');
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
              child: Text('Download $title'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _evaluationController,
              decoration: const InputDecoration(
                labelText: 'Grade (0-100)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCTIS290Section() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
              child: const Text('Download Report'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _evaluationController,
              decoration: const InputDecoration(
                labelText: 'Grade (0-100)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );  
}
}
