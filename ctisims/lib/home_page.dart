import 'package:flutter/material.dart';
import 'dashboard_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'services/user_service.dart';
import 'services/semester_service.dart';
import 'services/course_service.dart';
import 'services/deadline_service.dart';
import 'models/user.dart';

class HomePageModel extends ChangeNotifier {
  String? selectedYear;
  String? selectedSemester;
  String? selectedCourse;
  String? selectedRole;
  String? selectedUserSemester;
  String? selectedChangeDeadlineCourse;
  String? selectedOption;
  String? selectedSupervisor;

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
}

class AppStyles {
  static const primaryColor = Colors.orange;
  static const buttonColor = Colors.blue;
  static const cardElevation = 4.0;
  static const borderRadius = 16.0;
  static const padding = EdgeInsets.all(16.0);
  static const fieldSpacing = SizedBox(height: 16);
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _deadlineController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _bilkentIdController = TextEditingController();
  final UserService _userService = UserService();
  final SemesterService _semesterService = SemesterService();
  final CourseService _courseService = CourseService();
  final DeadlineService _deadlineService = DeadlineService();

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
    'Reports about an internship',
  ];
  final List<String> _supervisors = ['Dr. Smith', 'Dr. Brown', 'Dr. Johnson'];

  final List<Map<String, String>> _registeredSemesters = [
    {
      'year': '2022-2023',
      'semester': 'Fall',
      'course': 'CTIS310',
      'role': 'Student',
    },
    {
      'year': '2022-2023',
      'semester': 'Fall',
      'course': 'CTIS290',
      'role': 'Student',
    },
    {
      'year': '2022-2023',
      'semester': 'Fall',
      'course': 'CTIS290',
      'role': 'Admin',
    },
  ];

  String? _activeSemester;
  List<Map<String, dynamic>> _teachers = [];
  List<Map<String, dynamic>> _currentDeadlines = [];
  List<Map<String, dynamic>> _allCoursesForAdmin = [];
  Map<String, dynamic>? _activeCourseForStudent;

  @override
  void initState() {
    super.initState();
    _loadActiveSemester();
    _loadAllCoursesForAdmin();
    _loadActiveCourseForStudent();
  }

  Future<void> _loadActiveSemester() async {
    final activeSemester = await _semesterService.getActiveSemester();
    if (activeSemester != null) {
      setState(() {
        _activeSemester = '${activeSemester.year} ${activeSemester.semester}';
      });
      _loadTeachers(activeSemester.id);
      _loadCurrentDeadlines(activeSemester.id);
    }
  }

  Future<void> _loadTeachers(String semesterId) async {
    final courses = await _courseService.getCoursesBySemester(semesterId);
    List<Map<String, dynamic>> teachers = [];
    for (var course in courses) {
      final courseTeachers = await _userService.getTeachers(course['id']);
      teachers.addAll(courseTeachers);
    }
    setState(() {
      _teachers = teachers;
    });
  }

  Future<void> _loadCurrentDeadlines(String semesterId) async {
    final courses = await _courseService.getCoursesBySemester(semesterId);
    List<Map<String, dynamic>> deadlines = [];
    for (var course in courses) {
      final courseDeadlines = await _deadlineService.getDeadlinesByCourse(
        course['id'],
      );
      deadlines.addAll(courseDeadlines);
    }
    setState(() {
      _currentDeadlines = deadlines;
    });
  }

  Future<void> _loadAllCoursesForAdmin() async {
    final semesters = await _semesterService.getAllSemesters();
    List<Map<String, dynamic>> courses = [];
    for (var semester in semesters) {
      final semesterCourses = await _courseService.getCoursesBySemester(
        semester.id,
      );
      courses.addAll(semesterCourses);
    }
    setState(() {
      _allCoursesForAdmin = courses;
    });
  }

  Future<void> _loadActiveCourseForStudent() async {
    final activeSemester = await _semesterService.getActiveSemester();
    if (activeSemester != null) {
      final courses = await _courseService.getCoursesBySemester(
        activeSemester.id,
      );
      setState(() {
        _activeCourseForStudent = courses.isNotEmpty ? courses.first : null;
      });
    }
  }

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
      final name = _nameController.text;
      final email = _emailController.text;
      final bilkentId = _bilkentIdController.text;
      final role =
          Provider.of<HomePageModel>(context, listen: false).selectedRole;
      final semesterId =
          Provider.of<HomePageModel>(
            context,
            listen: false,
          ).selectedUserSemester;
      final supervisor =
          Provider.of<HomePageModel>(context, listen: false).selectedSupervisor;

      if (role == null || semesterId == null || supervisor == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
        return;
      }

      final id =
          DateTime.now().millisecondsSinceEpoch
              .toString(); // Benzersiz ID oluşturma
      final status = await _userService.addUser(
        id,
        name,
        email,
        bilkentId,
        role,
        supervisor,
      );

      if (status == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User added successfully')),
        );

        // Eklenen kullanıcıyı doğrulama
        final addedUser = await _userService.getUserDetailsByEmail(email);
        if (addedUser != null) {
          print(
            'User added: ${addedUser.name}, ${addedUser.bilkentId}, ${addedUser.role}',
          );
        } else {
          print('Failed to retrieve added user');
        }
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to add user')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add user: $e')));
    }
  }

  Future<void> _createSemester() async {
    try {
      final year =
          Provider.of<HomePageModel>(context, listen: false).selectedYear;
      final semester =
          Provider.of<HomePageModel>(context, listen: false).selectedSemester;
      final course =
          Provider.of<HomePageModel>(context, listen: false).selectedCourse;

      if (year == null || semester == null || course == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
        return;
      }

      final id =
          DateTime.now().millisecondsSinceEpoch
              .toString(); // Benzersiz ID oluşturma
      final status = await _semesterService.createSemester(id, year, semester);

      if (status == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Semester created successfully')),
        );
        print(
          'Semester created: Year: $year, Semester: $semester, Course: $course',
        );
        _loadActiveSemester(); // Yeni dönemi yükle
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create semester')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to create semester: $e')));
    }
  }

  Future<void> _changeDeadline() async {
    try {
      final course =
          Provider.of<HomePageModel>(
            context,
            listen: false,
          ).selectedChangeDeadlineCourse;
      final assignment =
          Provider.of<HomePageModel>(context, listen: false).selectedOption;
      final deadline = _deadlineController.text;

      if (course == null || assignment == null || deadline.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
        return;
      }

      final id =
          DateTime.now().millisecondsSinceEpoch
              .toString(); // Benzersiz ID oluşturma
      final status = await _deadlineService.createDeadline(
        id,
        course,
        assignment,
        DateTime.parse(deadline),
      );

      if (status == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deadline changed successfully')),
        );
        print(
          'Deadline changed: Course: $course, Assignment: $assignment, Deadline: $deadline',
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to change deadline')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to change deadline: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Seçili semester'ın geçerli olup olmadığını kontrol et
    String? selectedUserSemester =
        _registeredSemesters
                .map(
                  (semester) => '${semester['year']} - ${semester['semester']}',
                )
                .contains(
                  Provider.of<HomePageModel>(
                    context,
                    listen: false,
                  ).selectedUserSemester,
                )
            ? Provider.of<HomePageModel>(
              context,
              listen: false,
            ).selectedUserSemester
            : null;
    return Scaffold(
      appBar: AppBar(
        title: const Text('CTIS IMS'),
        backgroundColor: AppStyles.primaryColor,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => DashboardPage(
                        registeredSemesters: _registeredSemesters,
                      ),
                ),
              );
            },
            child: const Text(
              'Dashboard',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          TextButton(
            onPressed: () {},
            child: const Text(
              'Begin (Dr.)',
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
                color: Colors.white,
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
                child: Column(
                  children: [
                    Text(
                      'Initialize Semester & Add Users',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold, fontSize: 28),
                    ),
                    if (_activeSemester != null)
                      Text(
                        'Active Semester: $_activeSemester',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    if (_teachers.isNotEmpty)
                      Column(
                        children:
                            _teachers.map((teacher) {
                              return Text(
                                'Teacher: ${teacher['username']}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              );
                            }).toList(),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              headerTitle: 'Current Deadline Settings',
              headerIcon: Icons.settings,
              buttonText: 'View Settings',
              modalContent: _currentDeadlineModalContent(),
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              headerTitle: 'Change Deadline Settings',
              headerIcon: Icons.schedule,
              buttonText: 'Edit',
              modalContent: _changeDeadlineModalContent(),
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              headerTitle: 'Create Semester',
              headerIcon: Icons.add_circle_outline,
              buttonText: 'Create',
              modalContent: _createSemesterModalContent(),
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
              headerTitle: 'All Courses for Admin',
              headerIcon: Icons.list,
              buttonText: 'View Courses',
              modalContent: _allCoursesForAdminModalContent(),
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              headerTitle: 'Active Course for Student',
              headerIcon: Icons.school,
              buttonText: 'View Active Course',
              modalContent: _activeCourseForStudentModalContent(),
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
                child: ElevatedButton(
                  onPressed: () => _openModal(modalContent),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppStyles.buttonColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppStyles.borderRadius,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 24,
                    ),
                  ),
                  child: Text(buttonText),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openModal(Widget modalContent) async {
    final homePageModel = Provider.of<HomePageModel>(context, listen: false);
    await showGeneralDialog(
      context: context,
      barrierLabel: "Modal",
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Align(
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
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(scale: anim1, child: child),
        );
      },
    );
  }

  Widget _currentDeadlineModalContent() {
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
          if (_currentDeadlines.isNotEmpty)
            ..._currentDeadlines.map((deadline) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${deadline['assignmentName']} - Deadline: ${deadline['deadline']}',
                  ),
                  AppStyles.fieldSpacing,
                ],
              );
            }).toList(),
          AppStyles.fieldSpacing,
          const Text('Last edited by: Begin (Dr.)'),
          const Text('Last update: May 29th 2023 12:25:06 am'),
          AppStyles.fieldSpacing,
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppStyles.buttonColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppStyles.borderRadius),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 24,
                ),
              ),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _changeDeadlineModalContent() {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
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
            value:
                Provider.of<HomePageModel>(
                  context,
                  listen: false,
                ).selectedChangeDeadlineCourse,
            decoration: const InputDecoration(
              labelText: 'Course',
              border: OutlineInputBorder(),
            ),
            items:
                _changeDeadlineCourses
                    .map(
                      (course) =>
                          DropdownMenuItem(value: course, child: Text(course)),
                    )
                    .toList(),
            onChanged: (value) {
              Provider.of<HomePageModel>(
                context,
                listen: false,
              ).updateChangeDeadlineCourse(value);
              Provider.of<HomePageModel>(
                context,
                listen: false,
              ).updateOption(null);
            },
          ),
          AppStyles.fieldSpacing,
          if (Provider.of<HomePageModel>(
                context,
              ).selectedChangeDeadlineCourse !=
              null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Option:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                AppStyles.fieldSpacing,
                ...((Provider.of<HomePageModel>(
                              context,
                            ).selectedChangeDeadlineCourse ==
                            'CTIS 290')
                        ? _ctis290Options
                        : _ctis310Options)
                    .map(
                      (option) => RadioListTile<String>(
                        title: Text(option),
                        value: option,
                        groupValue:
                            Provider.of<HomePageModel>(context).selectedOption,
                        onChanged: (value) {
                          Provider.of<HomePageModel>(
                            context,
                            listen: false,
                          ).updateOption(value);
                        },
                      ),
                    )
                    .toList(),
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
          ElevatedButton(
            onPressed: () {
              if (Provider.of<HomePageModel>(
                        context,
                        listen: false,
                      ).selectedOption ==
                      null ||
                  _deadlineController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please select an option and set a deadline'),
                  ),
                );
                return;
              }
              _changeDeadline();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppStyles.buttonColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppStyles.borderRadius),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Widget _createSemesterModalContent() {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create Semester',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          AppStyles.fieldSpacing,
          DropdownButtonFormField<String>(
            isExpanded: true,
            value:
                Provider.of<HomePageModel>(context, listen: false).selectedYear,
            decoration: const InputDecoration(
              labelText: 'Year',
              border: OutlineInputBorder(),
            ),
            items:
                _years
                    .map(
                      (year) =>
                          DropdownMenuItem(value: year, child: Text(year)),
                    )
                    .toList(),
            onChanged: (value) {
              Provider.of<HomePageModel>(
                context,
                listen: false,
              ).updateYear(value);
            },
          ),
          AppStyles.fieldSpacing,
          DropdownButtonFormField<String>(
            isExpanded: true,
            value:
                Provider.of<HomePageModel>(
                  context,
                  listen: false,
                ).selectedSemester,
            decoration: const InputDecoration(
              labelText: 'Semester',
              border: OutlineInputBorder(),
            ),
            items:
                _semesters
                    .map(
                      (semester) => DropdownMenuItem(
                        value: semester,
                        child: Text(semester),
                      ),
                    )
                    .toList(),
            onChanged: (value) {
              Provider.of<HomePageModel>(
                context,
                listen: false,
              ).updateSemester(value);
            },
          ),
          AppStyles.fieldSpacing,
          DropdownButtonFormField<String>(
            isExpanded: true,
            value:
                Provider.of<HomePageModel>(
                  context,
                  listen: false,
                ).selectedCourse,
            decoration: const InputDecoration(
              labelText: 'Course',
              border: OutlineInputBorder(),
            ),
            items:
                _courses
                    .map(
                      (course) =>
                          DropdownMenuItem(value: course, child: Text(course)),
                    )
                    .toList(),
            onChanged: (value) {
              Provider.of<HomePageModel>(
                context,
                listen: false,
              ).updateCourse(value);
            },
          ),
          AppStyles.fieldSpacing,
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                _createSemester();
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppStyles.buttonColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppStyles.borderRadius),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Widget _addUserModalContent() {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    // Seçili semester'ın geçerli olup olmadığını kontrol et
    String? selectedUserSemester =
        _registeredSemesters
                .map(
                  (semester) => '${semester['year']} - ${semester['semester']}',
                )
                .contains(
                  Provider.of<HomePageModel>(
                    context,
                    listen: false,
                  ).selectedUserSemester,
                )
            ? Provider.of<HomePageModel>(
              context,
              listen: false,
            ).selectedUserSemester
            : null;

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

          // NAME
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
            validator:
                (value) =>
                    value == null || value.isEmpty
                        ? 'Please enter a name'
                        : null,
          ),
          AppStyles.fieldSpacing,

          // EMAIL
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
            validator:
                (value) =>
                    value == null || value.isEmpty
                        ? 'Please enter an email'
                        : null,
          ),
          AppStyles.fieldSpacing,

          // BILKENT ID
          TextFormField(
            controller: _bilkentIdController,
            decoration: const InputDecoration(
              labelText: 'Bilkent ID',
              border: OutlineInputBorder(),
            ),
            validator:
                (value) =>
                    value == null || value.isEmpty
                        ? 'Please enter a Bilkent ID'
                        : null,
          ),
          AppStyles.fieldSpacing,

          // ROLE SELECTION
          DropdownButtonFormField<String>(
            isExpanded: true,
            value:
                Provider.of<HomePageModel>(context, listen: false).selectedRole,
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
              Provider.of<HomePageModel>(
                context,
                listen: false,
              ).updateRole(value);
            },
          ),
          AppStyles.fieldSpacing,

          // SEMESTER SELECTION
          DropdownButtonFormField<String>(
            isExpanded: true,
            value: selectedUserSemester, // Varsayılan değer
            decoration: const InputDecoration(
              labelText: 'Semester',
              border: OutlineInputBorder(),
            ),
            items:
                _registeredSemesters
                    .map(
                      (semester) =>
                          '${semester['year']} - ${semester['semester']}',
                    )
                    .toSet() // Aynı olanları kaldır
                    .map(
                      (uniqueSemester) => DropdownMenuItem(
                        value: uniqueSemester,
                        child: Text(uniqueSemester),
                      ),
                    )
                    .toList(),
            onChanged: (value) {
              Provider.of<HomePageModel>(
                context,
                listen: false,
              ).updateUserSemester(value);
            },
          ),
          AppStyles.fieldSpacing,

          // SUPERVISOR SELECTION
          DropdownButtonFormField<String>(
            isExpanded: true,
            value:
                Provider.of<HomePageModel>(
                  context,
                  listen: false,
                ).selectedSupervisor,
            decoration: const InputDecoration(
              labelText: 'Supervisor',
              border: OutlineInputBorder(),
            ),
            items:
                _supervisors
                    .map(
                      (supervisor) => DropdownMenuItem(
                        value: supervisor,
                        child: Text(supervisor),
                      ),
                    )
                    .toList(),
            onChanged: (value) {
              Provider.of<HomePageModel>(
                context,
                listen: false,
              ).updateSupervisor(value);
            },
          ),
          AppStyles.fieldSpacing,

          // SUBMIT BUTTON
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                _addUser();
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppStyles.buttonColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppStyles.borderRadius),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            ),
            child: const Text('Add User'),
          ),
        ],
      ),
    );
  }

  Widget _allCoursesForAdminModalContent() {
    return Form(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'All Courses for Admin',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          AppStyles.fieldSpacing,
          if (_allCoursesForAdmin.isNotEmpty)
            ..._allCoursesForAdmin.map((course) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Course: ${course['code']} - Semester: ${course['semesterId']}',
                  ),
                  AppStyles.fieldSpacing,
                ],
              );
            }).toList(),
          AppStyles.fieldSpacing,
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppStyles.buttonColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppStyles.borderRadius),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 24,
                ),
              ),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _activeCourseForStudentModalContent() {
    return Form(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Active Course for Student',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          AppStyles.fieldSpacing,
          if (_activeCourseForStudent != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Course: ${_activeCourseForStudent!['code']} - Semester: ${_activeCourseForStudent!['semesterId']}',
                ),
                AppStyles.fieldSpacing,
              ],
            ),
          AppStyles.fieldSpacing,
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppStyles.buttonColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppStyles.borderRadius),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 24,
                ),
              ),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }
}
