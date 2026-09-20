import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/orchard_theme.dart';
import '../widgets/common.dart';
import 'order_detail_screen.dart';

/// Service detail (spec §3.5): hero, info, "Book this service" CTA.
class ServiceDetailScreen extends StatelessWidget {
  const ServiceDetailScreen({super.key, required this.service});
  final ServiceModel service;

  Future<void> _confirm(BuildContext context) async {
    final notes = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Confirm booking',
                style: Theme.of(ctx).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(service.name,
                style: Theme.of(ctx).textTheme.titleSmall),
            if (service.category.isNotEmpty)
              Text(service.category,
                  style: const TextStyle(
                      fontSize: 13, color: OrchardColors.muted)),
            const SizedBox(height: 12),
            TextField(
              controller: notes,
              maxLines: 3,
              maxLength: 2000,
              decoration: const InputDecoration(
                labelText: 'Notes for our team (optional)',
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: OrchardColors.brand),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Submit booking'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      final res = await context
          .read<CatalogState>()
          .book(service.id, notes.text);
      if (!context.mounted) return;
      context.read<OrdersState>().load(reset: true);
      context.read<DashboardState>().load();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => BookingSuccessScreen(
            message: res.message,
            orderId: res.order.id,
            orderNumber: res.order.number,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (context.mounted) {
        showSnack(context, e.friendlyMessage, isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = service;
    return Scaffold(
      appBar: AppBar(title: Text(s.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (s.image != null)
                  Image.network(s.image!,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          const SizedBox.shrink()),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (s.category.isNotEmpty)
                        StatusChip(label: s.category),
                      if (s.category.isNotEmpty)
                        const SizedBox(height: 8),
                      Text(s.name,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall),
                      if (s.description != null &&
                          s.description!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(s.description!),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('How it works',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  SizedBox(height: 6),
                  Text(
                    'Our field team executes the service stage-by-stage. '
                    'Track every stage, photo and material from Work Orders.',
                    style: TextStyle(
                        fontSize: 13,
                        color: OrchardColors.muted),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
              top: BorderSide(color: OrchardColors.border)),
        ),
        child: FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: OrchardColors.brand),
          onPressed: () => _confirm(context),
          child: const Text('Book this service'),
        ),
      ),
    );
  }
}

/// Booking success (spec §3.5) with a "View Work Order" action.
class BookingSuccessScreen extends StatelessWidget {
  const BookingSuccessScreen({
    super.key,
    required this.message,
    required this.orderId,
    required this.orderNumber,
  });
  final String message;
  final int orderId;
  final String orderNumber;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booking confirmed')),
      body: Center(
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
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: OrchardColors.tint100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                          Icons.check_circle_outline,
                          size: 40,
                          color: OrchardColors.pine),
                    ),
                    const SizedBox(height: 16),
                    Text(orderNumber,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall),
                    const SizedBox(height: 8),
                    Text(message,
                        textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () =>
                            Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                              builder: (_) => OrderDetailScreen(
                                  id: orderId)),
                        ),
                        child: const Text('View Work Order'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context)
                            .popUntil((r) => r.isFirst),
                        child: const Text('Back to Home'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
