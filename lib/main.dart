import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'services/customer_api.dart';
import 'state/app_state.dart';
import 'theme/orchard_theme.dart';

/// App-wide navigator key so background events (e.g. a 401 from any
/// request) can return the user to Login from anywhere.
final appNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final session = SessionStore();
  final client = ApiClient(session);
  final api = CustomerApi(client);
  runApp(CustomerApp(session: session, client: client, api: api));
}

class CustomerApp extends StatelessWidget {
  const CustomerApp({
    super.key,
    required this.session,
    required this.client,
    required this.api,
  });

  final SessionStore session;
  final ApiClient client;
  final CustomerApi api;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<SessionStore>.value(value: session),
        Provider<ApiClient>.value(value: client),
        Provider<CustomerApi>.value(value: api),
        ChangeNotifierProvider(create: (_) => AuthState(api, session)),
        ChangeNotifierProvider(create: (_) => DashboardState(api)),
        ChangeNotifierProvider(create: (_) => CatalogState(api)),
        ChangeNotifierProvider(create: (_) => OrdersState(api)),
        ChangeNotifierProvider(create: (_) => OrderDetailState(api)),
        ChangeNotifierProvider(create: (_) => InvoicesState(api)),
        ChangeNotifierProvider(create: (_) => InvoiceDetailState(api)),
        ChangeNotifierProvider(create: (_) => NotificationsState(api)),
        ChangeNotifierProvider(create: (_) => LedgerState(api)),
        ChangeNotifierProvider(create: (_) => WeatherState(api)),
      ],
      child: Builder(builder: (context) {
        // 401 anywhere: flush the token and bounce to Login (spec §5).
        client.onUnauthorized = () async {
          await context.read<AuthState>().logoutLocal();
          appNavigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (_) => false,
          );
        };
        return Consumer<AuthState>(
          builder: (context, auth, _) => MaterialApp(
            title: auth.config.appName.isEmpty
                ? 'Plant Tech Agro'
                : auth.config.appName,
            debugShowCheckedModeBanner: false,
            navigatorKey: appNavigatorKey,
            theme: buildOrchardTheme(auth.config.theme),
            // The Orchard Modernist system is light-theme only.
            themeMode: ThemeMode.light,
            home: const SplashScreen(),
          ),
        );
      }),
    );
  }
}
