import 'package:flutter/material.dart';
import 'services/user_service.dart';
import 'submission_detail_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:html' as html;

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _bilkentIdController = TextEditingController();
  final UserService _userService = UserService();
  Map<String, dynamic>? _studentInfo;

  Future<void> _searchStudent() async {
    final bilkentId = _bilkentIdController.text;
    final studentInfo = await _userService.getStudentInfo(bilkentId);
    setState(() {
      _studentInfo = studentInfo;
    });
    if (studentInfo != null) {
      print('Student found: ${studentInfo['name']}');
    } else {
      print('Student not found');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _bilkentIdController,
              decoration: const InputDecoration(
                labelText: 'Bilkent ID',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _searchStudent,
              child: const Text('Search Student'),
            ),
            const SizedBox(height: 16),
            if (_studentInfo != null) ...[
              Text('Name: ${_studentInfo!['name']}'),
              Text('Bilkent ID: ${_studentInfo!['bilkentId']}'),
              Text('Email: ${_studentInfo!['email']}'),
              const SizedBox(height: 16),
              Text('Active Courses:'),
              ..._studentInfo!['activeCourses'].map<Widget>((course) {
                return Text('Course ID: ${course['courseId']}');
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }
}
