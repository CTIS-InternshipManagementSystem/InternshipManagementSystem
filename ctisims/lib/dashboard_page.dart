import 'package:flutter/material.dart';
import 'submission_page.dart';
import 'assigned_submissions_page.dart';
import 'export_page.dart';
import 'search_page.dart';

class DashboardPage extends StatefulWidget {
  final List<Map<String, String>> registeredSemesters;

  const DashboardPage({super.key, required this.registeredSemesters});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late List<Map<String, String>> filteredSemesters;
  String searchQuery = "";
  String sortOption = "Year Ascending"; // default sort
  bool darkMode = false;

  // Filter state variables with default values ("All" means no filtering)
  String roleFilter = "All";
  String yearFilter = "All";
  String semesterFilter = "All";
  String courseFilter = "All";

  @override
  void initState() {
    super.initState();
    filteredSemesters = List.from(widget.registeredSemesters);
  }

  // Apply search and all filters
  void _applyFilters() {
    setState(() {
      filteredSemesters =
          widget.registeredSemesters.where((semester) {
            bool matches = true;
            // Search filter (course name)
            if (searchQuery.isNotEmpty) {
              matches =
                  matches &&
                  (semester['course']?.toLowerCase().contains(
                        searchQuery.toLowerCase(),
                      ) ??
                      false);
            }
            // Role filter
            if (roleFilter != "All") {
              matches = matches && (semester['role'] == roleFilter);
            }
            // Year filter
            if (yearFilter != "All") {
              matches = matches && (semester['year'] == yearFilter);
            }
            // Semester filter
            if (semesterFilter != "All") {
              matches = matches && (semester['semester'] == semesterFilter);
            }
            // Course filter
            if (courseFilter != "All") {
              matches = matches && (semester['course'] == courseFilter);
            }
            return matches;
          }).toList();
      _sortSemesters();
    });
  }

  // Update search query and re-apply filters.
  void updateSearch(String query) {
    searchQuery = query;
    _applyFilters();
  }

  // Updated sort method to include multiple sort options.
  void _sortSemesters() {
    setState(() {
      switch (sortOption) {
        case "Year Ascending":
          filteredSemesters.sort(
            (a, b) => (a['year'] ?? "").compareTo(b['year'] ?? ""),
          );
          break;
        case "Year Descending":
          filteredSemesters.sort(
            (a, b) => (b['year'] ?? "").compareTo(a['year'] ?? ""),
          );
          break;
        case "Semester Ascending":
          filteredSemesters.sort(
            (a, b) => (a['semester'] ?? "").compareTo(b['semester'] ?? ""),
          );
          break;
        case "Semester Descending":
          filteredSemesters.sort(
            (a, b) => (b['semester'] ?? "").compareTo(a['semester'] ?? ""),
          );
          break;
        case "Course Ascending":
          filteredSemesters.sort(
            (a, b) => (a['course'] ?? "").compareTo(b['course'] ?? ""),
          );
          break;
        case "Course Descending":
          filteredSemesters.sort(
            (a, b) => (b['course'] ?? "").compareTo(a['course'] ?? ""),
          );
          break;
        default:
          break;
      }
    });
  }

  // Show filter dialog with Reset button
  void _showFilterDialog() {
    // Get distinct values from the list for Year and Course filtering.
    final years = <String>{"All"};
    final courses = <String>{"All"};
    for (var s in widget.registeredSemesters) {
      if (s['year'] != null) years.add(s['year']!);
      if (s['course'] != null) courses.add(s['course']!);
    }

    showDialog(
      context: context,
      builder: (context) {
        // Temporary variables to hold changes in dialog.
        String tempRole = roleFilter;
        String tempYear = yearFilter;
        String tempSemester = semesterFilter;
        String tempCourse = courseFilter;
        return AlertDialog(
          title: const Text("Filter Options"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                // Role Filter
                DropdownButtonFormField<String>(
                  value: tempRole,
                  decoration: const InputDecoration(labelText: "Role"),
                  items:
                      ["All", "Student", "Admin"].map((value) {
                        return DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                  onChanged: (val) {
                    tempRole = val!;
                  },
                ),
                const SizedBox(height: 8),
                // Year Filter
                DropdownButtonFormField<String>(
                  value: tempYear,
                  decoration: const InputDecoration(labelText: "Year"),
                  items:
                      years.map((value) {
                        return DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                  onChanged: (val) {
                    tempYear = val!;
                  },
                ),
                const SizedBox(height: 8),
                // Semester Filter
                DropdownButtonFormField<String>(
                  value: tempSemester,
                  decoration: const InputDecoration(labelText: "Semester"),
                  items:
                      ["All", "Fall", "Spring"].map((value) {
                        return DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                  onChanged: (val) {
                    tempSemester = val!;
                  },
                ),
                const SizedBox(height: 8),
                // Course Filter
                DropdownButtonFormField<String>(
                  value: tempCourse,
                  decoration: const InputDecoration(labelText: "Course"),
                  items:
                      courses.map((value) {
                        return DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                  onChanged: (val) {
                    tempCourse = val!;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Cancel
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                // Reset filters to default values
                setState(() {
                  roleFilter = "All";
                  yearFilter = "All";
                  semesterFilter = "All";
                  courseFilter = "All";
                });
                _applyFilters();
                Navigator.pop(context);
              },
              child: const Text("Reset"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  roleFilter = tempRole;
                  yearFilter = tempYear;
                  semesterFilter = tempSemester;
                  courseFilter = tempCourse;
                });
                _applyFilters();
                Navigator.pop(context);
              },
              child: const Text("Apply"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
          if (widget.registeredSemesters.any(
            (semester) => semester['role'] == 'Admin',
          )) ...[
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            ExportPage(semesters: widget.registeredSemesters),
                  ),
                );
              },
              child: const Text(
                'Statistics & Grades',
                style: TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SearchPage()),
                );
              },
              child: const Text(
                'Search',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Header with search field and right-aligned filter & sort controls
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
                          borderSide: BorderSide(
                            color: textColor.withOpacity(0.4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: _showFilterDialog,
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
                          items:
                              <String>[
                                "Year Ascending",
                                "Year Descending",
                                "Semester Ascending",
                                "Semester Descending",
                                "Course Ascending",
                                "Course Descending",
                              ].map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value,
                                    style: TextStyle(color: textColor),
                                  ),
                                );
                              }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                sortOption = newValue;
                                _sortSemesters();
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
                      final String buttonText =
                          role == 'Student'
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    semester['year'] ?? '',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  Text(
                                    semester['semester'] ?? '',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge?.copyWith(
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
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall?.copyWith(
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
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                  ),
                                  onPressed: () {
                                    if (role == 'Student') {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => SubmissionPage(
                                                course: semester['course']!,
                                              ),
                                        ),
                                      );
                                    } else if (role == 'Admin') {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) =>
                                                  const AssignedSubmissionsPage(),
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
