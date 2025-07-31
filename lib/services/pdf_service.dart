import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';

class PdfService {
  Future<File> mergePdfs(List<File> pdfFiles, String outputName) async {
    if (pdfFiles.isEmpty) {
      throw Exception('No PDF files provided for merging');
    }

    // Create a new PDF document
    final pdf = pw.Document();

    // Request storage permission early
    final status = await Permission.storage.request();
    if (!status.isGranted) {
      throw Exception('Storage permission not granted');
    }

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
      final outputFile = File(outputName);
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

    // Request storage permission
    final status = await Permission.storage.request();
    if (!status.isGranted) {
      throw Exception('Storage permission not granted');
    }

    // Use the exact path provided
    final file = File(outputPath);
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  // Add more PDF utility methods as needed
}
