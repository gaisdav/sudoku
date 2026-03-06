import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Draws bold lines separating the nine 3×3 blocks of the Sudoku grid.
class SudokuGridPainter extends CustomPainter {
  SudokuGridPainter({
    required this.color,
    this.strokeWidth = 2.5,
  });

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;

    // Vertical lines between 3×3 blocks (at 1/3 and 2/3 of width)
    canvas.drawLine(Offset(w / 3, 0), Offset(w / 3, h), paint);
    canvas.drawLine(Offset(2 * w / 3, 0), Offset(2 * w / 3, h), paint);

    // Horizontal lines between 3×3 blocks
    canvas.drawLine(Offset(0, h / 3), Offset(w, h / 3), paint);
    canvas.drawLine(Offset(0, 2 * h / 3), Offset(w, 2 * h / 3), paint);
  }

  @override
  bool shouldRepaint(covariant SudokuGridPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}
