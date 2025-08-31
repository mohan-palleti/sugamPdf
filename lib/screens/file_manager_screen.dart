import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/file/file_bloc.dart';
import '../blocs/file/file_event.dart';
import '../blocs/file/file_state.dart';
import '../screens/pdf_editor_screen.dart';
import '../services/app_services.dart';
import '../blocs/pdf_editor/pdf_editor_bloc.dart';
import '../blocs/pdf_editor/pdf_editor_event.dart';

class FileManagerScreen extends StatelessWidget {
  const FileManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('File Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.create_new_folder),
            onPressed: () => _showCreateFolderDialog(context),
          ),
        ],
      ),
      body: BlocBuilder<FileBloc, FileState>(
        builder: (context, state) {
          if (state is FileInitial) {
            // First check for permissions, then load files
            context.read<FileBloc>().add(CheckPermissions(context));
            return const Center(child: CircularProgressIndicator());
          }
          
          if (state is FileLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (state is FileError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<FileBloc>().add(CheckPermissions(context)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          if (state is FileLoaded) {
            if (state.files.isEmpty) {
              return const Center(
                child: Text('No files found'),
              );
            }
            
            return ListView.builder(
              itemCount: state.files.length,
              itemBuilder: (context, index) {
                final file = state.files[index];
                return ListTile(
                  leading: _getFileIcon(file),
                  title: Text(file.path.split('/').last),
                  subtitle: Text(_formatFileSize(file)),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'rename',
                        child: Text('Rename'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                    onSelected: (value) => _handleFileAction(context, value, file),
                  ),
                  onTap: () => _handleFileTap(context, file),
                );
              },
            );
          }
          
          return const Center(child: Text('Something went wrong'));
        },
      ),
    );
  }

  Widget _getFileIcon(File file) {
    final extension = file.path.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return const Icon(Icons.picture_as_pdf, color: Colors.red);
      case 'jpg':
      case 'jpeg':
      case 'png':
        return const Icon(Icons.image, color: Colors.blue);
      default:
        return const Icon(Icons.insert_drive_file);
    }
  }

  String _formatFileSize(File file) {
    try {
      final bytes = file.lengthSync();
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
      if (bytes < 1024 * 1024 * 1024) {
        return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    } catch (e) {
      return 'Unknown size';
    }
  }

  void _showCreateFolderDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Folder'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Folder name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                final currentState = context.read<FileBloc>().state;
                if (currentState is FileLoaded && currentState.currentDirectory != null) {
                  final newPath = '${currentState.currentDirectory}/${controller.text}';
                  context.read<FileBloc>().add(CreateDirectory(newPath));
                }
              }
              Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _handleFileAction(BuildContext context, String action, File file) {
    switch (action) {
      case 'rename':
        _showRenameDialog(context, file);
        break;
      case 'delete':
        _showDeleteConfirmation(context, file);
        break;
    }
  }

  void _showRenameDialog(BuildContext context, File file) {
    final controller = TextEditingController(
      text: file.path.split('/').last,
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename File'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'New name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                final directory = file.parent;
                final newPath = '${directory.path}/${controller.text}';
                context.read<FileBloc>().add(RenameFile(
                  oldPath: file.path,
                  newPath: newPath,
                ));
              }
              Navigator.pop(context);
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, File file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: Text('Are you sure you want to delete ${file.path.split('/').last}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<FileBloc>().add(DeleteFile(file.path));
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _handleFileTap(BuildContext context, File file) {
    final extension = file.path.split('.').last.toLowerCase();
    if (extension == 'pdf') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BlocProvider(
            create: (context) => PdfEditorBloc(
              annotationService: services.annotationService,
              pdfPath: file.path,
            )..add(LoadPdfEditor(file.path)),
            child: PdfEditorScreen(pdfPath: file.path),
          ),
        ),
      );
    }
  }
}
