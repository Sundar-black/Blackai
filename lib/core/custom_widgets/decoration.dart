import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:black_ai/config/app_colors.dart';

class AuraBackground extends StatefulWidget {
  final Widget? child;
  const AuraBackground({super.key, this.child});

  @override
  State<AuraBackground> createState() => _AuraBackgroundState();
}

class _AuraBackgroundState extends State<AuraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(color: AppColors.background),
          ),
        ),

        // Aura Blobs - Use RepaintBoundary to isolate background animation
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Stack(
                children: [
                  _buildAuraBlob(
                    color: const Color(0xFF10A37F).withValues(alpha: 0.15),
                    alignment: _getAlignment(0, 0),
                    size: 400,
                  ),
                  _buildAuraBlob(
                    color: const Color(0xFF5436DA).withValues(alpha: 0.1),
                    alignment: _getAlignment(1, math.pi / 2),
                    size: 500,
                  ),
                  _buildAuraBlob(
                    color: const Color(0xFF10A37F).withValues(alpha: 0.1),
                    alignment: _getAlignment(2, math.pi),
                    size: 350,
                  ),
                ],
              );
            },
          ),
        ),

        // Dark Overlay for Content Readability
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.1),
            ),
          ),
        ),

        if (widget.child != null) RepaintBoundary(child: widget.child!),
      ],
    );
  }

  Alignment _getAlignment(int index, double offset) {
    final t = _controller.value * 2 * math.pi + offset;
    final x = math.cos(t + index) * 0.8;
    final y = math.sin(t * 0.7 + index) * 0.8;
    return Alignment(x, y);
  }

  Widget _buildAuraBlob({
    required Color color,
    required Alignment alignment,
    required double size,
  }) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}
