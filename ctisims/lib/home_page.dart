import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctisims/db_helper.dart';
import 'package:ctisims/local_db_helper.dart';
import 'package:ctisims/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dashboard_page.dart';
import 'animation_demo.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:async/async.dart';
import 'package:intl/intl.dart';
import 'package:flutter/rendering.dart';
import 'package:ctisims/themes/Theme_provider.dart';

class HomePageModel extends ChangeNotifier {
  String? selectedYear;
  String? selectedSemester;
  String? selectedCourse;
  String? selectedRole;
  String? selectedUserSemester;
  String? selectedChangeDeadlineCourse;
  String? selectedOption;
  String? selectedSupervisor;

  // New for SQLite
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _supervisors = [];
  Map<String, dynamic>? _selectedStudentMap;
  Map<String, dynamic>? _selectedCourseMap;

  // Getters for the new fields
  List<Map<String, dynamic>> get students => _students;
  List<Map<String, dynamic>> get courses => _courses;
  List<Map<String, dynamic>> get supervisors => _supervisors;
  Map<String, dynamic>? get selectedStudentMap => _selectedStudentMap;
  Map<String, dynamic>? get selectedCourseMap => _selectedCourseMap;

  void updateYear(String? year) {
    selectedYear = year;
    notifyListeners();
  }

  void updateSemester(String? semester) {
    selectedSemester = semester;
    notifyListeners();
  }

  void updateCourse(String? course) {
    selectedCourse = course;
    notifyListeners();
  }

  void updateRole(String? role) {
    selectedRole = role;
    notifyListeners();
  }

  void updateUserSemester(String? sem) {
    selectedUserSemester = sem;
    notifyListeners();
  }

  void updateChangeDeadlineCourse(String? course) {
    selectedChangeDeadlineCourse = course;
    notifyListeners();
  }

  void updateOption(String? option) {
    selectedOption = option;
    notifyListeners();
  }

  void updateSupervisor(String? supervisor) {
    selectedSupervisor = supervisor;
    notifyListeners();
  }

  // Methods for SQLite
  void setStudents(List<Map<String, dynamic>> students) {
    _students = students;
    notifyListeners();
  }

  void setCourses(List<Map<String, dynamic>> courses) {
    _courses = courses;
    notifyListeners();
  }

  void setSupervisors(List<Map<String, dynamic>> supervisors) {
    _supervisors = supervisors;
    notifyListeners();
  }

  void updateSelectedStudent(Map<String, dynamic>? student) {
    _selectedStudentMap = student;
    notifyListeners();
  }

  void updateSelectedCourse(Map<String, dynamic>? course) {
    _selectedCourseMap = course;
    notifyListeners();
  }

  // Load data from SQLite
  Future<void> loadDataFromLocalDB() async {
    try {
      final students = await LocalDBHelper.instance.getStudents();
      final courses = await LocalDBHelper.instance.getCourses();
      final supervisors = await LocalDBHelper.instance.getSupervisors();

      _students = students;
      _courses = courses;
      _supervisors = supervisors;

      notifyListeners();
    } catch (e) {
      debugPrint("Error loading data from local DB: $e");
    }
  }
}

class AppStyles {
  static const primaryColor = Colors.orange;
  static const buttonColor = Colors.blue;
  static const cardElevation = 4.0;
  static const borderRadius = 16.0;
  static const padding = EdgeInsets.all(16.0);
  static const fieldSpacing = SizedBox(height: 16);
  
  // Helper method to get color based on theme
  static Color getButtonColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? Colors.lightBlue 
        : Colors.blue;
  }
  
  static Color getPrimaryColor(BuildContext context) {
    return Colors.orange;
  }
}

