import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../theme/orchard_theme.dart';
import '../../widgets/common.dart';
import '../invoice_detail_screen.dart';
import '../ledger_screen.dart';
import '../order_detail_screen.dart';
import '../weather_detail_screen.dart';
import 'more_tab.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({
    super.key,
    this.onViewAllOrders,
    this.onViewAllInvoices,
    this.onOpenNotifications,
    this.onOpenServices,
  });
  final VoidCallback? onViewAllOrders;
  final VoidCallback? onViewAllInvoices;
  final VoidCallback? onOpenNotifications;
  final VoidCallback? onOpenServices;

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardState>().load();
      context.read<NotificationsState>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dash = context.watch<DashboardState>();
    final currency = context.select<AuthState, String>((a) => a.config.currency);
    final userName =
        context.select<AuthState, String>((a) => a.user?.name ?? 'Partner');
    if (dash.loading && dash.recentOrders.isEmpty) {
      return const LoadingView(message: 'Loading dashboard…');
    }
    if (dash.error != null && dash.recentOrders.isEmpty) {
      return ErrorView(message: dash.error!, onRetry: () => dash.load());
    }
    return RefreshIndicator(
      onRefresh: () => dash.load(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _WelcomeBanner(name: userName),
          const SizedBox(height: 12),
          _QuickActionsStrip(onServices: widget.onOpenServices),
          const SizedBox(height: 12),
          _StatsGrid(
            currency: currency,
            onOrders: widget.onViewAllOrders,
            onInvoices: widget.onViewAllInvoices,
            onNotifications: widget.onOpenNotifications,
          ),
          const SizedBox(height: 12),
          if (dash.weather != null) ...[
            const _WeatherStrip(),
            const SizedBox(height: 16),
          ],
          SectionTitle(
            title: 'Recent Work Orders',
            action: TextButton(
              onPressed: widget.onViewAllOrders,
              child: const Text('View All'),
            ),
          ),
          const SizedBox(height: 8),
          ...dash.recentOrders
              .map((o) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _OrderCard(order: o),
                  )),
          if (dash.recentOrders.isEmpty)
            const EmptyView(
                message:
                    'No work orders yet. Book a service to get started.'),
          const SizedBox(height: 8),
          SectionTitle(
            title: 'Recent Invoices',
            action: TextButton(
              onPressed: widget.onViewAllInvoices,
              child: const Text('View Invoices'),
            ),
          ),
          const SizedBox(height: 8),
          ...dash.recentInvoices.map((i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _InvoiceCard(invoice: i, currency: currency),
              )),
          if (dash.recentInvoices.isEmpty)
            const EmptyView(message: 'No invoices yet.'),
          const SizedBox(height: 4),
          const _SupportCard(),
        ],
      ),
    );
  }
}

// ------------------------------------------------------- Welcome banner ---

class _WelcomeBanner extends StatelessWidget {
  const _WelcomeBanner({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE9F8EF), Color(0xFFDCFCE7)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OrchardColors.tint200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'WELCOME BACK',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.22,
                    color: OrchardColors.pine,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: OrchardColors.forest,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Track, Stage, Optimize — all in one glance.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: OrchardColors.ink,
                  ),
                ),
              ],
            ),
          ),
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white,
            child: Text(
              name.isEmpty ? '?' : name.characters.first.toUpperCase(),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: OrchardColors.pine,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------- Quick actions ---

class _QuickActionsStrip extends StatelessWidget {
  const _QuickActionsStrip({this.onServices});
  final VoidCallback? onServices;

  @override
  Widget build(BuildContext context) {
    final actions = [
      (
        'Book Service',
        Icons.miscellaneous_services_outlined,
        const Color(0xFF15803D),
        const Color(0xFFDCFCE7),
        onServices,
      ),
      (
        'Products',
        Icons.shopping_bag_outlined,
        OrchardColors.brand,
        const Color(0xFFFFEDD5),
        () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProductsPage()),
            ),
      ),
      (
        'Ledger',
        Icons.account_balance_wallet_outlined,
        const Color(0xFF2563EB),
        const Color(0xFFDBEAFE),
        () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LedgerScreen()),
            ),
      ),
      (
        'Agri Weather',
        Icons.wb_sunny_outlined,
        const Color(0xFFD97706),
        const Color(0xFFFEF3C7),
        () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const WeatherDetailScreen()),
            ),
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: actions.map((item) {
          final (label, icon, fgColor, bgColor, onTap) = item;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: OrchardColors.border),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x08000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: bgColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: fgColor, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: OrchardColors.forest,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ------------------------------------------------------------ Stat grid ---

class _StatsGrid extends StatelessWidget {
  const _StatsGrid(
      {required this.currency,
      this.onOrders,
      this.onInvoices,
      this.onNotifications});
  final String currency;
  final VoidCallback? onOrders;
  final VoidCallback? onInvoices;
  final VoidCallback? onNotifications;

  @override
  Widget build(BuildContext context) {
    final s = context.select<DashboardState, DashboardStats>((d) => d.stats);
    void onOutstanding() {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LedgerScreen()),
      );
    }

    // Outstanding is highlighted red when above zero (spec §3.4).
    final cards = [
      (
        'Active Orders',
        '${s.workOrdersActive}',
        Icons.work_outline,
        OrchardColors.chipInfo,
        onOrders
      ),
      (
        'In Progress',
        '${s.workOrdersInProgress}',
        Icons.timelapse,
        OrchardColors.chipProgress,
        onOrders
      ),
      (
        'Outstanding',
        money(s.outstandingBalance, currency: currency),
        Icons.account_balance_wallet_outlined,
        s.outstandingBalance > 0
            ? OrchardColors.chipBad
            : OrchardColors.chipDone,
        onOutstanding
      ),
      (
        'Unread Alerts',
        '${s.unreadNotifications}',
        Icons.notifications_outlined,
        OrchardColors.chipDone,
        onNotifications
      ),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 138,
      ),
      itemCount: cards.length,
      itemBuilder: (context, i) {
        final (label, value, icon, _, onTap) = cards[i];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: OrchardColors.tint100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon,
                      color: OrchardColors.pine, size: 20),
                ),
                const SizedBox(height: 6),
                Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      fontFeatures: [FontFeature.tabularFigures()],
                      color: OrchardColors.ink,
                    )),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, color: OrchardColors.muted)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// -------------------------------------------------------------- Weather ---

