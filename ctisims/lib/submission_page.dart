import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class SubmissionPage extends StatefulWidget {
  final String course;

  const SubmissionPage({super.key, required this.course});

  @override
  _SubmissionPageState createState() => _SubmissionPageState();
}

class _SubmissionPageState extends State<SubmissionPage> {
  final TextEditingController _commentController = TextEditingController();
  String? _selectedOption;
  // New fields for file picking/upload for report submission
  String? _uploadFilePath;
  Uint8List? _uploadFileBytes;

  final List<String> _ctis290Options = ['Reports about an internship'];
  final List<String> _ctis310Options = [
    'Follow Up1',
    'Follow Up2',
    'Follow Up3',
    'Follow Up4',
    'Follow Up5',
    'Reports about an internship'
  ];

  Future<void> uploadFile({String? filePath, Uint8List? fileBytes}) async {
    try {
      await Firebase.initializeApp();
      // Use a fixed file name for report submission, customize as needed.
      String fileName = "CompanyEvaluationForm_22002357_Bilgehan_Demirkaya";
      final String destinationBase = "2024-2025 Spring/CTIS310/Bilgehan_Demirkaya_22002357";
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

  @override
  Widget build(BuildContext context) {
    final List<String> options = widget.course == 'CTIS290' ? _ctis290Options : _ctis310Options;

    return Scaffold(
      appBar: AppBar(
        title: Text('Submission for ${widget.course}'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Upper section: Status bar and company evaluation form status
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Status',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(value: 0.5), // Example status bar
                      const SizedBox(height: 8),
                      const Text(
                        'Company evaluation form not uploaded',
                        style: TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 8),
                      const Text('Grade: Not yet evaluated'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Middle section: Upload new report
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upload New Report',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () async {
                          if (kIsWeb) {
                            FilePickerResult? result = await FilePicker.platform.pickFiles();
                            if (result != null) {
                              setState(() {
                                _uploadFileBytes = result.files.single.bytes;
                                _uploadFilePath = result.files.single.name; // display file name
                              });
                              // Removed immediate uploadFile call and alert.
                            }
                          } else {
                            FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.any);
                            if (result != null) {
                              setState(() {
                                _uploadFilePath = result.files.single.path;
                              });
                              // Removed immediate uploadFile call and alert.
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
                      TextField(
                        controller: _commentController,
                        decoration: const InputDecoration(
                          labelText: 'Comments',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 8),
                      // New radio button group for selecting the report type
                      Column(
                        children: options.map((option) {
                          return RadioListTile<String>(
                            title: Text(option),
                            value: option,
                            groupValue: _selectedOption,
                            onChanged: (value) {
                              setState(() {
                                _selectedOption = value;
                              });
                            },
                          );
                        }).toList(),
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
                  ),
                ),
              ),
              const SizedBox(height: 16),

              
            ],
          ),
        ),
      ),
    );
  }
}
