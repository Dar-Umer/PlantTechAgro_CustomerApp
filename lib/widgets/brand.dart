import 'package:flutter/material.dart';

import '../theme/orchard_theme.dart';

/// Light mint → peach → lavender wash used on splash / login,
/// matching the Stitch "Welcome, Orchard Partner" screen.
class OrchardGradient extends StatelessWidget {
  const OrchardGradient({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFE9F8EF),
            Color(0xFFFDF3E8),
            Color(0xFFECEBFA),
          ],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: child,
    );
  }
}

/// "PlantTech Agro" wordmark: green + orchard-orange spans with the
/// "Complete Orchard Solutions." tagline, as in the Stitch brand screen.
class PlantTechLogo extends StatelessWidget {
  const PlantTechLogo({super.key, this.fontSize = 40, this.tagline = true});
  final double fontSize;
  final bool tagline;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
              children: const [
                TextSpan(
                    text: 'Plant',
                    style: TextStyle(color: OrchardColors.pine)),
                TextSpan(
                    text: 'Tech',
                    style: TextStyle(color: OrchardColors.brand)),
                TextSpan(
                    text: ' Agro',
                    style: TextStyle(color: OrchardColors.pine)),
              ],
            ),
          ),
        ),
        if (tagline) ...[
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: 28,
                    height: 2,
                    color: OrchardColors.pine.withValues(alpha: 0.5)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Complete Orchard Solutions.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: OrchardColors.forest,
                    ),
                  ),
                ),
                Container(
                    width: 28,
                    height: 2,
                    color: OrchardColors.pine.withValues(alpha: 0.5)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// "Better Yields • Better Returns" tinted pill from the splash design.
class YieldPill extends StatelessWidget {
  const YieldPill({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: OrchardColors.tint100.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.eco_outlined, size: 16, color: OrchardColors.pine),
          SizedBox(width: 6),
          Text(
            'Better Yields  •  Better Returns',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: OrchardColors.forest,
            ),
          ),
        ],
      ),
    );
  }
}

/// Adaptive Brand Logo that renders the remote uploaded logo from the Admin Panel
/// (`mobile.app_logo_url` or `theme.logo_url`) when set, with graceful
/// fallback to the SVG-like [PlantTechLogo] wordmark.
class AppBrandLogo extends StatelessWidget {
  const AppBrandLogo({
    super.key,
    this.logoUrl,
    this.fontSize = 36,
    this.tagline = true,
    this.maxHeight = 64,
  });

  final String? logoUrl;
  final double fontSize;
  final bool tagline;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final url = logoUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Image.network(
          url,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => PlantTechLogo(
            fontSize: fontSize,
            tagline: tagline,
          ),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return PlantTechLogo(
              fontSize: fontSize,
              tagline: tagline,
            );
          },
        ),
      );
    }
    return PlantTechLogo(fontSize: fontSize, tagline: tagline);
  }
}
