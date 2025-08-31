import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../services/pdf_service.dart';
import '../services/permissions_service.dart';
import 'home_screen.dart';
import 'image_editor_screen.dart';

class CameraToPdfScreen extends StatefulWidget {
  const CameraToPdfScreen({super.key});

  @override
  State<CameraToPdfScreen> createState() => _CameraToPdfScreenState();
}

class _CameraToPdfScreenState extends State<CameraToPdfScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  final List<XFile> _capturedImages = [];
  bool _isCameraInitialized = false;
  bool _isCreatingPdf = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final hasPermission = await PermissionsService.requestCameraPermission(context);
    if (hasPermission) {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _controller = CameraController(
          _cameras!.first,
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _controller!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _captureImage() async {
    if (!_controller!.value.isInitialized || _controller!.value.isTakingPicture) {
      return;
    }
    try {
      final image = await _controller!.takePicture();
      setState(() {
        _capturedImages.add(image);
      });
    } on CameraException catch (e) {
      _showErrorDialog('Error capturing image: ${e.description}');
    }
  }

  void _showErrorDialog(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _createPdf() async {
    if (_capturedImages.isEmpty) {
      _showErrorDialog('Please capture at least one image.');
      return;
    }

    setState(() {
      _isCreatingPdf = true;
    });

    try {
      final pdfService = PdfService();
      final imagesAsFiles = _capturedImages.map((xfile) => File(xfile.path)).toList();
      
      String? fileName = await _showFileNameDialog();
      if (fileName == null || fileName.isEmpty) {
        setState(() => _isCreatingPdf = false);
        return;
      }

      final downloadsDir = await getExternalStoragePublicDirectory(fileName);
      final finalPath = '${downloadsDir.path}/$fileName.pdf';

      await pdfService.createPdfFromImages(imagesAsFiles, finalPath);
      if (!mounted) return; 
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF saved successfully at $finalPath')),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      _showErrorDialog('Error creating PDF: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingPdf = false;
        });
      }
    }
  }

  Future<String?> _showFileNameDialog() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter PDF Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "e.g., my-document"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
  
  Future<Directory> getExternalStoragePublicDirectory(String folderName) async {
    final directory = await getExternalStorageDirectory();
    final downloadsPath = '${directory?.path}/downloads';
    final newDir = Directory(downloadsPath);
    if (!await newDir.exists()) {
      await newDir.create(recursive: true);
    }
    return newDir;
  }

  void _removeImage(int index) {
    setState(() {
      _capturedImages.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera to PDF'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _capturedImages.isNotEmpty ? _createPdf : null,
            tooltip: 'Create PDF',
          ),
        ],
      ),
      body: _isCreatingPdf
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Creating PDF...'),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildCameraPreview(),
                ),
                Expanded(
                  flex: 1,
                  child: _buildGallery(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _captureImage,
        child: const Icon(Icons.camera_alt),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Container(height: 50.0),
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (!_isCameraInitialized || _controller == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(20),
        bottomRight: Radius.circular(20),
      ),
      child: CameraPreview(_controller!),
    );
  }

  Future<void> _editImage(int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageEditorScreen(
          imagePath: _capturedImages[index].path,
        ),
      ),
    );
    
    if (result != null && result is String) {
      setState(() {
        _capturedImages[index] = XFile(result);
      });
    }
  }

  Widget _buildGallery() {
    if (_capturedImages.isEmpty) {
      return const Center(child: Text('Captured images will appear here.'));
    }
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: _capturedImages.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Stack(
            children: [
              // Image preview
              GestureDetector(
                onTap: () => _editImage(index),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(_capturedImages[index].path),
                    width: 100,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Delete button
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => _removeImage(index),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ),
              ),
              // Edit button
              Positioned(
                bottom: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => _editImage(index),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
