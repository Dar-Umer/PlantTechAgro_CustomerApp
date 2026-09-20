import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/orchard_theme.dart';
import '../widgets/common.dart';
import 'invoice_detail_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.id});
  final int id;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderDetailState>().load(widget.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OrderDetailState>();
    final currency =
        context.select<AuthState, String>((a) => a.config.currency);
    return Scaffold(
      appBar: AppBar(title: const Text('Order details')),
      body: Builder(builder: (context) {
        // NB: on first build neither loading, error nor detail is set —
        // fall through to a loader instead of force-unwrapping null.
        if (state.detail == null) {
          if (state.error != null) {
            return ErrorView(
                message: state.error!,
                onRetry: () => state.load(widget.id));
          }
          return const LoadingView(message: 'Loading order…');
        }
        final d = state.detail!;
        return RefreshIndicator(
          onRefresh: () => state.load(widget.id),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _HeaderCard(currency: currency),
              const SizedBox(height: 16),
              const SectionTitle(title: 'Execution Timeline'),
              const SizedBox(height: 8),
              for (var i = 0; i < d.stages.length; i++)
                _StageCard(
                  stage: d.stages[i],
                  currency: currency,
                  isLast: i == d.stages.length - 1,
                ),
            ],
          ),
        );
      }),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.currency});
  final String currency;

  @override
  Widget build(BuildContext context) {
    final d = context.select<OrderDetailState, WorkOrderDetail?>(
        (s) => s.detail)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(d.number,
                      style:
                          Theme.of(context).textTheme.headlineSmall),
                ),
                StatusChip(label: d.statusLabel, color: d.statusColor),
              ],
            ),
            Text(d.serviceName,
                style: const TextStyle(
                    fontSize: 14, color: OrchardColors.muted)),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: d.progressPercent / 100,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${d.stagesCompleted} of ${d.stagesTotal} stages • ${d.progressPercent}% Complete',
              style: const TextStyle(
                  fontSize: 12, color: OrchardColors.muted),
            ),
            if (d.assignedTo != null) ...[
              const SizedBox(height: 6),
              Text('Agent: ${d.assignedTo}',
                  style: const TextStyle(fontSize: 13)),
            ],
            if (d.notes != null && d.notes!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Notes: ${d.notes!}',
                  style: const TextStyle(fontSize: 13)),
            ],
            if (d.invoice != null) ...[
              const SizedBox(height: 12),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) =>
                          InvoiceDetailScreen(id: d.invoice!.id)),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: OrchardColors.tint50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.receipt_long_outlined,
                          color: OrchardColors.pine),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Invoice ${d.invoice!.number}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13),
                            ),
                            Text(
                              '${d.invoice!.statusLabel} • Balance ${money(d.invoice!.balanceDue, currency: currency)}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: OrchardColors.muted),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          color: OrchardColors.muted),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StageCard extends StatelessWidget {
  const _StageCard(
      {required this.stage, required this.currency, required this.isLast});
  final WorkOrderStage stage;
  final String currency;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final s = stage;
    final done = s.status == 'completed';
    final active = s.status == 'in_progress';
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Icon(
                done
                    ? Icons.check_circle
                    : active
                        ? Icons.timelapse
                        : Icons.circle_outlined,
                color: done
                    ? OrchardColors.primary
                    : active
                        ? OrchardColors.warning
                        : OrchardColors.border,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                      width: 2, color: OrchardColors.tint200),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(s.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall),
                          ),
                          StatusChip(
                              label: s.statusLabel,
                              color: s.statusColor),
                        ],
                      ),
                      if (s.description != null &&
                          s.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(s.description!,
                            style: const TextStyle(
                                fontSize: 13,
                                color: OrchardColors.muted)),
                      ],
                      if (s.requiresPhoto || s.requiresPdf) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          children: [
                            if (s.requiresPhoto)
                              const StatusChip(
                                  label: 'Requires photo'),
                            if (s.requiresPdf)
                              const StatusChip(
                                  label: 'Requires PDF'),
                          ],
                        ),
                      ],
                      if (s.attachments.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 64,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: s.attachments.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, i) {
                              final a = s.attachments[i];
                              return GestureDetector(
                                onTap: a.url == null
                                    ? null
                                    : () async {
                                        final uri =
                                            Uri.parse(a.url!);
                                        if (await canLaunchUrl(
                                            uri)) {
                                          await launchUrl(uri,
                                              mode: LaunchMode
                                                  .externalApplication);
                                        }
                                      },
                                child: ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(8),
                                  child: a.url != null &&
                                          a.type != 'pdf'
                                      ? Image.network(a.url!,
                                          width: 64,
                                          height: 64,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) =>
                                              _fileTile(a))
                                      : _fileTile(a),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                      if (s.products.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text('Materials',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                        for (final p in s.products)
                          Padding(
                            padding:
                                const EdgeInsets.only(top: 2),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${p.name} • ${p.quantity} ${p.unit}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color:
                                            OrchardColors.muted),
                                  ),
                                ),
                                Text(
                                    money(p.total,
                                        currency: currency),
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight:
                                            FontWeight.w600)),
                              ],
                            ),
                          ),
                      ],
                      if (s.notes != null &&
                          s.notes!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('Notes: ${s.notes!}',
                            style: const TextStyle(fontSize: 12)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fileTile(StageAttachment a) {
    return Container(
      width: 64,
      height: 64,
      color: OrchardColors.tint50,
      child: Icon(
        a.type == 'pdf'
            ? Icons.picture_as_pdf_outlined
            : Icons.image_outlined,
        color: OrchardColors.pine,
      ),
    );
  }
}
