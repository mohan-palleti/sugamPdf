import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import '../../services/permissions_service.dart';
import 'file_event.dart';
import 'file_state.dart';

class FileBloc extends Bloc<FileEvent, FileState> {
  FileBloc() : super(FileInitial()) {
    on<LoadFiles>(_onLoadFiles);
    on<DeleteFile>(_onDeleteFile);
    on<CreateDirectory>(_onCreateDirectory);
    on<MoveFile>(_onMoveFile);
    on<RenameFile>(_onRenameFile);
    on<CheckPermissions>(_onCheckPermissions);
  }
  
  Future<void> _onCheckPermissions(CheckPermissions event, Emitter<FileState> emit) async {
    emit(FileLoading());
    final hasPermission = await PermissionsService.requestStoragePermission(event.context);
    if (hasPermission) {
      add(const LoadFiles());
    } else {
      emit(const FileError('Storage permission denied. Please grant storage permission to access files.'));
    }
  }

  Future<void> _onLoadFiles(LoadFiles event, Emitter<FileState> emit) async {
    emit(FileLoading());
    try {
      final directory = event.directory != null
          ? Directory(event.directory!)
          : await getApplicationDocumentsDirectory();
      
      final entities = await directory.list().toList();
      final files = entities.whereType<File>().toList();
      
      emit(FileLoaded(
        files: files,
        currentDirectory: directory.path,
      ));
    } catch (e) {
      emit(FileError('Failed to load files: $e'));
    }
  }

  Future<void> _onDeleteFile(DeleteFile event, Emitter<FileState> emit) async {
    final currentState = state;
    if (currentState is FileLoaded) {
      try {
        final file = File(event.filePath);
        await file.delete();
        
        final updatedFiles = currentState.files
            .where((f) => f.path != event.filePath)
            .toList();
        
        emit(FileLoaded(
          files: updatedFiles,
          currentDirectory: currentState.currentDirectory,
        ));
      } catch (e) {
        emit(FileError('Failed to delete file: $e'));
      }
    }
  }

  Future<void> _onCreateDirectory(CreateDirectory event, Emitter<FileState> emit) async {
    try {
      final directory = Directory(event.path);
      await directory.create(recursive: true);
      
      if (state is FileLoaded) {
        final currentState = state as FileLoaded;
        await _onLoadFiles(
          LoadFiles(directory: currentState.currentDirectory),
          emit,
        );
      }
    } catch (e) {
      emit(FileError('Failed to create directory: $e'));
    }
  }

  Future<void> _onMoveFile(MoveFile event, Emitter<FileState> emit) async {
    try {
      final sourceFile = File(event.sourcePath);
      await sourceFile.rename(event.destinationPath);
      
      if (state is FileLoaded) {
        final currentState = state as FileLoaded;
        await _onLoadFiles(
          LoadFiles(directory: currentState.currentDirectory),
          emit,
        );
      }
    } catch (e) {
      emit(FileError('Failed to move file: $e'));
    }
  }

  Future<void> _onRenameFile(RenameFile event, Emitter<FileState> emit) async {
    try {
      final file = File(event.oldPath);
      await file.rename(event.newPath);
      
      if (state is FileLoaded) {
        final currentState = state as FileLoaded;
        await _onLoadFiles(
          LoadFiles(directory: currentState.currentDirectory),
          emit,
        );
      }
    } catch (e) {
      emit(FileError('Failed to rename file: $e'));
    }
  }
}
