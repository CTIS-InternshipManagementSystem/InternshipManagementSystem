import 'package:flutter/material.dart';
import 'dashboard_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

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
                  builder: (context) => DashboardPage(registeredSemesters: _registeredSemesters),
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
    return Form(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Deadline Settings',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          AppStyles.fieldSpacing,
          const Text('CTIS 310'),
          const Text('Follow Up1 - Deadline: 30 days'),
          const Text('Follow Up2 - Deadline: 60 days'),
          const Text('Follow Up3 - Deadline: 90 days'),
          const Text('Follow Up4 - Deadline: 120 days'),
          const Text('Follow Up5 - Deadline: 150 days'),
          const Text('Report - Deadline: 180 days'),
          AppStyles.fieldSpacing,
          const Text('CTIS 290'),
          const Text('Report - Deadline: 90 days'),
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
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
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
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          AppStyles.fieldSpacing,
          DropdownButtonFormField<String>(
            isExpanded: true,
            value: Provider.of<HomePageModel>(context, listen: false).selectedChangeDeadlineCourse,
            decoration: const InputDecoration(
              labelText: 'Course',
              border: OutlineInputBorder(),
            ),
            items: _changeDeadlineCourses
                .map((course) => DropdownMenuItem(value: course, child: Text(course)))
                .toList(),
            onChanged: (value) {
              Provider.of<HomePageModel>(context, listen: false).updateChangeDeadlineCourse(value);
              Provider.of<HomePageModel>(context, listen: false).updateOption(null);
            },
          ),
          AppStyles.fieldSpacing,
          if (Provider.of<HomePageModel>(context).selectedChangeDeadlineCourse != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Option:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                AppStyles.fieldSpacing,
                ...((Provider.of<HomePageModel>(context).selectedChangeDeadlineCourse == 'CTIS 290')
                        ? _ctis290Options
                        : _ctis310Options)
                    .map((option) => RadioListTile<String>(
                          title: Text(option),
                          value: option,
                          groupValue: Provider.of<HomePageModel>(context).selectedOption,
                          onChanged: (value) {
                            Provider.of<HomePageModel>(context, listen: false).updateOption(value);
                          },
                        ))
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
              if (Provider.of<HomePageModel>(context, listen: false).selectedOption == null ||
                  _deadlineController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select an option and set a deadline')));
                return;
              }
              debugPrint('New deadline: ${_deadlineController.text}');
              debugPrint('Selected option: ${Provider.of<HomePageModel>(context, listen: false).selectedOption}');
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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          AppStyles.fieldSpacing,
          DropdownButtonFormField<String>(
            isExpanded: true,
            value: Provider.of<HomePageModel>(context, listen: false).selectedYear,
            decoration: const InputDecoration(
              labelText: 'Year',
              border: OutlineInputBorder(),
            ),
            items: _years
                .map((year) => DropdownMenuItem(value: year, child: Text(year)))
                .toList(),
            onChanged: (value) {
              Provider.of<HomePageModel>(context, listen: false).updateYear(value);
            },
          ),
          AppStyles.fieldSpacing,
          DropdownButtonFormField<String>(
            isExpanded: true,
            value: Provider.of<HomePageModel>(context, listen: false).selectedSemester,
            decoration: const InputDecoration(
              labelText: 'Semester',
              border: OutlineInputBorder(),
            ),
            items: _semesters
                .map((semester) => DropdownMenuItem(value: semester, child: Text(semester)))
                .toList(),
            onChanged: (value) {
              Provider.of<HomePageModel>(context, listen: false).updateSemester(value);
            },
          ),
          AppStyles.fieldSpacing,
          DropdownButtonFormField<String>(
            isExpanded: true,
            value: Provider.of<HomePageModel>(context, listen: false).selectedCourse,
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
          ),
          AppStyles.fieldSpacing,
          ElevatedButton(
            onPressed: () {
              debugPrint('Year: ${Provider.of<HomePageModel>(context, listen: false).selectedYear}');
              debugPrint('Semester: ${Provider.of<HomePageModel>(context, listen: false).selectedSemester}');
              debugPrint('Course: ${Provider.of<HomePageModel>(context, listen: false).selectedCourse}');
              Navigator.pop(context);
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
            value: Provider.of<HomePageModel>(context, listen: false).selectedUserSemester,
            decoration: const InputDecoration(
              labelText: 'Semester',
              border: OutlineInputBorder(),
            ),
            items: _registeredSemesters
                .map((semester) => DropdownMenuItem(
                      value: '${semester['year']} - ${semester['semester']}',
                      child: Text('${semester['year']} - ${semester['semester']}'),
                    ))
                .toList(),
            onChanged: (value) {
              Provider.of<HomePageModel>(context, listen: false).updateUserSemester(value);
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
                .map((supervisor) => DropdownMenuItem(value: supervisor, child: Text(supervisor)))
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
