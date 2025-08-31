import 'package:equatable/equatable.dart';

abstract class PageOpsEvent extends Equatable {
  const PageOpsEvent();
  @override
  List<Object?> get props => [];
}

class LoadPageThumbnails extends PageOpsEvent {
  final String pdfPath;
  const LoadPageThumbnails(this.pdfPath);
  @override
  List<Object?> get props => [pdfPath];
}

class ReorderPagesEvent extends PageOpsEvent {
  final List<int> newOrder; // 1-based page numbers
  const ReorderPagesEvent(this.newOrder);
  @override
  List<Object?> get props => [newOrder];
}

class DeletePagesEvent extends PageOpsEvent {
  final List<int> pages; // 1-based
  const DeletePagesEvent(this.pages);
  @override
  List<Object?> get props => [pages];
}

class RotatePagesEvent extends PageOpsEvent {
  final Map<int,int> rotations; // page -> degrees
  const RotatePagesEvent(this.rotations);
  @override
  List<Object?> get props => [rotations];
}

class ApplyPageOps extends PageOpsEvent {
  final String outputPath; // suggested output path
  const ApplyPageOps(this.outputPath);
  @override
  List<Object?> get props => [outputPath];
}

class SplitPdfEvent extends PageOpsEvent {
  final List<List<int>> ranges; // list of [start,end]
  const SplitPdfEvent(this.ranges);
  @override
  List<Object?> get props => [ranges];
}

class CompressPdfEvent extends PageOpsEvent {
  final double scale;
  final int quality;
  final String outputPath;
  const CompressPdfEvent({required this.scale, required this.quality, required this.outputPath});
  @override
  List<Object?> get props => [scale, quality, outputPath];
}