// Reusable gesture button widget for consistent button styling
class GestureButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final Color color;
  final double? width;

  const GestureButton({
    super.key,
    required this.text,
    required this.onTap,
    this.color = AppStyles.buttonColor,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
      },
      child: Container(
        width: width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppStyles.borderRadius),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppStyles.borderRadius),
            onTap: onTap,
            splashColor: Colors.white.withOpacity(0.3),
            highlightColor: Colors.white.withOpacity(0.1),
            child: Ink(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(AppStyles.borderRadius),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              child: Center(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.userData});
  final UserData userData; // Ensure userData contains a 'role' field

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _deadlineController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _bilkentIdController = TextEditingController();

  final List<String> _years = ['2023', '2024', '2025'];
  final List<String> _semesters = ['Fall', 'Spring'];
  final List<String> _courseList = ['CTIS310', 'CTIS290'];
  final List<String> _roles = ['Student', 'Admin'];
  final List<String> _changeDeadlineCourses = ['CTIS 290', 'CTIS 310'];
  final List<String> _ctis290Options = ['Report'];
  final List<String> _ctis310Options = [
    'Follow Up 1',
    'Follow Up 2',
    'Follow Up 3',
    'Follow Up 4',
    'Follow Up 5',
    'Follow Up 6',
    'Report',
  ];

  // Data will be loaded from local DB
  List<Map<String, dynamic>> _registeredSemesters = [];

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
        setState(() {
          _deadlineController.text = pickedDate.toString();
        });
      }
    }
  }

  Future<void> _addUser() async {
    try {
      final homePageModel = Provider.of<HomePageModel>(context, listen: false);
      final selectedRole = homePageModel.selectedRole;

      if (selectedRole == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please select a role')));
        return;
      }

      String supervisorId;
      if (selectedRole == 'Admin') {
        supervisorId = "0";
      } else {
        final selectedSupervisorName = homePageModel.selectedSupervisor;
        if (selectedSupervisorName == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a supervisor')),
          );
          return;
        }

        // Find the supervisor ID
        final supervisors = homePageModel.supervisors;
        final selectedSupervisor = supervisors.firstWhere(
          (supervisor) => supervisor['name'] == selectedSupervisorName,
          orElse: () => {'id': '', 'name': ''},
        );
        supervisorId = selectedSupervisor['id'] as String;
      }

      // Create user map for local DB
      final user = {
        'bilkentId': _bilkentIdController.text,
        'name': _nameController.text,
        'email': _emailController.text,
        'role': selectedRole,
        'supervisorId': supervisorId,
      };

      // Add to local DB
      await LocalDBHelper.instance.createUser(user);

      // Add to Firebase
      await DBHelper.addUser(
        _nameController.text,
        _emailController.text,
        _bilkentIdController.text,
        selectedRole,
        supervisorId,
      );

      // Create Firebase auth account
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text,
            password: 'temporaryPassword123',
          );

      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text,
      );

      // Reload data from local DB
      await homePageModel.loadDataFromLocalDB();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User added and password reset email sent'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add user: $e')));
    }
  }

  Future<List<Map<String, dynamic>>>? _deadline310;
  Future<List<Map<String, dynamic>>>? _deadline290;

  @override
  void initState() {
    super.initState();
    _deadline310 = DBHelper.getActiveCourseAssignments("310");
    _deadline290 = DBHelper.getActiveCourseAssignments("290");
    _loadData();
  }

  Future<void> _loadData() async {
    final homePageModel = Provider.of<HomePageModel>(context, listen: false);
    await homePageModel.loadDataFromLocalDB();

    // Get registered semesters
    try {
      final courses = await LocalDBHelper.instance.getCourses();
      setState(() {
        _registeredSemesters =
            courses.map((course) {
              return {
                'year': course['year'] as String,
                'semester': course['semester'] as String,
                'course': 'CTIS${course['code']}',
                'role': 'Admin', // Default role for courses
              };
            }).toList();
      });
    } catch (e) {
      debugPrint("Error loading registered semesters: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('CTIS IMS'),
        backgroundColor: AppStyles.primaryColor,
        actions: [
          // Dashboard Button
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DashboardPage(
                    registeredSemesters: _registeredSemesters
                        .map(
                          (item) => Map<String, String>.fromEntries(
                            item.entries.map(
                              (e) => MapEntry(e.key, e.value.toString()),
                            ),
                          ),
                        )
                        .toList(),
                    userData: widget.userData,
                  ),
                ),
              );
            },
            child: const Text(
              'Dashboard',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          // Username Display
          TextButton(
            onPressed: () {},
            child: Text(
              '${widget.userData.username}',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          // Dark Mode Toggle
          IconButton(
            icon: Icon(
              isDark ? Icons.dark_mode : Icons.light_mode,
              color: Colors.grey,
            ),
            tooltip: 'Toggle Dark Mode',
            onPressed: () {
              themeProvider.toggleTheme();
            },
          ),
          // Logout Button
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginPage(),
                ),
              );
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppStyles.padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: AppStyles.padding,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.white,
                borderRadius: BorderRadius.circular(AppStyles.borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'Initialize Semester & Add Users',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Always show Current Deadline Settings
                _buildSectionCard(
                  headerTitle: 'Current Deadline Settings',
                  headerIcon: Icons.settings,
                  buttonText: 'View Settings',
                  modalContent: _currentDeadlineModalContent(),
                ),
                // Only show these for admin users
                if (widget.userData.role == 'Admin') ...[
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    headerTitle: 'Change Deadline Settings',
                    headerIcon: Icons.schedule,
                    buttonText: 'Edit',
                    modalContent: _changeDeadlineModalContent(),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    headerTitle: 'Create Course',
                    headerIcon: Icons.add_circle_outline,
                    buttonText: 'Create Course',
                    modalContent: _createCourseModalContent(),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    headerTitle: 'Add User',
                    headerIcon: Icons.person_add_alt,
                    buttonText: 'Add User',
                    modalContent: _addUserModalContent(),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    headerTitle: 'Add Student Course',
                    headerIcon: Icons.school,
                    buttonText: 'Add',
                    modalContent: _addStudentCourseModalContent(),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String headerTitle,
    required IconData headerIcon,
    required String buttonText,
    required Widget modalContent,
  }) {
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
            Semantics(
              label: "$headerTitle section",
              child: Row(
                children: [
                  Icon(headerIcon, color: AppStyles.buttonColor),
                  const SizedBox(width: 8),
                  Text(
                    headerTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            AppStyles.fieldSpacing,
            Text(
              'Tap below to open details.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            AppStyles.fieldSpacing,
            Align(
              alignment: Alignment.centerRight,
              child: Semantics(
                button: true,
                label: buttonText,
                child: GestureButton(
                  text: buttonText,
                  onTap: () => _openModal(modalContent),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openModal(Widget modalContent) async {
    // Prevent multiple modal opens
    if (!mounted) return;

    final homePageModel = Provider.of<HomePageModel>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Modal",
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return WillPopScope(
          // Reset any selections when modal is closed
          onWillPop: () async {
            homePageModel.updateSelectedStudent(null);
            homePageModel.updateSelectedCourse(null);
            homePageModel.updateRole(null);
            homePageModel.updateSupervisor(null);
            return true;
          },
          child: Align(
            alignment: Alignment.center,
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: AppStyles.padding,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppStyles.borderRadius),
                ),
                child: ChangeNotifierProvider.value(
                  value: homePageModel,
                  child: SingleChildScrollView(child: modalContent),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(scale: anim1, child: child),
        );
      },
    ).then((_) {
      // Reset selections after modal is closed
      if (mounted) {
        homePageModel.updateSelectedStudent(null);
        homePageModel.updateSelectedCourse(null);
        homePageModel.updateRole(null);
        homePageModel.updateSupervisor(null);
      }
    });
  }

  Widget _currentDeadlineModalContent() {
    final dateFormat = DateFormat('MM/dd/yyyy HH:mm');
    return StreamBuilder<List<List<Map<String, dynamic>>>>(
      stream: StreamZip([
        DBHelper.streamCurrentDeadline310(),
        DBHelper.streamCurrentDeadline290(),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data310 = snapshot.data![0];
        data310.sort((a, b) {
          final nameA = a['name'] ?? '';
          final nameB = b['name'] ?? '';
          final matchA = RegExp(r'Follow Up (\d+)').firstMatch(nameA);
          final matchB = RegExp(r'Follow Up (\d+)').firstMatch(nameB);
          if (matchA != null && matchB != null) {
            return int.parse(
              matchA.group(1)!,
            ).compareTo(int.parse(matchB.group(1)!));
          }
          return nameA.compareTo(nameB);
        });
        // For CTIS290, filter only "report" (case insensitive)
        final data290 =
            (snapshot.data![1] as List<Map<String, dynamic>>)
                .where(
                  (item) =>
                      (item['name'] ?? '').toString().toLowerCase() == 'report',
                )
                .toList();
        return Form(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Deadline Settings',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              AppStyles.fieldSpacing,
              Text('CTIS 310'),
              for (var item in data310)
                Builder(
                  builder: (context) {
                    final deadlineVal = item['deadline'];
                    String deadlineStr;
                    if (deadlineVal is Timestamp) {
                      deadlineStr = dateFormat.format(
                        deadlineVal.toDate().toLocal(),
                      );
                    } else {
                      deadlineStr = deadlineVal.toString();
                    }
                    return Text('${item['name']} - Deadline: $deadlineStr');
                  },
                ),
              AppStyles.fieldSpacing,
              Text('CTIS 290'),
              for (var item in data290)
                Builder(
                  builder: (context) {
                    final deadlineVal = item['deadline'];
                    String deadlineStr;
                    if (deadlineVal is Timestamp) {
                      deadlineStr = dateFormat.format(
                        deadlineVal.toDate().toLocal(),
                      );
                    } else {
                      deadlineStr = deadlineVal.toString();
                    }
                    return Text('${item['name']} - Deadline: $deadlineStr');
                  },
                ),
              AppStyles.fieldSpacing,
              Align(
                alignment: Alignment.centerRight,
                child: GestureButton(
                  text: 'Close',
                  onTap: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _changeDeadlineModalContent() {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    return Consumer<HomePageModel>(
      builder: (context, model, child) {
        return Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Change Deadline Settings',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              AppStyles.fieldSpacing,
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: model.selectedChangeDeadlineCourse,
                decoration: const InputDecoration(
                  labelText: 'Course',
                  border: OutlineInputBorder(),
                ),
                items:
                    _changeDeadlineCourses
                        .map(
                          (course) => DropdownMenuItem(
                            value: course,
                            child: Text(course),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  model.updateChangeDeadlineCourse(value);
                  model.updateOption(null);
                },
              ),
              AppStyles.fieldSpacing,
              if (model.selectedChangeDeadlineCourse != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Option:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    AppStyles.fieldSpacing,
                    ...((model.selectedChangeDeadlineCourse == 'CTIS 290')
                            ? _ctis290Options
                            : _ctis310Options)
                        .map(
                          (option) => RadioListTile<String>(
                            title: Text(option),
                            value: option,
                            groupValue: model.selectedOption,
                            onChanged: (value) {
                              model.updateOption(value);
                            },
                          ),
                        ),
                  ],
                ),
              AppStyles.fieldSpacing,
              const Text('Change first-submission deadline:'),
              AppStyles.fieldSpacing,
              TextField(
                controller: _deadlineController,
                decoration: const InputDecoration(
                  labelText: 'Deadline',
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
                onTap: () => _selectDeadlineDate(context),
              ),
              AppStyles.fieldSpacing,
              GestureButton(
                text: 'Update',
                onTap: () async {
                  if (model.selectedOption == null ||
                      _deadlineController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please select an option and set a deadline',
                        ),
                      ),
                    );
                    return;
                  }
                  final parsedDeadline = DateTime.tryParse(
                    _deadlineController.text,
                  );
                  if (parsedDeadline == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invalid deadline format')),
                    );
                    return;
                  }
                  String courseId =
                      (model.selectedChangeDeadlineCourse == 'CTIS 290')
                          ? '290'
                          : '310';
                  String assignmentName = model.selectedOption ?? '';
                  await DBHelper.changeDeadlineSettings(
                    courseId,
                    assignmentName,
                    parsedDeadline,
                  );
                  debugPrint('New deadline: ${_deadlineController.text}');
                  debugPrint('Selected option: ${model.selectedOption}');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _createCourseModalContent() {
    // Course year options
    final List<String> _courseYears = [
      "2020-2021",
      "2022-2023",
      "2023-2024",
      "2024-2025",
    ];
    final List<String> _courseSemesters = ["Fall", "Spring"];
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final homePageModel = Provider.of<HomePageModel>(context);
    bool isActive = true; // Initialize the isActive state

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create Course',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              AppStyles.fieldSpacing,
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: homePageModel.selectedYear,
                decoration: const InputDecoration(
                  labelText: 'Year',
                  border: OutlineInputBorder(),
                ),
                items:
                    _courseYears
                        .map(
                          (year) =>
                              DropdownMenuItem(value: year, child: Text(year)),
                        )
                        .toList(),
                onChanged: (value) {
                  homePageModel.updateYear(value);
                },
                validator:
                    (value) => value == null ? 'Please select a year' : null,
              ),
              AppStyles.fieldSpacing,
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: homePageModel.selectedSemester,
                decoration: const InputDecoration(
                  labelText: 'Semester',
                  border: OutlineInputBorder(),
                ),
                items:
                    _courseSemesters
                        .map(
                          (sem) =>
                              DropdownMenuItem(value: sem, child: Text(sem)),
                        )
                        .toList(),
                onChanged: (value) {
                  homePageModel.updateSemester(value);
                },
                validator:
                    (value) =>
                        value == null ? 'Please select a semester' : null,
              ),
              AppStyles.fieldSpacing,
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: homePageModel.selectedCourse,
                decoration: const InputDecoration(
                  labelText: 'Course',
                  border: OutlineInputBorder(),
                ),
                items:
                    _courseList
                        .map(
                          (course) => DropdownMenuItem(
                            value: course,
                            child: Text(course),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  homePageModel.updateCourse(value);
                },
                validator:
                    (value) => value == null ? 'Please select a course' : null,
              ),
              AppStyles.fieldSpacing,
              // Checkbox for isActive (we assume new courses are active by default).
              Row(
                children: [
                  const Text('Set Active:'),
                  Checkbox(
                    value: isActive,
                    onChanged: (bool? value) {
                      setState(() {
                        isActive = value ?? true;
                      });
                    },
                  ),
                ],
              ),
              AppStyles.fieldSpacing,
              GestureButton(
                text: 'Create Course',
                onTap: () async {
                  if (!formKey.currentState!.validate()) return;
                  try {
                    final selectedYear = homePageModel.selectedYear!;
                    final selectedSemester = homePageModel.selectedSemester!;
                    final selectedCourse = homePageModel.selectedCourse!;

                    // Generate a unique ID for the course
                    final courseId =
                        DateTime.now().millisecondsSinceEpoch.toString();
                    final numericCode =
                        selectedCourse.startsWith("CTIS")
                            ? selectedCourse.substring(4)
                            : selectedCourse;

                    // Create course in local DB
                    await LocalDBHelper.instance.createCourse({
                      'id': courseId,
                      'code': numericCode,
                      'year': selectedYear,
                      'semester': selectedSemester,
                      'isActive': isActive ? 1 : 0,
                    });

                    // Create course in Firebase
                    await DBHelper.createCourse(
                      selectedCourse,
                      selectedYear,
                      selectedSemester,
                      isActive,
                    );

                    // Reload data from local DB
                    await homePageModel.loadDataFromLocalDB();
                    await _loadData(); // Reload registered semesters

                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Course created successfully'),
                      ),
                    );
                    Navigator.pop(context);
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _addUserModalContent() {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final homePageModel = Provider.of<HomePageModel>(context, listen: false);

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add User',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              AppStyles.fieldSpacing,
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Please enter a name';
                  return null;
                },
              ),
              AppStyles.fieldSpacing,
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Please enter an email';
                  return null;
                },
              ),
              AppStyles.fieldSpacing,
              TextFormField(
                controller: _bilkentIdController,
                decoration: const InputDecoration(
                  labelText: 'Bilkent ID',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Please enter a Bilkent ID';
                  return null;
                },
              ),
              AppStyles.fieldSpacing,
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: homePageModel.selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
                items:
                    _roles
                        .map(
                          (role) =>
                              DropdownMenuItem(value: role, child: Text(role)),
                        )
                        .toList(),
                onChanged: (value) {
                  setState(() {
                    homePageModel.updateRole(value);
                  });
                },
              ),
              AppStyles.fieldSpacing,
              // Only show supervisor dropdown when role is Student
              if (homePageModel.selectedRole == 'Student')
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: homePageModel.selectedSupervisor,
                  decoration: const InputDecoration(
                    labelText: 'Supervisor',
                    border: OutlineInputBorder(),
                  ),
                  items:
                      homePageModel.supervisors
                          .map(
                            (supervisor) => DropdownMenuItem(
                              value: supervisor['name'] as String,
                              child: Text(supervisor['name'] as String),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    homePageModel.updateSupervisor(value);
                  },
                ),
              if (homePageModel.selectedRole == 'Student')
                AppStyles.fieldSpacing,
              GestureButton(
                text: 'Add User',
                onTap: () {
                  if (formKey.currentState!.validate()) {
                    _addUser();
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _addStudentCourseModalContent() {
    final homePageModel = Provider.of<HomePageModel>(context);

    return Form(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add Student Course',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          AppStyles.fieldSpacing,
          // Student dropdown
          DropdownButtonFormField<String>(
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: "Select Student",
              border: OutlineInputBorder(),
            ),
            value:
                homePageModel.selectedStudentMap != null
                    ? homePageModel.selectedStudentMap!['bilkentId'] as String
                    : null,
            items:
                homePageModel.students.map((student) {
                  final bilkentId = student['bilkentId'] as String;
                  return DropdownMenuItem<String>(
                    value: bilkentId,
                    child: Text("${student['name']} (${student['bilkentId']})"),
                  );
                }).toList(),
            onChanged: (bilkentId) {
              if (bilkentId != null) {
                final selectedStudent = homePageModel.students.firstWhere(
                  (student) => student['bilkentId'] == bilkentId,
                  orElse: () => {},
                );
                homePageModel.updateSelectedStudent(selectedStudent);
              }
            },
          ),
          AppStyles.fieldSpacing,
          // Course dropdown
          DropdownButtonFormField<String>(
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: "Select Course",
              border: OutlineInputBorder(),
            ),
            value:
                homePageModel.selectedCourseMap != null
                    ? homePageModel.selectedCourseMap!['id'] as String
                    : null,
            items:
                homePageModel.courses.map((course) {
                  final courseId = course['id'] as String;
                  return DropdownMenuItem<String>(
                    value: courseId,
                    child: Text(
                      "CTIS${course['code']} - ${course['year']} ${course['semester']}",
                    ),
                  );
                }).toList(),
            onChanged: (courseId) {
              if (courseId != null) {
                final selectedCourse = homePageModel.courses.firstWhere(
                  (course) => course['id'] == courseId,
                  orElse: () => {},
                );
                homePageModel.updateSelectedCourse(selectedCourse);
              }
            },
          ),
          AppStyles.fieldSpacing,
          GestureButton(
            text: 'Add',
            onTap: () async {
              final selectedStudent = homePageModel.selectedStudentMap;
              final selectedCourse = homePageModel.selectedCourseMap;

              if (selectedStudent != null && selectedCourse != null) {
                final bilkentId =
                    selectedStudent['bilkentId']?.toString() ?? '';
                final name = selectedStudent['name'] ?? 'Unknown';
                final courseId = selectedCourse['id']?.toString() ?? '';

                try {
                  // Add to local SQLite
                  await LocalDBHelper.instance.addStudentToCourse({
                    'id': DateTime.now().millisecondsSinceEpoch.toString(),
                    'bilkentId': bilkentId,
                    'courseId': courseId,
                    'name': name,
                    'companyEvaluationUploaded': 0,
                    'isActive': selectedCourse['isActive'] == 1 ? 1 : 0,
                  });

                  // Add to Firebase
                  await DBHelper.addStudentToCourse(bilkentId, courseId, name);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Student added to course")),
                  );

                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("Error: $e")));
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Please select both a student and a course"),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
