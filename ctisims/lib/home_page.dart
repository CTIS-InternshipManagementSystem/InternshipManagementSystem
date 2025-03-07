import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctisims/dbHelper.dart';
import 'package:ctisims/login_page.dart';
import 'package:flutter/material.dart';
import 'dashboard_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:async/async.dart';
import 'package:intl/intl.dart';

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
  final List<String> _courses = ['CTIS310', 'CTIS290'];
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
    'Report'
  ];
  final List<Map<String, String>> _supervisors = [
    {'id': '1', 'name': 'Neşe Şahin Özçelik'},
    {'id': '2', 'name': 'Serkan Genç'},
    {'id': '3', 'name': 'Erkan Uçar'},
  ];

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
        setState(() {
          _deadlineController.text = pickedDate.toString();
        });
      }
    }
  }

  Future<void> _addUser() async {
    try {
      DBHelper.addUser(_nameController.text, _emailController.text, _bilkentIdController.text, 
            Provider.of<HomePageModel>(context, listen: false).selectedRole ?? '',
            _supervisors.firstWhere((supervisor) => supervisor['name'] == Provider.of<HomePageModel>(context, listen: false).selectedSupervisor)['id'] ?? '');
      

      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: 'temporaryPassword123',
      );

      await FirebaseAuth.instance.sendPasswordResetEmail(email: _emailController.text);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User added and password reset email sent')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add user: $e')),
      );
    }
  }

  Future<List<Map<String, dynamic>>>? _deadline310;
  Future<List<Map<String, dynamic>>>? _deadline290;

  @override
  void initState() {
    super.initState();
    _deadline310 = DBHelper.getActiveCourseAssignments("310");
    _deadline290 = DBHelper.getActiveCourseAssignments("290");
  }

  @override
  Widget build(BuildContext context) {
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
                  builder: (context) => DashboardPage(
                    registeredSemesters: _registeredSemesters,
                    userData: widget.userData, // pass the userData
                  ),
                ),
              );
            },
            child: const Text('Dashboard', style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
          TextButton(
            onPressed: () {},
            child: const Text('Begin (Dr.)', style: TextStyle(color: Colors.white, fontSize: 16)),
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
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
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
                      borderRadius: BorderRadius.circular(AppStyles.borderRadius),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
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
    final dateFormat = DateFormat('MM/dd/yyyy HH:mm');
    return StreamBuilder<List<List<Map<String, dynamic>>>>(
      stream: StreamZip([DBHelper.streamCurrentDeadline310(), DBHelper.streamCurrentDeadline290()]),
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
            return int.parse(matchA.group(1)!).compareTo(int.parse(matchB.group(1)!));
          }
          return nameA.compareTo(nameB);
        });
        // For CTIS290, filter only "report" (case insensitive)
        final data290 = (snapshot.data![1] as List<Map<String, dynamic>>)
            .where((item) => (item['name'] ?? '').toString().toLowerCase() == 'report')
            .toList();
        return Form(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Deadline Settings',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              AppStyles.fieldSpacing,
              Text('CTIS 310'),
              for (var item in data310)
                Builder(
                  builder: (context) {
                    final deadlineVal = item['deadline'];
                    String deadlineStr;
                    if (deadlineVal is Timestamp) {
                      deadlineStr = dateFormat.format(deadlineVal.toDate().toLocal());
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
                      deadlineStr = dateFormat.format(deadlineVal.toDate().toLocal());
                    } else {
                      deadlineStr = deadlineVal.toString();
                    }
                    return Text('${item['name']} - Deadline: $deadlineStr');
                  },
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
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  ),
                  child: const Text('Close'),
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              AppStyles.fieldSpacing,
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: model.selectedChangeDeadlineCourse,
                decoration: const InputDecoration(
                  labelText: 'Course',
                  border: OutlineInputBorder(),
                ),
                items: _changeDeadlineCourses
                    .map((course) => DropdownMenuItem(value: course, child: Text(course)))
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
                    ...((model.selectedChangeDeadlineCourse == 'CTIS 290') ? _ctis290Options : _ctis310Options)
                        .map((option) => RadioListTile<String>(
                              title: Text(option),
                              value: option,
                              groupValue: model.selectedOption,
                              onChanged: (value) {
                                model.updateOption(value);
                              },
                            )),
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
                onPressed: () async {
                  if (model.selectedOption == null || _deadlineController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select an option and set a deadline')));
                    return;
                  }
                  final parsedDeadline = DateTime.tryParse(_deadlineController.text);
                  if (parsedDeadline == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invalid deadline format')));
                    return;
                  }
                  String courseId = (model.selectedChangeDeadlineCourse == 'CTIS 290') ? '290' : '310';
                  String assignmentName = model.selectedOption ?? '';
                  await DBHelper.changeDeadlineSettings(courseId, assignmentName, parsedDeadline);
                  debugPrint('New deadline: ${_deadlineController.text}');
                  debugPrint('Selected option: ${model.selectedOption}');
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
      },
    );
  }

  Widget _createCourseModalContent() {
    // New dropdown for year with the specified options.
    final List<String> _courseYears = ["2020-2021", "2022-2023", "2023-2024", "2024-2025"];
    final List<String> _courseSemesters = ["Fall", "Spring"];
    // New dropdown for course type remains; reuse _courses: but ensure they are 
    // "CTIS310" and "CTIS290" exactly.
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    String? selectedYear = Provider.of<HomePageModel>(context, listen: false).selectedYear;
    String? selectedSemester = Provider.of<HomePageModel>(context, listen: false).selectedSemester;
    String? selectedCourse = Provider.of<HomePageModel>(context, listen: false).selectedCourse;
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              AppStyles.fieldSpacing,
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: selectedYear,
                decoration: const InputDecoration(
                  labelText: 'Year',
                  border: OutlineInputBorder(),
                ),
                items: _courseYears
                    .map((year) => DropdownMenuItem(value: year, child: Text(year)))
                    .toList(),
                onChanged: (value) {
                  Provider.of<HomePageModel>(context, listen: false).updateYear(value);
                },
                validator: (value) => value == null ? 'Please select a year' : null,
              ),
              AppStyles.fieldSpacing,
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: selectedSemester,
                decoration: const InputDecoration(
                  labelText: 'Semester',
                  border: OutlineInputBorder(),
                ),
                items: _courseSemesters
                    .map((sem) => DropdownMenuItem(value: sem, child: Text(sem)))
                    .toList(),
                onChanged: (value) {
                  Provider.of<HomePageModel>(context, listen: false).updateSemester(value);
                },
                validator: (value) => value == null ? 'Please select a semester' : null,
              ),
              AppStyles.fieldSpacing,
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: selectedCourse,
                decoration: const InputDecoration(
                  labelText: 'Course',
                  border: OutlineInputBorder(),
                ),
                items: _courses
                    .map((course) => DropdownMenuItem(value: course, child: Text(course)))
                    .toList(),
                onChanged: (value) {
                  Provider.of<HomePageModel>(context, listen: false).updateCourse(value);
                },
                validator: (value) => value == null ? 'Please select a course' : null,
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
              ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  try {
                    await DBHelper.createCourse(
                      Provider.of<HomePageModel>(context, listen: false).selectedCourse!,
                      Provider.of<HomePageModel>(context, listen: false).selectedYear!,
                      Provider.of<HomePageModel>(context, listen: false).selectedSemester!,
                      isActive
                    );
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Course created successfully'))
                    );
                    Navigator.pop(context);
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}'))
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppStyles.buttonColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppStyles.borderRadius),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                ),
                child: const Text('Create Course'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _addUserModalContent() {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add User',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          AppStyles.fieldSpacing,
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter a name';
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
              if (value == null || value.isEmpty) return 'Please enter an email';
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
              if (value == null || value.isEmpty) return 'Please enter a Bilkent ID';
              return null;
            },
          ),
          AppStyles.fieldSpacing,
          DropdownButtonFormField<String>(
            isExpanded: true,
            value: Provider.of<HomePageModel>(context, listen: false).selectedRole,
            decoration: const InputDecoration(
              labelText: 'Role',
              border: OutlineInputBorder(),
            ),
            items: _roles
                .map((role) => DropdownMenuItem(value: role, child: Text(role)))
                .toList(),
            onChanged: (value) {
              Provider.of<HomePageModel>(context, listen: false).updateRole(value);
            },
          ),
          AppStyles.fieldSpacing,
          DropdownButtonFormField<String>(
            isExpanded: true,
            value: Provider.of<HomePageModel>(context, listen: false).selectedSupervisor,
            decoration: const InputDecoration(
              labelText: 'Supervisor',
              border: OutlineInputBorder(),
            ),
            items: _supervisors
                .map((supervisor) => DropdownMenuItem(value: supervisor['name'], child: Text(supervisor['name']!)))
                .toList(),
            onChanged: (value) {
              Provider.of<HomePageModel>(context, listen: false).updateSupervisor(value);
            },
          ),
          AppStyles.fieldSpacing,
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
}
