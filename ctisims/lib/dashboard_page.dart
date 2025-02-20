import 'package:flutter/material.dart';
import 'submission_page.dart';
import 'assigned_submissions_page.dart';
import 'export_page.dart';
import 'search_page.dart';

class DashboardPage extends StatefulWidget {
  final List<Map<String, String>> registeredSemesters;

  const DashboardPage({Key? key, required this.registeredSemesters}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late List<Map<String, String>> filteredSemesters;
  String searchQuery = "";
  String sortOption = "Year Ascending"; // default sort
  bool darkMode = false;

  @override
  void initState() {
    super.initState();
    filteredSemesters = List.from(widget.registeredSemesters);
  }

  void updateSearch(String query) {
    setState(() {
      searchQuery = query;
      filteredSemesters = widget.registeredSemesters.where((semester) {
        final course = semester['course']?.toLowerCase() ?? "";
        return course.contains(query.toLowerCase());
      }).toList();
    });
  }

  void sortSemesters() {
    setState(() {
      if (sortOption == "Year Ascending") {
        filteredSemesters.sort((a, b) {
          return (a['year'] ?? "").compareTo(b['year'] ?? "");
        });
      } else if (sortOption == "Year Descending") {
        filteredSemesters.sort((a, b) {
          return (b['year'] ?? "").compareTo(a['year'] ?? "");
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Adjust colors based on dark mode
    final bgColor = darkMode ? Colors.black : Colors.grey[100];
    final textColor = darkMode ? Colors.white : Colors.black;
    final cardBgColor = darkMode ? Colors.grey[850] : Colors.white;
    final headerCardColor = darkMode ? Colors.grey[800] : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.orange,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                darkMode = !darkMode;
              });
            },
            icon: Icon(darkMode ? Icons.dark_mode : Icons.light_mode),
          ),
          if (widget.registeredSemesters.any((semester) => semester['role'] == 'Admin')) ...[
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ExportPage(semesters: widget.registeredSemesters)),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Header with search field and right-aligned filter & sort
            Card(
              elevation: 4,
              color: headerCardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Search Field
                    TextField(
                      onChanged: updateSearch,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: "Search courses...",
                        hintStyle: TextStyle(color: textColor.withOpacity(0.6)),
                        prefixIcon: Icon(Icons.search, color: textColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: textColor.withOpacity(0.4)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: () {
                            // Implement filter logic or show a filter dialog
                          },
                          icon: const Icon(Icons.filter_list),
                          label: const Text("Filter"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 16),
                        DropdownButton<String>(
                          value: sortOption,
                          dropdownColor: cardBgColor,
                          items: <String>["Year Ascending", "Year Descending"]
                              .map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value, style: TextStyle(color: textColor)),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                sortOption = newValue;
                                sortSemesters();
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Responsive Grid of Cards
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
                      final role = semester['role'] ?? 'Student';
                      final String buttonText = role == 'Student'
                          ? 'View Submission'
                          : 'Evaluate Submission';
                      return Card(
                        color: cardBgColor,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              // Top Row: Year (left) and Semester (right)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    semester['year'] ?? '',
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                  ),
                                  Text(
                                    semester['semester'] ?? '',
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              // Center: Course Code emphasized
                              Center(
                                child: Text(
                                  semester['course'] ?? '',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                ),
                              ),
                              const Spacer(),
                              // Bottom: Action Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                  onPressed: () {
                                    if (role == 'Student') {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => SubmissionPage(course: semester['course']!),
                                        ),
                                      );
                                    } else if (role == 'Admin') {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const AssignedSubmissionsPage(),
                                        ),
                                      );
                                    }
                                  },
                                  child: Text(
                                    buttonText,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
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
