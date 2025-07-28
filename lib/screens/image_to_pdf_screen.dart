import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/pdf_service.dart';
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';

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

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    setState(() {
      _images = picked.map((x) => File(x.path)).toList();
    });
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
      print('Saving PDF to: $savePath');
      final pdf = await _pdfService.imagesToPdf(_images, savePath, pageFormat: _pageFormat);
      setState(() {
        _resultPath = pdf.path;
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF saved: ${pdf.path}'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          duration: const Duration(seconds: 1),
        ),
      );
      // Add a small delay before navigating to home screen
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      print(e);
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to convert images')));
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
                DropdownMenuItem(child: Text('A3'), value: PdfPageFormat.a3),
                DropdownMenuItem(child: Text('A4'), value: PdfPageFormat.a4),
                DropdownMenuItem(child: Text('A5'), value: PdfPageFormat.a5),
              ],
              onChanged: (v) => setState(() => _pageFormat = v!),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _images.isEmpty
                  ? const Center(child: Text('No images selected'))
                  : ListView.builder(
                      itemCount: _images.length,
                      itemBuilder: (context, i) => ListTile(
                        leading: Image.file(_images[i], width: 40, height: 40, fit: BoxFit.cover),
                        title: Text(_images[i].path.split('/').last),
                      ),
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
