import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/court_type_model.dart';

/// Locally drawn court illustrations: sharp at every resolution, no URL,
/// download, asset decoding or external font is required.
class CourtArtwork extends StatelessWidget {
  const CourtArtwork({
    super.key,
    required this.type,
    this.height = 180,
    this.variant = 0,
  });
  final CourtType type;
  final double height;
  final int variant;
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Hình minh họa sân ${type.label}',
    image: true,
    child: SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _CourtPainter(type, variant)),
    ),
  );
}

class _CourtPainter extends CustomPainter {
  _CourtPainter(this.type, this.variant);
  final CourtType type;
  final int variant;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final background = switch (type) {
      CourtType.football => const Color(0xFF153E2C),
      CourtType.badminton => const Color(0xFF23474B),
      CourtType.volleyball => const Color(0xFF674A32),
      CourtType.basketball => const Color(0xFF4D3C31),
      CourtType.pickleball => const Color(0xFF21474A),
    };
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [background.withValues(alpha: .84), background],
        ).createShader(rect),
    );
    final random = math.Random(variant + 41);
    final tree = Paint()..color = Colors.white.withValues(alpha: .035);
    for (var i = 0; i < 20; i++) {
      canvas.drawCircle(
        Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        ),
        10 + random.nextDouble() * 30,
        tree,
      );
    }
    // Floodlights and surrounding path set the scene outside the playing area.
    final pole = Paint()
      ..color = const Color(0xFF9FB5A8)
      ..strokeWidth = 2;
    for (final x in [.08, .92]) {
      canvas.drawLine(
        Offset(size.width * x, size.height * .17),
        Offset(size.width * x, size.height * .6),
        pole,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(size.width * x, size.height * .17),
            width: 22,
            height: 5,
          ),
          const Radius.circular(2),
        ),
        Paint()..color = const Color(0xFFF3E5B6),
      );
    }
    canvas.save();
    canvas.translate(size.width * .5, size.height * .53);
    canvas.rotate(-.10);
    final w = size.width * .72;
    final h = size.height * .64;
    final field = Rect.fromCenter(center: Offset.zero, width: w, height: h);
    canvas.drawRRect(
      RRect.fromRectAndRadius(field.inflate(9), const Radius.circular(4)),
      Paint()..color = const Color(0xFFADB8A0),
    );
    final fieldColor = switch (type) {
      CourtType.football => const Color(0xFF438D53),
      CourtType.badminton => const Color(0xFF459184),
      CourtType.volleyball => const Color(0xFFD4AD6F),
      CourtType.basketball => const Color(0xFFC08B54),
      CourtType.pickleball => const Color(0xFF458CA5),
    };
    canvas.drawRect(field, Paint()..color = fieldColor);
    if (type == CourtType.football) {
      for (var i = 0; i < 8; i += 2) {
        canvas.drawRect(
          Rect.fromLTWH(field.left + w / 8 * i, field.top, w / 8, h),
          Paint()..color = Colors.white.withValues(alpha: .07),
        );
      }
    }
    final line = Paint()
      ..color = const Color(0xFFF2F5DD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final inner = field.deflate(10);
    canvas.drawRect(inner, line);
    canvas.drawLine(Offset(0, inner.top), Offset(0, inner.bottom), line);
    if (type == CourtType.football || type == CourtType.basketball) {
      canvas.drawCircle(Offset.zero, h * .17, line);
      for (final edge in [-1, 1]) {
        final x = edge == -1 ? inner.left : inner.right - w * .15;
        canvas.drawRect(Rect.fromLTWH(x, -h * .22, w * .15, h * .44), line);
        if (type == CourtType.basketball) {
          canvas.drawCircle(Offset(edge * (w / 2 - 16), 0), 5, line);
        }
      }
    } else {
      canvas.drawLine(
        Offset(inner.left, -h * .25),
        Offset(inner.right, -h * .25),
        line,
      );
      canvas.drawLine(
        Offset(inner.left, h * .25),
        Offset(inner.right, h * .25),
        line,
      );
      canvas.drawLine(Offset(inner.left, 0), Offset(inner.right, 0), line);
      canvas.drawLine(
        Offset(-w * .18, inner.top),
        Offset(-w * .18, inner.bottom),
        line,
      );
      canvas.drawLine(
        Offset(w * .18, inner.top),
        Offset(w * .18, inner.bottom),
        line,
      );
      canvas.drawLine(
        Offset(0, field.top - 4),
        Offset(0, field.bottom + 4),
        Paint()
          ..color = const Color(0xFF263C37)
          ..strokeWidth = 3,
      );
    }
    // A pair of players gives scale to the illustration.
    for (final point in [Offset(-w * .24, h * .08), Offset(w * .26, -h * .1)]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: point + const Offset(3, 4),
          width: 14,
          height: 7,
        ),
        Paint()..color = Colors.black.withValues(alpha: .15),
      );
      canvas.drawCircle(point, 4, Paint()..color = const Color(0xFFF4D475));
      canvas.drawCircle(
        point + const Offset(0, -2),
        2,
        Paint()..color = const Color(0xFF394439),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CourtPainter oldDelegate) =>
      oldDelegate.type != type || oldDelegate.variant != variant;
}
