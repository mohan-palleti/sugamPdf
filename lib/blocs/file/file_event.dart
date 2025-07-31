import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class FileEvent extends Equatable {
  const FileEvent();

  @override
  List<Object?> get props => [];
}

class LoadFiles extends FileEvent {
  final String? directory;

  const LoadFiles({this.directory});

  @override
  List<Object?> get props => [directory];
}

class DeleteFile extends FileEvent {
  final String filePath;

  const DeleteFile(this.filePath);

  @override
  List<Object> get props => [filePath];
}

class CreateDirectory extends FileEvent {
  final String path;

  const CreateDirectory(this.path);

  @override
  List<Object> get props => [path];
}

class MoveFile extends FileEvent {
  final String sourcePath;
  final String destinationPath;

  const MoveFile({
    required this.sourcePath,
    required this.destinationPath,
  });

  @override
  List<Object> get props => [sourcePath, destinationPath];
}

class RenameFile extends FileEvent {
  final String oldPath;
  final String newPath;

  const RenameFile({
    required this.oldPath,
    required this.newPath,
  });

  @override
  List<Object> get props => [oldPath, newPath];
}
