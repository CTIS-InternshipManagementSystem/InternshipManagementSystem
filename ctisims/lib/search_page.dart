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
  bool _isUploading = false;

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

  Future<void> uploadFile(String bilkentId, String name, String courseId, String year, String semester, String code) async {
    setState(() {
      _isUploading = true;
    });

    try {
      await Firebase.initializeApp();
      final String fileName = "CompanyEvaluation_${bilkentId}_$name";
      final String destinationBase = "$year $semester/CTIS$code/${name}_$bilkentId";
      Reference storageRef;

      if (kIsWeb) {
        if (_uploadFileBytes == null) throw Exception("No file bytes provided for web upload");
        final destination = "$destinationBase/$fileName";
        storageRef = FirebaseStorage.instance.ref(destination);
        final uploadTask = storageRef.putData(_uploadFileBytes!);
        final snapshot = await uploadTask.whenComplete(() => null);
        final downloadUrl = await snapshot.ref.getDownloadURL();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("File uploaded successfully!")),
        );
        
        // Update company evaluation status
        await DBHelper.changeCompanyEvaluation(bilkentId, courseId, true);
        _updateFilteredSubmissions();
      } else {
        if (_uploadFilePath == null) throw Exception("No file path provided for mobile upload");
        final file = File(_uploadFilePath!);
        final destination = "$destinationBase/$fileName";
        storageRef = FirebaseStorage.instance.ref(destination);
        final uploadTask = storageRef.putFile(file);
        final snapshot = await uploadTask.whenComplete(() => null);
        final downloadUrl = await snapshot.ref.getDownloadURL();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("File uploaded successfully!")),
        );
        
        // Update company evaluation status
        await DBHelper.changeCompanyEvaluation(bilkentId, courseId, true);
        _updateFilteredSubmissions();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error during file upload: $e")),
      );
    } finally {
      setState(() {
        _isUploading = false;
        _uploadFilePath = null;
        _uploadFileBytes = null;
      });
    }
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Download started")),
        );
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
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("File deleted successfully")),
      );
      
      _updateFilteredSubmissions();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("File deletion error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
            const SizedBox(height: 8),
            TextField(
              controller: _bilkentIdController,
              decoration: const InputDecoration(
                labelText: 'Bilkent ID',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
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
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Year: $year'),
                              const SizedBox(height: 4),
                              Text('Semester: $semester'),
                              const SizedBox(height: 4),
                              Text('Course: CTIS $code'),
                              const SizedBox(height: 4),
                              Text('Student Name: $name'),
                              const SizedBox(height: 4),
                              Text('Bilkent ID: $bilkentId'),
                              const SizedBox(height: 4),
                              Text('Company Evaluation Uploaded: $companyEvaluationUploaded'),
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
                                    onPressed: _isUploading 
                                      ? null 
                                      : () => uploadFile(bilkentId, name, courseId, year, semester, code),
                                    child: _isUploading
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
