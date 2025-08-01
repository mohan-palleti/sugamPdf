import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdfx/pdfx.dart';
import '../blocs/pdf_editor/pdf_editor_bloc.dart';
import '../blocs/pdf_editor/pdf_editor_event.dart';
import '../blocs/pdf_editor/pdf_editor_state.dart';
import '../models/annotation.dart';
import '../widgets/annotation_toolbar.dart';
import '../widgets/pdf_annotation_layer.dart';

class PdfEditorScreen extends StatefulWidget {
  final String pdfPath;
  
  const PdfEditorScreen({
    Key? key,
    required this.pdfPath,
  }) : super(key: key);

  @override
  State<PdfEditorScreen> createState() => _PdfEditorScreenState();
}

class _PdfEditorScreenState extends State<PdfEditorScreen> {
  late final PdfController _pdfController;
  late final PageController _pageController;
  AnnotationType _currentTool = AnnotationType.drawing;
  Color _currentColor = Colors.red;
  double _currentStrokeWidth = 2.0;
  List<Offset> _currentPoints = [];
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfController(
      document: PdfDocument.openFile(widget.pdfPath),
    );
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pdfController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onToolSelected(AnnotationType tool) {
    setState(() {
      _currentTool = tool;
      _currentPoints = [];
    });
  }

  void _onColorSelected(Color color) {
    setState(() {
      _currentColor = color;
    });
  }

  void _onStrokeWidthChanged(double width) {
    setState(() {
      _currentStrokeWidth = width;
    });
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _currentPoints = [details.localPosition];
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _currentPoints.add(details.localPosition);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_currentPoints.isNotEmpty) {
      final annotation = AnnotationData(
        type: _currentTool,
        points: List.from(_currentPoints),
        color: _currentColor,
        strokeWidth: _currentStrokeWidth,
        pageNumber: _currentPage,
      );
      
      context.read<PdfEditorBloc>().add(AddAnnotation(annotation));
      
      setState(() {
        _currentPoints = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Editor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              context.read<PdfEditorBloc>().add(const SaveAnnotations());
            },
          ),
        ],
      ),
      body: BlocConsumer<PdfEditorBloc, PdfEditorState>(
        listener: (context, state) {
          if (state is PdfEditorError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is AnnotationsSaved) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Annotations saved successfully')),
            );
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              PdfView(
                controller: _pdfController,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
              ),
              if (_currentPoints.isNotEmpty)
                PdfAnnotationLayer(
                  points: _currentPoints,
                  color: _currentColor,
                  strokeWidth: _currentStrokeWidth,
                  type: _currentTool,
                ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: AnnotationToolbar(
                  selectedTool: _currentTool,
                  selectedColor: _currentColor,
                  strokeWidth: _currentStrokeWidth,
                  onToolSelected: _onToolSelected,
                  onColorSelected: _onColorSelected,
                  onStrokeWidthChanged: _onStrokeWidthChanged,
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.read<PdfEditorBloc>().add(const UndoAnnotation());
        },
        child: const Icon(Icons.undo),
      ),
    );
  }
}
