import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hotel_management_system/features/super_admin/domain/entities/super_admin_entities.dart';

class SimpleTrendChart extends StatelessWidget {
  const SimpleTrendChart({
    super.key,
    required this.title,
    required this.points,
    this.lineColor,
  });

  final String title;
  final List<TrendPoint> points;
  final Color? lineColor;

  @override
  Widget build(BuildContext context) {
    final chartColor = lineColor ?? Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          SizedBox(
            height: 180,
            child: points.isEmpty
                ? const Center(child: Text('No data available'))
                : CustomPaint(
                    painter: _TrendPainter(
                      points: points,
                      lineColor: chartColor,
                    ),
                    child: const SizedBox.expand(),
                  ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 4,
            children: points
                .map(
                  (p) => Text(
                    '${p.label}: ${p.value.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({required this.points, required this.lineColor});

  final List<TrendPoint> points;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final maxValue = points.map((e) => e.value).reduce(math.max);
    final minValue = points.map((e) => e.value).reduce(math.min);
    final valueRange = (maxValue - minValue).abs() < 0.001
        ? 1.0
        : (maxValue - minValue);

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = (size.width / (points.length - 1)) * i;
      final normalized = (points[i].value - minValue) / valueRange;
      final y = size.height - (normalized * (size.height - 8)) - 4;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          lineColor.withValues(alpha: 0.2),
          lineColor.withValues(alpha: 0.01),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.lineColor != lineColor;
  }
}
