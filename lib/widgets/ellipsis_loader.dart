import 'package:flutter/material.dart';

class EllipsisLoader extends StatefulWidget {
  final double size;
  final Color? color1;
  final Color? color2;
  final Color? color3;
  final Duration duration;

  const EllipsisLoader({
    super.key,
    this.size = 8.0,
    this.color1,
    this.color2,
    this.color3,
    this.duration = const Duration(milliseconds: 1200),
  });

  @override
  State<EllipsisLoader> createState() => _EllipsisLoaderState();
}

class _EllipsisLoaderState extends State<EllipsisLoader>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation1;
  late Animation<double> _animation2;
  late Animation<double> _animation3;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    // Create staggered animations for each dot
    _animation1 = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.33, curve: Curves.easeInOut),
      ),
    );

    _animation2 = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.33, 0.66, curve: Curves.easeInOut),
      ),
    );

    _animation3 = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.66, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.repeat();
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
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(_animation1, widget.color1 ?? const Color(0xFF5BE206)),
            SizedBox(width: widget.size * 0.5),
            _buildDot(_animation2, widget.color2 ?? const Color(0xFFFFD700)),
            SizedBox(width: widget.size * 0.5),
            _buildDot(_animation3, widget.color3 ?? const Color(0xFFFF9800)),
          ],
        );
      },
    );
  }

  Widget _buildDot(Animation<double> animation, Color color) {
    return Transform.scale(
      scale: 0.5 + (animation.value * 0.5),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.3 + (animation.value * 0.7)),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// Predefined variants for common use cases
class EllipsisLoaderSmall extends StatelessWidget {
  const EllipsisLoaderSmall({super.key});

  @override
  Widget build(BuildContext context) {
    return const EllipsisLoader(size: 6.0);
  }
}

class EllipsisLoaderMedium extends StatelessWidget {
  const EllipsisLoaderMedium({super.key});

  @override
  Widget build(BuildContext context) {
    return const EllipsisLoader(size: 10.0);
  }
}

class EllipsisLoaderLarge extends StatelessWidget {
  const EllipsisLoaderLarge({super.key});

  @override
  Widget build(BuildContext context) {
    return const EllipsisLoader(size: 14.0);
  }
}

// Pulsing variant
class PulsingEllipsisLoader extends StatefulWidget {
  final double size;
  final Color? color1;
  final Color? color2;
  final Color? color3;
  final Duration duration;

  const PulsingEllipsisLoader({
    super.key,
    this.size = 8.0,
    this.color1,
    this.color2,
    this.color3,
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  State<PulsingEllipsisLoader> createState() => _PulsingEllipsisLoaderState();
}

class _PulsingEllipsisLoaderState extends State<PulsingEllipsisLoader>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation1;
  late Animation<double> _animation2;
  late Animation<double> _animation3;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    // Create staggered pulsing animations
    _animation1 = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
      ),
    );

    _animation2 = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.7, curve: Curves.easeInOut),
      ),
    );

    _animation3 = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.9, curve: Curves.easeInOut),
      ),
    );

    _controller.repeat(reverse: true);
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
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPulsingDot(_animation1, widget.color1 ?? const Color(0xFF5BE206)),
            SizedBox(width: widget.size * 0.5),
            _buildPulsingDot(_animation2, widget.color2 ?? const Color(0xFFFFD700)),
            SizedBox(width: widget.size * 0.5),
            _buildPulsingDot(_animation3, widget.color3 ?? const Color(0xFFFF9800)),
          ],
        );
      },
    );
  }

  Widget _buildPulsingDot(Animation<double> animation, Color color) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: animation.value),
        shape: BoxShape.circle,
      ),
    );
  }
}

// Bouncing variant
class BouncingEllipsisLoader extends StatefulWidget {
  final double size;
  final Color? color1;
  final Color? color2;
  final Color? color3;
  final Duration duration;

  const BouncingEllipsisLoader({
    super.key,
    this.size = 8.0,
    this.color1,
    this.color2,
    this.color3,
    this.duration = const Duration(milliseconds: 1000),
  });

  @override
  State<BouncingEllipsisLoader> createState() => _BouncingEllipsisLoaderState();
}

class _BouncingEllipsisLoaderState extends State<BouncingEllipsisLoader>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation1;
  late Animation<double> _animation2;
  late Animation<double> _animation3;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    // Create staggered bouncing animations
    _animation1 = Tween<double>(
      begin: 0.0,
      end: -widget.size,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.bounceOut),
      ),
    );

    _animation2 = Tween<double>(
      begin: 0.0,
      end: -widget.size,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.7, curve: Curves.bounceOut),
      ),
    );

    _animation3 = Tween<double>(
      begin: 0.0,
      end: -widget.size,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.9, curve: Curves.bounceOut),
      ),
    );

    _controller.repeat();
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
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildBouncingDot(_animation1, widget.color1 ?? const Color(0xFF5BE206)),
            SizedBox(width: widget.size * 0.5),
            _buildBouncingDot(_animation2, widget.color2 ?? const Color(0xFFFFD700)),
            SizedBox(width: widget.size * 0.5),
            _buildBouncingDot(_animation3, widget.color3 ?? const Color(0xFFFF9800)),
          ],
        );
      },
    );
  }

  Widget _buildBouncingDot(Animation<double> animation, Color color) {
    return Transform.translate(
      offset: Offset(0, animation.value),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
