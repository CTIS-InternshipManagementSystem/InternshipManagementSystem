import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

class DragDropFilePicker extends StatefulWidget {
  final Function(String? filePath, Uint8List? fileBytes) onFileSelected;
  final Color? primaryColor;
  final Color? textColor;
  final String acceptedFileTypes;
  final String instructionText;
  
  const DragDropFilePicker({
    Key? key, 
    required this.onFileSelected,
    this.primaryColor = Colors.blue,
    this.textColor,
    this.acceptedFileTypes = '.pdf,.doc,.docx,.xlsx',
    this.instructionText = 'Drag & drop file or click to select',
  }) : super(key: key);

  @override
  _DragDropFilePickerState createState() => _DragDropFilePickerState();
}

class _DragDropFilePickerState extends State<DragDropFilePicker> with SingleTickerProviderStateMixin {
  late DropzoneViewController controller;
  String? _fileName;
  bool _isHighlighted = false;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.textColor ?? Theme.of(context).textTheme.bodyLarge?.color;
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _isHighlighted ? _pulseAnimation.value : 1.0,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              color: _isHighlighted 
                ? widget.primaryColor!.withOpacity(0.1) 
                : widget.primaryColor!.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isHighlighted 
                  ? widget.primaryColor! 
                  : widget.primaryColor!.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Stack(
              children: [
                if (kIsWeb)
                  DropzoneView(
                    onCreated: (controller) => this.controller = controller,
                    onDrop: _onDrop,
                    onHover: () => setState(() => _isHighlighted = true),
                    onLeave: () => setState(() => _isHighlighted = false),
                    onLoaded: () => print('Zone loaded'),
                    onError: (err) => print('DropzoneError: $err'),
                  ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _fileName != null ? Icons.check_circle : Icons.cloud_upload,
                        color: widget.primaryColor,
                        size: 50,
                      ),
                      const SizedBox(height: 12),
                      if (_fileName != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Selected: $_fileName',
                            style: TextStyle(color: textColor),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      else
                        Text(widget.instructionText, style: TextStyle(color: textColor)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.attach_file),
                        label: const Text('Select File'),
                        onPressed: _pickFile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _onDrop(dynamic event) async {
    setState(() => _isHighlighted = false);
    
    final name = event.name;
    final mime = await controller.getFileMIME(event);
    final bytes = await controller.getFileData(event);
    final size = await controller.getFileSize(event);
    
    print('Name: $name, MIME: $mime, Size: $size bytes');
    
    setState(() => _fileName = name);
    widget.onFileSelected(name, bytes);
  }

  Future<void> _pickFile() async {
    try {
      if (kIsWeb) {
        FilePickerResult? result = await FilePicker.platform.pickFiles();
        if (result != null) {
          final file = result.files.first;
          setState(() => _fileName = file.name);
          widget.onFileSelected(file.name, file.bytes);
        }
      } else {
        FilePickerResult? result = await FilePicker.platform.pickFiles();
        if (result != null) {
          final file = result.files.first;
          setState(() => _fileName = file.name);
          widget.onFileSelected(file.path, null);
        }
      }
    } catch (e) {
      print('Error picking file: $e');
    }
  }
} 