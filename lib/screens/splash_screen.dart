import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/orchard_theme.dart';
import '../widgets/brand.dart';
import 'gate_screens.dart';
import 'home_screen.dart';
import 'login_screen.dart';

/// Branded launch screen that loads session + `/app-config`, then applies
/// the Laravel system gates: Version Control (Update Required) → Maintenance Mode → Login / Home.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;

  String _statusText = 'Connecting to Plant Tech Agro cloud…';
  String _versionLabel = '';
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
    _animController.forward();

    _boot();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _boot() async {
    setState(() {
      _hasError = false;
      _errorMessage = null;
      _statusText = 'Connecting to Plant Tech Agro cloud…';
    });

    final auth = context.read<AuthState>();

    // Step 1: Detect local platform app version
    PackageInfo? pkg;
    try {
      pkg = await PackageInfo.fromPlatform();
    } catch (_) {
      pkg = null;
    }
    final running = (pkg?.version != null && pkg!.version.isNotEmpty)
        ? pkg.version
        : '1.0.0';
    final buildNumber = pkg?.buildNumber ?? '1';

    if (mounted) {
      setState(() {
        _versionLabel = 'v$running (Build $buildNumber)';
      });
    }

    // Step 2: Bootstrap Auth & fetch /api/app-config from Laravel
    try {
      await auth.bootstrap();
    } catch (e) {
      // If bootstrap fails completely offline
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage =
              'Could not connect to Plant Tech Agro servers. Please check your internet connection.';
          _statusText = 'Connection failed';
        });
        return;
      }
    }

    if (!mounted) return;

    final m = auth.config.mobile;

    // Step 3: Check System Maintenance Mode (from Laravel config('mobile.maintenance_mode'))
    setState(() {
      _statusText = 'Checking system health & policies…';
    });
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    if (m.maintenanceMode) {
      final retry = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => MaintenanceScreen(config: auth.config),
        ),
      );
      if (retry == true && mounted) {
        // User retried and maintenance was lifted; reboot
        _boot();
      }
      return;
    }

    // Step 4: Check Version Control (from Laravel config('mobile.minimum_supported') & force_update)
    final isBelowMinimum = compareVersions(running, m.minimumSupported) < 0;
    final isForcedUpdate =
        m.forceUpdate && compareVersions(running, m.version) < 0;

    if (isBelowMinimum || isForcedUpdate) {
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => UpdateRequiredScreen(config: auth.config),
        ),
      );
      return;
    }

    // Step 5: Smooth Transition into App
    setState(() {
      _statusText = 'Orchard workspace ready…';
    });
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            auth.isLoggedIn ? const HomeScreen() : const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final m = auth.config.mobile;
    final dynamicTagline = m.splashTagline.isNotEmpty
        ? m.splashTagline
        : 'Growing trust, one harvest at a time.';
    final effectiveLogo = (m.appLogoUrl != null && m.appLogoUrl!.isNotEmpty)
        ? m.appLogoUrl
        : auth.config.theme.logoUrl;

    return Scaffold(
      body: OrchardGradient(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Brand Logo Card with subtle drop shadow
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 26),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: OrchardColors.tint200),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 24,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: AppBrandLogo(
                          logoUrl: effectiveLogo,
                          fontSize: 36,
                          maxHeight: 72,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Tagline
                      Text(
                        dynamicTagline,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                          color: OrchardColors.forest,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Certified Agritech Badge
                      const YieldPill(),
                      const SizedBox(height: 32),

                      if (_hasError) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFECACA)),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.cloud_off_outlined,
                                  color: Color(0xFFB91C1C), size: 28),
                              const SizedBox(height: 6),
                              Text(
                                _errorMessage ?? 'Connection error.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF991B1B),
                                ),
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton.icon(
                                onPressed: _boot,
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text('Retry Connection'),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // Sleek Progress Indicator
                        const SizedBox(
                          width: 180,
                          child: ClipRRect(
                            borderRadius: BorderRadius.all(Radius.circular(4)),
                            child: LinearProgressIndicator(
                              minHeight: 5,
                              backgroundColor: OrchardColors.tint100,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  OrchardColors.pine),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Animated Status Text
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            _statusText,
                            key: ValueKey<String>(_statusText),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: OrchardColors.ink,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 28),

                      // Version and Environment Info
                      if (_versionLabel.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: OrchardColors.border),
                          ),
                          child: Text(
                            _versionLabel,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: OrchardColors.muted,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
