import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class LoadingButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? disabledBackgroundColor;
  final Color? disabledForegroundColor;
  final double? elevation;
  final OutlinedBorder? shape;
  final EdgeInsetsGeometry? padding;
  final Size? minimumSize;
  final Size? maximumSize;
  final Widget? loadingWidget;
  final ButtonStyle? style;
  final bool isOutlined;

  const LoadingButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isLoading = false,
    this.width,
    this.height,
    this.backgroundColor,
    this.foregroundColor,
    this.disabledBackgroundColor,
    this.disabledForegroundColor,
    this.elevation,
    this.shape,
    this.padding,
    this.minimumSize,
    this.maximumSize,
    this.loadingWidget,
    this.style,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final buttonChild = isLoading ? _buildLoadingWidget() : child;

    final buttonStyle = style ?? _getDefaultStyle(context);

    final effectiveOnPressed = isLoading ? null : onPressed;

    Widget button;
    if (isOutlined) {
      button = OutlinedButton(
        onPressed: effectiveOnPressed,
        style: buttonStyle,
        child: buttonChild,
      );
    } else {
      button = ElevatedButton(
        onPressed: effectiveOnPressed,
        style: buttonStyle,
        child: buttonChild,
      );
    }

    if (width != null || height != null) {
      return SizedBox(
        width: width,
        height: height,
        child: button,
      );
    }

    return button;
  }

  Widget _buildLoadingWidget() {
    return loadingWidget ??
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isOutlined ? AppColors.primary : Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text('Loading...'),
          ],
        );
  }

  ButtonStyle _getDefaultStyle(BuildContext context) {
    if (isOutlined) {
      return OutlinedButton.styleFrom(
        foregroundColor: foregroundColor ?? AppColors.primary,
        backgroundColor: backgroundColor,
        disabledForegroundColor:
            disabledForegroundColor ?? AppColors.textSecondary,
        disabledBackgroundColor: disabledBackgroundColor,
        elevation: elevation ?? 0,
        shape: shape,
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        minimumSize: minimumSize ?? const Size(88, 48),
        maximumSize: maximumSize ?? Size.infinite,
      );
    } else {
      return ElevatedButton.styleFrom(
        foregroundColor: foregroundColor ?? Colors.white,
        backgroundColor: backgroundColor ?? AppColors.primary,
        disabledForegroundColor: disabledForegroundColor ?? Colors.white70,
        disabledBackgroundColor:
            disabledBackgroundColor ?? AppColors.textSecondary,
        elevation: elevation ?? 2,
        shape: shape,
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        minimumSize: minimumSize ?? const Size(88, 48),
        maximumSize: maximumSize ?? Size.infinite,
      );
    }
  }
}

class LoadingIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget icon;
  final bool isLoading;
  final double? size;
  final Color? color;
  final Color? disabledColor;
  final String? tooltip;
  final Widget? loadingWidget;

  const LoadingIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.isLoading = false,
    this.size,
    this.color,
    this.disabledColor,
    this.tooltip,
    this.loadingWidget,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIcon = isLoading ? _buildLoadingWidget() : icon;

    return IconButton(
      onPressed: isLoading ? null : onPressed,
      icon: effectiveIcon,
      iconSize: size ?? 24,
      color: color,
      disabledColor: disabledColor,
      tooltip: tooltip,
    );
  }

  Widget _buildLoadingWidget() {
    return loadingWidget ??
        SizedBox(
          width: size ?? 24,
          height: size ?? 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? AppColors.primary,
            ),
          ),
        );
  }
}

class LoadingFloatingActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final Widget? loadingWidget;
  final bool mini;

  const LoadingFloatingActionButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isLoading = false,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.loadingWidget,
    this.mini = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveChild = isLoading ? _buildLoadingWidget() : child;

    if (mini) {
      return FloatingActionButton.small(
        onPressed: isLoading ? null : onPressed,
        tooltip: tooltip,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        elevation: elevation,
        child: effectiveChild,
      );
    } else {
      return FloatingActionButton(
        onPressed: isLoading ? null : onPressed,
        tooltip: tooltip,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        elevation: elevation,
        child: effectiveChild,
      );
    }
  }

  Widget _buildLoadingWidget() {
    return loadingWidget ??
        const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        );
  }
}

class LoadingTextButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;
  final Color? foregroundColor;
  final Color? disabledForegroundColor;
  final OutlinedBorder? shape;
  final EdgeInsetsGeometry? padding;
  final Widget? loadingWidget;

  const LoadingTextButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isLoading = false,
    this.foregroundColor,
    this.disabledForegroundColor,
    this.shape,
    this.padding,
    this.loadingWidget,
  });

  @override
  Widget build(BuildContext context) {
    final buttonChild = isLoading ? _buildLoadingWidget() : child;

    return TextButton(
      onPressed: isLoading ? null : onPressed,
      style: TextButton.styleFrom(
        foregroundColor: foregroundColor ?? AppColors.primary,
        disabledForegroundColor:
            disabledForegroundColor ?? AppColors.textSecondary,
        shape: shape,
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: buttonChild,
    );
  }

  Widget _buildLoadingWidget() {
    return loadingWidget ??
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  foregroundColor ?? AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text('Loading...'),
          ],
        );
  }
}

class LoadingChip extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget label;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? labelColor;
  final Widget? avatar;
  final Widget? loadingWidget;

  const LoadingChip({
    super.key,
    required this.onPressed,
    required this.label,
    this.isLoading = false,
    this.backgroundColor,
    this.labelColor,
    this.avatar,
    this.loadingWidget,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveLabel = isLoading ? _buildLoadingWidget() : label;

    return ActionChip(
      onPressed: isLoading ? null : onPressed,
      label: effectiveLabel,
      backgroundColor: backgroundColor,
      labelStyle: TextStyle(color: labelColor),
      avatar: avatar,
    );
  }

  Widget _buildLoadingWidget() {
    return loadingWidget ??
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  labelColor ?? AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Text('Loading...'),
          ],
        );
  }
}
