import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Form controller'ları
  final TextEditingController _deadlineController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  // Dropdown listeleri
  final List<String> _years = ['2023', '2024', '2025'];
  final List<String> _semesters = ['Fall', 'Spring', 'Summer'];
  final List<String> _courses = ['Course A', 'Course B', 'Course C'];
  final List<String> _roles = ['Student', 'Instructor', 'Admin'];

  String? _selectedYear;
  String? _selectedSemester;
  String? _selectedCourse;
  String? _selectedRole;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JMS'),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Dashboard', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {},
            child: const Text('Announcements', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {},
            child: const Text('FAQ', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {},
            child: const Text('Begin (Dr.)', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sayfa Başlığı
            Text(
              'Initialize Semester & Add Users',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),

            // 1) Current Deadline Settings
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Deadline Settings',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text('First submission deadline (in days): 30'),
                    const SizedBox(height: 4),
                    const Text('Last edited by: Begin (Dr.)'),
                    const SizedBox(height: 4),
                    const Text('Last update: May 29th 2023 12:25:06 am'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2) Change Deadline Settings
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Change Deadline Settings',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text('Change first-submission deadline (in days):'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _deadlineController,
                      decoration: const InputDecoration(
                        labelText: 'Deadline (days)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        debugPrint('New deadline: ${_deadlineController.text}');
                      },
                      child: const Text('Update'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 3) Create Semester (alt alta düzenlendi)
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create Semester',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    // Choose File butonu
                    ElevatedButton(
                      onPressed: () {
                        debugPrint('Choose file clicked');
                      },
                      child: const Text('Choose File'),
                    ),
                    const SizedBox(height: 16),
                    // Year Dropdown
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _selectedYear,
                      decoration: const InputDecoration(
                        labelText: 'Year',
                        border: OutlineInputBorder(),
                      ),
                      items: _years.map((year) {
                        return DropdownMenuItem(
                          value: year,
                          child: Text(year),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedYear = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Semester Dropdown
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _selectedSemester,
                      decoration: const InputDecoration(
                        labelText: 'Semester',
                        border: OutlineInputBorder(),
                      ),
                      items: _semesters.map((semester) {
                        return DropdownMenuItem(
                          value: semester,
                          child: Text(semester),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSemester = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Course Dropdown
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _selectedCourse,
                      decoration: const InputDecoration(
                        labelText: 'Course',
                        border: OutlineInputBorder(),
                      ),
                      items: _courses.map((course) {
                        return DropdownMenuItem(
                          value: course,
                          child: Text(course),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCourse = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        debugPrint('Year: $_selectedYear');
                        debugPrint('Semester: $_selectedSemester');
                        debugPrint('Course: $_selectedCourse');
                      },
                      child: const Text('Create'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 4) Add User
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add User',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    // Name
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Email
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Mail',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    // Role Dropdown
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Role',
                        border: OutlineInputBorder(),
                      ),
                      items: _roles.map((role) {
                        return DropdownMenuItem(
                          value: role,
                          child: Text(role),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedRole = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        debugPrint('Name: ${_nameController.text}');
                        debugPrint('Mail: ${_emailController.text}');
                        debugPrint('Role: $_selectedRole');
                      },
                      child: const Text('Submit'),
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
}
