import 'package:flutter/material.dart';

class EvaluatePage extends StatefulWidget {
  final Map<String, String> submission;

  const EvaluatePage({Key? key, required this.submission}) : super(key: key);

  @override
  _EvaluatePageState createState() => _EvaluatePageState();
}

class _EvaluatePageState extends State<EvaluatePage> {
  final TextEditingController _evaluationController = TextEditingController();
  final TextEditingController _companyEvaluationController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final String studentName = widget.submission['studentName'] ?? 'Demo student';
    final String bilkentId = widget.submission['bilkentId'] ?? '1110002';
    final String email = widget.submission['email'] ?? 'demo.student@bilkent.edu.tr';
    final String course = widget.submission['course'] ?? 'CTIS310';
    final String title = widget.submission['title'] ?? 'Submission';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Evaluate Submission'),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student Information Section
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Student Information',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text('Name: $studentName'),
                    const SizedBox(height: 4),
                    Text('Bilkent ID: $bilkentId'),
                    const SizedBox(height: 4),
                    Text('Email: $email'),
                    const SizedBox(height: 4),
                    Text('Course: $course'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            

            // CTIS 310 Specific Sections
            if (course == 'CTIS310') ...[
              _buildCTIS310Section('Follow Up1'),
              _buildCTIS310Section('Follow Up2'),
              _buildCTIS310Section('Follow Up3'),
              _buildCTIS310Section('Follow Up4'),
              _buildCTIS310Section('Follow Up5'),
              _buildCTIS310Section('Reports about an internship'),
            ],

            // CTIS 290 Specific Section
            if (course == 'CTIS290') ...[
              _buildCTIS290Section(),
            ],

            // Company Evaluation Section
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Company Evaluation',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        // TODO: Implement file picker for company evaluation
                      },
                      child: const Text('Upload Company Evaluation'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _companyEvaluationController,
                      decoration: const InputDecoration(
                        labelText: 'Grade (0-100)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCTIS310Section(String title) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement file download logic
              },
              child: Text('Download $title'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _evaluationController,
              decoration: const InputDecoration(
                labelText: 'Grade (0-100)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCTIS290Section() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reports about an internship',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement file download logic
              },
              child: const Text('Download Report'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _evaluationController,
              decoration: const InputDecoration(
                labelText: 'Grade (0-100)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }
}
