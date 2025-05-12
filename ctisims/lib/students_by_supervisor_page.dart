import 'package:flutter/material.dart';
import 'package:ctisims/db_helper.dart';
import 'package:ctisims/themes/Theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class StudentsBySupervisorPage extends StatefulWidget {
  const StudentsBySupervisorPage({Key? key}) : super(key: key);

  @override
  State<StudentsBySupervisorPage> createState() =>
      _StudentsBySupervisorPageState();
}

class _StudentsBySupervisorPageState extends State<StudentsBySupervisorPage> {
  String? _selectedSupervisorId;
  String? _selectedSupervisorName;
  List<Map<String, dynamic>> _supervisors = [];
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = false;
  bool _isFetchingSupervisors = true;
  Set<String> _favoriteStudentIds = {};
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _fetchSupervisors();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesList = prefs.getStringList('favorite_students') ?? [];
    setState(() {
      _favoriteStudentIds = favoritesList.toSet();
    });
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'favorite_students',
      _favoriteStudentIds.toList(),
    );
  }

  void _toggleFavorite(String studentId) {
    setState(() {
      if (_favoriteStudentIds.contains(studentId)) {
        _favoriteStudentIds.remove(studentId);
      } else {
        _favoriteStudentIds.add(studentId);
      }
    });
    _saveFavorites();
  }

  Future<void> _fetchSupervisors() async {
    setState(() {
      _isFetchingSupervisors = true;
    });

    try {
      // Fetch supervisors directly from Firebase
      final supervisorsSnapshot =
          await FirebaseFirestore.instance
              .collection('User')
              .where('role', isEqualTo: 'Supervisor')
              .get();

      List<Map<String, dynamic>> supervisors = [];

      // If there are no explicit supervisor roles, fetch teachers or default ones
      if (supervisorsSnapshot.docs.isEmpty) {
        // Default supervisors if no data found
        supervisors = [
          {'id': '1', 'name': 'Neşe Şahin Özçelik'},
          {'id': '2', 'name': 'Serkan Genç'},
          {'id': '3', 'name': 'Erkan Uçar'},
        ];
      } else {
        supervisors =
            supervisorsSnapshot.docs
                .map(
                  (doc) => {
                    'id': doc.id,
                    'name': doc.data()['name'] ?? 'Unknown',
                    'bilkentId': doc.data()['bilkentId'] ?? doc.id,
                    ...doc.data() as Map<String, dynamic>,
                  },
                )
                .toList();
      }

      setState(() {
        _supervisors = supervisors;
        _isFetchingSupervisors = false;
      });
    } catch (e) {
      setState(() {
        // Fallback to default supervisors if there's an error
        _supervisors = [
          {'id': '1', 'name': 'Neşe Şahin Özçelik'},
          {'id': '2', 'name': 'Serkan Genç'},
          {'id': '3', 'name': 'Erkan Uçar'},
        ];
        _isFetchingSupervisors = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching supervisors: $e')));
    }
  }

  // Generate and export Excel file
  Future<void> _exportToExcel() async {
    if (_students.isEmpty || _selectedSupervisorName == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No students to export')));
      return;
    }

    setState(() {
      _isExporting = true;
    });

    try {
      // Create Excel object
      final excel = Excel.createExcel();
      final sheet = excel['Students by Supervisor'];

      // Add header row
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
        ..value = TextCellValue('Student Name')
        ..cellStyle = CellStyle(bold: true);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0))
        ..value = TextCellValue('Bilkent ID')
        ..cellStyle = CellStyle(bold: true);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 0))
        ..value = TextCellValue('Email')
        ..cellStyle = CellStyle(bold: true);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0))
        ..value = TextCellValue('Supervisor')
        ..cellStyle = CellStyle(bold: true);

      // Add data rows
      for (int i = 0; i < _students.length; i++) {
        final student = _students[i];
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i + 1))
          ..value = TextCellValue(student['name'] ?? 'Unknown');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i + 1))
          ..value = TextCellValue(student['bilkentId']?.toString() ?? '');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: i + 1))
          ..value = TextCellValue(student['email']?.toString() ?? '');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: i + 1))
          ..value = TextCellValue(_selectedSupervisorName!);
      }

      // Auto fit columns
      for (int i = 0; i < 4; i++) {
        sheet.setColumnWidth(i, 25);
      }

      // Generate the Excel file as bytes
      final bytes = excel.encode();

      if (bytes == null) {
        throw Exception('Failed to generate Excel file');
      }

      final fileName =
          'Students_${_selectedSupervisorName?.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.xlsx';

      if (kIsWeb) {
        // For web platform
        final blob = html.Blob([Uint8List.fromList(bytes)]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor =
            html.AnchorElement(href: url)
              ..setAttribute('download', fileName)
              ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        // For mobile platform
        final directory = await getApplicationDocumentsDirectory();
        final path = '${directory.path}/$fileName';
        final file = File(path);
        await file.writeAsBytes(bytes);

        // Show path where file is saved
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('File saved to: $path')));
      }

      // Show success message
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export successful: $fileName')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(title: const Text('Students by Supervisor')),
      body:
          _isFetchingSupervisors
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select a Supervisor',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Supervisor',
                                border: OutlineInputBorder(),
                              ),
                              value: _selectedSupervisorId,
                              items:
                                  _supervisors
                                      .map(
                                        (supervisor) => DropdownMenuItem(
                                          value: supervisor['id'] as String,
                                          child: Text(
                                            supervisor['name'] as String,
                                          ),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedSupervisorId = value;
                                  if (value != null) {
                                    final supervisor = _supervisors.firstWhere(
                                      (s) => s['id'] == value,
                                      orElse: () => {'name': 'Unknown'},
                                    );
                                    _selectedSupervisorName =
                                        supervisor['name'] as String;
                                  }
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                                onPressed:
                                    _selectedSupervisorId == null
                                        ? null
                                        : _fetchStudentsBySupervisor,
                                child: const Text('View Students'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (_students.isNotEmpty)
                      Expanded(
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Students List',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Total: ${_students.length}',
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (_selectedSupervisorName != null)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 16.0,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Supervisor: $_selectedSupervisorName',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleSmall?.copyWith(
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: _students.length,
                                    itemBuilder: (context, index) {
                                      final student = _students[index];
                                      final studentId =
                                          student['bilkentId'] as String;
                                      final isFavorite = _favoriteStudentIds
                                          .contains(studentId);

                                      return Card(
                                        margin: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: Colors.blue,
                                            child: Text(
                                              student['name']
                                                  .toString()
                                                  .substring(0, 1)
                                                  .toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          title: Text(
                                            student['name'] ?? 'Unknown Name',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'ID: ${student['bilkentId'] ?? 'Unknown ID'}',
                                              ),
                                              Text(
                                                'Email: ${student['email'] ?? 'No email'}',
                                              ),
                                              Text(
                                                'Supervisor: $_selectedSupervisorName',
                                              ),
                                            ],
                                          ),
                                          isThreeLine: true,
                                          trailing: IconButton(
                                            icon: Icon(
                                              isFavorite
                                                  ? Icons.star
                                                  : Icons.star_border,
                                              color:
                                                  isFavorite
                                                      ? Colors.amber
                                                      : null,
                                            ),
                                            onPressed:
                                                () =>
                                                    _toggleFavorite(studentId),
                                            tooltip:
                                                isFavorite
                                                    ? 'Remove from Favorites'
                                                    : 'Add to Favorites',
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else if (_selectedSupervisorId != null)
                      Center(
                        child: Text(
                          'No students found for this supervisor',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                  ],
                ),
              ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_students.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: FloatingActionButton.extended(
                heroTag: 'excelButton',
                onPressed: _isExporting ? null : _exportToExcel,
                backgroundColor: Colors.green,
                icon:
                    _isExporting
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Icon(Icons.file_download),
                label: const Text('Excel İndir'),
              ),
            ),
          if (_favoriteStudentIds.isNotEmpty)
            FloatingActionButton.extended(
              heroTag: 'favoritesButton',
              onPressed: _showFavorites,
              backgroundColor: Colors.amber,
              icon: const Icon(Icons.star),
              label: const Text('Favoriler'),
            ),
        ],
      ),
    );
  }

  void _showFavorites() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Favorite Students'),
          content: SizedBox(
            width: double.maxFinite,
            child:
                _favoriteStudentIds.isEmpty
                    ? const Text('No favorite students yet')
                    : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _favoriteStudentIds.length,
                      itemBuilder: (context, index) {
                        final studentId = _favoriteStudentIds.elementAt(index);
                        // Find student in current list if available
                        final student = _students.firstWhere(
                          (s) => s['bilkentId'] == studentId,
                          orElse:
                              () => {
                                'name': 'Unknown Student',
                                'bilkentId': studentId,
                              },
                        );

                        return ListTile(
                          title: Text(student['name'] ?? 'Unknown Student'),
                          subtitle: Text('ID: $studentId'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              _toggleFavorite(studentId);
                              Navigator.pop(context);
                              _showFavorites(); // Reopen with updated list
                            },
                          ),
                        );
                      },
                    ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _fetchStudentsBySupervisor() async {
    if (_selectedSupervisorId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Directly fetch students from Firebase instead of using DBHelper
      final QuerySnapshot studentsSnapshot =
          await FirebaseFirestore.instance
              .collection('User')
              .where('role', isEqualTo: 'Student')
              .where('supervisorId', isEqualTo: _selectedSupervisorId)
              .get();

      List<Map<String, dynamic>> students = [];

      if (studentsSnapshot.docs.isNotEmpty) {
        students =
            studentsSnapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return {
                'id': doc.id,
                'name': data['name'] ?? 'Unknown',
                'bilkentId': data['bilkentId'] ?? doc.id,
                'email': data['email'] ?? '',
                ...data,
              };
            }).toList();
      }

      setState(() {
        _students = students;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching students: $e')));
    }
  }
}
