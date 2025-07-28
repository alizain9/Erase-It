// File: lib/presentation/widgets/custom_button.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? color;
  final bool isLoading;
  final IconData? icon;
  final String? loadingText;
  final double? progress;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.color,
    this.isLoading = false,
    this.icon,
    this.loadingText,
    this.progress,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = widget.onPressed != null && !widget.isLoading;
    
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: widget.isLoading
                  ? LinearGradient(
                      colors: [
                        (widget.color ?? theme.colorScheme.primary).withOpacity(0.6),
                        (widget.color ?? theme.colorScheme.primary).withOpacity(0.8),
                      ],
                    )
                  : LinearGradient(
                      colors: [
                        widget.color ?? theme.colorScheme.primary,
                        (widget.color ?? theme.colorScheme.primary).withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              boxShadow: isEnabled
                  ? [
                      BoxShadow(
                        color: (widget.color ?? theme.colorScheme.primary)
                            .withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: isEnabled ? widget.onPressed : null,
                onTapDown: isEnabled ? (_) => _onTapDown() : null,
                onTapUp: isEnabled ? (_) => _onTapUp() : null,
                onTapCancel: isEnabled ? _onTapUp : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: _buildContent(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    if (widget.isLoading) {
      return _buildLoadingContent();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.icon != null) ...[
          Icon(
            widget.icon,
            color: Colors.black87,
            size: 18,
          ),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(
            widget.text,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingContent() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.black54),
            value: widget.progress,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          widget.loadingText ?? 'Loading...',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        if (widget.progress != null)
          Text(
            ' ${(widget.progress! * 100).toInt()}%',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
      ],
    );
  }

  void _onTapDown() {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _onTapUp() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }
}
