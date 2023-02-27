import 'dart:ui';

import 'package:flutter/rendering.dart';
import 'package:perfect_freehand/perfect_freehand.dart' as pf;
import 'package:scribble/scribble.dart';

class ScribblePainter extends CustomPainter {
  ScribblePainter({
    required this.state,
    required this.drawPointer,
    required this.drawEraser,
  });

  final ScribbleState state;
  final bool drawPointer;
  final bool drawEraser;

  List<SketchLine> get lines => state.lines;

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < lines.length; ++i) {
      final line = lines[i];
      final simulatePressure = line.points.isNotEmpty &&
          line.points.every((p) => p.pressure == line.points.first.pressure);
      paint.color = Color(lines[i].color);
      final points = line.points
          .map((point) => pf.Point(point.x, point.y, point.pressure))
          .toList();
      final outlinePoints = pf.getStroke(
        points,
        size: line.width * 2 * state.scaleFactor,
        simulatePressure: simulatePressure,
        thinning: 0.0,
      );
      final path = Path();
      if (outlinePoints.isEmpty) {
        continue;
      } else if (outlinePoints.length < 2) {
        path.addOval(Rect.fromCircle(
            center: Offset(outlinePoints[0].x, outlinePoints[0].y), radius: 1));
      } else {
        path.moveTo(outlinePoints[0].x, outlinePoints[0].y);
        for (int i = 1; i < outlinePoints.length - 1; ++i) {
          final p0 = outlinePoints[i];
          final p1 = outlinePoints[i + 1];
          path.quadraticBezierTo(
              p0.x, p0.y, (p0.x + p1.x) / 2, (p0.y + p1.y) / 2);
        }
      }
      paint.color = Color(lines[i].color);
      canvas.drawPath(path, paint);
    }
    if (state.pointerPosition != null &&
        (state is Drawing && drawPointer || state is Erasing && drawEraser)) {
      paint.style = state.map(
        drawing: (_) => PaintingStyle.fill,
        erasing: (_) => PaintingStyle.stroke,
      );
      paint.color = state.map(
        drawing: (s) => Color(s.selectedColor),
        erasing: (s) => const Color(0xFF000000),
      );
      paint.strokeWidth = 1;
      canvas.drawCircle(
        state.pointerPosition!.asOffset,
        state.selectedWidth / state.scaleFactor,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ScribblePainter oldDelegate) {
    return oldDelegate.state != state;
  }
}
