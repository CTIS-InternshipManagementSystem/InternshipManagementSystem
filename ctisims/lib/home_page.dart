import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dashboard_page.dart';

/// Simple state model for HomePage selections.
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

/// Centralized styling constants.
class AppStyles {
  static const primaryColor = Colors.orange;
  static const buttonColor = Colors.blue;
  static const cardElevation = 4.0;
  static const borderRadius = 16.0;
  static const padding = EdgeInsets.all(16.0);
  static const fieldSpacing = SizedBox(height: 16);
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  // Controllers for fields outside modals.
  final TextEditingController _deadlineController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _bilkentIdController = TextEditingController();

  // Dropdown lists.
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

  // Sample data for registered semesters.
  final List<Map<String, String>> _registeredSemesters = [
    {'year': '2022-2023', 'semester': 'Fall', 'course': 'CTIS310', 'role': 'Student'},
    {'year': '2022-2023', 'semester': 'Fall', 'course': 'CTIS290', 'role': 'Student'},
    {'year': '2022-2023', 'semester': 'Fall', 'course': 'CTIS290', 'role': 'Admin'},
  ];

  // Animation for subtle fade-in.
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _animationController.forward();
  }

  @override
  void dispose() {
    _deadlineController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _bilkentIdController.dispose();
    _animationController.dispose();
    super.dispose();
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

  /// Helper method to open a modal with custom fade-scale transition.
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

  /// Helper widget to build a section card with header icon, title, explanation, and button to open modal.
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
      margin: const EdgeInsets.only(bottom: 16),
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
                  child: Text(buttonText),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppStyles.buttonColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppStyles.borderRadius),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Modal content for "Current Deadline Settings" (Section 1).
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
          const Text('First submission deadline (in days): 30'),
          AppStyles.fieldSpacing,
          const Text('Last edited by: Begin (Dr.)'),
          AppStyles.fieldSpacing,
          const Text('Last update: May 29th 2023 12:25:06 am'),
          AppStyles.fieldSpacing,
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppStyles.buttonColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppStyles.borderRadius),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Modal content for "Change Deadline Settings" (Section 2).
  Widget _changeDeadlineModalContent() {
    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
    return Form(
      key: _formKey,
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
            child: const Text('Update'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppStyles.buttonColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppStyles.borderRadius),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            ),
          ),
        ],
      ),
    );
  }

  /// Modal content for "Create Semester" (Section 3).
  Widget _createSemesterModalContent() {
    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
    return Form(
      key: _formKey,
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
            child: const Text('Create'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppStyles.buttonColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppStyles.borderRadius),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            ),
          ),
        ],
      ),
    );
  }

  /// Modal content for "Add User" (Section 4).
  Widget _addUserModalContent() {
    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
    return Form(
      key: _formKey,
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
              labelText: 'Mail',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter an email';
              if (!value.contains('@')) return 'Enter a valid email';
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
            keyboardType: TextInputType.number,
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
          if (Provider.of<HomePageModel>(context, listen: false).selectedRole == 'Student') ...[
            DropdownButtonFormField<String>(
              isExpanded: true,
              value: Provider.of<HomePageModel>(context, listen: false).selectedSupervisor,
              decoration: const InputDecoration(
                labelText: 'Supervisor',
                border: OutlineInputBorder(),
              ),
              items: _supervisors
                  .map((supervisor) =>
                      DropdownMenuItem(value: supervisor, child: Text(supervisor)))
                  .toList(),
              onChanged: (value) {
                Provider.of<HomePageModel>(context, listen: false).updateSupervisor(value);
              },
            ),
            AppStyles.fieldSpacing,
          ],
          DropdownButtonFormField<String>(
            isExpanded: true,
            value: Provider.of<HomePageModel>(context, listen: false).selectedUserSemester,
            decoration: const InputDecoration(
              labelText: 'Semester',
              border: OutlineInputBorder(),
            ),
            items: _semesters
                .map((semester) =>
                    DropdownMenuItem(value: semester, child: Text(semester)))
                .toList(),
            onChanged: (value) {
              Provider.of<HomePageModel>(context, listen: false).updateUserSemester(value);
            },
          ),
          AppStyles.fieldSpacing,
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                debugPrint('Name: ${_nameController.text}');
                debugPrint('Mail: ${_emailController.text}');
                debugPrint('Bilkent ID: ${_bilkentIdController.text}');
                debugPrint('Role: ${Provider.of<HomePageModel>(context, listen: false).selectedRole}');
                debugPrint('Supervisor: ${Provider.of<HomePageModel>(context, listen: false).selectedSupervisor}');
                debugPrint('Semester: ${Provider.of<HomePageModel>(context, listen: false).selectedUserSemester}');
                Navigator.pop(context);
              }
            },
            child: const Text('Submit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppStyles.buttonColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppStyles.borderRadius),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomePageModel(),
      child: Scaffold(
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
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: AppStyles.primaryColor,
                ),
                child: const Text(
                  'CTIS IMS Menu',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.dashboard),
                title: const Text('Dashboard'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            DashboardPage(registeredSemesters: _registeredSemesters)),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Create Semester'),
                onTap: () {
                  // Navigate to Create Semester page if available.
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_add),
                title: const Text('Add User'),
                onTap: () {
                  // Navigate to Add User page if available.
                },
              ),
            ],
          ),
        ),
        body: SingleChildScrollView(
          padding: AppStyles.padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Section with centered title.
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
              AppStyles.fieldSpacing,
              // Section 1: Current Deadline Settings with a settings icon.
              _buildSectionCard(
                headerTitle: 'Current Deadline Settings',
                headerIcon: Icons.settings,
                buttonText: 'View Settings',
                modalContent: _currentDeadlineModalContent(),
              ),
              // Section 2: Change Deadline Settings.
              _buildSectionCard(
                headerTitle: 'Change Deadline Settings',
                headerIcon: Icons.schedule,
                buttonText: 'Edit',
                modalContent: _changeDeadlineModalContent(),
              ),
              // Section 3: Create Semester.
              _buildSectionCard(
                headerTitle: 'Create Semester',
                headerIcon: Icons.add_circle_outline,
                buttonText: 'Create',
                modalContent: _createSemesterModalContent(),
              ),
              // Section 4: Add User.
              _buildSectionCard(
                headerTitle: 'Add User',
                headerIcon: Icons.person_add_alt,
                buttonText: 'Add User',
                modalContent: _addUserModalContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
