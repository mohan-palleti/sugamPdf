import 'package:equatable/equatable.dart';
import '../../models/annotation.dart';

abstract class PdfEditorState extends Equatable {
  const PdfEditorState();

  @override
  List<Object?> get props => [];
}

class PdfEditorInitial extends PdfEditorState {}

class PdfEditorLoading extends PdfEditorState {}

class PdfEditorLoaded extends PdfEditorState {
  final List<AnnotationData> annotations;
  final int currentPage;

  const PdfEditorLoaded({
    required this.annotations,
    required this.currentPage,
  });

  @override
  List<Object?> get props => [annotations, currentPage];

  PdfEditorLoaded copyWith({
    List<AnnotationData>? annotations,
    int? currentPage,
  }) {
    return PdfEditorLoaded(
      annotations: annotations ?? this.annotations,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class PdfEditorError extends PdfEditorState {
  final String message;

  const PdfEditorError(this.message);

  @override
  List<Object?> get props => [message];
}

class AnnotationsSaved extends PdfEditorState {
  final String outputPath;

  const AnnotationsSaved(this.outputPath);

  @override
  List<Object?> get props => [outputPath];
}
