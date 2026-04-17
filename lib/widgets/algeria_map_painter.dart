import 'package:flutter/material.dart';
import '../models/wilaya.dart';
import '../controllers/game_controller.dart';

class AlgeriaMapPainter extends CustomPainter {
  final List<Wilaya> wilayas;
  final GameController controller;
  final Rect viewRect;
  final double zoom;
  final bool showAllNames;

  AlgeriaMapPainter({
    required this.wilayas,
    required this.controller,
    required this.viewRect,
    required this.zoom,
    required this.showAllNames,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (wilayas.isEmpty) return;
    if (viewRect.width <= 0 || viewRect.height <= 0) return;

    final scaleX = size.width / viewRect.width;
    final scaleY = size.height / viewRect.height;
    double scale = scaleX < scaleY ? scaleX : scaleY;
    scale *= zoom;

    final offsetX = (size.width - viewRect.width * scale) / 2;
    final offsetY = (size.height - viewRect.height * scale) / 2;

    canvas.save();
    canvas.translate(offsetX, offsetY);
    canvas.scale(scale, scale);
    canvas.translate(-viewRect.left, -viewRect.top);
    canvas.clipRect(viewRect);

    for (var w in wilayas) {
      final bounds = w.path.getBounds();
      if (!viewRect.overlaps(bounds)) continue;

      Color fillColor;
      if (w.isFlashing) {
        fillColor = w.flashColor;
      } else if (controller.discoveredIds.contains(w.id)) {
        fillColor = Colors.green.withOpacity(0.6);
      } else {
        
        fillColor = const Color(0xFFF0EEFF); 
      }

      canvas.drawPath(
        w.path,
        Paint()
          ..color = fillColor
          ..style = PaintingStyle.fill,
      );

      canvas.drawPath(
        w.path,
        Paint()
          ..color = Colors.grey[600]!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    if (showAllNames) {
      List<Rect> drawnRects = [];
      for (var w in wilayas) {
        final bounds = w.path.getBounds();
        if (!viewRect.overlaps(bounds)) continue;
        if (w.center != Offset.zero) {
          final textSpan = TextSpan(
            text: w.name,
            style: TextStyle(
              color: Colors.black,
              fontSize: 12 / scale,
              fontWeight: FontWeight.bold,
            ),
          );
          final tp = TextPainter(text: textSpan, textDirection: TextDirection.rtl);
          tp.layout();
          final offset = Offset(w.center.dx - tp.width / 2, w.center.dy - tp.height / 2);
          final rect = offset & tp.size;
          bool overlap = false;
          for (var r in drawnRects) {
            if (r.overlaps(rect)) { overlap = true; break; }
          }
          if (!overlap) {
            drawnRects.add(rect);
            tp.paint(canvas, offset);
          }
        }
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant AlgeriaMapPainter oldDelegate) {
    return oldDelegate.showAllNames != showAllNames ||
        oldDelegate.controller != controller ||
        oldDelegate.viewRect != viewRect ||
        oldDelegate.zoom != zoom;
  }
}