import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/customer_api.dart';
import '../../state/app_state.dart';
import '../../theme/orchard_theme.dart';
import '../../widgets/common.dart';
import '../gate_screens.dart';
import '../login_screen.dart';
import '../ledger_screen.dart';
import '../weather_detail_screen.dart';
import '../product_detail_screen.dart';
import 'invoices_tab.dart';

/// "More" hub (spec §2/§3.11): Invoices, Products, Profile,
/// Change password, Support, About, Logout.
class MoreTab extends StatelessWidget {
  const MoreTab({super.key });

  void _push(BuildContext context, Widget page) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final u = auth.user;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: OrchardColors.tint100,
              child: Text(
                (u?.name.isNotEmpty ?? false)
                    ? u!.name.characters.first.toUpperCase()
                    : '?',
                style: const TextStyle(
                    color: OrchardColors.pine,
                    fontWeight: FontWeight.w700),
              ),
            ),
            title: Text(u?.name ?? '—'),
            subtitle: Text(
              [u?.phone ?? '', u?.area ?? '']
                  .where((e) => e.isNotEmpty)
                  .join(' • '),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _push(context, const ProfilePage()),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: const Text('Account Statement & Ledger'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _push(context, const LedgerScreen()),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.receipt_long_outlined),
                title: const Text('Invoices'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _push(context, const InvoicesPage()),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.shopping_bag_outlined),
                title: const Text('Products Catalog'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _push(context, const ProductsPage()),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.wb_sunny_outlined),
                title: const Text('Agri-Weather & Spraying Advisory'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _push(context, const WeatherDetailScreen()),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Profile & settings'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _push(context, const ProfilePage()),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Change password'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    _push(context, const ChangePasswordPage()),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.support_agent_outlined),
                title: const Text('Support'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    _push(context, const SupportScreen()),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('About'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _push(context, const AboutScreen()),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading:
                const Icon(Icons.logout, color: OrchardColors.danger),
            title: const Text('Sign out',
                style: TextStyle(color: OrchardColors.danger)),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Sign out?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel')),
                    FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Sign out')),
                  ],
                ),
              );
              if (confirm != true || !context.mounted) return;
              await context.read<AuthState>().logout();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------ Products ---

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final _search = TextEditingController();
  bool _onlyInStock = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatalogState>().loadProducts(reset: true);
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogState>();
    final currency = context.select<AuthState, String>((a) => a.config.currency);

    final rawProducts = catalog.products;
    final products = _onlyInStock
        ? rawProducts.where((p) => p.inStock).toList()
        : rawProducts;

    return Scaffold(
      appBar: AppBar(title: const Text('Products Catalog')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text('Farm Inputs & Nutrition',
                style: Theme.of(context).textTheme.headlineMedium),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 2, 16, 0),
            child: Text(
              'Genuine certified inputs for your orchard with transparent rates.',
              style: TextStyle(fontSize: 13, color: OrchardColors.muted),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: SearchBar(
              controller: _search,
              hintText: 'Search products by name or SKU…',
              leading: const Icon(Icons.search),
              trailing: [
                if (_search.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _search.clear();
                      catalog.loadProducts(q: '', reset: true);
                    },
                  ),
              ],
              onSubmitted: (v) => catalog.loadProducts(q: v, reset: true),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All Products'),
                  selected: !_onlyInStock,
                  onSelected: (_) => setState(() => _onlyInStock = false),
                  selectedColor: OrchardColors.tint100,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: !_onlyInStock ? FontWeight.w600 : FontWeight.w500,
                    color: !_onlyInStock ? OrchardColors.pine : OrchardColors.ink,
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('In Stock Only'),
                  selected: _onlyInStock,
                  onSelected: (val) => setState(() => _onlyInStock = val),
                  selectedColor: OrchardColors.tint100,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: _onlyInStock ? FontWeight.w600 : FontWeight.w500,
                    color: _onlyInStock ? OrchardColors.pine : OrchardColors.ink,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Builder(builder: (context) {
              if (catalog.loading && rawProducts.isEmpty) {
                return const LoadingView(message: 'Loading products…');
              }
              if (catalog.error != null && rawProducts.isEmpty) {
                return ErrorView(
                  message: catalog.error!,
                  onRetry: () => catalog.loadProducts(reset: true),
                );
              }
              if (products.isEmpty) {
                return const EmptyView(message: 'No products match your filter.');
              }
              return RefreshIndicator(
                onRefresh: () => catalog.loadProducts(reset: true),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 24),
                  itemCount: products.length + (catalog.hasMore && !_onlyInStock ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (i >= products.length) {
                      catalog.loadProducts(reset: false);
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final p = products[i];
                    final hasDiscount = p.mrp != null && p.mrp! > p.price;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ProductDetailScreen(product: p),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  color: OrchardColors.tint50,
                                  child: p.image != null && p.image!.isNotEmpty
                                      ? Image.network(
                                          p.image!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) => const Icon(
                                            Icons.agriculture_outlined,
                                            size: 28,
                                            color: OrchardColors.pine,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.agriculture_outlined,
                                          size: 28,
                                          color: OrchardColors.pine,
                                        ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            p.name,
                                            style: const TextStyle(
                                              fontFamily: 'Inter',
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        StatusChip(
                                          label: p.inStock ? 'In Stock' : 'Out of Stock',
                                          color: p.inStock ? 'green' : 'red',
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${p.sku}${p.hsnCode != null ? ' • HSN: ${p.hsnCode}' : ''}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: OrchardColors.muted,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          money(p.price, currency: currency),
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            color: OrchardColors.forest,
                                          ),
                                        ),
                                        if (p.unit.isNotEmpty)
                                          Text(
                                            ' / ${p.unit}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: OrchardColors.muted,
                                            ),
                                          ),
                                        if (hasDiscount) ...[
                                          const SizedBox(width: 8),
                                          Text(
                                            money(p.mrp!, currency: currency),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: OrchardColors.muted,
                                              decoration: TextDecoration.lineThrough,
                                            ),
                                          ),
                                        ],
                                      ],
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
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------- Profile ---

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _address;
  late final TextEditingController _area;
  late final String _phone;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final u = context.read<AuthState>().user;
    _name = TextEditingController(text: u?.name ?? '');
    _email = TextEditingController(text: u?.email ?? '');
    _address = TextEditingController(text: u?.address ?? '');
    _area = TextEditingController(text: u?.area ?? '');
    _phone = u?.phone ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _address.dispose();
    _area.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    final api = context.read<CustomerApi>();
    setState(() => _busy = true);
    try {
      final updated = await api.updateProfile(
        name: _name.text.trim(),
        email: _email.text.trim().isEmpty ? null : _email.text.trim(),
        address: _address.text.trim().isEmpty ? null : _address.text.trim(),
        area: _area.text.trim().isEmpty ? null : _area.text.trim(),
      );
      if (!mounted) return;
      final auth = context.read<AuthState>();
      auth.setUser(updated);
      await auth.session.updateUser(updated.toJson());
      messenger.showSnackBar(const SnackBar(content: Text('Profile updated.')));
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('Update failed. Check connection.')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                    labelText: 'Name', border: OutlineInputBorder()),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _phone,
                readOnly: true,
                decoration: const InputDecoration(
                    labelText: 'Phone (cannot be changed)',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                    labelText: 'Email', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _area,
                decoration: const InputDecoration(
                    labelText: 'Area / Village', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _address,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: 'Address', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _busy ? null : _save,
                child: Text(_busy ? 'Saving…' : 'Save changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------- Change password ---

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _cur = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _cur.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_next.text.length < 8 || _next.text != _confirm.text) {
      showSnack(context, 'New passwords must match and be 8+ chars.',
          isError: true);
      return;
    }
    setState(() => _busy = true);
    try {
      final api = context.read<CustomerApi>();
      final msg =
          await api.changePassword(_cur.text, _next.text, _confirm.text);
      if (mounted) {
        showSnack(context, msg);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        showSnack(context, 'Failed. Check current password.', isError: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change password')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
                controller: _cur,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: 'Current password',
                    border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(
                controller: _next,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: 'New password (letters + numbers, 8+)',
                    border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(
                controller: _confirm,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: 'Confirm new password',
                    border: OutlineInputBorder())),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: Text(_busy ? 'Saving…' : 'Change password'),
            ),
          ],
        ),
      ),
    );
  }
}
