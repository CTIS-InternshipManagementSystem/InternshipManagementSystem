import 'package:flutter/material.dart';
import 'evaluate_page.dart';

class AssignedSubmissionsPage extends StatefulWidget {
  const AssignedSubmissionsPage({Key? key}) : super(key: key);

  @override
  _AssignedSubmissionsPageState createState() => _AssignedSubmissionsPageState();
}

class _AssignedSubmissionsPageState extends State<AssignedSubmissionsPage> {
  bool _showWithCompanyEvaluation = false;

  // Example data for submissions
  final List<Map<String, String>> _submissions = [
    {'title': 'Submission 1', 'companyEvaluation': 'Uploaded'},
    {'title': 'Submission 2', 'companyEvaluation': 'Not Uploaded'},
    {'title': 'Submission 3', 'companyEvaluation': 'Uploaded'},
  ];

  @override
  Widget build(BuildContext context) {
    final filteredSubmissions = _showWithCompanyEvaluation
        ? _submissions.where((submission) => submission['companyEvaluation'] == 'Uploaded').toList()
        : _submissions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assigned Submissions'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: const Text('Show only with company evaluation form uploaded'),
                ),
                Switch(
                  value: _showWithCompanyEvaluation,
                  onChanged: (value) {
                    setState(() {
                      _showWithCompanyEvaluation = value;
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
                      title: Text(submission['title']!),
                      subtitle: Text('Company Evaluation: ${submission['companyEvaluation']}'),
                      trailing: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => EvaluatePage(submission: submission)),
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
        ),
      ),
    );
  }
}
