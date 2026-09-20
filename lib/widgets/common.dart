import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/orchard_theme.dart';

final _inr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

String money(double v, {String currency = '₹'}) {
  if (currency == '₹') return _inr.format(v);
  return '$currency ${v.toStringAsFixed(2)}';
}

String fmtDate(String? iso) {
  if (iso == null || iso.isEmpty) return '—';
  try {
    return DateFormat('dd MMM yyyy').format(DateTime.parse(iso));
  } catch (_) {
    return iso;
  }
}

/// Compact relative time ("2h ago") for notification timestamps (spec §5).
String relativeTime(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  try {
    final dt = DateTime.parse(iso).toLocal();
    final diff = DateTime.now().difference(dt);
    if (diff.isNegative) return fmtDate(iso);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return fmtDate(iso);
  } catch (_) {
    return '';
  }
}

Color statusColor(String? color, BuildContext context) {
  switch ((color ?? '').toLowerCase()) {
    case 'green':
      return OrchardColors.pine;
    case 'yellow':
    case 'amber':
    case 'orange':
      return OrchardColors.warning;
    case 'red':
      return OrchardColors.danger;
    case 'blue':
      return OrchardColors.info;
    default:
      return OrchardColors.muted;
  }
}

/// Status badge per the Orchard Modernist chip spec:
/// 24px height, 12px radius, mapped (bg, fg) pairs by label.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, this.color});
  final String label;
  final String? color;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = OrchardColors.statusPair(label);
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message = 'Loading…'});
  final String message;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined,
                size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.message, this.icon = Icons.inbox_outlined});
  final String message;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.title, this.action});
  final String title;
  final Widget? action;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ),
        if (action != null) action!, // ignore: use_null_aware_elements
      ],
    );
  }
}

void showSnack(BuildContext context, String message, {bool isError = false}) {  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
    ),
  );
}
