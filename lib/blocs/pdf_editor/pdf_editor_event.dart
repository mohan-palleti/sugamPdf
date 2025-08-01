import 'package:equatable/equatable.dart';
import '../../models/annotation.dart';

abstract class PdfEditorEvent extends Equatable {
  const PdfEditorEvent();

  @override
  List<Object?> get props => [];
}

class LoadPdfEditor extends PdfEditorEvent {
  final String pdfPath;

  const LoadPdfEditor(this.pdfPath);

  @override
  List<Object?> get props => [pdfPath];
}

class AddAnnotation extends PdfEditorEvent {
  final AnnotationData annotation;

  const AddAnnotation(this.annotation);

  @override
  List<Object?> get props => [annotation];
}

class UndoAnnotation extends PdfEditorEvent {
  const UndoAnnotation();
}

class SaveAnnotations extends PdfEditorEvent {
  final String? outputPath;

  const SaveAnnotations([this.outputPath]);

  @override
  List<Object?> get props => [outputPath];
}

class ChangeCurrentPage extends PdfEditorEvent {
  final int pageNumber;

  const ChangeCurrentPage(this.pageNumber);

  @override
  List<Object?> get props => [pageNumber];
}
