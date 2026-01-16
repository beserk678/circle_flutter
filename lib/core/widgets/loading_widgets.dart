import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';

/// Loading indicator with optional text
class LoadingIndicator extends StatelessWidget {
  final String? message;
  final double size;
  final Color? color;

  const LoadingIndicator({super.key, this.message, this.size = 24, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: color ?? Theme.of(context).colorScheme.primary,
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message!,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// Full screen loading overlay
class LoadingOverlay extends StatelessWidget {
  final String? message;
  final bool isLoading;
  final Widget child;

  const LoadingOverlay({
    super.key,
    this.message,
    required this.isLoading,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: DesignTokens.cardShadow(context),
                ),
                child: LoadingIndicator(message: message, size: 32),
              ),
            ),
          ),
      ],
    );
  }
}

/// Skeleton loading for lists
class SkeletonLoader extends StatefulWidget {
  final int itemCount;
  final double height;
  final EdgeInsets? padding;

  const SkeletonLoader({
    super.key,
    this.itemCount = 3,
    this.height = 80,
    this.padding,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ListView.builder(
          padding: widget.padding,
          itemCount: widget.itemCount,
          itemBuilder: (context, index) {
            return Container(
              height: widget.height,
              margin: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(
                            alpha: _animation.value,
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              height: 16,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(
                                  alpha: _animation.value,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 12,
                              width: 200,
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(
                                  alpha: _animation.value * 0.7,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Shimmer effect for loading content
class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade100,
                Colors.grey.shade300,
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Loading button with spinner
class LoadingButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final ButtonStyle? style;
  final Widget? icon;

  const LoadingButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.style,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    if (icon != null) {
      return ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        style: style,
        icon:
            isLoading
                ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                : icon!,
        label: Text(text),
      );
    }

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: style,
      child:
          isLoading
              ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
              : Text(text),
    );
  }
}

/// Refresh indicator wrapper
class CustomRefreshIndicator extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;
  final String? refreshText;

  const CustomRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
    this.refreshText,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: Theme.of(context).colorScheme.primary,
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: child,
    );
  }
}
