import 'package:ctisims/evaluate_page.dart';
import 'package:ctisims/favorite_list_page.dart';
import 'package:flutter/material.dart';
import 'package:ctisims/db_helper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'themes/Theme_provider.dart';
import 'providers/favorites_provider.dart';

// Use a conditional import for web support
// This approach doesn't use dart:html directly which is deprecated
import 'web_download_helper.dart' if (dart.library.io) 'mobile_download_helper.dart';

// Add http package as dev dependency or regular dependency
import 'package:http/http.dart' as http;

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String? _selectedOption;
  final TextEditingController _bilkentIdController = TextEditingController();
  final Map<String, String?> _uploadFilePaths = {};
  final Map<String, Uint8List?> _uploadFileBytes = {};
  final Map<String, bool> _isUploading = {};
  
  List<Map<String, dynamic>> _supervisors = [];
  String? _selectedSupervisorId;
  String? _selectedSupervisorName;
  
  Future<List<Map<String, dynamic>>>? _futureStudentCourses;

  @override
  void initState() {
    super.initState();
    _futureStudentCourses = DBHelper.getStudentCoursesWithCourseInfo();
    _bilkentIdController.addListener(_onBilkentIdChanged);
    _loadSupervisors();
  }

  @override
  void dispose() {
    _bilkentIdController.dispose();
    super.dispose();
  }

  void _onBilkentIdChanged() {
    _searchSubmissions(_bilkentIdController.text);
  }

  Future<void> _loadSupervisors() async {
    try {
      final supervisors = await DBHelper.getAllSupervisors();
      if (!mounted) return;
      setState(() {
        _supervisors = supervisors;
      });
    } catch (e) {
      debugPrint("Error loading supervisors: $e");
    }
  }

  void _searchSubmissions(String query) {
    setState(() {
      if (_selectedOption == 'Search by Supervisor' && _selectedSupervisorId != null) {
        _futureStudentCourses = _getStudentsBySupervisor(_selectedSupervisorId!);
      } else if (query.isEmpty) {
        _futureStudentCourses = DBHelper.getStudentCoursesWithCourseInfo();
      } else {
        _futureStudentCourses = DBHelper.getStudentCoursesWithCourseInfo().then(
          (submissions) => submissions.where(
            (submission) => submission['bilkentId'].toString().startsWith(query)
          ).toList()
        );
      }
    });
  }

  Future<List<Map<String, dynamic>>> _getStudentsBySupervisor(String supervisorId) async {
    try {
      final allStudentCourses = await DBHelper.getStudentCoursesWithCourseInfo();
      final studentsWithSupervisor = await DBHelper.getStudentsBySupervisor(supervisorId);
      final bilkentIds = studentsWithSupervisor.map((s) => s['bilkentId'].toString()).toSet();
      
      return allStudentCourses.where(
        (submission) => bilkentIds.contains(submission['bilkentId'])
      ).toList();
    } catch (e) {
      debugPrint("Error getting students by supervisor: $e");
      return [];
    }
  }

  void _updateFilteredSubmissions() {
    if (_selectedOption == 'Search by Supervisor' && _selectedSupervisorId != null) {
      _searchSubmissions('');
    } else {
      setState(() {
        _futureStudentCourses = DBHelper.getStudentCoursesWithCourseInfo();
      });
    }
  }

  void _showCenteredSuccessNotification(String operation, String fileName, {int? fileSize}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..clearSnackBars();
    
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Success Dialog',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => Container(),
      transitionBuilder: (context, animation, secondaryAnimation, _) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        );
        
        return ScaleTransition(
          scale: Tween<double>(begin: 0.5, end: 1.0).animate(curvedAnimation),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation),
            child: AlertDialog(
              backgroundColor: Theme.of(context).brightness == Brightness.dark 
                ? Colors.grey[850] 
                : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 300,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildAnimatedIcon(
                        color: Colors.green,
                        icon: Icons.check,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        operation == 'upload' 
                          ? 'Upload Successful!' 
                          : 'File Deleted Successfully!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.white 
                            : Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      _buildFileInfoContainer(fileName, fileSize: fileSize),
                      const SizedBox(height: 20),
                      _buildActionButton(
                        onPressed: () => Navigator.of(context).pop(),
                        backgroundColor: Colors.green,
                        text: 'Done',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedIcon({
    required Color color,
    required IconData icon,
  }) {
    return TweenAnimationBuilder(
      duration: const Duration(seconds: 1),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, _) {
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: color.withAlpha(26), // 0.1 * 255 ≈ 26
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 70,
                  width: 70,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    strokeWidth: 3,
                  ),
                ),
                Icon(
                  icon,
                  color: color,
                  size: 50 * value,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFileInfoContainer(String fileName, {int? fileSize}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(26), // 0.1 * 255 ≈ 26
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.insert_drive_file, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  fileName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (fileSize != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.storage, color: Colors.blue),
                const SizedBox(width: 8),
                Text('${(fileSize / 1024).toStringAsFixed(2)} KB'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required Color backgroundColor,
    required String text,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        minimumSize: const Size(150, 40),
      ),
      child: Text(text),
    );
  }

  void _showErrorDialog(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..clearSnackBars();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> uploadFile(String bilkentId, String name, String courseId, 
      String year, String semester, String code) async {
    setState(() {
      _isUploading[bilkentId] = true;
    });
    
    try {
      await Firebase.initializeApp();
      final String fileName = "CompanyEvaluation_${bilkentId}_$name";
      final String destinationBase = "$year $semester/CTIS$code/${name}_$bilkentId";
      final String destination = "$destinationBase/$fileName";
      Reference storageRef;
      int fileSize = 0;
      
      if (kIsWeb) {
        if (_uploadFileBytes[bilkentId] == null) {
          throw Exception("No file bytes provided for web upload");
        }
        
        fileSize = _uploadFileBytes[bilkentId]!.length;
        storageRef = FirebaseStorage.instance.ref(destination);
        await storageRef.putData(_uploadFileBytes[bilkentId]!).whenComplete(() => null);
      } else {
        if (_uploadFilePaths[bilkentId] == null) {
          throw Exception("No file path provided for mobile upload");
        }
        
        final file = File(_uploadFilePaths[bilkentId]!);
        fileSize = file.lengthSync();
        storageRef = FirebaseStorage.instance.ref(destination);
        await storageRef.putFile(file).whenComplete(() => null);
      }
      
      _showCenteredSuccessNotification('upload', fileName, fileSize: fileSize);
      await DBHelper.changeCompanyEvaluation(bilkentId, courseId, true);
      _updateFilteredSubmissions();
    } catch (e) {
      _showErrorDialog("Error during file upload: $e");
    } finally {
      setState(() {
        _isUploading[bilkentId] = false;
        _uploadFilePaths[bilkentId] = null;
        _uploadFileBytes[bilkentId] = null;
      });
    }
  }

  void _showDownloadSuccessNotification(String fileName, String path) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..clearSnackBars();
    
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Download Success Dialog',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => Container(),
      transitionBuilder: (context, animation, secondaryAnimation, _) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        );
        
        return ScaleTransition(
          scale: Tween<double>(begin: 0.5, end: 1.0).animate(curvedAnimation),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation),
            child: AlertDialog(
              backgroundColor: Theme.of(context).brightness == Brightness.dark 
                ? Colors.grey[850] 
                : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 300,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildAnimatedIcon(
                        color: Colors.blue,
                        icon: Icons.download_done,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Download Complete!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.white 
                            : Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      _buildDownloadInfoContainer(fileName, path),
                      const SizedBox(height: 20),
                      _buildActionButton(
                        onPressed: () => Navigator.of(context).pop(),
                        backgroundColor: Colors.blue,
                        text: 'Done',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDownloadInfoContainer(String fileName, String path) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(26), // 0.1 * 255 ≈ 26
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.insert_drive_file, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  fileName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.folder, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  path,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> downloadFile(String bilkentId, String name, String year, 
      String semester, String code) async {
    try {
      final String fileName = "CompanyEvaluation_${bilkentId}_$name";
      final String destinationBase = "$year $semester/CTIS$code/${name}_$bilkentId";
      final String destination = "$destinationBase/$fileName";
      final ref = FirebaseStorage.instance.ref(destination);
      final downloadUrl = await ref.getDownloadURL();
      
      if (kIsWeb) {
        // Web download using our custom AnchorElement implementation
        final anchor = AnchorElement(href: downloadUrl);
        anchor.download = fileName;
        anchor.click();
        _showDownloadSuccessNotification(fileName, "Downloaded to your device");
      } else {
        // Mobile download to app documents
        final response = await http.get(Uri.parse(downloadUrl));
        final Directory appDocDir = await getApplicationDocumentsDirectory();
        final File file = File('${appDocDir.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);
        _showDownloadSuccessNotification(fileName, file.path);
      }
    } catch (e) {
      _showErrorDialog("Download error: $e");
    }
  }

  Future<void> deleteFile(String bilkentId, String name, String courseId, 
      String year, String semester, String code) async {
    try {
      final String fileName = "CompanyEvaluation_${bilkentId}_$name";
      final String destinationBase = "$year $semester/CTIS$code/${name}_$bilkentId";
      final String destination = "$destinationBase/$fileName";
      final ref = FirebaseStorage.instance.ref(destination);
      await ref.delete();
      
      await DBHelper.changeCompanyEvaluation(bilkentId, courseId, false);
      _showCenteredSuccessNotification('delete', fileName);
      _updateFilteredSubmissions();
    } catch (e) {
      _showErrorDialog("File deletion error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    final isDark = themeProvider.isDarkMode;
    
    final cardBgColor = isDark ? Colors.grey[850] : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.dark_mode : Icons.light_mode,
              color: Colors.grey,
            ),
            tooltip: 'Toggle Dark Mode',
            onPressed: themeProvider.toggleTheme,
          ),
          IconButton(
            icon: const Icon(Icons.favorite),
            tooltip: 'View Favorites',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FavoriteListPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilterSection(isDark, cardBgColor, textColor),
            const SizedBox(height: 16),
            _buildStudentList(cardBgColor, textColor, favoritesProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(bool isDark, Color? cardBgColor, Color textColor) {
    return Card(
      elevation: 4,
      color: cardBgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select an option:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildRadioOption(
              'Search Student', 
              'Search Student', 
              textColor,
            ),
            _buildRadioOption(
              'Uploading Company Evaluation Reports', 
              'Uploading Company Evaluation Reports', 
              textColor,
            ),
            _buildRadioOption(
              'Search by Supervisor', 
              'Search by Supervisor', 
              textColor,
            ),
            const SizedBox(height: 8),
            
            _selectedOption == 'Search by Supervisor'
                ? _buildSupervisorDropdown(isDark, textColor)
                : _buildBilkentIdTextField(isDark, textColor),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioOption(String title, String value, Color textColor) {
    return RadioListTile<String>(
      title: Text(title, style: TextStyle(color: textColor)),
      value: value,
      groupValue: _selectedOption,
      onChanged: (value) {
        setState(() {
          _selectedOption = value;
          if (value != 'Search by Supervisor') {
            _selectedSupervisorId = null;
            _selectedSupervisorName = null;
            _updateFilteredSubmissions();
          } else {
            _bilkentIdController.clear();
          }
        });
      },
    );
  }

  Widget _buildSupervisorDropdown(bool isDark, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: 'Select Supervisor',
          labelStyle: TextStyle(color: textColor.withAlpha((0.8 * 255).toInt())),
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: isDark ? Colors.grey[800] : Colors.grey[200],
        ),
        value: _selectedSupervisorName,
        items: _supervisors.map((supervisor) {
          return DropdownMenuItem<String>(
            value: supervisor['name'] as String,
            child: Text(supervisor['name'] as String),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            final supervisor = _supervisors.firstWhere(
              (s) => s['name'] == value,
              orElse: () => {},
            );
            setState(() {
              _selectedSupervisorName = value;
              _selectedSupervisorId = supervisor['bilkentId'] as String;
              _searchSubmissions('');
            });
          }
        },
        style: TextStyle(color: textColor),
        dropdownColor: isDark ? Colors.grey[850] : Colors.white,
      ),
    );
  }

  Widget _buildBilkentIdTextField(bool isDark, Color textColor) {
    return TextField(
      controller: _bilkentIdController,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        labelText: 'Bilkent ID',
        labelStyle: TextStyle(color: textColor.withAlpha((0.8 * 255).toInt())),
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: isDark ? Colors.grey[800] : Colors.grey[200],
      ),
      keyboardType: TextInputType.number,
    );
  }

  Widget _buildStudentList(Color? cardBgColor, Color textColor, FavoritesProvider favoritesProvider) {
    return Expanded(
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureStudentCourses,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No students found"));
          }

          final studentCourses = snapshot.data!;
          return ListView.builder(
            itemCount: studentCourses.length,
            itemBuilder: (context, index) {
              final submission = studentCourses[index];
              final course = submission['course'];
              final bilkentId = submission['bilkentId'] ?? '';
              final name = submission['name'] ?? '';
              final courseId = course['courseId'] ?? '';
              final year = course['year'] ?? '';
              final semester = course['semester'] ?? '';
              final code = course['code'] ?? '';
              final companyEvaluationUploaded = submission['companyEvaluationUploaded'] ?? false;
              
              return Card(
                elevation: 2,
                color: cardBgColor,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Student: $name', 
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              )
                            ),
                          ),
                          IconButton(
                            icon: Consumer<FavoritesProvider>(
                              builder: (context, favProvider, _) {
                                final isFav = favProvider.isFavorite(bilkentId);
                                return Icon(
                                  isFav ? Icons.favorite : Icons.favorite_border,
                                  color: isFav ? Colors.red : Colors.grey,
                                  size: 24,
                                );
                              },
                            ),
                            tooltip: favoritesProvider.isFavorite(bilkentId)
                                ? 'Remove from favorites'
                                : 'Add to favorites',
                            onPressed: () {
                              // Create a clean copy of the student data with only what we need
                              final studentData = {
                                'bilkentId': bilkentId,
                                'name': name,
                                'email': submission['email'] ?? '',
                                'course': {
                                  'courseId': courseId,
                                  'year': year,
                                  'semester': semester,
                                  'code': code,
                                },
                                'companyEvaluationUploaded': companyEvaluationUploaded
                              };
                              
                              // Toggle favorite for this specific student only
                              favoritesProvider.toggleFavorite(studentData);
                              
                              // Show feedback
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    favoritesProvider.isFavorite(bilkentId)
                                        ? 'Added to favorites'
                                        : 'Removed from favorites',
                                  ),
                                  duration: const Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Bilkent ID: $bilkentId', style: TextStyle(color: textColor)),
                      const SizedBox(height: 4),
                      Text('Year: $year', style: TextStyle(color: textColor)),
                      const SizedBox(height: 4),
                      Text('Semester: $semester', style: TextStyle(color: textColor)),
                      const SizedBox(height: 4),
                      Text('Course: CTIS $code', style: TextStyle(color: textColor)),
                      const SizedBox(height: 4),
                      Text(
                        'Company Evaluation Uploaded: $companyEvaluationUploaded', 
                        style: TextStyle(color: textColor)
                      ),
                      const SizedBox(height: 16),
                      
                      if (_selectedOption == 'Uploading Company Evaluation Reports') ...[
                        if (companyEvaluationUploaded) ...[
                          ElevatedButton(
                            onPressed: () => downloadFile(bilkentId, name, year, semester, code),
                            child: const Text('Download Company Evaluation Report'),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => deleteFile(bilkentId, name, courseId, year, semester, code),
                            child: const Text('Delete Company Evaluation Report'),
                          ),
                        ] else ...[
                          ElevatedButton(
                            onPressed: () async {
                              if (kIsWeb) {
                                FilePickerResult? result = await FilePicker.platform.pickFiles();
                                if (result != null) {
                                  setState(() {
                                    _uploadFileBytes[bilkentId] = result.files.single.bytes;
                                    _uploadFilePaths[bilkentId] = result.files.single.name;
                                  });
                                }
                              } else {
                                FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.any);
                                if (result != null) {
                                  setState(() {
                                    _uploadFilePaths[bilkentId] = result.files.single.path;
                                  });
                                }
                              }
                            },
                            child: const Text('Choose File'),
                          ),
                          if (_uploadFilePaths[bilkentId] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text('Selected file: ${_uploadFilePaths[bilkentId]}'),
                            ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _isUploading[bilkentId] == true 
                              ? null 
                              : () => uploadFile(bilkentId, name, courseId, year, semester, code),
                            child: _isUploading[bilkentId] == true
                              ? const CircularProgressIndicator()
                              : const Text('Upload'),
                          ),
                        ],
                      ],
                      
                      if (_selectedOption == 'Search Student') ...[
                        ElevatedButton(
                          onPressed: () {
                            final submissionMap = {
                              'bilkentId': bilkentId,
                              'courseId': courseId,
                              'studentName': name,
                              'email': submission['email'] ?? '',
                              'course': 'CTIS$code',
                              'companyEvaluation': companyEvaluationUploaded ? 'Uploaded' : 'Not Uploaded'
                            };
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EvaluatePage(
                                  submission: submissionMap.map((k, v) => MapEntry(k, v.toString())),
                                ),
                              ),
                            );
                          },
                          child: const Text('View Submission'),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
