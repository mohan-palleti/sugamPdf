import 'dart:io';
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../models/annotation.dart';
import 'utilities.dart';

class PdfAnnotationService {
  /// Location (beside original PDF) where annotation JSON is stored: <pdfName>.annotations.json
  Future<File> _annotationJsonFile(String pdfPath) async {
    final pdfFile = File(pdfPath);
    final dir = pdfFile.parent;
    final baseName = pdfFile.uri.pathSegments.last.replaceAll('.pdf', '');
    return File('${dir.path}/$baseName.annotations.json');
  }

  /// Save annotations as JSON (non-destructive) – separate from embedding into new PDF.
  Future<void> persistAnnotations(String pdfPath, List<AnnotationData> annotations) async {
    try {
      final file = await _annotationJsonFile(pdfPath);
      final list = annotations.map((a) => a.toJson()).toList();
      await file.writeAsString(jsonEncode(list));
      appLog('Persisted ${annotations.length} annotations for $pdfPath');
    } catch (e, st) {
      appLog('Failed to persist annotations', error: e, stackTrace: st);
    }
  }

  /// Load previously saved annotations JSON (if any).
  Future<List<AnnotationData>> loadPersistedAnnotations(String pdfPath) async {
    try {
      final file = await _annotationJsonFile(pdfPath);
      if (!await file.exists()) return [];
      final raw = await file.readAsString();
      final data = jsonDecode(raw) as List<dynamic>;
      return data.map((e) => AnnotationData.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e, st) {
      appLog('Failed to load persisted annotations', error: e, stackTrace: st);
      return [];
    }
  }

  Future<File> addAnnotations({
    required File pdfFile,
    required List<AnnotationData> annotations,
    String? outputPath,
  }) async {
    final document = pw.Document();
    
    // Group annotations by page
    final annotationsByPage = <int, List<AnnotationData>>{};
    for (final annotation in annotations) {
      annotationsByPage.putIfAbsent(annotation.pageNumber, () => [])
        .add(annotation);
    }

    // Create pages with annotations
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          final pages = <pw.Widget>[];
          
          for (var pageNum = 0; pageNum < annotationsByPage.length; pageNum++) {
            final pageAnnotations = annotationsByPage[pageNum] ?? [];
            
            pages.add(
              pw.Stack(
                children: [
                  // Add annotations
                  ...pageAnnotations.map((annotation) {
                    switch (annotation.type) {
                      case AnnotationType.drawing:
                        return _createDrawing(annotation);
                      case AnnotationType.text:
                        return _createText(annotation);
                      case AnnotationType.highlight:
                        return _createHighlight(annotation);
                      case AnnotationType.shape:
                        return _createShape(annotation);
                    }
                  }).toList(),
                ],
              ),
            );
          }
          
          return pages;
        },
      ),
    );

    // Save the annotated PDF
  final output = outputPath ?? await _getTemporaryPath(pdfFile.path);
    final file = File(output);
    await file.writeAsBytes(await document.save());
    return file;
  }

  pw.Widget _createDrawing(AnnotationData annotation) {
    return pw.Container(
      margin: pw.EdgeInsets.only(
        left: annotation.points.first.dx,
        top: annotation.points.first.dy,
      ),
      child: pw.CustomPaint(
        size: const PdfPoint(100, 100),
        painter: (context, size) {
          context
            ..setStrokeColor(PdfColors.black)
            ..setLineWidth(annotation.strokeWidth);
          
          var currentPoint = annotation.points.first;
          for (var point in annotation.points.skip(1)) {
            context
              ..moveTo(currentPoint.dx, currentPoint.dy)
              ..lineTo(point.dx, point.dy)
              ..strokePath();
            currentPoint = point;
          }
        },
      ),
    );
  }

  pw.Widget _createText(AnnotationData annotation) {
    return pw.Positioned(
      left: annotation.points.first.dx,
      top: annotation.points.first.dy,
      child: pw.Text(
        annotation.text ?? '',
        style: pw.TextStyle(
          color: PdfColor.fromInt(annotation.color.value),
          fontSize: annotation.strokeWidth * 6,
        ),
      ),
    );
  }

  pw.Widget _createHighlight(AnnotationData annotation) {
    return pw.Positioned(
      left: annotation.points.first.dx,
      top: annotation.points.first.dy,
      child: pw.Container(
        width: annotation.points.last.dx - annotation.points.first.dx,
        height: annotation.strokeWidth * 2,
        color: PdfColor.fromInt(annotation.color.value),
      ),
    );
  }

  pw.Widget _createShape(AnnotationData annotation) {
    return pw.Container(
      margin: pw.EdgeInsets.only(
        left: annotation.points.first.dx,
        top: annotation.points.first.dy,
      ),
      width: annotation.points.last.dx - annotation.points.first.dx,
      height: annotation.points.last.dy - annotation.points.first.dy,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
          color: PdfColor.fromInt(annotation.color.value),
          width: annotation.strokeWidth,
        ),
      ),
    );
  }

  Future<String> _getTemporaryPath(String originalPath) async {
    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = originalPath.split('/').last;
  return '${directory.path}/${timestamp}_${sanitizeFileName(fileName)}';
  }
}
