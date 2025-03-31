import 'dart:io';

import 'dart:html' as html;
import 'package:ctisims/dbHelper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';

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
  final List<Map<String, String>> registeredSemesters; // added field

  const ExportPage({
    super.key,
    required this.registeredSemesters,
  }); // updated constructor

  @override
  _ExportPageState createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> {
  bool darkMode = false;
  String searchQuery = "";

  // Replace semesters with courses loaded from DBHelper.getAllCourses()
  List<Map<String, dynamic>> _allCourses = [];
  List<Map<String, dynamic>> _filteredCourses = [];

  // Per-card loading states using maps keyed by card index.
  final Map<int, bool> _gradesLoading = {};
  final Map<int, bool> _submissionsLoading = {};
  final Map<int, bool> _deactivateLoading = {};

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  Future<void> _fetchCourses() async {
    try {
      final courses = await DBHelper.getAllCourses();
      setState(() {
        _allCourses = courses;
        _filteredCourses = List.from(courses);
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error fetching courses: $e")));
    }
  }

  void updateSearch(String query) {
    setState(() {
      searchQuery = query;
      _filteredCourses =
          _allCourses.where((course) {
            // Assuming we display course as "CTIS${course['code']}"
            final courseText = "CTIS${course['code']}".toLowerCase();
            return courseText.contains(query.toLowerCase());
          }).toList();
    });
  }

  // Simulate an export operation per card.
  Future<void> simulateExport(Function onCompleted) async {
    await Future.delayed(const Duration(seconds: 2));
    onCompleted();
  }

  // Add helper function to export grades in Excel format using getAllGradesWithStudentInfo.
  Future<void> _exportGradesExcel(String courseId) async {
    try {
      debugPrint("Starting export grades for course: $courseId");
      final gradeData = await DBHelper.getAllGradesWithStudentInfo(courseId);
      if (!mounted) return;

      debugPrint("Received grade data: $gradeData");

      var excel = Excel.createExcel();
      Sheet sheet = excel['Grades'];

      sheet.appendRow([
        TextCellValue("Bilkent ID"),
        TextCellValue("Student Name"),
        TextCellValue("Assignment"),
        TextCellValue("Grade"),
      ]);

      // Check if grades exist and not empty
      if (gradeData.containsKey('grades') &&
          gradeData['grades'] is Map &&
          (gradeData['grades'] as Map).isNotEmpty) {
        final grades = (gradeData['grades'] as Map).cast<String, dynamic>();
        debugPrint("Processing ${grades.length} student records");

        grades.forEach((bilkentId, info) {
          final String name = info['name'] ?? '';
          debugPrint("Processing student: $name ($bilkentId)");

          if (info.containsKey('grades') && info['grades'] is Map) {
            final gradeMap = (info['grades'] as Map).cast<String, dynamic>();
            debugPrint("Student has ${gradeMap.length} grades");

            gradeMap.forEach((assignment, grade) {
              debugPrint("Adding row: $bilkentId, $name, $assignment, $grade");
              sheet.appendRow([
                TextCellValue(bilkentId),
                TextCellValue(name),
                TextCellValue(assignment),
                TextCellValue(grade?.toString() ?? ''),
              ]);
            });
          } else {
            debugPrint("No grades found for student: $name");
            // Add a row indicating no grades
            sheet.appendRow([
              TextCellValue(bilkentId),
              TextCellValue(name),
              TextCellValue("No assignments"),
              TextCellValue(""),
            ]);
          }
        });
      } else {
        debugPrint("No grades data found in the response");
        // Add a row indicating no data
        sheet.appendRow([
          TextCellValue(""),
          TextCellValue(""),
          TextCellValue("No grade data available"),
          TextCellValue(""),
        ]);
      }

      final excelBytes = excel.encode();
      if (excelBytes == null) throw Exception("Failed to encode Excel file");

      if (kIsWeb) {
        final blob = html.Blob([
          excelBytes,
        ], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        final url = html.Url.createObjectUrlFromBlob(blob);

        html.AnchorElement(href: url)
          ..download = "grades_$courseId.xlsx"
          ..click();

        html.Url.revokeObjectUrl(url);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Excel file downloaded successfully")),
        );
      } else {
        final directory = await getTemporaryDirectory();
        if (!mounted) return; // Check if (mounted) after async gap.
        final filePath = '${directory.path}/grades_$courseId.xlsx';
        final File file = File(filePath);
        await file.writeAsBytes(excelBytes, flush: true);
        if (!mounted) return; // Check if (mounted).
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Excel file saved at: $filePath")),
        );
      }
    } catch (e) {
      if (!mounted) return; // Check if (mounted).
      debugPrint("Error exporting grades: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error exporting grades: $e")));
    }
  }

  // Add helper function to deactivate the course.
  Future<void> _deactivateCourse(String courseId) async {
    try {
      await DBHelper.deactiveCourse(courseId);
      if (!mounted) return; // Check if (mounted).
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Course $courseId deactivated successfully")),
      );
    } catch (e) {
      if (!mounted) return; // Check if (mounted).
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error deactivating course: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = darkMode ? Colors.black : Colors.grey[100];
    final textColor = darkMode ? Colors.white : Colors.black;
    // Replace .withOpacity(0.6) with .withAlpha(153).
    final hintColor = textColor.withAlpha(153);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Grades & Files'),
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
                hintStyle: TextStyle(color: hintColor),
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
                    itemCount: _filteredCourses.length,
                    itemBuilder: (context, index) {
                      final course = _filteredCourses[index];
                      return Card(
                        elevation: AppStyles.cardElevation,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppStyles.borderRadius,
                          ),
                        ),
                        child: Padding(
                          padding: AppStyles.padding,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header: Year (left) and Semester (right)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    course['year'] ?? '',
                                    style: Theme.of(context).textTheme.bodyLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    course['semester'] ?? '',
                                    style: Theme.of(context).textTheme.bodyLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              AppStyles.fieldSpacing,
                              // Center: Course Code emphasized
                              Center(
                                child: Text(
                                  "CTIS ${course['code'] ?? ''}",
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
                                  // Updated Export Grades Button.
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () async {
                                        setState(() {
                                          _gradesLoading[index] = true;
                                        });
                                        await _exportGradesExcel(
                                          course['courseId'] ?? '',
                                        );
                                        setState(() {
                                          _gradesLoading[index] = false;
                                        });
                                      },
                                      icon:
                                          _gradesLoading[index] == true
                                              ? const SizedBox(
                                                height: 24,
                                                width: 24,
                                                child:
                                                    CircularProgressIndicator(),
                                              )
                                              : const Icon(Icons.grade),
                                      label: const Text(
                                        "Export Grades (Excel)",
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppStyles.buttonColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            AppStyles.borderRadius,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  AppStyles.fieldSpacing,
                                  // Export Submissions Button
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed:
                                          _submissionsLoading[index] == true
                                              ? null
                                              : () async {
                                                setState(() {
                                                  _submissionsLoading[index] =
                                                      true;
                                                });
                                                await simulateExport(() {
                                                  setState(() {
                                                    _submissionsLoading[index] =
                                                        false;
                                                  });
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        "Submissions exported successfully",
                                                      ),
                                                    ),
                                                  );
                                                });
                                              },
                                      icon:
                                          _submissionsLoading[index] == true
                                              ? const SizedBox(
                                                height: 16,
                                                width: 16,
                                                child: CircularProgressIndicator(
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Colors.white),
                                                  strokeWidth: 2,
                                                ),
                                              )
                                              : const Icon(Icons.file_download),
                                      label: const Text("Export Submissions"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppStyles.buttonColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            AppStyles.borderRadius,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  AppStyles.fieldSpacing,
                                  // Updated Deactivate Course Button.
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () async {
                                        setState(() {
                                          _deactivateLoading[index] = true;
                                        });
                                        await _deactivateCourse(
                                          course['courseId'] ?? '',
                                        );
                                        setState(() {
                                          _deactivateLoading[index] = false;
                                        });
                                      },
                                      icon:
                                          _deactivateLoading[index] == true
                                              ? const SizedBox(
                                                height: 24,
                                                width: 24,
                                                child:
                                                    CircularProgressIndicator(),
                                              )
                                              : const Icon(Icons.cancel),
                                      label: const Text("Deactivate Course"),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
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
