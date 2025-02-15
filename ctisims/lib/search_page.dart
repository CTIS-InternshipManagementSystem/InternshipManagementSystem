import 'package:flutter/material.dart';
import 'submission_detail_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String? _selectedOption;
  final TextEditingController _bilkentIdController = TextEditingController();

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

  @override
  void initState() {
    super.initState();
    _filteredSubmissions = _studentSubmissions;
  }

  void _searchSubmissions() {
    final bilkentId = _bilkentIdController.text;
    setState(() {
      _filteredSubmissions = _studentSubmissions
          .where((submission) => submission['bilkentId'] == bilkentId)
          .toList();
    });
  }

  void _updateFilteredSubmissions() {
    setState(() {
      _filteredSubmissions = _studentSubmissions;
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
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _searchSubmissions,
              child: const Text('Search Student Submissions'),
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
                                  // Implement download logic
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
                                onPressed: () {
                                  // Implement file picker for company evaluation
                                },
                                child: const Text('Choose File'),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () {
                                  // Implement upload logic
                                },
                                child: const Text('Upload'),
                              ),
                            ],
                          ],
                          if (_selectedOption == 'Search Student') ...[
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => SubmissionDetailPage(submission: submission)),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
