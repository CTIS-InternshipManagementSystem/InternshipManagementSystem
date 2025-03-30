import 'package:ctisims/dbHelper.dart';
import 'package:ctisims/local_db_helper.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'firebase_options.dart'; // flutterfire configure ile oluşturulan dosya
import 'login_page.dart';
import 'home_page.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite
  if (!kIsWeb) {
    sqfliteFfiInit();
  }

  // Initialize local database
  try {
    await LocalDBHelper.instance.database;
    // Populate with example data if needed
    await LocalDBHelper.instance.populateWithExampleData();
    debugPrint("SQLite initialized successfully");
  } catch (e) {
    debugPrint("Error initializing SQLite: $e");
  }

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("Firebase initialized successfully");
  } catch (e) {
    debugPrint("Error initializing Firebase: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomePageModel(),
      child: MaterialApp(
        title: 'CTIS IMS',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const LoginPage(),
      ),
    );
  }
}
