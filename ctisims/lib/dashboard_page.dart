import 'package:flutter/material.dart';
import 'submission_page.dart';
import 'assigned_submissions_page.dart';
import 'export_page.dart';
import 'search_page.dart';

class DashboardPage extends StatelessWidget {
  final List<Map<String, String>> registeredSemesters;

  const DashboardPage({Key? key, required this.registeredSemesters}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.orange,
        actions: [
          if (registeredSemesters.any((semester) => semester['role'] == 'Admin')) ...[
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ExportPage(semesters: registeredSemesters)),
                );
              },
              child: const Text('Statistics & Grades', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SearchPage()),
                );
              },
              child: const Text('Search', style: TextStyle(color: Colors.white)),
            ),
          ],
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: registeredSemesters.length,
        itemBuilder: (context, index) {
          final semester = registeredSemesters[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
              title: Text('${semester['year']} ${semester['semester']} ${semester['course']}'),
              trailing: ElevatedButton(
                onPressed: () {
                  if (semester['role'] == 'Student') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SubmissionPage(course: semester['course']!)),
                    );
                  } else if (semester['role'] == 'Admin') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AssignedSubmissionsPage()),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AssignedSubmissionsPage()),
                    );
                  }
                },
                child: Text(semester['role'] == 'Student' ? 'View Submission' : 'Evaluate Submission'),
              ),
            ),
          );
        },
      ),
    );
  }
}
