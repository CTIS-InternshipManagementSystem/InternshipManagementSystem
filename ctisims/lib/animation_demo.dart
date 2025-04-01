import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'themes/Theme_provider.dart';
import 'animated_button.dart';
import 'animated_loader.dart';
import 'drag_drop_file_picker.dart';

class AnimationDemoPage extends StatefulWidget {
  const AnimationDemoPage({Key? key}) : super(key: key);

  @override
  _AnimationDemoPageState createState() => _AnimationDemoPageState();
}

class _AnimationDemoPageState extends State<AnimationDemoPage> {
  bool _isLoading = false;
  bool _isSuccess = false;
  double _progressValue = 0.0;
  Timer? _progressTimer;
  String? _filePath;
  Uint8List? _fileBytes;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  void _simulateLoading() {
    setState(() {
      _isLoading = true;
      _isSuccess = false;
      _progressValue = 0.0;
    });

    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _progressValue += 0.01;
        if (_progressValue >= 1.0) {
          _progressValue = 1.0;
          _isLoading = false;
          _isSuccess = true;
          timer.cancel();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Animation Showcase'),
        actions: [
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
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Button Animations',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        alignment: WrapAlignment.center,
                        children: [
                          AnimatedButton(
                            label: 'Scale Button',
                            icon: Icons.touch_app,
                            onPressed: () {},
                            animationType: AnimationType.scale,
                            color: Colors.orange,
                          ),
                          AnimatedButton(
                            label: 'Bounce Button',
                            icon: Icons.holiday_village,
                            onPressed: () {},
                            animationType: AnimationType.bounce,
                            color: Colors.purple,
                          ),
                          AnimatedButton(
                            label: 'Pulse Button',
                            icon: Icons.favorite,
                            onPressed: () {},
                            animationType: AnimationType.pulse,
                            color: Colors.red,
                          ),
                          AnimatedButton(
                            label: 'Glow Button',
                            icon: Icons.lightbulb,
                            onPressed: () {},
                            animationType: AnimationType.glow,
                            color: Colors.teal,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Loading & Progress',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedLoader(
                                color: Colors.orange,
                                size: 60,
                                message: "Loading...",
                              ),
                              const SizedBox(width: 40),
                              AnimatedButton(
                                label: _isSuccess ? 'Success!' : (_isLoading ? 'Loading...' : 'Start Loading'),
                                onPressed: _simulateLoading,
                                isLoading: _isLoading,
                                isSuccess: _isSuccess,
                                color: Colors.blue,
                                animationType: AnimationType.scale,
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          AnimatedProgressIndicator(
                            value: _progressValue,
                            label: 'Upload Progress',
                            valueColor: Colors.orange,
                            showSuccess: _isSuccess,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Drag & Drop File Upload',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 24),
                    DragDropFilePicker(
                      primaryColor: Colors.orange,
                      textColor: isDark ? Colors.white : Colors.black87,
                      onFileSelected: (path, bytes) {
                        setState(() {
                          _filePath = path;
                          _fileBytes = bytes;
                          _simulateLoading();
                        });
                      },
                    ),
                    if (_filePath != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Text(
                          'Selected file: $_filePath',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 