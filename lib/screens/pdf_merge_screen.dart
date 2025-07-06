import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/pdf_service.dart';

class PdfMergeScreen extends StatefulWidget {
  const PdfMergeScreen({super.key});

  @override
  State<PdfMergeScreen> createState() => _PdfMergeScreenState();
}

class _PdfMergeScreenState extends State<PdfMergeScreen> {
  final PdfService _pdfService = PdfService();
  List<File> _selectedPdfs = [];
  bool _loading = false;
  String? _resultPath;

  Future<void> _pickPdfs() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true, type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null) {
      setState(() {
        _selectedPdfs = result.paths.map((p) => File(p!)).toList();
      });
    }
  }

  Future<void> _mergePdfs() async {
    if (_selectedPdfs.isEmpty) return;
    setState(() => _loading = true);
    try {
      final merged = await _pdfService.mergePdfs(_selectedPdfs, 'merged_output');
      setState(() {
        _resultPath = merged.path;
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Merged PDF saved: ${merged.path}')));
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to merge PDFs')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PDF Merge')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _pickPdfs,
              icon: const Icon(Icons.file_open),
              label: const Text('Pick PDFs'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _selectedPdfs.isEmpty
                  ? const Center(child: Text('No PDFs selected'))
                  : ListView.builder(
                      itemCount: _selectedPdfs.length,
                      itemBuilder: (context, i) => ListTile(
                        leading: const Icon(Icons.picture_as_pdf),
                        title: Text(_selectedPdfs[i].path.split('/').last),
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            if (_loading) const CircularProgressIndicator(),
            if (!_loading && _selectedPdfs.isNotEmpty)
              ElevatedButton.icon(
                onPressed: _mergePdfs,
                icon: const Icon(Icons.merge_type),
                label: const Text('Merge PDFs'),
              ),
            if (_resultPath != null)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text('Merged PDF: $_resultPath'),
              ),
          ],
        ),
      ),
    );
  }
}
