import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../theme/orchard_theme.dart';
import '../../widgets/common.dart';
import '../service_detail_screen.dart';

class ServicesTab extends StatefulWidget {
  const ServicesTab({super.key});

  @override
  State<ServicesTab> createState() => _ServicesTabState();
}

class _ServicesTabState extends State<ServicesTab> {
  String? _category;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatalogState>().loadServices();
    });
  }

  void _open(BuildContext context, ServiceModel s) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ServiceDetailScreen(service: s)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogState>();
    if (catalog.loading && catalog.services.isEmpty) {
      return const LoadingView(message: 'Loading services…');
    }
    if (catalog.error != null && catalog.services.isEmpty) {
      return ErrorView(
          message: catalog.error!, onRetry: () => catalog.loadServices());
    }
    final categories = [
      ...{for (final s in catalog.services) s.category}
        ..removeWhere((c) => c.isEmpty),
    ];
    final visible = _category == null
        ? catalog.services
        : catalog.services.where((s) => s.category == _category).toList();
    return RefreshIndicator(
      onRefresh: () => catalog.loadServices(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          const Row(
            children: [
              Icon(Icons.miscellaneous_services_outlined,
                  size: 15, color: OrchardColors.pine),
              SizedBox(width: 6),
              Text(
                'OUR SERVICES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.22,
                  color: OrchardColors.pine,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Bookable AgriTech Services',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          const Text(
            'Precision orchard care, executed stage-by-stage by our field team.',
            style: TextStyle(fontSize: 13, color: OrchardColors.muted),
          ),
          if (categories.isNotEmpty) ...[
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: const Text('All'),
                      selected: _category == null,
                      onSelected: (_) =>
                          setState(() => _category = null),
                    ),
                  ),
                  for (final c in categories)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(c),
                        selected: _category == c,
                        onSelected: (_) =>
                            setState(() => _category = c),
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (visible.isEmpty)
            const EmptyView(message: 'No services available right now.'),
          for (final s in visible)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _open(context, s),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                    if (s.image != null)
                      Image.network(s.image!,
                          height: 140,
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
                                  .titleMedium),
                          if (s.description != null &&
                              s.description!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              s.description!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: OrchardColors.muted),
                            ),
                          ],
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: OrchardColors.brand,
                              ),
                              onPressed: () =>
                                  _open(context, s),
                              child: const Text('Book Service'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
