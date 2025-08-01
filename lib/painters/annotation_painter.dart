import 'package:flutter/material.dart';
import '../models/annotation.dart';

class AnnotationPainter extends CustomPainter {
  final List<AnnotationData> annotations;
  final List<Offset> currentPoints;
  final Color currentColor;
  final double currentStrokeWidth;
  final AnnotationType currentTool;

  AnnotationPainter({
    required this.annotations,
    required this.currentPoints,
    required this.currentColor,
    required this.currentStrokeWidth,
    required this.currentTool,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw existing annotations
    for (final annotation in annotations) {
      _drawAnnotation(canvas, annotation);
    }

    // Draw current annotation being created
    if (currentPoints.isNotEmpty) {
      final currentAnnotation = AnnotationData(
        type: currentTool,
        points: currentPoints,
        color: currentColor,
        strokeWidth: currentStrokeWidth,
        pageNumber: 0, // Current page number should be passed if needed
      );
      _drawAnnotation(canvas, currentAnnotation);
    }
  }

  void _drawAnnotation(Canvas canvas, AnnotationData annotation) {
    final paint = Paint()
      ..color = annotation.color
      ..strokeWidth = annotation.strokeWidth
      ..strokeCap = StrokeCap.round;

    switch (annotation.type) {
      case AnnotationType.drawing:
        _drawFreehand(canvas, paint, annotation.points);
        break;
      case AnnotationType.highlight:
        _drawHighlight(canvas, paint, annotation.points);
        break;
      case AnnotationType.shape:
        _drawShape(canvas, paint, annotation.points);
        break;
      case AnnotationType.text:
        // Text annotations are handled separately in the widget layer
        break;
    }
  }

  void _drawFreehand(Canvas canvas, Paint paint, List<Offset> points) {
    if (points.length < 2) return;

    paint.style = PaintingStyle.stroke;
    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, paint);
  }

  void _drawHighlight(Canvas canvas, Paint paint, List<Offset> points) {
    if (points.length < 2) return;

    paint
      ..style = PaintingStyle.fill
      ..color = paint.color.withOpacity(0.3);

    final rect = Rect.fromPoints(points.first, points.last);
    canvas.drawRect(rect, paint);
  }

  void _drawShape(Canvas canvas, Paint paint, List<Offset> points) {
    if (points.length < 2) return;

    paint.style = PaintingStyle.stroke;
    final rect = Rect.fromPoints(points.first, points.last);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant AnnotationPainter oldDelegate) {
    return annotations != oldDelegate.annotations ||
        currentPoints != oldDelegate.currentPoints ||
        currentColor != oldDelegate.currentColor ||
        currentStrokeWidth != oldDelegate.currentStrokeWidth ||
        currentTool != oldDelegate.currentTool;
  }
}
