import 'dart:io';
import 'dart:ui';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../models/annotation.dart';

class PdfAnnotationService {
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
    return '${directory.path}/${timestamp}_$fileName';
  }
}
