import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Internship Management System',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // Uygulama açıldığında önce AuthWrapper çalışır
      home: const AuthWrapper(),
      routes: {
        '/homePage': (context) => const MyHomePage(title: 'Home Page'),
        '/login': (context) => const LoginPage(),
      },
    );
  }
}

/// Kullanıcının oturum durumunu dinleyip, giriş yapmışsa HomePage,
/// yapmamışsa LoginPage yönlendirmesi yapan ara sayfa.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Bağlantı kuruluyorsa yükleniyor ekranı göster
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // Kullanıcı oturumu varsa HomePage'e yönlendir
        if (snapshot.hasData) {
          return const MyHomePage(title: 'Home Page');
        }
        // Kullanıcı oturumu yoksa LoginPage'e yönlendir
        return const LoginPage();
      },
    );
  }
}

/// Örnek Login Page
class LoginPage extends StatelessWidget {
  const LoginPage({Key? key}) : super(key: key);

  /// Örnek olarak anonim giriş işlemi
  Future<void> _signInAnonymously(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Giriş yapılamadı: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login Page'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _signInAnonymously(context),
          child: const Text('Anonim Giriş Yap'),
        ),
      ),
    );
  }
}

/// Örnek Home Page
class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  /// Çıkış yapma işlemi
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Butona kaç kere bastığınız:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Arttır',
        child: const Icon(Icons.add),
      ),
    );
  }
}
