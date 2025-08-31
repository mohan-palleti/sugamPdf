import 'dart:ui';

enum AnnotationType {
  drawing,
  text,
  highlight,
  shape
}

class AnnotationData {
  final AnnotationType type;
  final List<Offset> points;
  final String? text;
  final Color color;
  final double strokeWidth;
  final int pageNumber;

  AnnotationData({
    required this.type,
    required this.points,
    this.text,
    required this.color,
    this.strokeWidth = 2.0,
    required this.pageNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString(),
      'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
      'text': text,
      'color': color.toARGB32(),
      'strokeWidth': strokeWidth,
      'pageNumber': pageNumber,
    };
  }

  factory AnnotationData.fromJson(Map<String, dynamic> json) {
    return AnnotationData(
      type: AnnotationType.values.firstWhere(
        (e) => e.toString() == json['type'],
      ),
      points: (json['points'] as List).map((p) => Offset(
        p['x'] as double,
        p['y'] as double,
      )).toList(),
      text: json['text'] as String?,
      color: Color(json['color'] as int),
      strokeWidth: json['strokeWidth'] as double,
      pageNumber: json['pageNumber'] as int,
    );
  }
}
