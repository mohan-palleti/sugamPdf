import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/pdf_service.dart';
import 'package:pdf/pdf.dart';

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
    setState(() => _loading = true);
    try {
      final pdf = await _pdfService.imagesToPdf(_images, 'images_to_pdf', pageFormat: _pageFormat);
      setState(() {
        _resultPath = pdf.path;
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF saved: ${pdf.path}')));
    } catch (e) {
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
                child: Text('PDF: $_resultPath'),
              ),
          ],
        ),
      ),
    );
  }
}
