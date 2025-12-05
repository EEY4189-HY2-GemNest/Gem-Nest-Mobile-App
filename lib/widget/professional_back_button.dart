import 'package:flutter/material.dart';

class ProfessionalBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? iconColor;
  final Color? backgroundColor;
  final double? size;

  const ProfessionalBackButton({
    super.key,
    this.onPressed,
    this.iconColor,
    this.backgroundColor,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed ?? () => Navigator.of(context).pop(),
      child: Container(
        padding: EdgeInsets.all(size != null ? size! * 0.3 : 8),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.arrow_back,
          color: iconColor ?? Colors.black87,
          size: size ?? 24,
        ),
      ),
    );
  }
}

class ProfessionalAppBarBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? color;

  const ProfessionalAppBarBackButton({
    super.key,
    this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back_ios, color: color ?? Colors.white),
      onPressed: onPressed ?? () => Navigator.of(context).pop(),
    );
  }
}