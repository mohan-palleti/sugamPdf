import 'dart:io';
import 'package:flutter/material.dart';
import '../services/pdf_annotation_service.dart';
import '../widgets/annotation_toolbar.dart';
import '../models/annotation.dart';
import '../painters/annotation_painter.dart';
import 'package:pdfx/pdfx.dart';
import 'package:path_provider/path_provider.dart';

class PdfAnnotationExample extends StatefulWidget {
  final String pdfPath;

  const PdfAnnotationExample({
    Key? key,
    required this.pdfPath,
  }) : super(key: key);

  @override
  State<PdfAnnotationExample> createState() => _PdfAnnotationExampleState();
}

class _PdfAnnotationExampleState extends State<PdfAnnotationExample> {
  late final PdfController _pdfController;
  final List<AnnotationData> _annotations = [];
  AnnotationType _currentTool = AnnotationType.drawing;
  Color _currentColor = Colors.red;
  double _currentStrokeWidth = 2.0;
  List<Offset> _currentPoints = [];
  bool _isDrawing = false;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _initPdfController();
  }

  void _initPdfController() {
    _pdfController = PdfController(
      document: PdfDocument.openFile(widget.pdfPath),
    );
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  Future<void> _saveAnnotations() async {
    try {
      final service = PdfAnnotationService();
      final directory = await getApplicationDocumentsDirectory();
      final outputPath = '${directory.path}/annotated_${DateTime.now().millisecondsSinceEpoch}.pdf';
      
      await service.addAnnotations(
        pdfFile: File(widget.pdfPath),
        annotations: _annotations,
        outputPath: outputPath,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF saved to: $outputPath')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving PDF: $e')),
        );
      }
    }
  }

  void _handlePanStart(DragStartDetails details, BoxConstraints constraints) {
    final renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.globalToLocal(details.globalPosition);
    
    setState(() {
      _isDrawing = true;
      _currentPoints = [position];
    });
  }

  void _handlePanUpdate(DragUpdateDetails details, BoxConstraints constraints) {
    if (!_isDrawing) return;

    final renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.globalToLocal(details.globalPosition);
    
    setState(() {
      _currentPoints.add(position);
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    if (!_isDrawing) return;

    setState(() {
      _isDrawing = false;
      if (_currentPoints.isNotEmpty) {
        final annotation = AnnotationData(
          type: _currentTool,
          points: List.from(_currentPoints),
          color: _currentColor,
          strokeWidth: _currentStrokeWidth,
          pageNumber: _currentPage,
        );
        _annotations.add(annotation);
        _currentPoints = [];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Annotation Example'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveAnnotations,
          ),
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _annotations.isEmpty
                ? null
                : () {
                    setState(() {
                      _annotations.removeLast();
                    });
                  },
          ),
        ],
      ),
      body: Stack(
        children: [
          // PDF View
          PdfView(
            controller: _pdfController,
            onPageChanged: (page) {
              setState(() {
                _currentPage = page;
              });
            },
          ),
          
          // Annotation Layer
          LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onPanStart: (details) => _handlePanStart(details, constraints),
                onPanUpdate: (details) => _handlePanUpdate(details, constraints),
                onPanEnd: _handlePanEnd,
                child: CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: AnnotationPainter(
                    annotations: _annotations,
                    currentPoints: _currentPoints,
                    currentColor: _currentColor,
                    currentStrokeWidth: _currentStrokeWidth,
                    currentTool: _currentTool,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: AnnotationToolbar(
        selectedTool: _currentTool,
        selectedColor: _currentColor,
        strokeWidth: _currentStrokeWidth,
        onToolSelected: (tool) {
          setState(() {
            _currentTool = tool;
          });
        },
        onColorSelected: (color) {
          setState(() {
            _currentColor = color;
          });
        },
        onStrokeWidthChanged: (width) {
          setState(() {
            _currentStrokeWidth = width;
          });
        },
      ),
    );
  }
}
