import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

abstract class PdfEvent extends Equatable {
  const PdfEvent();

  @override
  List<Object?> get props => [];
}

class LoadPdfs extends PdfEvent {}

class AddPdf extends PdfEvent {
  final File pdfFile;

  const AddPdf(this.pdfFile);

  @override
  List<Object> get props => [pdfFile];
}

class DeletePdf extends PdfEvent {
  final String pdfPath;

  const DeletePdf(this.pdfPath);

  @override
  List<Object> get props => [pdfPath];
}

class MergePdfs extends PdfEvent {
  final List<File> pdfs;
  final String outputPath;
  final BuildContext? context;

  const MergePdfs({
    required this.pdfs,
    required this.outputPath,
    this.context,
  });

  @override
  List<Object?> get props => [pdfs, outputPath, context];
}

class OpenPdf extends PdfEvent {
  final String pdfPath;

  const OpenPdf(this.pdfPath);

  @override
  List<Object> get props => [pdfPath];
}

class ConvertImagesToPdf extends PdfEvent {
  final List<File> images;
  final String outputPath;

  const ConvertImagesToPdf({
    required this.images,
    required this.outputPath,
  });

  @override
  List<Object> get props => [images, outputPath];
}
