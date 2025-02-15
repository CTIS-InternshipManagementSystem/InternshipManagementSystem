import 'package:flutter/material.dart';

class SubmissionDetailPage extends StatelessWidget {
  final Map<String, String> submission;

  const SubmissionDetailPage({Key? key, required this.submission}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String course = submission['course'] ?? 'CTIS290';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Submission Details'),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student Information Section
            _buildCard(
              context,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Student Information',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text('Name: ${submission['studentName']}'),
                  const SizedBox(height: 4),
                  Text('Bilkent ID: ${submission['bilkentId']}'),
                  const SizedBox(height: 4),
                  Text('Email: ${submission['email']}'),
                  const SizedBox(height: 4),
                  Text('Course: $course'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Submission Details Section
            if (course == 'CTIS310') ...[
              _buildCTIS310Section(context, 'Follow Up1'),
              _buildCTIS310Section(context, 'Follow Up2'),
              _buildCTIS310Section(context, 'Follow Up3'),
              _buildCTIS310Section(context, 'Follow Up4'),
              _buildCTIS310Section(context, 'Follow Up5'),
              _buildCTIS310Section(context, 'Reports about an internship'),
            ] else if (course == 'CTIS290') ...[
              _buildCTIS290Section(context),
            ],

            // Company Evaluation Section
            _buildCard(
              context,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Company Evaluation',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, Widget child) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          width: MediaQuery.of(context).size.width - 50, // Full width minus margins
          child: child,
        ),
      ),
    );
  }

  Widget _buildCTIS310Section(BuildContext context, String title) {
    return _buildCard(
      context,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              // Implement file download logic
            },
            child: Text('Download $title'),
          ),
        ],
      ),
    );
  }

  Widget _buildCTIS290Section(BuildContext context) {
    return _buildCard(
      context,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reports about an internship',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              // Implement file download logic
            },
            child: const Text('Download Report'),
          ),
        ],
      ),
    );
  }
}
