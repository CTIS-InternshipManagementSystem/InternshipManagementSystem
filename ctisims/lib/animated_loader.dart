import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedLoader extends StatefulWidget {
  final Color color;
  final double size;
  final String? message;
  final bool isLoading;
  
  const AnimatedLoader({
    Key? key, 
    this.color = Colors.orange, 
    this.size = 50.0,
    this.message,
    this.isLoading = true,
  }) : super(key: key);

  @override
  _AnimatedLoaderState createState() => _AnimatedLoaderState();
}

class _AnimatedLoaderState extends State<AnimatedLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _radiusAnimation;
  late Animation<double> _opacityAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _rotationAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubic,
      ),
    );
    
    _radiusAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubic,
      ),
    );
    
    _opacityAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
    
    if (widget.isLoading) {
      _controller.repeat();
    }
  }
  
  @override
  void didUpdateWidget(AnimatedLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isLoading && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isLoading && _controller.isAnimating) {
      _controller.stop();
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.rotate(
              angle: _rotationAnimation.value,
              child: CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _LoaderPainter(
                  color: widget.color,
                  radius: _radiusAnimation.value,
                  opacity: _opacityAnimation.value,
                ),
              ),
            );
          },
        ),
        if (widget.message != null) ...[
          const SizedBox(height: 16),
          Text(
            widget.message!,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontSize: 16,
            ),
          ),
        ],
      ],
    );
  }
}

class _LoaderPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double opacity;
  
  _LoaderPainter({
    required this.color,
    required this.radius,
    required this.opacity,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final circleRadius = size.width / 2;
    
    // Draw shadow
    final shadowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.fill;
      
    canvas.drawCircle(center, circleRadius, shadowPaint);
    
    // Draw main circles
    for (int i = 0; i < 4; i++) {
      final angle = (i * (math.pi / 2)) + (radius * math.pi);
      final offset = Offset(
        center.dx + math.cos(angle) * circleRadius * 0.7,
        center.dy + math.sin(angle) * circleRadius * 0.7,
      );
      
      final circlePaint = Paint()
        ..color = color.withOpacity(opacity * (i / 4 + 0.5))
        ..style = PaintingStyle.fill;
      
      final dotRadius = (circleRadius * 0.2) * (1.0 - (i * 0.1));
      canvas.drawCircle(offset, dotRadius, circlePaint);
    }
    
    // Draw center circle
    final centerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
      
    canvas.drawCircle(center, circleRadius * 0.3, centerPaint);
  }

  @override
  bool shouldRepaint(_LoaderPainter oldDelegate) {
    return oldDelegate.radius != radius || 
           oldDelegate.opacity != opacity ||
           oldDelegate.color != color;
  }
}

// Progress indicator with success/error animations
class AnimatedProgressIndicator extends StatefulWidget {
  final double value;
  final Color backgroundColor;
  final Color valueColor;
  final double height;
  final String? label;
  final bool showSuccess;
  
  const AnimatedProgressIndicator({
    Key? key,
    required this.value,
    this.backgroundColor = const Color(0xFFE0E0E0),
    this.valueColor = Colors.orange,
    this.height = 8.0,
    this.label,
    this.showSuccess = false,
  }) : super(key: key);
  
  @override
  _AnimatedProgressIndicatorState createState() => _AnimatedProgressIndicatorState();
}

class _AnimatedProgressIndicatorState extends State<AnimatedProgressIndicator> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _successAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _successAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    
    if (widget.showSuccess && widget.value >= 1.0) {
      _controller.forward();
    }
  }
  
  @override
  void didUpdateWidget(AnimatedProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.showSuccess && widget.value >= 1.0 && !_controller.isCompleted) {
      _controller.forward();
    } else if (!widget.showSuccess && _controller.isCompleted) {
      _controller.reverse();
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              widget.label!,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        Stack(
          children: [
            // Background
            Container(
              height: widget.height,
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(widget.height / 2),
              ),
            ),
            // Progress
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              height: widget.height,
              width: widget.value * MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                color: widget.value < 1.0 ? widget.valueColor : Colors.green,
                borderRadius: BorderRadius.circular(widget.height / 2),
                boxShadow: [
                  BoxShadow(
                    color: (widget.value < 1.0 ? widget.valueColor : Colors.green).withOpacity(0.3),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            // Success checkmark
            if (widget.showSuccess && widget.value >= 1.0)
              Positioned(
                right: 0,
                top: -widget.height,
                bottom: -widget.height,
                child: AnimatedBuilder(
                  animation: _successAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _successAnimation.value,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '${(widget.value * 100).toInt()}%',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
} 