import 'dart:math';
import 'package:flutter/material.dart';
import 'word_themes.dart';

/// Shared themed building blocks for the Woodworker's Study art direction.
/// Pseudo-3D physical materials: beveled tiles, carved letters, soft shadows.
/// No neon, no gradients-as-decoration (subtle shading only).

class WlText {
  static TextStyle display(double size, WordThemeDef t) => TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w900,
        color: t.text,
        letterSpacing: 1.2,
        shadows: [
          Shadow(
              color: Colors.black.withValues(alpha: 0.55),
              offset: const Offset(0, 3),
              blurRadius: 6),
        ],
      );

  static TextStyle title(double size, WordThemeDef t) => TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: t.text,
      );

  static TextStyle body(double size, WordThemeDef t, {Color? color}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: color ?? t.text,
        height: 1.45,
      );

  static TextStyle label(double size, WordThemeDef t) => TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: t.muted,
        letterSpacing: 1.5,
      );

  static TextStyle tileLetter(double size, WordThemeDef t) => TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w900,
        color: t.letter,
        shadows: [
          Shadow(
              color: t.letterShadow.withValues(alpha: 0.7),
              offset: const Offset(0, 1.5),
              blurRadius: 0), // carved-letter light catch
          Shadow(
              color: Colors.black.withValues(alpha: 0.35),
              offset: const Offset(0, -1),
              blurRadius: 1),
        ],
      );
}

/// Full-screen warm wooden backdrop with subtle vignette.
class WlBackdrop extends StatelessWidget {
  final WordThemeDef theme;
  final Widget child;
  const WlBackdrop({super.key, required this.theme, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [theme.bgTop, theme.bgBottom],
        ),
      ),
      child: child,
    );
  }
}

/// Carved wooden button with physical depth.
class WlButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final WordThemeDef theme;
  final bool primary;
  final bool locked;

  const WlButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    required this.theme,
    this.primary = false,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = primary ? theme.accent : theme.board;
    final fg = primary ? theme.boardEdge : theme.text;
    return Opacity(
      opacity: locked ? 0.75 : 1.0,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: theme.boardEdge, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                offset: const Offset(0, 4),
                blurRadius: 8,
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.12),
                offset: const Offset(0, -2),
                blurRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: fg, size: 22),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: fg,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (locked) ...[
                const SizedBox(width: 8),
                Icon(Icons.lock, color: fg, size: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Physical letter tile: beveled face, carved letter, drop shadow.
/// [shape] indexes [TileStyles.names]. [selected] lifts and warms the tile;
/// [foundState] dims it into a "linked" token.
class WlTile extends StatelessWidget {
  final String letter;
  final WordThemeDef theme;
  final int shape;
  final bool selected;
  final bool foundState;
  final double reveal; // 0..1 scale-in for deal animation
  final int selectOrder; // 1-based order in current swipe, 0 = none

  const WlTile({
    super.key,
    required this.letter,
    required this.theme,
    required this.shape,
    this.selected = false,
    this.foundState = false,
    this.reveal = 1.0,
    this.selectOrder = 0,
  });

  @override
  Widget build(BuildContext context) {
    final scale = 0.3 + 0.7 * reveal.clamp(0.0, 1.0);
    final lift = selected ? -6.0 : 0.0;
    return Transform.translate(
      offset: Offset(0, lift),
      child: Transform.scale(
        scale: scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: _faceColor(),
            borderRadius: _radius(),
            shape: shape == 2 ? BoxShape.circle : BoxShape.rectangle,
            border: Border.all(
              color: selected ? theme.selected : theme.tileBevel,
              width: selected ? 3 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: foundState ? 0.25 : 0.5),
                offset: Offset(0, selected ? 8 : 4),
                blurRadius: selected ? 12 : 6,
              ),
              if (selected)
                BoxShadow(
                  color: theme.selected.withValues(alpha: 0.5),
                  offset: const Offset(0, 0),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.18),
                offset: const Offset(0, -2),
                blurRadius: 2,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              LayoutBuilder(
                builder: (ctx, c) => Text(
                  letter,
                  style: WlText.tileLetter(
                      c.biggest.shortestSide * 0.52, theme),
                ),
              ),
              if (selectOrder > 0)
                Positioned(
                  right: 5,
                  top: 3,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: theme.selected,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$selectOrder',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: theme.boardEdge,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _faceColor() {
    if (selected) return Color.lerp(theme.tileFace, theme.selected, 0.35)!;
    if (foundState) return Color.lerp(theme.tileFace, theme.found, 0.45)!;
    return theme.tileFace;
  }

  BorderRadius _radius() {
    switch (shape) {
      case 0:
        return BorderRadius.circular(4);
      case 1:
        return BorderRadius.circular(14);
      case 3:
        return BorderRadius.circular(6);
      case 4:
        return BorderRadius.circular(2);
      case 5:
        return BorderRadius.circular(24);
      case 6:
        return const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(4),
        );
      case 7:
        return BorderRadius.circular(8);
      default:
        return BorderRadius.circular(10);
    }
  }
}

/// Draws the swipe trail through tile centers: a warm carved-rope line.
class TrailPainter extends CustomPainter {
  final List<Offset> points;
  final Color color;

  TrailPainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.4)
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    final offsetPath = path.shift(const Offset(0, 3));
    canvas.drawPath(offsetPath, shadow);
    canvas.drawPath(path, paint);
    // Knot on each visited tile.
    for (final p in points) {
      canvas.drawCircle(
          p,
          7,
          Paint()
            ..color = color
            ..style = PaintingStyle.fill);
      canvas.drawCircle(
          p,
          7,
          Paint()
            ..color = Colors.black.withValues(alpha: 0.25)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    }
  }

  @override
  bool shouldRepaint(covariant TrailPainter old) =>
      old.points != points || old.color != color;
}

/// Shake animation for a wrong-word message (UI-side, engine only flips a nonce).
class ShakeText extends StatefulWidget {
  final String text;
  final WordThemeDef theme;
  final int nonce;
  const ShakeText(
      {super.key, required this.text, required this.theme, required this.nonce});

  @override
  State<ShakeText> createState() => _ShakeTextState();
}

class _ShakeTextState extends State<ShakeText>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  int _last = 0;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _last = widget.nonce;
    if (_last > 0) _c.forward();
  }

  @override
  void didUpdateWidget(covariant ShakeText old) {
    super.didUpdateWidget(old);
    if (widget.nonce != _last) {
      _last = widget.nonce;
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final t = _c.value;
        final dx = sin(t * pi * 5) * 10 * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: Text(
        widget.text,
        style: WlText.body(14, widget.theme, color: widget.theme.accent),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Small stat chip for HUD.
class StatChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final WordThemeDef theme;
  const StatChip(
      {super.key, required this.icon, required this.text, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: theme.board,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: theme.boardEdge, width: 2),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              offset: const Offset(0, 2),
              blurRadius: 4),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.accent),
          const SizedBox(width: 6),
          Text(text,
              style: TextStyle(
                  color: theme.text,
                  fontWeight: FontWeight.w800,
                  fontSize: 14)),
        ],
      ),
    );
  }
}