class _WeatherStrip extends StatelessWidget {
  const _WeatherStrip();

  @override
  Widget build(BuildContext context) {
    final w = context.select<DashboardState, WeatherInfo?>((d) => d.weather);
    if (w == null) return const SizedBox.shrink();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const WeatherDetailScreen()),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: OrchardColors.tint100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.wb_sunny_outlined,
                    color: OrchardColors.pine),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(w.area.isEmpty ? 'Farm weather' : w.area,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            )),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: OrchardColors.tint50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Agri Advisory',
                              style: TextStyle(
                                fontSize: 10,
                                color: OrchardColors.forest,
                                fontWeight: FontWeight.w600,
                              )),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (w.temperature != null)
                          '${w.temperature!.toStringAsFixed(1)}°C',
                        if (w.condition.isNotEmpty) w.condition,
                        if (w.advisory.isNotEmpty) '• ${w.advisory}',
                      ].join(' '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: OrchardColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: OrchardColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------- Order card ---

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});
  final WorkOrderSummary order;

  @override
  Widget build(BuildContext context) {
    final o = order;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('${o.number} • ${o.serviceName}',
                      style:
                          Theme.of(context).textTheme.titleSmall),
                ),
                StatusChip(label: o.statusLabel, color: o.statusColor),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: o.progressPercent / 100,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Stage ${o.stagesCompleted} of ${o.stagesTotal} • ${o.progressPercent}% Complete',
              style: const TextStyle(
                  fontSize: 12, color: OrchardColors.muted),
            ),
            if (o.assignedTo != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.person_outline,
                      size: 14, color: OrchardColors.muted),
                  const SizedBox(width: 4),
                  Text('Agent: ${o.assignedTo}',
                      style: const TextStyle(
                          fontSize: 12,
                          color: OrchardColors.muted)),
                ],
              ),
            ],
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => OrderDetailScreen(id: o.id)),
                ),
                child: const Text('View Details'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------- Invoice card ---

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({required this.invoice, required this.currency});
  final InvoiceSummary invoice;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final i = invoice;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(i.number,
                      style:
                          Theme.of(context).textTheme.titleSmall),
                ),
                StatusChip(label: i.statusLabel, color: i.statusColor),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Grand Total ${money(i.grandTotal, currency: currency)}',
              style: const TextStyle(
                  fontSize: 13, color: OrchardColors.muted),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'BALANCE DUE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.22,
                          color: OrchardColors.muted,
                        ),
                      ),
                      Text(
                        money(i.balanceDue, currency: currency),
                        style: orchardCurrencyStyle,
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: OrchardColors.brand,
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) =>
                            InvoiceDetailScreen(id: i.id)),
                  ),
                  child: const Text('Pay Now'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------- Support card ---

class _SupportCard extends StatelessWidget {
  const _SupportCard();

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.select<DashboardState, SupportInfo>((d) => d.support);
    final phone = s.phone.isNotEmpty
        ? s.phone
        : context.select<AuthState, SupportInfo>((a) => a.config.support).phone;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: OrchardColors.tint100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.support_agent_outlined,
                      color: OrchardColors.pine),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Plant Tech AgriTech Support',
                          style: Theme.of(context).textTheme.titleSmall),
                      if (s.hours.isNotEmpty)
                        Text('Operational Hours: ${s.hours}',
                            style: const TextStyle(
                                fontSize: 12,
                                color: OrchardColors.muted)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: phone.isEmpty ? null : () => _call(phone),
                icon: const Icon(Icons.call_outlined, size: 18),
                label: Text(phone.isEmpty
                    ? 'Call Agronomist'
                    : 'Call Agronomist • $phone'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
