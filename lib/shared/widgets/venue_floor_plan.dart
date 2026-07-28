import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class VenueFloorPlan extends StatelessWidget {
  const VenueFloorPlan({
    super.key,
    required this.rooms,
    required this.floor,
    this.highlightRoomId,
  });

  final List<String> rooms;
  final String floor;
  final String? highlightRoomId;

  @override
  Widget build(BuildContext context) {
    final chrome = AppChromeColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    return CustomPaint(
      painter: _FloorPlanPainter(
        floor: floor,
        rooms: rooms,
        highlightRoomId: highlightRoomId,
        textStyle: Theme.of(context).textTheme.bodySmall,
        fillColor: chrome.elevatedPanel,
        borderColor: scheme.outlineVariant,
      ),
      child: SizedBox(width: double.infinity, height: floor == 'G' ? 170 : 320),
    );
  }
}

class _FloorPlanPainter extends CustomPainter {
  _FloorPlanPainter({
    required this.floor,
    required this.rooms,
    required this.highlightRoomId,
    required this.textStyle,
    required this.fillColor,
    required this.borderColor,
  });

  final String floor;
  final List<String> rooms;
  final String? highlightRoomId;
  final TextStyle? textStyle;
  final Color fillColor;
  final Color borderColor;

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = borderColor;
    final fill = Paint()..color = fillColor;
    final highlight = Paint()..color = const Color(0x6622C55E);

    if (floor == 'G') {
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(12, 16, size.width - 24, size.height - 32),
        const Radius.circular(16),
      );
      canvas.drawRRect(rect, fill);
      canvas.drawRRect(rect, borderPaint);
      _drawLabel(canvas, Offset(24, size.height / 2 - 8), 'Reception Hall');
      return;
    }

    final columns = 6;
    final rows = 2;
    final gutter = 8.0;
    final cellW = (size.width - gutter * (columns + 1)) / columns;
    final cellH = (size.height - gutter * (rows + 2)) / rows;
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < columns; col++) {
        final index = row * columns + col;
        if (index >= rooms.length) continue;
        final roomId = rooms[index];
        final x = gutter + col * (cellW + gutter);
        final y = gutter + (row + 1) * gutter + row * cellH;
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, cellW, cellH),
          const Radius.circular(8),
        );
        canvas.drawRRect(rect, fill);
        if (highlightRoomId == roomId) {
          canvas.drawRRect(rect, highlight);
        }
        canvas.drawRRect(rect, borderPaint);
        _drawLabel(
          canvas,
          Offset(x + 6, y + 6),
          roomId.replaceFirst('ven-', ''),
        );
      }
    }
    _drawLabel(
      canvas,
      const Offset(12, 8),
      floor == '6' ? 'North / South wings' : 'North row · South row',
    );
  }

  void _drawLabel(Canvas canvas, Offset offset, String value) {
    final tp = TextPainter(
      text: TextSpan(text: value, style: textStyle),
      textDirection: TextDirection.ltr,
      maxLines: 2,
    )..layout(maxWidth: 220);
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _FloorPlanPainter oldDelegate) {
    return oldDelegate.floor != floor ||
        oldDelegate.highlightRoomId != highlightRoomId ||
        oldDelegate.rooms != rooms;
  }
}
