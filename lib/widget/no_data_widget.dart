import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A reusable "No Data Available" widget with a gem icon.
/// Use this across the app wherever data is empty or unavailable.
class NoDataWidget extends StatelessWidget {
  /// The main title text (e.g. "No auctions found")
  final String title;

  /// Optional subtitle/description text
  final String? subtitle;

  /// Optional icon to display alongside the gem. If null, only the gem icon is shown.
  final IconData? icon;

  /// Optional icon size (default: 64)
  final double iconSize;

  /// Optional action button label
  final String? actionLabel;

  /// Optional action button callback
  final VoidCallback? onAction;

  const NoDataWidget({
    super.key,
    this.title = 'No Data Available',
    this.subtitle,
    this.icon,
    this.iconSize = 64,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Gem icon with decorative circle
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryBlue.withOpacity(0.10),
                    AppTheme.primaryBlueDark.withOpacity(0.06),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Gem icon (diamond)
                  Icon(
                    Icons.diamond_outlined,
                    size: iconSize,
                    color: AppTheme.primaryBlue.withOpacity(0.7),
                  ),
                  // Small secondary icon badge (if provided)
                  if (icon != null)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          icon,
                          size: iconSize * 0.35,
                          color: AppTheme.primaryBlueDark.withOpacity(0.7),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkGray,
              ),
              textAlign: TextAlign.center,
            ),
            // Subtitle
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            // Action button
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  actionLabel!,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
