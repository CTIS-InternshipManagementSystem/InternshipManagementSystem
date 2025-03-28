import 'package:flutter/material.dart';
import 'evaluate_page.dart';
import 'dbHelper.dart'; // Ensure DBHelper is imported

class AssignedSubmissionsPage extends StatefulWidget {
  final String courseId; // new parameter

  const AssignedSubmissionsPage({super.key, required this.courseId});

  @override
  _AssignedSubmissionsPageState createState() => _AssignedSubmissionsPageState();
}

class _AssignedSubmissionsPageState extends State<AssignedSubmissionsPage> {
  bool _showWithoutEvaluation = false;
  Future<List<Map<String, dynamic>>>? _futureSubmissions;

  @override
  void initState() {
    super.initState();
    _futureSubmissions = DBHelper.getStudentsFromCourses(widget.courseId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assigned Submissions'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _futureSubmissions,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            // If no submissions, show "No submission"
            if (snapshot.data!.isEmpty) {
              return const Center(child: Text("No submission"));
            }
            List<Map<String, dynamic>> submissions = snapshot.data!;
            // Assume each submission has a field 'companyEvaluation'
            // If absent, set it to "Not Uploaded".
            submissions = submissions.map((s) {
              if (!s.containsKey('companyEvaluation')) {
                s['companyEvaluation'] = 'Not Uploaded';
              }
              return s;
            }).toList();
            final filteredSubmissions = _showWithoutEvaluation
                ? submissions.where((s) => s['companyEvaluation'] == 'Not Uploaded').toList()
                : submissions;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('Show only without company evaluation'),
                    ),
                    Switch(
                      value: _showWithoutEvaluation,
                      onChanged: (value) {
                        setState(() {
                          _showWithoutEvaluation = value;
                        });
                      },
                    ),
                  ],
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredSubmissions.length,
                    itemBuilder: (context, index) {
                      final submission = filteredSubmissions[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          title: Text(submission['name'] ?? "Student"),
                          subtitle: Text('Company Evaluation: ${submission['companyEvaluation']}'),
                          trailing: ElevatedButton(
                            onPressed: () {
                              final submissionMap = {
                                'bilkentId': submission['bilkentId'] ?? '',
                                'courseId': widget.courseId,
                                'studentName': submission['name'] ?? '',
                                'email': submission['email'] ?? '',
                                'course': 'CTIS' + (submission['courseCode'] ?? '310'),
                                'companyEvaluation': submission['companyEvaluation'] ?? 'Not Uploaded'
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
                            child: const Text('Evaluate'),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
