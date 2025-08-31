import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import '../../services/pdf_service.dart';
import 'pdf_event.dart';
import 'pdf_state.dart';

class PdfBloc extends Bloc<PdfEvent, PdfState> {
  final PdfService _pdfService;
  
  PdfBloc({required PdfService pdfService}) 
      : _pdfService = pdfService,
        super(PdfInitial()) {
    on<LoadPdfs>(_onLoadPdfs);
    on<AddPdf>(_onAddPdf);
    on<DeletePdf>(_onDeletePdf);
    on<MergePdfs>(_onMergePdfs);
    on<OpenPdf>(_onOpenPdf);
    on<ConvertImagesToPdf>(_onConvertImagesToPdf);
  }

  Future<void> _onLoadPdfs(LoadPdfs event, Emitter<PdfState> emit) async {
    emit(PdfLoading());
    try {
      final directory = await getApplicationDocumentsDirectory();
      final pdfs = await _listPdfsInDirectory(directory);
      emit(PdfLoaded(pdfs: pdfs));
    } catch (e) {
      emit(PdfError('Failed to load PDFs: $e'));
    }
  }

  Future<void> _onAddPdf(AddPdf event, Emitter<PdfState> emit) async {
    final currentState = state;
    if (currentState is PdfLoaded) {
      try {
        final updatedPdfs = List<File>.from(currentState.pdfs)..add(event.pdfFile);
        emit(PdfLoaded(pdfs: updatedPdfs, currentPdfPath: currentState.currentPdfPath));
      } catch (e) {
        emit(PdfError('Failed to add PDF: $e'));
      }
    }
  }

  Future<void> _onDeletePdf(DeletePdf event, Emitter<PdfState> emit) async {
    final currentState = state;
    if (currentState is PdfLoaded) {
      try {
        final file = File(event.pdfPath);
        await file.delete();
        final updatedPdfs = currentState.pdfs.where((pdf) => pdf.path != event.pdfPath).toList();
        emit(PdfLoaded(pdfs: updatedPdfs));
      } catch (e) {
        emit(PdfError('Failed to delete PDF: $e'));
      }
    }
  }

  Future<void> _onMergePdfs(MergePdfs event, Emitter<PdfState> emit) async {
    emit(PdfLoading());
    try {
      await _pdfService.mergePdfs(event.pdfs, event.outputPath, context: event.context);
      final directory = await getApplicationDocumentsDirectory();
      final pdfs = await _listPdfsInDirectory(directory);
      emit(PdfLoaded(pdfs: pdfs, currentPdfPath: event.outputPath));
    } catch (e) {
      emit(PdfError('Failed to merge PDFs: $e'));
    }
  }

  Future<void> _onOpenPdf(OpenPdf event, Emitter<PdfState> emit) async {
    final currentState = state;
    if (currentState is PdfLoaded) {
      emit(PdfLoaded(pdfs: currentState.pdfs, currentPdfPath: event.pdfPath));
    }
  }

  Future<void> _onConvertImagesToPdf(ConvertImagesToPdf event, Emitter<PdfState> emit) async {
    emit(PdfLoading());
    try {
      await _pdfService.createPdfFromImages(event.images, event.outputPath);
      final directory = await getApplicationDocumentsDirectory();
      final pdfs = await _listPdfsInDirectory(directory);
      emit(PdfLoaded(pdfs: pdfs, currentPdfPath: event.outputPath));
    } catch (e) {
      emit(PdfError('Failed to convert images to PDF: $e'));
    }
  }

  Future<List<File>> _listPdfsInDirectory(Directory directory) async {
    final entities = await directory.list().toList();
    return entities
        .whereType<File>()
        .where((file) => file.path.toLowerCase().endsWith('.pdf'))
        .toList();
  }
}
