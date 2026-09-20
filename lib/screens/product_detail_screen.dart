import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/orchard_theme.dart';
import '../widgets/common.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key, required this.product});
  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final currency = context.select<AuthState, String>((a) => a.config.currency);
    final support = context.select<AuthState, SupportInfo>((a) => a.config.support);
    final p = product;

    final hasDiscount = p.mrp != null && p.mrp! > p.price;
    final discountPercent = hasDiscount
        ? (((p.mrp! - p.price) / p.mrp!) * 100).round()
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(p.name),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          // Product Image Banner
          Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              color: OrchardColors.tint50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: OrchardColors.tint200),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: p.image != null && p.image!.isNotEmpty
                  ? Image.network(
                      p.image!,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => _ImagePlaceholder(name: p.name),
                    )
                  : _ImagePlaceholder(name: p.name),
            ),
          ),
          const SizedBox(height: 16),

          // Name and Badges
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  p.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: OrchardColors.forest,
                      ),
                ),
              ),
              StatusChip(
                label: p.inStock ? 'In Stock' : 'Out of Stock',
                color: p.inStock ? 'green' : 'red',
              ),
            ],
          ),
          const SizedBox(height: 6),

          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              if (p.sku.isNotEmpty)
                _PillTag(label: 'SKU: ${p.sku}', icon: Icons.tag),
              if (p.hsnCode != null && p.hsnCode!.isNotEmpty)
                _PillTag(label: 'HSN: ${p.hsnCode}', icon: Icons.receipt_outlined),
              if (p.unit.isNotEmpty)
                _PillTag(label: 'Unit: ${p.unit}', icon: Icons.scale_outlined),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Pricing Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: OrchardColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'STOREFRONT PRICE',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: OrchardColors.muted,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      money(p.price, currency: currency),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: OrchardColors.forest,
                      ),
                    ),
                    if (p.unit.isNotEmpty)
                      Text(
                        ' / ${p.unit}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: OrchardColors.muted,
                        ),
                      ),
                    const SizedBox(width: 12),
                    if (hasDiscount) ...[
                      Text(
                        money(p.mrp!, currency: currency),
                        style: const TextStyle(
                          fontSize: 15,
                          color: OrchardColors.muted,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '$discountPercent% OFF',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: OrchardColors.pine,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: OrchardColors.tint50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'GST: ${p.gstRate}% Included',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: OrchardColors.forest,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (p.stockQty > 0)
                      Text(
                        'Available: ${p.stockQty} ${p.unit}',
                        style: const TextStyle(fontSize: 12, color: OrchardColors.muted),
                      ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const SectionTitle(title: 'Product Information & Notes'),
          const SizedBox(height: 8),
          Text(
            p.description != null && p.description!.trim().isNotEmpty
                ? p.description!
                : 'High-grade agrochemical and nutrition formulation curated for Jammu & Kashmir apple and fruit orchards. Certified for commercial application by Plant Tech Agro agronomy experts.',
            style: const TextStyle(
              fontSize: 14,
              color: OrchardColors.ink,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),

          // Quality & Application Badge
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: OrchardColors.tint50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: OrchardColors.tint200),
            ),
            child: const Row(
              children: [
                Icon(Icons.verified_outlined, color: OrchardColors.pine),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'All supplies are batch-tested and guaranteed genuine directly from certified agricultural manufacturers.',
                    style: TextStyle(fontSize: 12, color: OrchardColors.forest),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: OrchardColors.border)),
        ),
        child: SafeArea(
          child: Row(
            children: [
              if (support.phone.isNotEmpty)
                IconButton.outlined(
                  tooltip: 'Call Support',
                  onPressed: () => launchUrl(Uri.parse('tel:${support.phone}')),
                  icon: const Icon(Icons.phone_outlined, color: OrchardColors.pine),
                ),
              if (support.phone.isNotEmpty) const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _showInquirySheet(context, p, support),
                  icon: const Icon(Icons.send_outlined),
                  label: const Text('Order / Inquire for Orchard'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInquirySheet(BuildContext context, ProductModel p, SupportInfo support) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Inquire for ${p.name}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: OrchardColors.forest,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Our agronomist will arrange batch allocation and deliver directly to your orchard.',
              style: const TextStyle(fontSize: 13, color: OrchardColors.muted),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: OrchardColors.tint100,
                child: Icon(Icons.phone, color: OrchardColors.pine),
              ),
              title: const Text('Direct Agronomist Line'),
              subtitle: Text(support.phone.isNotEmpty ? support.phone : 'Available via PTA Desk'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(ctx);
                if (support.phone.isNotEmpty) {
                  launchUrl(Uri.parse('tel:${support.phone}'));
                }
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Inquiry recorded for ${p.name}. We will contact you.'),
                      backgroundColor: OrchardColors.forest,
                    ),
                  );
                },
                child: const Text('Submit Callback Request'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: OrchardColors.tint100,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.agriculture_outlined,
              size: 48,
              color: OrchardColors.pine,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: OrchardColors.forest,
            ),
          ),
        ],
      ),
    );
  }
}

class _PillTag extends StatelessWidget {
  const _PillTag({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: OrchardColors.tint50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: OrchardColors.tint200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: OrchardColors.pine),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: OrchardColors.forest,
            ),
          ),
        ],
      ),
    );
  }
}
