import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../theme/orchard_theme.dart';
import '../../widgets/common.dart';
import '../invoice_detail_screen.dart';
import '../ledger_screen.dart';

const invoiceStatuses = [
  '',
  'unpaid',
  'partial',
  'overdue',
  'paid',
  'cancelled'
];

/// Stack version of the invoice list (More → Invoices, spec §2).
class InvoicesPage extends StatelessWidget {
  const InvoicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoices'),
        actions: [
          IconButton(
            tooltip: 'Account Statement & Ledger',
            icon: const Icon(Icons.account_balance_wallet_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LedgerScreen()),
            ),
          ),
        ],
      ),
      body: const InvoicesTab(),
    );
  }
}

class InvoicesTab extends StatefulWidget {
  const InvoicesTab({super.key});

  @override
  State<InvoicesTab> createState() => _InvoicesTabState();
}

class _InvoicesTabState extends State<InvoicesTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InvoicesState>().load(reset: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<InvoicesState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Invoices & Payments',
                  style: Theme.of(context).textTheme.headlineMedium),
              TextButton.icon(
                icon: const Icon(Icons.receipt_long, size: 16),
                label: const Text('Ledger'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LedgerScreen()),
                ),
              ),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: invoiceStatuses.map((s) {
              final selected =
                  state.statusFilter == (s.isEmpty ? null : s);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(
                      s.isEmpty ? 'All' : s.toUpperCase()),
                  selected: selected,
                  onSelected: (_) => state.load(
                      status: s.isEmpty ? null : s, reset: true),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: Builder(builder: (context) {
            if (state.loading && state.items.isEmpty) {
              return const LoadingView(message: 'Loading invoices…');
            }
            if (state.error != null && state.items.isEmpty) {
              return ErrorView(
                  message: state.error!,
                  onRetry: () => state.load(reset: true));
            }
            if (state.items.isEmpty) {
              return const EmptyView(message: 'No invoices found.');
            }
            return RefreshIndicator(
              onRefresh: () => state.load(reset: true),
              child: ListView.builder(
                padding:
                    const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount:
                    state.items.length + (state.hasMore ? 1 : 0),
                itemBuilder: (context, i) {
                  if (i >= state.items.length) {
                    state.load(reset: false);
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child:
                          Center(child: CircularProgressIndicator()),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _InvoiceCard(invoice: state.items[i]),
                  );
                },
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({required this.invoice});
  final InvoiceSummary invoice;

  @override
  Widget build(BuildContext context) {
    final currency =
        context.select<AuthState, String>((a) => a.config.currency);
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
                StatusChip(
                    label: i.statusLabel, color: i.statusColor),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Due ${fmtDate(i.dueDate)} • Total ${money(i.grandTotal, currency: currency)}',
              style: const TextStyle(
                  fontSize: 12, color: OrchardColors.muted),
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
                        style: orchardCurrencyStyle.copyWith(
                            fontSize: 20),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: OrchardColors.brand,
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20),
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
