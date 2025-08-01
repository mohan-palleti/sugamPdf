import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/pdf_annotation_service.dart';
import '../../models/annotation.dart';
import 'pdf_editor_event.dart';
import 'pdf_editor_state.dart';

class PdfEditorBloc extends Bloc<PdfEditorEvent, PdfEditorState> {
  final PdfAnnotationService _annotationService;
  final String pdfPath;
  final List<AnnotationData> _annotations = [];
  int _currentPage = 0;

  PdfEditorBloc({
    required PdfAnnotationService annotationService,
    required this.pdfPath,
  })  : _annotationService = annotationService,
        super(PdfEditorInitial()) {
    on<LoadPdfEditor>(_onLoadPdfEditor);
    on<AddAnnotation>(_onAddAnnotation);
    on<UndoAnnotation>(_onUndoAnnotation);
    on<SaveAnnotations>(_onSaveAnnotations);
    on<ChangeCurrentPage>(_onChangeCurrentPage);
  }

  void _onLoadPdfEditor(
    LoadPdfEditor event,
    Emitter<PdfEditorState> emit,
  ) {
    emit(PdfEditorLoaded(
      annotations: _annotations,
      currentPage: _currentPage,
    ));
  }

  void _onAddAnnotation(
    AddAnnotation event,
    Emitter<PdfEditorState> emit,
  ) {
    _annotations.add(event.annotation);
    emit(PdfEditorLoaded(
      annotations: _annotations,
      currentPage: _currentPage,
    ));
  }

  void _onUndoAnnotation(
    UndoAnnotation event,
    Emitter<PdfEditorState> emit,
  ) {
    if (_annotations.isNotEmpty) {
      _annotations.removeLast();
      emit(PdfEditorLoaded(
        annotations: _annotations,
        currentPage: _currentPage,
      ));
    }
  }

  Future<void> _onSaveAnnotations(
    SaveAnnotations event,
    Emitter<PdfEditorState> emit,
  ) async {
    try {
      emit(PdfEditorLoading());
      final outputFile = await _annotationService.addAnnotations(
        pdfFile: File(pdfPath),
        annotations: _annotations,
        outputPath: event.outputPath,
      );
      emit(AnnotationsSaved(outputFile.path));
    } catch (e) {
      emit(PdfEditorError('Failed to save annotations: $e'));
    }
  }

  void _onChangeCurrentPage(
    ChangeCurrentPage event,
    Emitter<PdfEditorState> emit,
  ) {
    _currentPage = event.pageNumber;
    emit(PdfEditorLoaded(
      annotations: _annotations,
      currentPage: _currentPage,
    ));
  }
}
