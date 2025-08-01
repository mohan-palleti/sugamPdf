import 'package:flutter/material.dart';
import '../models/annotation.dart';

class PdfAnnotationLayer extends StatelessWidget {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final AnnotationType type;

  const PdfAnnotationLayer({
    Key? key,
    required this.points,
    required this.color,
    required this.strokeWidth,
    required this.type,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _AnnotationPainter(
        points: points,
        color: color,
        strokeWidth: strokeWidth,
        type: type,
      ),
    );
  }
}

class _AnnotationPainter extends CustomPainter {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final AnnotationType type;

  _AnnotationPainter({
    required this.points,
    required this.color,
    required this.strokeWidth,
    required this.type,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    switch (type) {
      case AnnotationType.drawing:
        _drawFreehand(canvas, paint);
        break;
      case AnnotationType.highlight:
        _drawHighlight(canvas, paint, size);
        break;
      case AnnotationType.shape:
        _drawShape(canvas, paint);
        break;
      case AnnotationType.text:
        // Text is handled separately in the widget layer
        break;
    }
  }

  void _drawFreehand(Canvas canvas, Paint paint) {
    paint.style = PaintingStyle.stroke;
    
    if (points.length < 2) return;
    
    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    
    canvas.drawPath(path, paint);
  }

  void _drawHighlight(Canvas canvas, Paint paint, Size size) {
    if (points.length < 2) return;
    
    paint
      ..style = PaintingStyle.fill
      ..color = color.withOpacity(0.3);
    
    final rect = Rect.fromPoints(points.first, points.last);
    canvas.drawRect(rect, paint);
  }

  void _drawShape(Canvas canvas, Paint paint) {
    if (points.length < 2) return;
    
    paint.style = PaintingStyle.stroke;
    final rect = Rect.fromPoints(points.first, points.last);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _AnnotationPainter oldDelegate) {
    return points != oldDelegate.points ||
        color != oldDelegate.color ||
        strokeWidth != oldDelegate.strokeWidth ||
        type != oldDelegate.type;
  }
}
