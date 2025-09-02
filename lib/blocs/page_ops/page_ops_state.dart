import 'package:equatable/equatable.dart';
import 'dart:typed_data';

class PageThumb {
  final int pageNumber; // 1-based
  final Uint8List bytes;
  PageThumb(this.pageNumber, this.bytes);
}

abstract class PageOpsState extends Equatable {
  const PageOpsState();
  @override
  List<Object?> get props => [];
}

class PageOpsInitial extends PageOpsState {}
class PageOpsLoading extends PageOpsState {}

class PageOpsLoaded extends PageOpsState {
  final String pdfPath;
  final List<PageThumb> thumbs;
  final List<int> workingOrder; // 1-based sequence representing current tentative order
  final Map<int,int> rotations; // page -> degrees
  final Set<int> deletions; // pages flagged for deletion
  const PageOpsLoaded({
    required this.pdfPath,
    required this.thumbs,
    required this.workingOrder,
    required this.rotations,
    required this.deletions,
  });
  @override
  List<Object?> get props => [pdfPath, thumbs, workingOrder, rotations, deletions];
  PageOpsLoaded copyWith({
    List<PageThumb>? thumbs,
    List<int>? workingOrder,
    Map<int,int>? rotations,
    Set<int>? deletions,
  }) => PageOpsLoaded(
    pdfPath: pdfPath,
    thumbs: thumbs ?? this.thumbs,
    workingOrder: workingOrder ?? this.workingOrder,
    rotations: rotations ?? this.rotations,
    deletions: deletions ?? this.deletions,
  );
}

class PageOpsProgress extends PageOpsState {
  final double progress; // 0-1
  final String stage;
  const PageOpsProgress(this.progress, this.stage);
  @override
  List<Object?> get props => [progress, stage];
}

class PageOpsResult extends PageOpsState {
  final List<String> outputPaths; // one for normal ops or many for split
  const PageOpsResult(this.outputPaths);
  @override
  List<Object?> get props => [outputPaths];
}

class PageOpsError extends PageOpsState {
  final String message;
  const PageOpsError(this.message);
  @override
  List<Object?> get props => [message];
}
