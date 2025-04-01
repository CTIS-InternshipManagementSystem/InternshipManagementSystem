import 'package:flutter/material.dart';
import 'evaluate_page.dart';
import 'dbHelper.dart'; // Ensure DBHelper is imported
import 'package:provider/provider.dart';
import 'themes/Theme_provider.dart';

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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    
    final cardBgColor = isDark ? Colors.grey[850] : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assigned Submissions'),
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.dark_mode : Icons.light_mode,
              color: Colors.grey,
            ),
            tooltip: 'Toggle Dark Mode',
            onPressed: () {
              themeProvider.toggleTheme();
            },
          ),
        ],
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
              return Center(child: Text("No submission", style: TextStyle(color: textColor)));
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
                    Expanded(
                      child: Text(
                        'Show only without company evaluation',
                        style: TextStyle(color: textColor),
                      ),
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
                        color: cardBgColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          title: Text(
                            submission['name'] ?? "Student",
                            style: TextStyle(color: textColor),
                          ),
                          subtitle: Text(
                            'Company Evaluation: ${submission['companyEvaluation']}',
                            style: TextStyle(color: textColor.withOpacity(0.8)),
                          ),
                          trailing: ElevatedButton(
                            onPressed: () {
                              final submissionMap = {
                                'bilkentId': submission['bilkentId'] ?? '',
                                'courseId': widget.courseId,
                                'studentName': submission['name'] ?? '',
                                'email': submission['email'] ?? '',
                                'course': 'CTIS${submission['courseCode'] ?? '310'}',
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
