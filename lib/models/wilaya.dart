import 'package:flutter/material.dart';

class Wilaya {
  final String id;
  final String name;
  final String? pathString;
  final String? pointsString;
  final bool isPolygon;
  final double translateX;
  final double translateY;
  late Path path;
  bool isDiscovered = false;
  bool isFlashing = false;
  Color flashColor = Colors.transparent;
  Offset center = Offset.zero;

  Wilaya({
    required this.id,
    required this.name,
    this.pathString,
    this.pointsString,
    this.isPolygon = false,
    this.translateX = 0,
    this.translateY = 0,
  }) : assert(pathString != null || pointsString != null,
            'Either pathString or pointsString must be provided');
}