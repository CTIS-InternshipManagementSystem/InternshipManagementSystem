import 'package:flutter/material.dart';

class SubmissionPage extends StatefulWidget {
  final String course;

  const SubmissionPage({Key? key, required this.course}) : super(key: key);

  @override
  _SubmissionPageState createState() => _SubmissionPageState();
}

class _SubmissionPageState extends State<SubmissionPage> {
  final TextEditingController _commentController = TextEditingController();
  String? _selectedOption;

  final List<String> _ctis290Options = ['Reports about an internship'];
  final List<String> _ctis310Options = [
    'Follow Up1',
    'Follow Up2',
    'Follow Up3',
    'Follow Up4',
    'Follow Up5',
    'Reports about an internship'
  ];

  @override
  Widget build(BuildContext context) {
    final List<String> options = widget.course == 'CTIS290' ? _ctis290Options : _ctis310Options;

    return Scaffold(
      appBar: AppBar(
        title: Text('Submission for ${widget.course}'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Upper section: Status bar and company evaluation form status
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Status',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(value: 0.5), // Example status bar
                      const SizedBox(height: 8),
                      const Text(
                        'Company evaluation form not uploaded',
                        style: TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 8),
                      const Text('Grade: Not yet evaluated'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Middle section: Upload new report
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upload New Report',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          // Implement file picker
                        },
                        child: const Text('Choose File'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _commentController,
                        decoration: const InputDecoration(
                          labelText: 'Comments',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 8),
                      // New radio button group for selecting the report type
                      Column(
                        children: options.map((option) {
                          return RadioListTile<String>(
                            title: Text(option),
                            value: option,
                            groupValue: _selectedOption,
                            onChanged: (value) {
                              setState(() {
                                _selectedOption = value;
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          // Implement submission logic
                        },
                        child: const Text('Submit'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              
            ],
          ),
        ),
      ),
    );
  }
}
