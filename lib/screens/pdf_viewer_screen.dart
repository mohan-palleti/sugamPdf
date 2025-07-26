import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class PdfViewerScreen extends StatefulWidget {
  const PdfViewerScreen({super.key});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  List<File> _pdfFiles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPdfFiles();
  }

  Future<void> _loadPdfFiles() async {
    if (await Permission.storage.request().isGranted) {
      final directory = await getExternalStorageDirectory();
      if (directory != null) {
        final files = directory.listSync(recursive: true, followLinks: false);
        setState(() {
          _pdfFiles = files
              .where((file) => file.path.toLowerCase().endsWith('.pdf'))
              .map((file) => File(file.path))
              .toList();
          _loading = false;
        });
      }
    } else {
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Storage permission denied')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PDF Viewer')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _pdfFiles.isEmpty
              ? const Center(child: Text('No PDF files found.'))
              : ListView.builder(
                  itemCount: _pdfFiles.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(_pdfFiles[index].path.split('/').last),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                PdfDisplayScreen(pdfFile: _pdfFiles[index]),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}

class PdfDisplayScreen extends StatelessWidget {
  final File pdfFile;

  const PdfDisplayScreen({super.key, required this.pdfFile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(pdfFile.path.split('/').last)),
      body: PDFView(
        filePath: pdfFile.path,
      ),
    );
  }
}
