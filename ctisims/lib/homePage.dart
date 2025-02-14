import 'package:flutter/material.dart';
import 'dashboardPage.dart';

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
  final TextEditingController _bilkentIdController = TextEditingController();

  // Dropdown listeleri
  final List<String> _years = ['2023', '2024', '2025'];
  final List<String> _semesters = ['Fall', 'Spring'];
  final List<String> _courses = ['CTIS310', 'CTIS290'];
  final List<String> _roles = ['Student', 'Admin'];
  final List<String> _changeDeadlineCourses = ['CTIS 290', 'CTIS 310'];
  final List<String> _ctis290Options = ['Reports about an internship'];
  final List<String> _ctis310Options = [
    'Follow Up1',
    'Follow Up2',
    'Follow Up3',
    'Follow Up4',
    'Follow Up5',
    'Reports about an internship'
  ];
  final List<String> _supervisors = ['Dr. Smith', 'Dr. Brown', 'Dr. Johnson'];

  String? _selectedYear;
  String? _selectedSemester;
  String? _selectedCourse;
  String? _selectedRole;
  String? _selectedUserSemester;
  String? _selectedChangeDeadlineCourse;
  String? _selectedOption;
  String? _selectedSupervisor;

  // Sample data for registered semesters
  final List<Map<String, String>> _registeredSemesters = [
    {'year': '2022-2023', 'semester': 'Fall', 'course': 'CTIS310', 'role': 'Student'},
    {'year': '2022-2023', 'semester': 'Fall', 'course': 'CTIS290', 'role': 'Student'},
    {'year': '2022-2023', 'semester': 'Fall', 'course': 'CTIS290', 'role': 'Admin'},
  ];

  Future<void> _selectDeadlineDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
        final DateTime fullDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        setState(() {
          _deadlineController.text = fullDateTime.toString();
        });
      } else {
        // Optional: if no time is selected, just use the picked date.
        setState(() {
          _deadlineController.text = pickedDate.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CTIS IMS '),
        backgroundColor: Colors.orange,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DashboardPage(registeredSemesters: _registeredSemesters)),
              );
            },
            child: const Text('Dashboard', style: TextStyle(color: Colors.white)),
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
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _selectedChangeDeadlineCourse,
                      decoration: const InputDecoration(
                        labelText: 'Course',
                        border: OutlineInputBorder(),
                      ),
                      items: _changeDeadlineCourses.map((course) {
                        return DropdownMenuItem(
                          value: course,
                          child: Text(course),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedChangeDeadlineCourse = value;
                          _selectedOption = null; // Reset selected option
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_selectedChangeDeadlineCourse != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Option:',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          ...(_selectedChangeDeadlineCourse == 'CTIS 290'
                              ? _ctis290Options
                              : _ctis310Options)
                              .map((option) => RadioListTile<String>(
                            title: Text(option),
                            value: option,
                            groupValue: _selectedOption,
                            onChanged: (value) {
                              setState(() {
                                _selectedOption = value;
                              });
                            },
                          ))
                              .toList(),
                        ],
                      ),
                    const SizedBox(height: 16),
                    const Text('Change first-submission deadline:'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _deadlineController,
                      decoration: const InputDecoration(
                        labelText: 'Deadline',
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true,
                      onTap: () => _selectDeadlineDate(context),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (_selectedOption == null || _deadlineController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please select an option and set a deadline')),
                          );
                          return;
                        }
                        debugPrint('New deadline: ${_deadlineController.text}');
                        debugPrint('Selected option: $_selectedOption');
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
                    // Bilkent ID
                    TextField(
                      controller: _bilkentIdController,
                      decoration: const InputDecoration(
                        labelText: 'Bilkent ID',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
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
                          _selectedSupervisor = null; // Reset selected supervisor
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Supervisor Dropdown (only for students)
                    if (_selectedRole == 'Student') ...[
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _selectedSupervisor,
                        decoration: const InputDecoration(
                          labelText: 'Supervisor',
                          border: OutlineInputBorder(),
                        ),
                        items: _supervisors.map((supervisor) {
                          return DropdownMenuItem(
                            value: supervisor,
                            child: Text(supervisor),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedSupervisor = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Semester Dropdown
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _selectedUserSemester,
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
                          _selectedUserSemester = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        debugPrint('Name: ${_nameController.text}');
                        debugPrint('Mail: ${_emailController.text}');
                        debugPrint('Bilkent ID: ${_bilkentIdController.text}');
                        debugPrint('Role: $_selectedRole');
                        debugPrint('Supervisor: $_selectedSupervisor');
                        debugPrint('Semester: $_selectedUserSemester');
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
