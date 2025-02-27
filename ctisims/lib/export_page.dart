import 'package:flutter/material.dart';

// Centralized styling constants (reuse or import from your common styles file)
class AppStyles {
  static const primaryColor = Colors.orange;
  static const buttonColor = Colors.blue;
  static const cardElevation = 4.0;
  static const borderRadius = 16.0;
  static const padding = EdgeInsets.all(16.0);
  static const fieldSpacing = SizedBox(height: 8);
}

class ExportPage extends StatefulWidget {
  final List<Map<String, String>> semesters;

  const ExportPage({super.key, required this.semesters});

  @override
  _ExportPageState createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> {
  bool darkMode = false;
  String searchQuery = "";
  late List<Map<String, String>> filteredSemesters;

  // Per-card loading states using maps keyed by card index.
  final Map<int, bool> _gradesLoading = {};
  final Map<int, bool> _statisticsLoading = {};
  final Map<int, bool> _submissionsLoading = {};
  final Map<int, bool> _deactivateLoading = {};

  @override
  void initState() {
    super.initState();
    filteredSemesters = widget.semesters;
  }

  void updateSearch(String query) {
    setState(() {
      searchQuery = query;
      filteredSemesters = widget.semesters.where((semester) {
        final course = (semester['course'] ?? "").toLowerCase();
        return course.contains(query.toLowerCase());
      }).toList();
    });
  }

  // Simulate an export operation per card.
  Future<void> simulateExport(Function onCompleted) async {
    await Future.delayed(const Duration(seconds: 2));
    onCompleted();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = darkMode ? Colors.black : Colors.grey[100];
    final textColor = darkMode ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Grades & Statistics'),
        backgroundColor: AppStyles.primaryColor,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(darkMode ? Icons.dark_mode : Icons.light_mode),
            onPressed: () {
              setState(() {
                darkMode = !darkMode;
              });
            },
          ),
        ],
      ),
      backgroundColor: bgColor,
      body: Padding(
        padding: AppStyles.padding,
        child: Column(
          children: [
            // Interactive search field.
            TextField(
              onChanged: updateSearch,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: "Search by course...",
                hintStyle: TextStyle(color: textColor.withOpacity(0.6)),
                prefixIcon: Icon(Icons.search, color: textColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppStyles.borderRadius),
                ),
              ),
            ),
            AppStyles.fieldSpacing,
            // Responsive Grid of Cards.
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = 1;
                  if (constraints.maxWidth >= 1200) {
                    crossAxisCount = 3;
                  } else if (constraints.maxWidth >= 800) {
                    crossAxisCount = 2;
                  }
                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 3 / 2,
                    ),
                    itemCount: filteredSemesters.length,
                    itemBuilder: (context, index) {
                      final semester = filteredSemesters[index];
                      return Card(
                        elevation: AppStyles.cardElevation,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppStyles.borderRadius),
                        ),
                        child: Padding(
                          padding: AppStyles.padding,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header: Year (left) and Semester (right)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    semester['year'] ?? '',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    semester['semester'] ?? '',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              AppStyles.fieldSpacing,
                              // Center: Course Code emphasized
                              Center(
                                child: Text(
                                  semester['course'] ?? '',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              AppStyles.fieldSpacing,
                              // Action Buttons Column.
                              Column(
                                children: [
                                  // Export Grades Button
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: _gradesLoading[index] == true
                                          ? null
                                          : () async {
                                              setState(() {
                                                _gradesLoading[index] = true;
                                              });
                                              await simulateExport(() {
                                                setState(() {
                                                  _gradesLoading[index] = false;
                                                });
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text("Grades exported successfully")),
                                                );
                                              });
                                            },
                                      icon: _gradesLoading[index] == true
                                          ? const SizedBox(
                                              height: 16,
                                              width: 16,
                                              child: CircularProgressIndicator(
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(Icons.grade),
                                      label: const Text("Export Grades"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppStyles.buttonColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(AppStyles.borderRadius),
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                    ),
                                  ),
                                  AppStyles.fieldSpacing,
                                  // Export Statistics Button
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: _statisticsLoading[index] == true
                                          ? null
                                          : () async {
                                              setState(() {
                                                _statisticsLoading[index] = true;
                                              });
                                              await simulateExport(() {
                                                setState(() {
                                                  _statisticsLoading[index] = false;
                                                });
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text("Statistics exported successfully")),
                                                );
                                              });
                                            },
                                      icon: _statisticsLoading[index] == true
                                          ? const SizedBox(
                                              height: 16,
                                              width: 16,
                                              child: CircularProgressIndicator(
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(Icons.bar_chart),
                                      label: const Text("Export Stats"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppStyles.buttonColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(AppStyles.borderRadius),
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                    ),
                                  ),
                                  AppStyles.fieldSpacing,
                                  // Export Submissions Button
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: _submissionsLoading[index] == true
                                          ? null
                                          : () async {
                                              setState(() {
                                                _submissionsLoading[index] = true;
                                              });
                                              await simulateExport(() {
                                                setState(() {
                                                  _submissionsLoading[index] = false;
                                                });
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text("Submissions exported successfully")),
                                                );
                                              });
                                            },
                                      icon: _submissionsLoading[index] == true
                                          ? const SizedBox(
                                              height: 16,
                                              width: 16,
                                              child: CircularProgressIndicator(
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(Icons.file_download),
                                      label: const Text("Export Submissions"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppStyles.buttonColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(AppStyles.borderRadius),
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                    ),
                                  ),
                                  AppStyles.fieldSpacing,
                                  // Deactivate Semester Button
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: _deactivateLoading[index] == true
                                          ? null
                                          : () async {
                                              setState(() {
                                                _deactivateLoading[index] = true;
                                              });
                                              await simulateExport(() {
                                                setState(() {
                                                  _deactivateLoading[index] = false;
                                                });
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text("Semester deactivated")),
                                                );
                                              });
                                            },
                                      icon: _deactivateLoading[index] == true
                                          ? const SizedBox(
                                              height: 16,
                                              width: 16,
                                              child: CircularProgressIndicator(
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(Icons.cancel),
                                      label: const Text("Deactivate"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppStyles.buttonColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(AppStyles.borderRadius),
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
