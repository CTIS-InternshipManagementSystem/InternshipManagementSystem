import 'package:flutter/material.dart';

class ExportPage extends StatelessWidget {
  final List<Map<String, String>> semesters;

  const ExportPage({Key? key, required this.semesters}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Grades and Statistics'),
        backgroundColor: Colors.orange,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: semesters.length,
        itemBuilder: (context, index) {
          final semester = semesters[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${semester['year']} ${semester['semester']} ${semester['course']}'),
                  const SizedBox(height: 8),
                  Text('Status: ${semester['status']}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Implement export grades logic
                    },
                    child: const Text('Export Grades'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      // Implement export statistics logic
                    },
                    child: const Text('Export Statistics'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      // Implement export submissions logic
                    },
                    child: const Text('Export Submissions'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      // Implement deactivate semester logic
                    },
                    child: const Text('Deactivate'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
