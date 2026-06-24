import 'package:flutter/material.dart';
import '../theme/neon_theme.dart';

class NeonButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isPrimary;
  final bool isFloating;

  const NeonButton({
    super.key,
    this.onPressed,
    required this.child,
    this.isPrimary = true,
    this.isFloating = false,
  });

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    if (widget.isFloating) {
      _animation = Tween<double>(begin: 15.0, end: 30.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            _controller.reverse();
          } else if (status == AnimationStatus.dismissed) {
            _controller.forward();
          }
        });
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final glowRadius = widget.isFloating ? _animation.value : (widget.isPrimary ? 10.0 : 0.0);
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.isFloating ? 50 : 12),
            boxShadow: widget.isPrimary
                ? [
                    BoxShadow(
                      color: NeonTheme.primary.withOpacity(widget.isFloating ? 0.5 : 0.3),
                      blurRadius: glowRadius,
                      spreadRadius: 1,
                    )
                  ]
                : [],
          ),
          child: ElevatedButton(
            onPressed: widget.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.isPrimary ? NeonTheme.primary : NeonTheme.surfaceContainerHigh,
              foregroundColor: widget.isPrimary ? NeonTheme.onPrimary : NeonTheme.onBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(widget.isFloating ? 50 : 12),
                side: widget.isPrimary ? BorderSide.none : BorderSide(color: Colors.white.withOpacity(0.05)),
              ),
              padding: widget.isFloating ? const EdgeInsets.all(16) : const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              elevation: 0,
            ),
            child: widget.child,
          ),
        );
      },
    );
  }
}
