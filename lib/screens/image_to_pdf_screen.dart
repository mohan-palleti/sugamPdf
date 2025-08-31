import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/pdf_service.dart';
import '../services/permissions_service.dart';
import '../services/utilities.dart';
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'image_editor_screen.dart';

class ImageToPdfScreen extends StatefulWidget {
  const ImageToPdfScreen({super.key});

  @override
  State<ImageToPdfScreen> createState() => _ImageToPdfScreenState();
}

class _ImageToPdfScreenState extends State<ImageToPdfScreen> {
  final PdfService _pdfService = PdfService();
  List<File> _images = [];
  bool _loading = false;
  String? _resultPath;
  PdfPageFormat _pageFormat = PdfPageFormat.a4;
  // Per-image adjustment metadata (in-memory only for preview before conversion)
  final Map<String, int> _rotation = {}; // degrees (0,90,180,270)
  final Set<String> _grayscale = {}; // paths marked grayscale

  void _toggleGray(String path) {
    setState(() {
      if (_grayscale.contains(path)) {
        _grayscale.remove(path);
      } else {
        _grayscale.add(path);
      }
    });
  }

  void _rotateCW(String path) {
    setState(() {
      final cur = _rotation[path] ?? 0;
      _rotation[path] = (cur + 90) % 360;
    });
  }

  String _fmtSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    if (mb < 1024) return '${mb.toStringAsFixed(2)} MB';
    final gb = mb / 1024;
    return '${gb.toStringAsFixed(2)} GB';
  }

  Future<void> _pickImages() async {
    final hasPermission = await PermissionsService.requestStoragePermission(context);
    if (hasPermission) {
      final picker = ImagePicker();
      final picked = await picker.pickMultiImage();
      if (picked.isNotEmpty) {
        setState(() {
          _images = picked.map((x) => File(x.path)).toList();
        });
      }
    }
    // Permission dialog is already handled by PermissionsService
  }

  Future<void> _convertToPdf() async {
    if (_images.isEmpty) return;
    String? pdfName = await showDialog<String>(
      context: context,
      builder: (context) {
        String tempName = '';
        return AlertDialog(
          title: const Text('Enter PDF Name'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(hintText: 'PDF name'),
            onChanged: (val) => tempName = val,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, tempName.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (pdfName == null || pdfName.isEmpty) return;
    setState(() => _loading = true);
    try {
      // Use app's external files directory (Play Store-safe)
      final extDir = await getExternalStorageDirectory();
      final sugamDir = Directory('${extDir!.path}/SugamPDF');
      if (!await sugamDir.exists()) {
        await sugamDir.create(recursive: true);
      }
  final savePath = '${sugamDir.path}/$pdfName.pdf';
  appLog('Saving PDF to: $savePath');
  final pdf = await _pdfService.imagesToPdf(_images, savePath, pageFormat: _pageFormat);
      setState(() {
        _resultPath = pdf.path;
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF saved: ${pdf.path}'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 1),
        ),
      );
      }
      // Add a small delay before navigating to home screen
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e, st) {
      appLog('Image to PDF conversion failed', error: e, stackTrace: st);
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to convert images')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Image to PDF')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.image),
              label: const Text('Pick Images'),
            ),
            const SizedBox(height: 16),
            DropdownButton<PdfPageFormat>(
              value: _pageFormat,
              items: const [
                DropdownMenuItem(value: PdfPageFormat.a3, child: Text('A3')),
                DropdownMenuItem(value: PdfPageFormat.a4, child: Text('A4')),
                DropdownMenuItem(value: PdfPageFormat.a5, child: Text('A5')),
              ],
              onChanged: (v) => setState(() => _pageFormat = v!),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _images.isEmpty
                  ? const Center(child: Text('No images selected'))
                  : ReorderableListView.builder(
                      buildDefaultDragHandles: false,
                      itemCount: _images.length,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) newIndex -= 1;
                          final item = _images.removeAt(oldIndex);
                          _images.insert(newIndex, item);
                        });
                      },
                      itemBuilder: (context, i) {
                        final file = _images[i];
                        final name = file.path.split('/').last;
                        final path = file.path;
                        final rot = _rotation[path] ?? 0;
                        final isGray = _grayscale.contains(path);
                        return Dismissible(
                          key: ValueKey(file.path),
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) => setState(() => _images.removeAt(i)),
                          child: ListTile(
                            leading: GestureDetector(
                              onTap: () async {
                                final editedPath = await Navigator.push<String>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ImageEditorScreen(imagePath: path),
                                  ),
                                );
                                if (editedPath != null) {
                                  setState(() {
                                    _images[i] = File(editedPath);
                                  });
                                }
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Transform.rotate(
                                  angle: rot * 3.1415926535897932 / 180,
                                  child: ColorFiltered(
                                    colorFilter: isGray
                                        ? const ColorFilter.matrix([
                                            0.2126, 0.7152, 0.0722, 0, 0,
                                            0.2126, 0.7152, 0.0722, 0, 0,
                                            0.2126, 0.7152, 0.0722, 0, 0,
                                            0, 0, 0, 1, 0,
                                          ])
                                        : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
                                    child: Image.file(file, width: 50, height: 50, fit: BoxFit.cover),
                                  ),
                                ),
                              ),
                            ),
                            title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text('${_fmtSize(file.lengthSync())}\n${rot == 0 ? '' : 'Rot: $rot° '}${isGray ? 'Grayscale' : ''}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Rotate 90°',
                                  icon: const Icon(Icons.rotate_90_degrees_cw, size: 20),
                                  onPressed: () => _rotateCW(path),
                                ),
                                IconButton(
                                  tooltip: isGray ? 'Remove grayscale' : 'Apply grayscale',
                                  icon: Icon(isGray ? Icons.filter_b_and_w : Icons.filter_alt_outlined, size: 20),
                                  onPressed: () => _toggleGray(path),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  tooltip: 'Edit',
                                  onPressed: () async {
                                    final editedPath = await Navigator.push<String>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ImageEditorScreen(imagePath: path),
                                      ),
                                    );
                                    if (editedPath != null) {
                                      setState(() => _images[i] = File(editedPath));
                                    }
                                  },
                                ),
                                ReorderableDragStartListener(
                                  index: i,
                                  child: const Icon(Icons.drag_indicator),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            if (_loading) const CircularProgressIndicator(),
            if (!_loading && _images.isNotEmpty)
              ElevatedButton.icon(
                onPressed: _convertToPdf,
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Convert to PDF'),
              ),
            if (_resultPath != null)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Row(
                  children: [
                    Expanded(child: Text('PDF: $_resultPath')),
                    IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: () async {
                        if (_resultPath != null) {
                          // Use share_plus or similar package for sharing
                          // Uncomment the following after adding share_plus to pubspec.yaml
                          // await Share.shareFiles([_resultPath!], text: 'Here is your PDF!');
                        }
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
