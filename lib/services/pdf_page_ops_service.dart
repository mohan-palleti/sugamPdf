import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:pdf/widgets.dart' as pw; // pdf creation
import 'package:pdf/pdf.dart';
import 'package:pdfx/pdfx.dart' as pdfx; // viewing/rendering
import 'package:image/image.dart' as img;
import 'utilities.dart';

/// Represents an inclusive page range (1-based indexes as displayed to users).
class PageRange {
  final int start; // inclusive, 1-based
  final int end;   // inclusive, 1-based
  const PageRange(this.start, this.end) : assert(start >= 1), assert(end >= start);

  Iterable<int> pages() sync* { for (int p = start; p <= end; p++) yield p; }
}

typedef ProgressCallback = void Function(double progress, String stage);

class PdfPageOpsService {
  Future<File> reorderPages({
    required String pdfPath,
    required List<int> newOrder, // 1-based page numbers in desired order
    String? outputPath,
    ProgressCallback? onProgress,
    double scale = 1.0,
    int jpegQuality = 85,
  }) async {
  return rebuildFromPageList(
      pdfPath: pdfPath,
      pageSequence: newOrder,
      rotations: const {},
      outputPath: outputPath,
      onProgress: onProgress,
      scale: scale,
      jpegQuality: jpegQuality,
    );
  }

  Future<File> deletePages({
    required String pdfPath,
    required List<int> pagesToDelete,
    String? outputPath,
    ProgressCallback? onProgress,
    double scale = 1.0,
    int jpegQuality = 85,
  }) async {
  final doc = await pdfx.PdfDocument.openFile(pdfPath); // pdfx PdfDocument
    final total = doc.pagesCount;
    final remaining = [
      for (int i = 1; i <= total; i++)
        if (!pagesToDelete.contains(i)) i
    ];
    doc.close();
  return rebuildFromPageList(
      pdfPath: pdfPath,
      pageSequence: remaining,
      rotations: const {},
      outputPath: outputPath,
      onProgress: onProgress,
      scale: scale,
      jpegQuality: jpegQuality,
    );
  }

  Future<File> rotatePages({
    required String pdfPath,
    required Map<int, int> rotations, // page -> degrees (90 multiples)
    String? outputPath,
    ProgressCallback? onProgress,
    double scale = 1.0,
    int jpegQuality = 85,
  }) async {
  final doc = await pdfx.PdfDocument.openFile(pdfPath); // pdfx PdfDocument
    final total = doc.pagesCount;
    final order = [for (int i = 1; i <= total; i++) i];
    doc.close();
  return rebuildFromPageList(
      pdfPath: pdfPath,
      pageSequence: order,
      rotations: rotations,
      outputPath: outputPath,
      onProgress: onProgress,
      scale: scale,
      jpegQuality: jpegQuality,
    );
  }

  Future<List<File>> splitPdf({
    required String pdfPath,
    required List<PageRange> ranges,
    ProgressCallback? onProgress,
    double scale = 1.0,
    int jpegQuality = 85,
  }) async {
    final outputFiles = <File>[];
    double base = 0;
    final perRange = 1 / max(ranges.length, 1);
    for (final range in ranges) {
      final pages = range.pages().toList();
  final file = await rebuildFromPageList(
        pdfPath: pdfPath,
        pageSequence: pages,
        rotations: const {},
        outputPath: null,
        onProgress: (p, s) => onProgress?.call(base + p * perRange, 'range ${range.start}-${range.end}: $s'),
        scale: scale,
        jpegQuality: jpegQuality,
      );
      outputFiles.add(file);
      base += perRange;
    }
    onProgress?.call(1, 'done');
    return outputFiles;
  }

  Future<File> compressPdf({
    required String pdfPath,
    double scale = 0.7, // downscale factor
    int jpegQuality = 70,
    String? outputPath,
    ProgressCallback? onProgress,
  }) async {
  final doc = await pdfx.PdfDocument.openFile(pdfPath); // pdfx PdfDocument
    final order = [for (int i = 1; i <= doc.pagesCount; i++) i];
    doc.close();
  return rebuildFromPageList(
      pdfPath: pdfPath,
      pageSequence: order,
      rotations: const {},
      outputPath: outputPath,
      onProgress: onProgress,
      scale: scale,
      jpegQuality: jpegQuality,
    );
  }

  Future<File> rebuildFromPageList({
    required String pdfPath,
    required List<int> pageSequence,
    required Map<int, int> rotations,
    required double scale,
    required int jpegQuality,
    String? outputPath,
    ProgressCallback? onProgress,
    bool Function()? isCancelled,
  }) async {
    onProgress?.call(0, 'opening');
  final source = await pdfx.PdfDocument.openFile(pdfPath); // pdfx PdfDocument
    final doc = pw.Document();
    final total = pageSequence.length;
    int index = 0;
    for (final pageNum in pageSequence) {
      if (isCancelled?.call() == true) {
        break; // stop early; will still write partial doc
      }
      index++;
      onProgress?.call(index / max(total, 1), 'render page $pageNum');
      final page = await source.getPage(pageNum);
      final targetWidth = page.width * scale;
      final targetHeight = page.height * scale;
      final pageImage = await page.render(
        width: targetWidth,
        height: targetHeight,
        format: pdfx.PdfPageImageFormat.png,
      );
      if (pageImage == null) continue; // skip if failed
      final rendered = pageImage.bytes; // Uint8List
      page.close();

      // Convert to JPEG with compression
      final imgDecoded = img.Image.fromBytes(
        width: pageImage.width!,
        height: pageImage.height!,
        bytes: rendered.buffer,
        order: img.ChannelOrder.rgba,
      );
      final jpg = img.encodeJpg(imgDecoded, quality: jpegQuality);
      final rotation = (rotations[pageNum] ?? 0) % 360;
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(pageImage.width!.toDouble(), pageImage.height!.toDouble()),
          build: (_) {
            pw.Widget content = pw.Image(pw.MemoryImage(Uint8List.fromList(jpg)), fit: pw.BoxFit.contain);
            if (rotation != 0) {
              final radians = rotation * pi / 180;
              content = pw.Transform.rotate(angle: radians, child: content);
            }
            return content;
          },
        ),
      );
    }
    source.close();
    onProgress?.call(0.98, 'writing');
    final originalFile = File(pdfPath);
    final parent = originalFile.parent.path;
    final originalName = originalFile.uri.pathSegments.last;
    final stem = originalName.toLowerCase().endsWith('.pdf')
        ? originalName.substring(0, originalName.length - 4)
        : originalName;
    String finalPath;
    if (outputPath != null) {
      // Sanitize only last segment
      final provided = File(outputPath);
      final providedName = sanitizeFileName(provided.uri.pathSegments.last);
      finalPath = '${provided.parent.path}/$providedName';
    } else {
      final generatedName = sanitizeFileName('${stem}_processed.pdf');
      finalPath = '$parent/$generatedName';
    }
    final file = File(finalPath);
    await file.writeAsBytes(await doc.save());
  onProgress?.call(1.0, 'done');
    return file;
  }
}
