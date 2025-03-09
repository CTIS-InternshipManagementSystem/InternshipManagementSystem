import 'package:ctisims/evaluate_page.dart';
import 'package:flutter/material.dart';
import 'package:ctisims/dbHelper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:html' as html;

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

  Future<List<Map<String, dynamic>>>? _futureStudentCourses;

  @override
  void initState() {
    super.initState();
    _futureStudentCourses = DBHelper.getStudentCoursesWithCourseInfo();
    _bilkentIdController.addListener(_searchSubmissions);
  }

  void _searchSubmissions() {
    final bilkentId = _bilkentIdController.text;
    setState(() {
      _futureStudentCourses = DBHelper.getStudentCoursesWithCourseInfo().then((submissions) {
        if (bilkentId.isEmpty) {
          return submissions;
        } else {
          return submissions.where((submission) => submission['bilkentId'].startsWith(bilkentId)).toList();
        }
      });
    });
  }

  void _updateFilteredSubmissions() {
    setState(() {
      _futureStudentCourses = DBHelper.getStudentCoursesWithCourseInfo();
    });
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
                  _updateFilteredSubmissions();
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
                  _updateFilteredSubmissions();
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
              onChanged: (value) {
              _searchSubmissions();
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _futureStudentCourses,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.data!.isEmpty) {
                    return const Center(child: Text("No students found"));
                  }
                  final studentCourses = snapshot.data!;
                  return ListView.builder(
                    itemCount: studentCourses.length,
                    itemBuilder: (context, index) {
                      final submission = studentCourses[index];
                      final course = submission['course'];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Year: ${course['year']}'),
                              const SizedBox(height: 4),
                              Text('Semester: ${course['semester']}'),
                              const SizedBox(height: 4),
                              Text('Course: CTIS ${course['code']}'),
                              const SizedBox(height: 4),
                              Text('Student Name: ${submission['name']}'),
                              const SizedBox(height: 4),
                              Text('Bilkent ID: ${submission['bilkentId']}'),
                              const SizedBox(height: 4),
                              Text('Company Evaluation Uploaded: ${submission['companyEvaluationUploaded']}'),
                              const SizedBox(height: 16),
                              if (_selectedOption == 'Uploading Company Evaluation Reports') ...[
                                if (submission['companyEvaluationUploaded'] == true) ...[
                                  ElevatedButton(
                                    onPressed: () async {
                                                  try {
                                                    final String destinationBase = "${course['year']} ${course['semester']}/CTIS${course['code']}/${submission['name']}_${submission['bilkentId']}";
                                                    final String fileName = "CompanyEvaluation_${submission['bilkentId']}_${submission['name']}";
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
                                    },
                                    child: const Text('Download Company Evaluation Report'),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: () async {
                                      try {
                                        final String destinationBase = "${course['year']} ${course['semester']}/CTIS${course['code']}/${submission['name']}_${submission['bilkentId']}";
                                        final String fileName = "CompanyEvaluation_${submission['bilkentId']}_${submission['name']}";
                                        final String destination = "$destinationBase/$fileName";
                                        final ref = FirebaseStorage.instance.ref(destination);
                                        await ref.delete();
                                        print("Dosya başarıyla silindi: $fileName");
                                        final bilkentId = submission['bilkentId'];
                                        final courseId = course['id'];
                                        final companyEvaluationUploaded = false;
                                        DBHelper.changeCompanyEvaluation(bilkentId, courseId, companyEvaluationUploaded);
                                        setState(() {
                                        _futureStudentCourses = DBHelper.getStudentCoursesWithCourseInfo();
                                        });
                                      } catch (e) {
                                        print("Dosya silme sırasında bir hata oluştu: $e");
                                      }
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
                                      child: Text('Seçilen dosya: $_uploadFilePath'),
                                    ),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: () async {
                                      if (kIsWeb) {
                                        if (_uploadFileBytes != null) {
                                          try {
                                                await Firebase.initializeApp();
                                                final String fileName = "CompanyEvaluation_${submission['bilkentId']}_${submission['name']}";
                                                final String destinationBase = "${course['year']} ${course['semester']}/CTIS${course['code']}/${submission['name']}_${submission['bilkentId']}";
                                                Reference storageRef;
                                                if (kIsWeb) {
                                                  if (_uploadFileBytes == null) throw Exception("No file bytes provided for web upload");
                                                  final destination = "$destinationBase/$fileName";
                                                  storageRef = FirebaseStorage.instance.ref(destination);
                                                  final uploadTask = storageRef.putData(_uploadFileBytes!);
                                                  final snapshot = await uploadTask.whenComplete(() => null);
                                                  final downloadUrl = await snapshot.ref.getDownloadURL();
                                                  print("Dosya başarıyla yüklendi: $downloadUrl");
                                                  final bilkentId = submission['bilkentId'];
                                                  final courseId = course['id'];
                                                  final companyEvaluationUploaded = true;
                                                  DBHelper.changeCompanyEvaluation(bilkentId, courseId, companyEvaluationUploaded);
                                                  setState(() {
                                                  _futureStudentCourses = DBHelper.getStudentCoursesWithCourseInfo();
                                                  });
                                                } else {
                                                  final file = File(_uploadFilePath!);
                                                  final destination = "$destinationBase/$fileName";
                                                  storageRef = FirebaseStorage.instance.ref(destination);
                                                  final uploadTask = storageRef.putFile(file);
                                                  final snapshot = await uploadTask.whenComplete(() => null);
                                                  final downloadUrl = await snapshot.ref.getDownloadURL();
                                                  print("Dosya başarıyla yüklendi: $downloadUrl");
                                                  final bilkentId = submission['bilkentId'];
                                                  final courseId = course['id'];
                                                  final companyEvaluationUploaded = true;
                                                  DBHelper.changeCompanyEvaluation(bilkentId, courseId, companyEvaluationUploaded);
                                                  setState(() {
                                                  _futureStudentCourses = DBHelper.getStudentCoursesWithCourseInfo();
                                                  });
                                                }
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
                                              await Firebase.initializeApp();
                                              final String fileName = "CompanyEvaluation_${submission['bilkentId']}_${submission['name']}";
                                              final String destinationBase = "${course['year']} ${course['semester']}/CTIS${course['code']}/${submission['name']}_${submission['bilkentId']}";
                                              Reference storageRef;
                                              if (kIsWeb) {
                                                if (_uploadFileBytes == null) throw Exception("No file bytes provided for web upload");
                                                final destination = "$destinationBase/$fileName";
                                                storageRef = FirebaseStorage.instance.ref(destination);
                                                final uploadTask = storageRef.putData(_uploadFileBytes!);
                                                final snapshot = await uploadTask.whenComplete(() => null);
                                                final downloadUrl = await snapshot.ref.getDownloadURL();
                                                print("Dosya başarıyla yüklendi: $downloadUrl");
                                              } else {
                                                final file = File(_uploadFilePath!);
                                                final destination = "$destinationBase/$fileName";
                                                storageRef = FirebaseStorage.instance.ref(destination);
                                                final uploadTask = storageRef.putFile(file);
                                                final snapshot = await uploadTask.whenComplete(() => null);
                                                final downloadUrl = await snapshot.ref.getDownloadURL();
                                                print("Dosya başarıyla yüklendi: $downloadUrl");
                                              }
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
                              if (_selectedOption == 'Search Student') ...[
                                ElevatedButton(
                                    onPressed: () {
                                    final submissionMap = {
                                      'bilkentId': submission['bilkentId'] ?? '',
                                      'courseId': course['courseId'].toString(),
                                      'studentName': submission['name'] ?? '',
                                      'email': submission['email'] ?? '',
                                      'course': 'CTIS' + (course['code'] ?? '310'),
                                      'companyEvaluation': submission['companyEvaluationUploaded'] == true ? 'Uploaded' : 'Not Uploaded'
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
