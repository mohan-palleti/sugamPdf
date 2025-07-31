import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class PdfState extends Equatable {
  const PdfState();

  @override
  List<Object?> get props => [];
}

class PdfInitial extends PdfState {}

class PdfLoading extends PdfState {}

class PdfLoaded extends PdfState {
  final List<File> pdfs;
  final String? currentPdfPath;

  const PdfLoaded({
    required this.pdfs,
    this.currentPdfPath,
  });

  @override
  List<Object?> get props => [pdfs, currentPdfPath];
}

class PdfError extends PdfState {
  final String message;

  const PdfError(this.message);

  @override
  List<Object> get props => [message];
}
