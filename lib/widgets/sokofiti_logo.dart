import 'package:flutter/material.dart';

class SokofitiLogo extends StatelessWidget {
  final double size;
  final Color? backgroundColor;
  final double borderRadius;
  final bool showShadow;
  final bool useWhiteLogo;

  const SokofitiLogo({
    super.key,
    this.size = 120,
    this.backgroundColor,
    this.borderRadius = 25,
    this.showShadow = true,
    this.useWhiteLogo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? const Color(0xFF5BE206),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.asset(
          useWhiteLogo
              ? 'assets/images/sokofiti_logo_white_logo.png'
              : 'assets/images/sokofiti_logo.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to a simple icon if image fails to load
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                size: size * 0.5,
                color: const Color(0xFF5BE206),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Animated version of the logo
class AnimatedSokofitiLogo extends StatefulWidget {
  final double size;
  final Color? backgroundColor;
  final double borderRadius;
  final bool showShadow;
  final bool useWhiteLogo;

  const AnimatedSokofitiLogo({
    super.key,
    this.size = 120,
    this.backgroundColor,
    this.borderRadius = 25,
    this.showShadow = true,
    this.useWhiteLogo = false,
  });

  @override
  State<AnimatedSokofitiLogo> createState() => _AnimatedSokofitiLogoState();
}

class _AnimatedSokofitiLogoState extends State<AnimatedSokofitiLogo>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: SokofitiLogo(
            size: widget.size,
            backgroundColor: widget.backgroundColor,
            borderRadius: widget.borderRadius,
            showShadow: widget.showShadow,
            useWhiteLogo: widget.useWhiteLogo,
          ),
        );
      },
    );
  }
}
