import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';

class PdfService {
  Future<File> mergePdfs(List<File> pdfFiles, String outputName) async {
    // TODO: Implement PDF merging logic
    // Use the pdf package to merge pages
    throw UnimplementedError();
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
