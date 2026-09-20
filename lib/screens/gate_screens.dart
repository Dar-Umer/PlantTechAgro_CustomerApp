import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/models.dart';
import '../services/customer_api.dart';
import '../state/app_state.dart';
import '../theme/orchard_theme.dart';
import '../widgets/brand.dart';

/// "Update required" gate (spec §3.1): shown when `force_update` is on
/// and the running build is below `minimum_supported`. No bypass.
class UpdateRequiredScreen extends StatelessWidget {
  const UpdateRequiredScreen({super.key, required this.config});
  final AppConfigModel config;

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = config.mobile;
    final showAndroid = m.androidUpdateUrl.isNotEmpty &&
        (defaultTargetPlatform == TargetPlatform.android || kIsWeb);
    final showIos = m.iosUpdateUrl.isNotEmpty &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS ||
            kIsWeb);
    return Scaffold(
      body: OrchardGradient(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            color: OrchardColors.tint100,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                              Icons.system_update_outlined,
                              size: 32,
                              color: OrchardColors.pine),
                        ),
                        const SizedBox(height: 16),
                        Text('Update required',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall),
                        const SizedBox(height: 8),
                        Text(
                          'A newer version of ${config.appName} is required to continue. (minimum ${m.minimumSupported})',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: OrchardColors.muted),
                        ),
                        if (m.releaseNotes.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: OrchardColors.tint50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const Text("What's new",
                                    style: TextStyle(
                                        fontWeight:
                                            FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text(m.releaseNotes),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        if (showAndroid)
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () =>
                                  _open(m.androidUpdateUrl),
                              icon: const Icon(
                                  Icons.play_arrow_outlined),
                              label: const Text('Update on Google Play'),
                            ),
                          ),
                        if (showIos) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () =>
                                  _open(m.iosUpdateUrl),
                              icon: const Icon(
                                  Icons.apple_outlined),
                              label: const Text('Update on App Store'),
                            ),
                          ),
                        ],
                        if (!showAndroid && !showIos)
                          const Text(
                            'Please install the latest version from your app store.',
                            textAlign: TextAlign.center,
                          ),
                      ],
                    ),
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

/// Maintenance gate (spec §3.1): no API calls beyond re-checking
/// `/app-config` via Retry.
class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key, required this.config});
  final AppConfigModel config;

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  bool _checking = false;
  String? _statusMessage;

  Future<void> _checkStatus() async {
    setState(() {
      _checking = true;
      _statusMessage = null;
    });

    try {
      final api = context.read<CustomerApi>();
      final fresh = await api.appConfig();
      if (!mounted) return;
      context.read<AuthState>().updateConfig(fresh);

      if (!fresh.mobile.maintenanceMode) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _checking = false;
          _statusMessage =
              'Maintenance is currently active. Orchard servers will resume shortly.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _checking = false;
        _statusMessage = 'Could not verify server status. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final supportPhone = widget.config.support.phone;

    return Scaffold(
      body: OrchardGradient(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFEF3C7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.engineering_outlined,
                            size: 36,
                            color: Color(0xFFD97706),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Under Scheduled Maintenance',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${widget.config.appName} is temporarily offline for planned system enhancements and database optimizations.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: OrchardColors.muted,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: OrchardColors.tint50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: OrchardColors.tint200),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.shield_outlined,
                                  size: 18, color: OrchardColors.pine),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Your orchard bookings, ledger, and field records are completely secure.',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: OrchardColors.forest),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_statusMessage != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFECACA)),
                            ),
                            child: Text(
                              _statusMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF991B1B),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _checking ? null : _checkStatus,
                            icon: _checking
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.refresh),
                            label: Text(_checking
                                ? 'Checking Status…'
                                : 'Check Server Status'),
                          ),
                        ),
                        if (supportPhone.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  launchUrl(Uri.parse('tel:$supportPhone')),
                              icon: const Icon(Icons.phone_outlined),
                              label: const Text('Call Support Desk'),
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
      ),
    );
  }
}

/// Support screen (More → Support): tap-to-call / email / address / hours.
class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  Future<void> _launch(Uri uri) async {
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final s =
        context.select<AuthState, SupportInfo>((a) => a.config.support);
    return Scaffold(
      appBar: AppBar(title: const Text('Support')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                if (s.phone.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.call_outlined),
                    title: const Text('Call us'),
                    subtitle: Text(s.phone),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () =>
                        _launch(Uri.parse('tel:${s.phone}')),
                  ),
                if (s.email.isNotEmpty) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.email_outlined),
                    title: const Text('Email'),
                    subtitle: Text(s.email),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () =>
                        _launch(Uri.parse('mailto:${s.email}')),
                  ),
                ],
                if (s.address.isNotEmpty) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading:
                        const Icon(Icons.location_on_outlined),
                    title: const Text('Visit'),
                    subtitle: Text(s.address),
                  ),
                ],
                if (s.hours.isNotEmpty) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading:
                        const Icon(Icons.schedule_outlined),
                    title: const Text('Hours'),
                    subtitle: Text(s.hours),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// About screen (More → About): logo, version, tagline, release notes.
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((pkg) {
      if (mounted) {
        setState(() {
          _version = 'v${pkg.version} (${pkg.buildNumber})';
        });
      }
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final config =
        context.select<AuthState, AppConfigModel>((a) => a.config);
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  AppBrandLogo(
                    logoUrl: (config.mobile.appLogoUrl != null &&
                            config.mobile.appLogoUrl!.isNotEmpty)
                        ? config.mobile.appLogoUrl
                        : config.theme.logoUrl,
                    fontSize: 28,
                    maxHeight: 56,
                  ),
                  const SizedBox(height: 12),
                  Text(
                      _version.isEmpty
                          ? config.mobile.version
                          : _version,
                      style: const TextStyle(
                          color: OrchardColors.muted)),
                  if (config.mobile.splashTagline.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(config.mobile.splashTagline,
                        textAlign: TextAlign.center),
                  ],
                ],
              ),
            ),
          ),
          if (config.mobile.releaseNotes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("What's new",
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall),
                    const SizedBox(height: 4),
                    Text(config.mobile.releaseNotes),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
