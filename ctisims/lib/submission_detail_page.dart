import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:html' as html;

class SubmissionDetailPage extends StatefulWidget {
  final Map<String, String> submission;
  const SubmissionDetailPage({super.key, required this.submission});

  @override
  _SubmissionDetailPageState createState() => _SubmissionDetailPageState();
}

class _SubmissionDetailPageState extends State<SubmissionDetailPage> {
  String? _uploadFilePath;
  Uint8List? _uploadFileBytes;

  final String destinationBase = "2024-2025 Spring/CTIS310/Bilgehan_Demirkaya_22002357";

  Future<void> uploadFile({String? filePath, Uint8List? fileBytes}) async {
    try {
      await Firebase.initializeApp();
      String fileName = "CompanyEvaluation_22002357_Bilgehan_Demirkaya";
      Reference storageRef;
      if (kIsWeb) {
        if (fileBytes == null) throw Exception("No file bytes provided for web upload");
        final destination = "$destinationBase/$fileName";
        storageRef = FirebaseStorage.instance.ref(destination);
        final uploadTask = storageRef.putData(fileBytes);
        final snapshot = await uploadTask.whenComplete(() => null);
        final downloadUrl = await snapshot.ref.getDownloadURL();
        print("Dosya başarıyla yüklendi: $downloadUrl");
      } else {
        final file = File(filePath!);
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
        // For mobile, download file and save locally.
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
    final String course = widget.submission['course'] ?? 'CTIS290';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Submission Details'),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student Information Section
            _buildCard(
              context,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Student Information',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text('Name: ${widget.submission['studentName']}'),
                  const SizedBox(height: 4),
                  Text('Bilkent ID: ${widget.submission['bilkentId']}'),
                  const SizedBox(height: 4),
                  Text('Email: ${widget.submission['email']}'),
                  const SizedBox(height: 4),
                  Text('Course: $course'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Submission Details Section
            if (course == 'CTIS310') ...[
              _buildCTIS310Section(context, 'Follow Up1'),
              _buildCTIS310Section(context, 'Follow Up2'),
              _buildCTIS310Section(context, 'Follow Up3'),
              _buildCTIS310Section(context, 'Follow Up4'),
              _buildCTIS310Section(context, 'Follow Up5'),
              _buildCTIS310Section(context, 'Reports about an internship'),
            ] else if (course == 'CTIS290') ...[
              _buildCTIS290Section(context),
            ],

            // Company Evaluation Section
            _buildCard(
              context,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Company Evaluation',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (widget.submission['companyEvaluation'] == 'Uploaded') ...[
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
                          if(result != null) {
                            setState(() {
                              _uploadFileBytes = result.files.single.bytes;
                              _uploadFilePath = result.files.single.name; // display file name
                            });
                          }
                        } else {
                          FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.any);
                          if(result != null) {
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
                        child: Text('Seçilen dosya: $_uploadFilePath'),
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
                                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
                                ),
                              );
                            } catch (e) {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text("Error"),
                                  content: const Text("File not uploaded."),
                                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
                                ),
                              );
                            }
                          } else {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Error"),
                                content: const Text("No file selected."),
                                actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
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
                                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
                                ),
                              );
                            } catch (e) {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text("Error"),
                                  content: const Text("File not uploaded."),
                                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
                                ),
                              );
                            }
                          } else {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Error"),
                                content: const Text("No file selected."),
                                actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
                              ),
                            );
                          }
                        }
                      },
                      child: const Text('Upload'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, Widget child) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          width: MediaQuery.of(context).size.width - 50, // Full width minus margins
          child: child,
        ),
      ),
    );
  }

  Widget _buildCTIS310Section(BuildContext context, String title) {
    final String fileName = title.replaceAll(' ', '_');
    return _buildCard(
      context,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              downloadFile(fileName);
            },
            child: Text('Download $title'),
          ),
        ],
      ),
    );
  }

  Widget _buildCTIS290Section(BuildContext context) {
    return _buildCard(
      context,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reports about an internship',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              // Implement file download logic
            },
            child: const Text('Download Report'),
          ),
        ],
      ),
    );
  }
}
