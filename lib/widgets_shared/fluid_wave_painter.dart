import 'dart:math' as math;
import 'package:flutter/material.dart';

// =========================================================================
// CUSTOM PAINTER: ONDA 3D OBLIQUA, AD ALTA DENSITÀ E MOVIMENTO CONTINUO
// =========================================================================
class FluidWavePainter extends CustomPainter {
  final double animationValue;

  FluidWavePainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()..style = PaintingStyle.fill;
    final linePaint = Paint()..style = PaintingStyle.stroke;

    const int rows = 50; 
    const int cols = 75; 

    // Fase periodica pura per garantire un loop fluido a 360° senza scatti
    final double loopPhase = math.sin(animationValue * 2 * math.pi);
    final double loopPhaseCos = math.cos(animationValue * 2 * math.pi);
    
    const double rotationAngle = -0.42; // Inclinazione obliqua

    List<List<_Point3D>> grid = [];

    // 1. GENERAZIONE GRID 3D ULTRA-DENSA CON ONDA FLUIDA
    for (int r = 0; r < rows; r++) {
      List<_Point3D> rowPoints = [];
      double normR = r / (rows - 1);

      for (int c = 0; c < cols; c++) {
        double normC = c / (cols - 1);

        // Profondità Z
        double z = 260.0 + (1.0 - normR) * 840.0; 
        double xRaw = (normC - 0.5) * 1700.0;
        
        // Equazione dell'onda basata su oscillazioni armoniche continue
        double wave1 = math.sin(normC * math.pi * 3.5 + loopPhase * 1.5) * 90.0;
        double wave2 = math.cos(normR * math.pi * 2.8 + normC * math.pi * 1.8 + loopPhaseCos * 1.2) * 45.0;
        double wave3 = math.sin((normC * 2 + normR) * math.pi * 1.5 + loopPhase * 0.8) * 20.0;

        double yRaw = (normR - 0.5) * 450.0 + wave1 + wave2 + wave3;

        // ROTAZIONE MATEMATICA PER INCLINAZIONE OBLIQUA
        double xRotated = xRaw * math.cos(rotationAngle) - yRaw * math.sin(rotationAngle);
        double yRotated = xRaw * math.sin(rotationAngle) + yRaw * math.cos(rotationAngle);

        // PROIEZIONE PROSPETTICA
        double perspective = 500.0 / z;
        double x2D = size.width / 2 + xRotated * perspective;
        double y2D = size.height * 0.68 + yRotated * perspective;

        // Variazione armonica di scala dei pallini
        double randomSizeFactor = 0.5 + 0.9 * math.sin(r * 15.3 + c * 9.7).abs();

        rowPoints.add(_Point3D(
          offset: Offset(x2D, y2D),
          z: z,
          scale: perspective,
          normR: normR,
          normC: normC,
          sizeFactor: randomSizeFactor,
        ));
      }
      grid.add(rowPoints);
    }

    // 2. DISEGNO RETICOLATO E PARTICELLE
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        _Point3D point = grid[r][c];

        // Mappatura Profondità Z
        double depthFactor = ((1100.0 - point.z) / 840.0).clamp(0.0, 1.0); 
        double alpha = (math.pow(depthFactor, 1.8) * 0.48).toDouble().clamp(0.01, 0.48);

        Color pointColor = Color.lerp(
          const Color(0xFF041E18),
          const Color(0xFF2DD4BF),
          depthFactor,
        )!;

        // A. RETE ORIZZONTALE
        if (c < cols - 1) {
          _Point3D nextCol = grid[r][c + 1];
          linePaint.strokeWidth = 0.15 + depthFactor * 0.45;
          linePaint.color = pointColor.withOpacity(alpha * 0.22);
          canvas.drawLine(point.offset, nextCol.offset, linePaint);
        }

        // B. RETE VERTICALE
        if (r < rows - 1) {
          _Point3D nextRow = grid[r + 1][c];
          linePaint.strokeWidth = 0.12 + depthFactor * 0.35;
          linePaint.color = const Color(0xFF0D9488).withOpacity(alpha * 0.15);
          canvas.drawLine(point.offset, nextRow.offset, linePaint);
        }

        // C. PALLINI FITTI E PICCOLI CON DIMENSIONI DIVERSIFICATE
        double baseRadius = (0.25 + math.pow(depthFactor, 2.3) * 2.1) * point.scale * 1.05;
        double finalRadius = baseRadius * point.sizeFactor;

        // Punti di luce bianchi diffusi
        bool isBrightStar = depthFactor > 0.62 && (r * 9 + c * 5) % 13 == 0;

        dotPaint.color = Color.lerp(
          pointColor,
          Colors.white,
          isBrightStar ? 0.8 : 0.04,
        )!.withOpacity(isBrightStar ? (alpha * 1.35).clamp(0.1, 0.9) : alpha * 1.05);

        canvas.drawCircle(point.offset, isBrightStar ? finalRadius * 1.25 : finalRadius, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant FluidWavePainter oldDelegate) => true;
}

// Classe di supporto per la proiezione 3D
class _Point3D {
  final Offset offset;
  final double z;
  final double scale;
  final double normR;
  final double normC;
  final double sizeFactor;

  _Point3D({
    required this.offset,
    required this.z,
    required this.scale,
    required this.normR,
    required this.normC,
    required this.sizeFactor,
  });
}