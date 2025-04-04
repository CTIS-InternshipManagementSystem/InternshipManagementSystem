import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AnimatedButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? textColor;
  final double width;
  final double height;
  final bool isLoading;
  final bool isSuccess;
  final AnimationType animationType;

  const AnimatedButton({
    Key? key,
    required this.label,
    this.icon,
    this.onPressed,
    this.color = Colors.blue,
    this.textColor = Colors.white,
    this.width = 200,
    this.height = 50,
    this.isLoading = false,
    this.isSuccess = false,
    this.animationType = AnimationType.scale,
  }) : super(key: key);

  @override
  _AnimatedButtonState createState() => _AnimatedButtonState();
}

enum AnimationType {
  scale,
  bounce,
  pulse,
  glow,
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.9), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 0.9, end: 1.05), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 1.05, end: 1.0), weight: 1),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() => _isPressed = true);
      _controller.forward();
      HapticFeedback.lightImpact();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color buttonColor = widget.isSuccess ? Colors.green : widget.color ?? Colors.blue;
    final Color textColor = widget.textColor ?? Colors.white;

    Widget buttonContent = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.icon != null && !widget.isLoading) ...[
          Icon(widget.icon, color: textColor),
          const SizedBox(width: 8),
        ],
        if (widget.isLoading)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              valueColor: AlwaysStoppedAnimation<Color>(textColor),
            ),
          )
        else if (widget.isSuccess)
          Icon(Icons.check_circle, color: textColor)
        else
          Text(
            widget.label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
      ],
    );

    // Wrap with various animation types
    Widget animatedButton;
    switch (widget.animationType) {
      case AnimationType.scale:
        animatedButton = AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: _buildButtonContainer(buttonColor, buttonContent),
            );
          },
        );
        break;
      case AnimationType.bounce:
        animatedButton = AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _bounceAnimation.value,
              child: _buildButtonContainer(buttonColor, buttonContent),
            );
          },
        );
        break;
      case AnimationType.pulse:
        animatedButton = _buildPulseAnimation(buttonColor, buttonContent);
        break;
      case AnimationType.glow:
        animatedButton = _buildGlowAnimation(buttonColor, buttonContent);
        break;
    }

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onPressed != null && !widget.isLoading
          ? () {
              widget.onPressed!();
              if (widget.animationType == AnimationType.bounce) {
                _controller.forward(from: 0);
              }
            }
          : null,
      child: animatedButton,
    );
  }

  Widget _buildButtonContainer(Color color, Widget child) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(widget.height / 2),
        boxShadow: _isPressed
            ? []
            : [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Center(child: child),
    );
  }

  Widget _buildPulseAnimation(Color color, Widget child) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: _isPressed ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      builder: (context, value, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(widget.height / 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4 + (0.2 * value)),
                spreadRadius: 0,
                blurRadius: 10 + (10 * value),
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(child: child),
        );
      },
    );
  }

  Widget _buildGlowAnimation(Color color, Widget child) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(widget.height / 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(_isPressed ? 0.7 : 0.4),
            spreadRadius: _isPressed ? 4 : 1,
            blurRadius: _isPressed ? 15 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(child: child),
    );
  }
} 