import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/orchard_theme.dart';
import '../widgets/common.dart';

class InvoiceDetailScreen extends StatefulWidget {
  const InvoiceDetailScreen({super.key, required this.id});
  final int id;

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

/// Company block + bill-to (spec §3.9), from `app_config.company`.
class _CompanyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final company =
        context.select<AuthState, CompanyInfo>((a) => a.config.company);
    final billTo =
        context.select<AuthState, String>((a) => a.user?.name ?? '');
    if (company.name.isEmpty && billTo.isEmpty) {
      return const SizedBox.shrink();
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (company.name.isNotEmpty)
              Text(company.name,
                  style: Theme.of(context).textTheme.titleSmall),
            if (company.address.isNotEmpty)
              Text(company.address,
                  style: const TextStyle(
                      fontSize: 12, color: OrchardColors.muted)),
            if (company.phone.isNotEmpty || company.email.isNotEmpty)
              Text(
                  [company.phone, company.email]
                      .where((e) => e.isNotEmpty)
                      .join(' • '),
                  style: const TextStyle(
                      fontSize: 12, color: OrchardColors.muted)),
            if (company.gstNo.isNotEmpty)
              Text('GST: ${company.gstNo}',
                  style: const TextStyle(
                      fontSize: 12, color: OrchardColors.muted)),
            if (billTo.isNotEmpty) ...[
              const Divider(height: 20),
              const Text(
                'BILL TO',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.22,
                  color: OrchardColors.muted,
                ),
              ),
              const SizedBox(height: 2),
              Text(billTo,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      ),
    );
  }
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InvoiceDetailState>().load(widget.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<InvoiceDetailState>();
    final currency = context.select<AuthState, String>((a) => a.config.currency);
    return Scaffold(
      appBar: AppBar(title: const Text('Invoice details')),
      body: Builder(builder: (context) {
        // NB: on first build neither loading, error nor detail is set —
        // fall through to a loader instead of force-unwrapping null.
        if (state.detail == null) {
          if (state.error != null) {
            return ErrorView(
                message: state.error!,
                onRetry: () => state.load(widget.id));
          }
          return const LoadingView(message: 'Loading invoice…');
        }
        final d = state.detail!;
        return RefreshIndicator(
          onRefresh: () => state.load(widget.id),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _CompanyCard(),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(d.number,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                          ),
                          StatusChip(label: d.statusLabel, color: d.statusColor),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Invoice date: ${fmtDate(d.invoiceDate)}'),
                      Text('Due date: ${fmtDate(d.dueDate)}'),
                      if (d.workOrderNumber != null)
                        Text('Work order: ${d.workOrderNumber}'),
                      const Divider(height: 24),
                      _row('Subtotal', money(d.subtotal, currency: currency)),
                      _row('Discount', money(d.discountTotal, currency: currency)),
                      _row('GST', money(d.gstTotal, currency: currency)),
                      _row('Paid', money(d.amountPaid, currency: currency)),
                      const SizedBox(height: 4),
                      _row('Grand total',
                          money(d.grandTotal, currency: currency),
                          bold: true),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: OrchardColors.tint50,
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                              money(d.balanceDue,
                                  currency: currency),
                              style: orchardCurrencyStyle,
                            ),
                          ],
                        ),
                      ),
                      if (d.isOverdue)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: StatusChip(label: 'Overdue', color: 'red'),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const SectionTitle(title: 'Items'),
              ...d.items.map((it) => Card(
                    child: ListTile(
                      title: Text(it.name),
                      subtitle: Text(
                          '${it.qty} ${it.unit} × ${money(it.rate, currency: currency)} • GST ${it.gstRate}%'),
                      trailing: Text(money(it.total, currency: currency)),
                    ),
                  )),
              if (d.payments.isNotEmpty) ...[
                const SizedBox(height: 8),
                const SectionTitle(title: 'Payments'),
                ...d.payments.map((p) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.payments_outlined),
                        title: Text(
                            '${money(p.amount, currency: currency)} • ${p.methodLabel}'),
                        subtitle: Text(
                          [p.paidAt != null ? fmtDate(p.paidAt) : '', p.reference ?? '']
                              .where((e) => e.isNotEmpty)
                              .join(' • '),
                        ),
                      ),
                    )),
              ],
              if (d.terms != null && d.terms!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: const Text('Terms'),
                    subtitle: Text(d.terms!),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.support_agent_outlined),
                  title: const Text('Questions about this bill?'),
                  subtitle: const Text('Contact our team — we will help.'),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    final style = bold ? const TextStyle(fontWeight: FontWeight.bold) : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}
