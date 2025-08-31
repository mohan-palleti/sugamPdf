import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'pdf_viewer_screen.dart';
import '../services/utilities.dart';
import '../services/permissions_service.dart';

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
    setState(() => _loading = true);
    try {
      final hasPermission = await PermissionsService.requestStoragePermission(context);
      if (!hasPermission) {
        setState(() => _loading = false);
        return;
      }
      Directory? dir;
      if (Platform.isAndroid) {
        dir = await getExternalStorageDirectory();
      } else {
        dir = await getApplicationDocumentsDirectory();
      }
      if (dir == null) {
        setState(() => _loading = false);
        return;
      }
      final files = dir
          .listSync(recursive: true, followLinks: false)
          .where((f) => f.path.toLowerCase().endsWith('.pdf'))
          .map((e) => File(e.path))
          .toList();
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      if (mounted) {
        setState(() {
          _pdfFiles = files;
          _loading = false;
        });
      }
    } catch (e, st) {
      appLog('Failed loading PDFs', error: e, stackTrace: st);
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refresh() => _loadPdfFiles();

  void _openPdf(File file) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PdfDisplayScreen(pdfFile: file)),
    );
  }

  void _showPdfActions(File file) {
    final fileName = file.path.split('/').last;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility),
              title: Text('Open "$fileName"'),
              onTap: () {
                Navigator.pop(ctx);
                _openPdf(file);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_note),
              title: const Text('Page operations'),
              subtitle: const Text('Reorder, delete, rotate pages'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, '/page_ops', arguments: {'pdfPath': file.path});
              },
            ),
            ListTile(
              leading: const Icon(Icons.compress),
              title: const Text('Compress'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, '/compress', arguments: {'pdfPath': file.path});
              },
            ),
            ListTile(
              leading: const Icon(Icons.call_split),
              title: const Text('Split'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, '/split', arguments: {'pdfPath': file.path});
              },
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCompressTap() async => _selectPdfAndNavigate('/compress');
  Future<void> _handleSplitTap() async => _selectPdfAndNavigate('/split');

  Future<void> _selectPdfAndNavigate(String route) async {
    if(!mounted) return;
    if (_loading) {
      _showSnack('Still loading PDFs...');
      return;
    }
    if (_pdfFiles.isEmpty) {
      await _loadPdfFiles();
      if (_pdfFiles.isEmpty) {
        _showSnack('No PDFs available. Create or import one first.');
        return;
      }
    }

    final selected = await showModalBottomSheet<File?>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: 340,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  'Select PDF to ${route == '/compress' ? 'compress' : 'split'}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: _pdfFiles.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (c, i) {
                    final f = _pdfFiles[i];
                    final name = f.path.split('/').last;
                    return ListTile(
                      leading: const Icon(Icons.picture_as_pdf),
                      title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(_fmtSize(f.lengthSync())),
                      onTap: () => Navigator.pop(c, f),
                    );
                  },
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8, bottom: 8),
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('CANCEL'),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
    if (selected == null) return;
    if (!await selected.exists()) {
      _showSnack('File no longer exists. Refreshing list...');
      await _loadPdfFiles();
      return;
    }
    try {
      final doc = await PdfDocument.openFile(selected.path);
      if (doc.pagesCount < 1) {
        doc.close();
        _showSnack('PDF appears empty.');
        return;
      }
      final p = await doc.getPage(1);
      await p.render(width: 10, height: 10);
      p.close();
      doc.close();
    } catch (e) {
      _showSnack('Unable to open PDF: $e');
      return;
    }
    if (!mounted) return;
    Navigator.pushNamed(context, route, arguments: {'pdfPath': selected.path});
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _fmtSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _FeatureTile(title: 'Merge PDFs', icon: Icons.merge, onTap: () => Navigator.pushNamed(context, '/pdf-merge')),
      _FeatureTile(title: 'Images to PDF', icon: Icons.image, onTap: () => Navigator.pushNamed(context, '/image-to-pdf')),
      _FeatureTile(title: 'Camera to PDF', icon: Icons.photo_camera, onTap: () => Navigator.pushNamed(context, '/camera-to-pdf')),
      _FeatureTile(title: 'Compress PDF', icon: Icons.compress, onTap: _handleCompressTap),
      _FeatureTile(title: 'Split PDF', icon: Icons.call_split, onTap: _handleSplitTap),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Utilities'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  SizedBox(
                    height: 150,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: tiles.length,
                      itemBuilder: (_, i) => tiles[i],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text('Your PDFs', style: Theme.of(context).textTheme.titleMedium),
                  ),
                  const SizedBox(height: 8),
                  if (_pdfFiles.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        'No PDFs found. Use the tools above to create or import.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  else
                    GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: _pdfFiles.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.68,
                      ),
                      itemBuilder: (_, i) {
                        final file = _pdfFiles[i];
                        final name = file.path.split('/').last;
                        return InkWell(
                          onTap: () => _openPdf(file),
                          onLongPress: () => _showPdfActions(file),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: PdfThumbnail(pdfPath: file.path),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _fmtSize(file.lengthSync()),
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  const _FeatureTile({required this.title, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Card(
        child: InkWell(
          onTap: onTap,
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
    } catch (e, st) {
      appLog('Error loading PDF thumbnail', error: e, stackTrace: st);
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
