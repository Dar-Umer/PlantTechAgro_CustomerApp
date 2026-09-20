import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/orchard_theme.dart';
import 'notifications_screen.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/invoices_tab.dart';
import 'tabs/services_tab.dart';
import 'tabs/orders_tab.dart';
import 'tabs/more_tab.dart';

/// 4-tab shell (spec §2): Home, Services, Work Orders, More.
/// Invoices, Notifications, Profile, Support, About are stack screens.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationsPage()),
    );
  }

  void _openInvoices() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const InvoicesPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unread = context.select<NotificationsState, int>((n) => n.unread);
    final name = context.select<AuthState, String>((a) => a.config.appName);
    final tabs = [
      DashboardTab(
        onViewAllOrders: () => setState(() => _index = 2),
        onViewAllInvoices: _openInvoices,
        onOpenNotifications: _openNotifications,
        onOpenServices: () => setState(() => _index = 1),
      ),
      const ServicesTab(),
      const OrdersTab(),
      const MoreTab(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: _openNotifications,
              ),
              if (unread > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    height: 18,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: OrchardColors.brand,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Center(
                      child: Text(
                        unread > 99 ? '99+' : '$unread',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
              top: BorderSide(color: OrchardColors.border, width: 1)),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'Home'),
            NavigationDestination(
                icon: Icon(Icons.miscellaneous_services_outlined),
                selectedIcon: Icon(Icons.miscellaneous_services),
                label: 'Services'),
            NavigationDestination(
                icon: Icon(Icons.work_outline),
                selectedIcon: Icon(Icons.work),
                label: 'Work Orders'),
            NavigationDestination(
                icon: Icon(Icons.menu),
                selectedIcon: Icon(Icons.menu_open),
                label: 'More'),
          ],
        ),
      ),
    );
  }
}
