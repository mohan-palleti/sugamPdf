import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:image/image.dart' as img;
import 'utilities.dart';
import 'package:path_provider/path_provider.dart';

class PdfService {
  Future<File> mergePdfs(List<File> pdfFiles, String outputName, {BuildContext? context}) async {
    if (pdfFiles.isEmpty) {
      throw Exception('No PDF files provided for merging');
    }

    // Create a new PDF document
    final pdf = pw.Document();

    // Request storage permission early if context is provided
  // Caller should ensure permissions granted beforehand.

    // For each PDF file
    for (final pdfFile in pdfFiles) {
      try {
        final bytes = await pdfFile.readAsBytes();
        pdf.addPage(
          pw.Page(
            build: (context) {
              return pw.Center(
                child: pw.SizedBox(
                  width: PdfPageFormat.a4.width,
                  height: PdfPageFormat.a4.height,
                  child: pw.FittedBox(
                    child: pw.Image(
                      pw.MemoryImage(bytes),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      } catch (e) {
        throw Exception('Failed to process PDF file: ${pdfFile.path}\nError: $e');
      }
    }

    try {
      // Determine safe directory & sanitized name
      final baseDir = await getApplicationDocumentsDirectory();
      final appDir = await getOrCreateAppDataDir(baseDir);
      final safeName = sanitizeFileName(outputName.endsWith('.pdf') ? outputName : '$outputName.pdf');
      final outputFile = File('${appDir.path}/$safeName');
      await outputFile.writeAsBytes(await pdf.save());
      return outputFile;
    } catch (e) {
      throw Exception('Failed to save merged PDF: $e');
    }
  }

  Future<void> createPdfFromImages(List<File> images, String outputPath) async {
    final pdf = pw.Document();

    for (var imageFile in images) {
      final image = pw.MemoryImage(imageFile.readAsBytesSync());
      pdf.addPage(pw.Page(
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Image(image),
          );
        },
      ));
    }

    final file = File(outputPath);
    await file.writeAsBytes(await pdf.save());
  }

  Future<File> imagesToPdf(List<File> images, String outputPath, {PdfPageFormat? pageFormat}) async {
    final pdf = pw.Document();
    for (var imageFile in images) {
      final image = img.decodeImage(await imageFile.readAsBytes());
      if (image != null) {
        pdf.addPage(
          pw.Page(
            pageFormat: pageFormat ?? PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Center(
                child: pw.Image(pw.MemoryImage(Uint8List.fromList(img.encodeJpg(image)))),
              );
            },
          ),
        );
      }
    }

    // Storage permissions should already be checked with the context parameter
    // If we got this far, we assume permissions are granted

    // Use the exact path provided
  final baseDir = await getApplicationDocumentsDirectory();
  final appDir = await getOrCreateAppDataDir(baseDir);
  final safeName = sanitizeFileName(outputPath.split('/').last.endsWith('.pdf')
    ? outputPath.split('/').last
    : '${outputPath.split('/').last}.pdf');
  final file = File('${appDir.path}/$safeName');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  // Add more PDF utility methods as needed
}
