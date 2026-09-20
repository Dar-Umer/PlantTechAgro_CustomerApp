import 'package:customerapp/core/api_client.dart';
import 'package:customerapp/core/config.dart';
import 'package:customerapp/models/models.dart';
import 'package:customerapp/theme/orchard_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ApiConfig exposes a usable base URL', () {
    expect(ApiConfig.baseUrl, endsWith('/api'));
    expect(ApiConfig.hostRoot, isNotEmpty);
  });

  test('SessionStore starts logged out', () {
    expect(SessionStore().isLoggedIn, isFalse);
  });

  test('AppUser parses login payload', () {
    final user = AppUser.fromJson({
      'id': 1,
      'name': 'Test Farmer',
      'phone': '+911234567890',
      'email': null,
      'address': null,
      'area': 'Pune',
      'status': 'active',
    });
    expect(user.name, 'Test Farmer');
    expect(user.phone, '+911234567890');
  });

  test('WorkOrderSummary parses dashboard payload', () {
    final wo = WorkOrderSummary.fromJson({
      'id': 7,
      'number': 'WO-0007',
      'service_name': 'Soil Testing',
      'status': 'in_progress',
      'status_label': 'In Progress',
      'progress_percent': 50,
    });
    expect(wo.number, 'WO-0007');
    expect(wo.progressPercent, 50);
  });

  test('WorkOrderStage parses photo/pdf requirements', () {
    final stage = WorkOrderStage.fromJson({
      'id': 3,
      'name': 'Canopy Spray',
      'status': 'in_progress',
      'requires_photo': true,
      'min_photos': 2,
      'requires_pdf': false,
    });
    expect(stage.requiresPhoto, isTrue);
    expect(stage.minPhotos, 2);
    expect(stage.requiresPdf, isFalse);
  });

  test('Orchard status chips follow the design mapping', () {
    expect(OrchardColors.statusPair('Completed').$2,
        OrchardColors.chipDone.$2);
    expect(OrchardColors.statusPair('In Progress').$2,
        OrchardColors.chipProgress.$2);
    expect(OrchardColors.statusPair('Overdue').$2,
        OrchardColors.chipBad.$2);
    expect(OrchardColors.statusPair('Assigned').$2,
        OrchardColors.chipInfo.$2);
    expect(OrchardColors.statusPair('Pending').$2,
        OrchardColors.chipIdle.$2);
  });

  test('compareVersions orders releases numerically', () {
    expect(compareVersions('1.0.0', '1.0.0'), 0);
    expect(compareVersions('1.0.9', '1.0.10'), -1);
    expect(compareVersions('2.0', '1.9.9'), 1);
    expect(compareVersions('1.0', '1.0.0'), 0);
  });

  test('MobileInfo parses update gating flags', () {
    final m = MobileInfo.fromJson({
      'minimum_supported': '1.2.0',
      'force_update': true,
      'maintenance_mode': false,
      'release_notes': 'Bug fixes',
    });
    expect(m.forceUpdate, isTrue);
    expect(m.minimumSupported, '1.2.0');
    expect(
        m.forceUpdate && compareVersions('1.0.0', m.minimumSupported) < 0,
        isTrue);
  });

  test('WeatherInfo parses the nested backend payload', () {
    final w = WeatherInfo.fromJson({
      'location': {
        'district': 'pulwama',
        'label': 'Pulwama',
        'lat': 33.8792,
        'lon': 74.8997,
      },
      'current': {
        'temp': 21.5,
        'humidity': 55,
        'wind': 8.2,
        'code': 1,
        'label': 'Partly cloudy',
      },
      'advisory': {
        'level': 'good',
        'messages': ['Good spraying window today — calm and mostly dry.'],
      },
    });
    expect(w.area, 'Pulwama');
    expect(w.temperature, 21.5);
    expect(w.condition, 'Partly cloudy');
    expect(w.advisory, contains('Good spraying window'));
    expect(w.level, 'good');
  });

  test('MobileInfo and ThemeConfig parse appearance branding from admin', () {
    final m = MobileInfo.fromJson({
      'name': 'Plant Tech Agro',
      'splash_tagline': 'Custom Tagline',
      'app_palette': 'rose',
      'app_font_family': 'Poppins',
      'app_logo_url': '/storage/logos/logo.png',
    });
    expect(m.name, 'Plant Tech Agro');
    expect(m.splashTagline, 'Custom Tagline');
    expect(m.appPalette, 'rose');
    expect(m.appFontFamily, 'Poppins');
    expect(m.appLogoUrl, contains('logo.png'));

    final t = ThemeConfig.fromJson({
      'palette': {
        '500': '#f43f5e',
        '600': '#e11d48',
        '700': '#be123c',
        '900': '#881337',
        '100': '#ffe4e6',
      },
      'font_family': 'Poppins',
      'logo_url': '/storage/logos/logo.png',
    });
    expect(t.fontFamily, 'Poppins');
    expect(t.palette['500'], '#f43f5e');

    final theme = buildOrchardTheme(t);
    expect(theme.colorScheme.primary.toARGB32(), 0xFFF43F5E);
  });
}
