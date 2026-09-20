import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/orchard_theme.dart';
import '../widgets/common.dart';
import 'invoice_detail_screen.dart';

class LedgerScreen extends StatefulWidget {
  const LedgerScreen({super.key});

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LedgerState>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LedgerState>();
    final currency = context.select<AuthState, String>((a) => a.config.currency);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Statement & Ledger'),
      ),
      body: state.loading && state.statement == null
          ? const LoadingView(message: 'Generating statement…')
          : state.error != null && state.statement == null
              ? ErrorView(message: state.error!, onRetry: () => state.load())
              : RefreshIndicator(
                  onRefresh: () => state.load(),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    children: [
                      _BalanceSummaryCard(
                        statement: state.statement,
                        currency: currency,
                      ),
                      const SizedBox(height: 16),
                      _PeriodFilterSelector(
                        selectedPeriod: state.period,
                        onSelected: (p) => context.read<LedgerState>().setPeriod(p),
                      ),
                      const SizedBox(height: 16),
                      SectionTitle(
                        title: 'Transaction History',
                        action: Text(
                          '${state.statement?.transactions.length ?? 0} records',
                          style: const TextStyle(
                            fontSize: 12,
                            color: OrchardColors.muted,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (state.statement?.transactions.isEmpty ?? true)
                        const EmptyView(
                          message: 'No ledger transactions recorded in this period.',
                        )
                      else
                        ...state.statement!.transactions.reversed.map((tx) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _TransactionCard(
                                tx: tx,
                                currency: currency,
                              ),
                            )),
                    ],
                  ),
                ),
    );
  }
}

class _BalanceSummaryCard extends StatelessWidget {
  const _BalanceSummaryCard({
    required this.statement,
    required this.currency,
  });

  final CustomerLedgerStatement? statement;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final closing = statement?.closingBalance ?? 0;
    final opening = statement?.openingBalance ?? 0;
    final debits = statement?.totalDebit ?? 0;
    final credits = statement?.totalCredit ?? 0;

    final isDue = closing > 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDue
              ? const [Color(0xFFFEF2F2), Color(0xFFFEE2E2)]
              : const [Color(0xFFE9F8EF), Color(0xFFDCFCE7)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDue ? const Color(0xFFFECACA) : OrchardColors.tint200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CLOSING BALANCE (OUTSTANDING)',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: isDue ? const Color(0xFF991B1B) : OrchardColors.pine,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDue ? const Color(0xFFFCA5A5) : OrchardColors.tint100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isDue ? 'Payment Pending' : 'Clear / Settled',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDue ? const Color(0xFF7F1D1D) : OrchardColors.forest,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            money(closing, currency: currency),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: isDue ? const Color(0xFF991B1B) : OrchardColors.forest,
            ),
          ),
          if (statement != null && statement!.from.isNotEmpty && statement!.to.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Statement: ${fmtDate(statement!.from)} to ${fmtDate(statement!.to)}',
                style: const TextStyle(fontSize: 12, color: OrchardColors.muted),
              ),
            ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniMetric(
                  label: 'Opening',
                  value: money(opening, currency: currency),
                  color: OrchardColors.ink,
                ),
              ),
              Container(height: 30, width: 1, color: OrchardColors.border),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: _MiniMetric(
                    label: 'Invoiced (Debit)',
                    value: '+${money(debits, currency: currency)}',
                    color: const Color(0xFFC2410C),
                  ),
                ),
              ),
              Container(height: 30, width: 1, color: OrchardColors.border),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: _MiniMetric(
                    label: 'Paid (Credit)',
                    value: '-${money(credits, currency: currency)}',
                    color: const Color(0xFF15803D),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, color: OrchardColors.muted),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _PeriodFilterSelector extends StatelessWidget {
  const _PeriodFilterSelector({
    required this.selectedPeriod,
    required this.onSelected,
  });

  final String selectedPeriod;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    const periods = [
      ('this_year', 'This Year'),
      ('this_month', 'This Month'),
      ('30_days', 'Last 30 Days'),
      ('all', 'All Time'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: periods.map((p) {
          final isSelected = selectedPeriod == p.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(p.$2),
              selected: isSelected,
              onSelected: (_) => onSelected(p.$1),
              selectedColor: OrchardColors.tint100,
              labelStyle: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? OrchardColors.pine : OrchardColors.ink,
              ),
              side: BorderSide(
                color: isSelected ? OrchardColors.primary : OrchardColors.border,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({
    required this.tx,
    required this.currency,
  });

  final LedgerTransaction tx;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final isInv = tx.isInvoice;
    final color = isInv ? const Color(0xFFC2410C) : const Color(0xFF15803D);
    final icon = isInv ? Icons.receipt_long_outlined : Icons.check_circle_outline;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // If invoice, find and navigate to invoice if possible
          if (isInv) {
            final invoices = context.read<InvoicesState>().items;
            final match = invoices.where((i) => i.number == tx.reference).firstOrNull;
            if (match != null) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => InvoiceDetailScreen(id: match.id)),
              );
            }
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isInv ? const Color(0xFFFFF7ED) : const Color(0xFFF0FDF4),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isInv ? const Color(0xFFFFEDD5) : const Color(0xFFDCFCE7),
                  ),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            tx.reference,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Text(
                          isInv
                              ? '+${money(tx.debit, currency: currency)}'
                              : '-${money(tx.credit, currency: currency)}',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tx.description,
                      style: const TextStyle(fontSize: 12, color: OrchardColors.muted),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          fmtDate(tx.date),
                          style: const TextStyle(fontSize: 11, color: OrchardColors.muted),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: OrchardColors.tint50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Balance: ${money(tx.runningBalance, currency: currency)}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: OrchardColors.forest,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
