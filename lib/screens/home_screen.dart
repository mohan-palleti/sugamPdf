import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'pdf_viewer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<File> _pdfFiles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPdfFiles();
  }

  Future<void> _loadPdfFiles() async {
    try {
      final extDir = await getExternalStorageDirectory();
      final sugamDir = Directory('${extDir!.path}/SugamPDF');
      
      if (await sugamDir.exists()) {
        final files = sugamDir.listSync(recursive: true, followLinks: false);
        setState(() {
          _pdfFiles = files
              .where((file) => file.path.toLowerCase().endsWith('.pdf'))
              .map((file) => File(file.path))
              .toList();
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      print('Error loading PDFs: $e');
      setState(() => _loading = false);
    }
  }

  void _openPdf(File pdfFile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfDisplayScreen(pdfFile: pdfFile),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Utility Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _loading = true);
              _loadPdfFiles();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Feature tiles section
          Container(
            padding: const EdgeInsets.only(top: 16),
            height: 200,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                _FeatureTile(title: 'PDF Merge', icon: Icons.merge_type, route: '/pdf-merge'),
                _FeatureTile(title: 'Image to PDF', icon: Icons.image, route: '/image-to-pdf'),
                _FeatureTile(title: 'Camera to PDF', icon: Icons.camera_alt, route: '/camera-to-pdf'),
                _FeatureTile(title: 'PDF Viewer', icon: Icons.picture_as_pdf, route: '/pdf-viewer'),
                _FeatureTile(title: 'File Manager', icon: Icons.folder, route: '/file-manager'),
              ],
            ),
          ),
          
          // Recent PDFs section
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Your PDFs",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          // PDFs grid view
          Expanded(
            child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _pdfFiles.isEmpty
                ? const Center(child: Text('No PDFs found. Create one!'))
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: _pdfFiles.length,
                    itemBuilder: (context, index) {
                      final file = _pdfFiles[index];
                      final fileName = file.path.split('/').last;
                      return InkWell(
                        onTap: () => _openPdf(file),
                        child: Card(
                          margin: const EdgeInsets.all(8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              PdfThumbnail(
                                pdfPath: file.path,
                                width: 100,
                                height: 120,
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                                  fileName,
                                  style: const TextStyle(fontSize: 12),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final String route;
  const _FeatureTile({required this.title, required this.icon, required this.route});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Card(
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, route),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 42, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PdfThumbnail extends StatefulWidget {
  final String pdfPath;
  final double width;
  final double height;

  const PdfThumbnail({
    super.key,
    required this.pdfPath,
    this.width = 100,
    this.height = 120,
  });

  @override
  State<PdfThumbnail> createState() => _PdfThumbnailState();
}

class _PdfThumbnailState extends State<PdfThumbnail> {
  PdfDocument? _document;
  PdfPage? _page;
  PdfPageImage? _pageImage;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  @override
  void dispose() {
    _page?.close();
    _document?.close();
    super.dispose();
  }

  Future<void> _loadThumbnail() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      _document = await PdfDocument.openFile(widget.pdfPath);
      _page = await _document!.getPage(1); // Get the first page
      _pageImage = await _page!.render(
        width: widget.width * 2,
        height: widget.height * 2,
      );
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading PDF thumbnail: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_hasError || _pageImage == null) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        child: const Icon(
          Icons.picture_as_pdf,
          size: 50,
          color: Colors.red,
        ),
      );
    }

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
      child: Image(
        image: MemoryImage(_pageImage!.bytes),
        fit: BoxFit.cover,
        width: widget.width,
        height: widget.height,
      ),
    );
  }
}
