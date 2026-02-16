import 'package:flutter/material.dart';
import 'package:focus_life/services/furniture_service.dart';
import 'cave_interior_painter.dart';
import 'shack_interior_painter.dart';
import 'house_interior_painter.dart';
import 'mansion_interior_painter.dart';

// Re-export so existing imports still work
export 'cave_interior_painter.dart';
export 'shack_interior_painter.dart';
export 'house_interior_painter.dart';
export 'mansion_interior_painter.dart';

/// Get the interior painter for a given stage.
/// Pass [furnitureService] so equipped items are drawn.
CustomPainter getInteriorPainter(int stage, {FurnitureService? furnitureService}) {
  final fs = furnitureService ?? FurnitureService();
  switch (stage) {
    case 0: return CaveInteriorPainter(furniture: fs);
    case 1: return ShackInteriorPainter(furniture: fs);
    case 2: return HouseInteriorPainter(furniture: fs);
    case 3: return MansionInteriorPainter(furniture: fs);
    default: return CaveInteriorPainter(furniture: fs);
  }
}