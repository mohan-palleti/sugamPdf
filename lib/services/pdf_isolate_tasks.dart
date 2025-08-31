import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:image/image.dart' as img;

/// Data model for merge task payload (paths only so it is isolate-friendly).
class _MergePayload {
  final List<String> inputPaths;
  final String outputPath;
  _MergePayload(this.inputPaths, this.outputPath);
}

/// Data model for images->pdf task payload.
class _ImagesPayload {
  final List<String> imagePaths;
  final String outputPath;
  final PdfPageFormat? pageFormat;
  _ImagesPayload(this.imagePaths, this.outputPath, this.pageFormat);
}

Future<File> isolateMergePdfs(List<String> paths, String outputPath) async {
  final payload = _MergePayload(paths, outputPath);
  return _mergeImpl(payload);
}

Future<File> isolateImagesToPdf(List<String> imagePaths, String outputPath, PdfPageFormat? pageFormat) async {
  final payload = _ImagesPayload(imagePaths, outputPath, pageFormat);
  return _imagesImpl(payload);
}

Future<File> _mergeImpl(_MergePayload payload) async {
  final pdf = pw.Document();
  for (final path in payload.inputPaths) {
    final file = File(path);
    if (!await file.exists()) continue;
    try {
      final bytes = await file.readAsBytes();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (_) => pw.Center(
            child: pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.contain),
          ),
        ),
      );
    } catch (_) {}
  }
  final outFile = File(payload.outputPath);
  await outFile.writeAsBytes(await pdf.save());
  return outFile;
}

Future<File> _imagesImpl(_ImagesPayload payload) async {
  final pdf = pw.Document();
  for (final path in payload.imagePaths) {
    final file = File(path);
    if (!await file.exists()) continue;
    try {
      final raw = await file.readAsBytes();
      final decoded = img.decodeImage(raw);
      if (decoded == null) continue;
      final jpg = Uint8List.fromList(img.encodeJpg(decoded));
      pdf.addPage(
        pw.Page(
          pageFormat: payload.pageFormat ?? PdfPageFormat.a4,
          build: (_) => pw.Center(child: pw.Image(pw.MemoryImage(jpg))),
        ),
      );
    } catch (_) {}
  }
  final outFile = File(payload.outputPath);
  await outFile.writeAsBytes(await pdf.save());
  return outFile;
}
