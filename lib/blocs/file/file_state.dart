import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class FileState extends Equatable {
  const FileState();

  @override
  List<Object?> get props => [];
}

class FileInitial extends FileState {}

class FileLoading extends FileState {}

class FileLoaded extends FileState {
  final List<File> files;
  final String? currentDirectory;

  const FileLoaded({
    required this.files,
    this.currentDirectory,
  });

  @override
  List<Object?> get props => [files, currentDirectory];
}

class FileError extends FileState {
  final String message;

  const FileError(this.message);

  @override
  List<Object> get props => [message];
}
