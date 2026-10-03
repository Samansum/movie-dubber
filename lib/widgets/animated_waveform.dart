import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AnimatedWaveform extends StatefulWidget {
  final bool isPlaying;
  final int barCount;
  final double height;
  final Color activeColor;
  final Color inactiveColor;

  const AnimatedWaveform({
    super.key,
    required this.isPlaying,
    this.barCount = 14,
    this.height = 24,
    this.activeColor = AppColors.secondary,
    this.inactiveColor = AppColors.surfaceBright,
  });

  @override
  State<AnimatedWaveform> createState() => _AnimatedWaveformState();
}

class _AnimatedWaveformState extends State<AnimatedWaveform> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random(42);
  late List<double> _baseHeights;

  @override
  void initState() {
    super.initState();
    _baseHeights = List.generate(widget.barCount, (index) => 0.2 + _random.nextDouble() * 0.8);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..addListener(() {
        if (mounted) setState(() {});
      });

    if (widget.isPlaying) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(widget.barCount, (index) {
          final factor = widget.isPlaying
              ? (sin((_controller.value * pi * 2) + index * 0.5).abs() * 0.7 + 0.3)
              : _baseHeights[index];
          final barHeight = (widget.height * factor).clamp(4.0, widget.height);
          final isHighlighted = index % 3 == 0 || index % 5 == 0;

          return Container(
            width: 3,
            height: barHeight,
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              color: widget.isPlaying
                  ? (isHighlighted ? AppColors.primary : widget.activeColor)
                  : widget.inactiveColor,
              borderRadius: BorderRadius.circular(99),
              boxShadow: widget.isPlaying && isHighlighted
                  ? [
                      BoxShadow(
                        color: widget.activeColor.withOpacity(0.5),
                        blurRadius: 4,
                      ),
                    ]
                  : null,
            ),
          );
        }),
      ),
    );
  }
}
