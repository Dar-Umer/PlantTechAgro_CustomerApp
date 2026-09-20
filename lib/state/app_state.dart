import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../models/models.dart';
import '../services/customer_api.dart';

/// Shared async-state helper: loading flag + error message.
mixin Loadable on ChangeNotifier {
  bool _loading = false;
  String? _error;

  bool get loading => _loading;
  String? get error => _error;

  Future<T> guard<T>(Future<T> Function() fn, {bool notify = true}) async {
    _loading = true;
    _error = null;
    if (notify) notifyListeners();
    try {
      return await fn();
    } on ApiException catch (e) {
      _error = e.firstFieldError ?? e.message;
      rethrow;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _loading = false;
      if (notify) notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

// ------------------------------------------------------------------ Auth ---

class AuthState extends ChangeNotifier with Loadable {
  AuthState(this.api, this.session);
  final CustomerApi api;
  final SessionStore session;

  AppUser? user;
  AppConfigModel config = AppConfigModel();

  bool get isLoggedIn => session.isLoggedIn;

  Future<void> bootstrap() async {
    await session.load();
    if (session.user != null) {
      try {
        user = AppUser.fromJson(session.user!);
      } catch (_) {}
    }
    // Refresh config + profile in background; ignore failures offline.
    try {
      config = await api.appConfig();
    } catch (_) {}
    if (isLoggedIn) {
      try {
        final me = await api.me();
        user = me.user;
        config = me.config;
        await session.updateUser(user!.toJson());
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> login(String phone, String password) async {
    await guard(() async {
      final res = await api.login(phone.trim(), password);
      user = res.user;
      config = res.config;
      await session.save(res.token, res.user.toJson());
    });
  }

  Future<void> logout() async {
    await api.logout();
    await logoutLocal();
  }

  /// Flush the local session without a network call (401 / token flush).
  Future<void> logoutLocal() async {
    user = null;
    await session.clear();
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    final me = await api.me();
    user = me.user;
    config = me.config;
    await session.updateUser(user!.toJson());
    notifyListeners();
  }

  void setUser(AppUser updated) {
    user = updated;
    notifyListeners();
  }

  void updateConfig(AppConfigModel config) {
    this.config = config;
    notifyListeners();
  }
}

// ------------------------------------------------------------- Dashboard ---

class DashboardState extends ChangeNotifier with Loadable {
  DashboardState(this.api);
  final CustomerApi api;

  DashboardStats stats = DashboardStats();
  List<WorkOrderSummary> recentOrders = [];
  List<InvoiceSummary> recentInvoices = [];
  SupportInfo support = SupportInfo();
  WeatherInfo? weather;

  Future<void> load() async {
    await guard(() async {
      final d = await api.dashboard();
      stats = d.stats;
      recentOrders = d.recentOrders;
      recentInvoices = d.recentInvoices;
      support = d.support;
      weather = d.weather;
    });
  }
}

// ---------------------------------------------------------------- Catalog ---

class CatalogState extends ChangeNotifier with Loadable {
  CatalogState(this.api);
  final CustomerApi api;

  List<ServiceModel> services = [];
  List<ProductModel> products = [];
  String query = '';
  int _page = 1;
  bool _hasMore = true;
  bool _loadingMore = false;

  bool get hasMore => _hasMore;
  bool get loadingMore => _loadingMore;

  Future<void> loadServices() async {
    await guard(() async {
      services = await api.services();
    });
  }

  Future<void> loadProducts({String? q, bool reset = true}) async {
    if (reset) {
      query = q ?? query;
      _page = 1;
      _hasMore = true;
      await guard(() async {
        final p = await api.products(q: query, page: 1);
        products = p.items;
        _hasMore = p.hasMore;
      });
    } else {
      if (_loadingMore || !_hasMore) return;
      _loadingMore = true;
      notifyListeners();
      try {
        final p = await api.products(q: query, page: _page + 1);
        _page = p.currentPage;
        _hasMore = p.hasMore;
        products = [...products, ...p.items];
      } finally {
        _loadingMore = false;
        notifyListeners();
      }
    }
  }

  Future<({String message, WorkOrderSummary order})> book(int serviceId, String? notes) {
    return api.bookService(serviceId, notes);
  }
}

// ----------------------------------------------------------------- Orders ---

class OrdersState extends ChangeNotifier with Loadable {
  OrdersState(this.api);
  final CustomerApi api;

  List<WorkOrderSummary> items = [];
  String? statusFilter;
  int _page = 1;
  bool _hasMore = true;
  bool _loadingMore = false;
  int total = 0;

  bool get hasMore => _hasMore;
  bool get loadingMore => _loadingMore;

  Future<void> load({String? status, bool reset = true}) async {
    if (reset) {
      statusFilter = status;
      _page = 1;
      _hasMore = true;
      await guard(() async {
        final p = await api.workOrders(status: statusFilter, page: 1);
        items = p.items;
        total = p.total;
        _hasMore = p.hasMore;
      });
    } else {
      if (_loadingMore || !_hasMore) return;
      _loadingMore = true;
      notifyListeners();
      try {
        final p = await api.workOrders(status: statusFilter, page: _page + 1);
        _page = p.currentPage;
        _hasMore = p.hasMore;
        total = p.total;
        items = [...items, ...p.items];
      } finally {
        _loadingMore = false;
        notifyListeners();
      }
    }
  }
}

class OrderDetailState extends ChangeNotifier with Loadable {
  OrderDetailState(this.api);
  final CustomerApi api;

  WorkOrderDetail? detail;

  Future<void> load(int id) async {
    detail = null;
    await guard(() async {
      detail = await api.workOrder(id);
    });
  }
}

// --------------------------------------------------------------- Invoices ---

class InvoicesState extends ChangeNotifier with Loadable {
  InvoicesState(this.api);
  final CustomerApi api;

  List<InvoiceSummary> items = [];
  String? statusFilter;
  int _page = 1;
  bool _hasMore = true;
  bool _loadingMore = false;
  int total = 0;

  bool get hasMore => _hasMore;
  bool get loadingMore => _loadingMore;

  Future<void> load({String? status, bool reset = true}) async {
    if (reset) {
      statusFilter = status;
      _page = 1;
      _hasMore = true;
      await guard(() async {
        final p = await api.invoices(status: statusFilter, page: 1);
        items = p.items;
        total = p.total;
        _hasMore = p.hasMore;
      });
    } else {
      if (_loadingMore || !_hasMore) return;
      _loadingMore = true;
      notifyListeners();
      try {
        final p = await api.invoices(status: statusFilter, page: _page + 1);
        _page = p.currentPage;
        _hasMore = p.hasMore;
        total = p.total;
        items = [...items, ...p.items];
      } finally {
        _loadingMore = false;
        notifyListeners();
      }
    }
  }
}

class InvoiceDetailState extends ChangeNotifier with Loadable {
  InvoiceDetailState(this.api);
  final CustomerApi api;

  InvoiceDetail? detail;

  Future<void> load(int id) async {
    detail = null;
    await guard(() async {
      detail = await api.invoice(id);
    });
  }
}

// ---------------------------------------------------------- Notifications ---

class NotificationsState extends ChangeNotifier with Loadable {
  NotificationsState(this.api);
  final CustomerApi api;

  List<AppNotification> items = [];
  int unread = 0;

  Future<void> load() async {
    await guard(() async {
      final n = await api.notifications();
      items = n.items;
      unread = n.unread;
    });
  }

  Future<void> markRead(AppNotification n) async {
    if (n.isRead) return;
    unread = await api.markRead(n.id);
    final i = items.indexWhere((e) => e.id == n.id);
    if (i != -1) {
      items[i] = AppNotification(
        id: n.id,
        title: n.title,
        body: n.body,
        type: n.type,
        readAt: DateTime.now().toIso8601String(),
        createdAt: n.createdAt,
      );
    }
    notifyListeners();
  }

  Future<void> markAllRead() async {
    await api.markAllRead();
    unread = 0;
    items = [
      for (final n in items)
        AppNotification(
          id: n.id,
          title: n.title,
          body: n.body,
          type: n.type,
          readAt: n.readAt ?? DateTime.now().toIso8601String(),
          createdAt: n.createdAt,
        ),
    ];
    notifyListeners();
  }
}

// ----------------------------------------------------------------- Ledger ---

class LedgerState extends ChangeNotifier with Loadable {
  LedgerState(this.api);
  final CustomerApi api;

  CustomerLedgerStatement? statement;
  String period = 'this_year';
  String? fromDate;
  String? toDate;

  Future<void> setPeriod(String p) async {
    period = p;
    final now = DateTime.now();
    switch (p) {
      case '30_days':
        final start = now.subtract(const Duration(days: 30));
        fromDate = '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
        toDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        break;
      case 'this_month':
        fromDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
        toDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        break;
      case 'this_year':
        fromDate = '${now.year}-01-01';
        toDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        break;
      case 'all':
      default:
        fromDate = null;
        toDate = null;
        break;
    }
    await load();
  }

  Future<void> setCustomDates(String from, String to) async {
    period = 'custom';
    fromDate = from;
    toDate = to;
    await load();
  }

  Future<void> load() async {
    await guard(() async {
      statement = await api.ledger(from: fromDate, to: toDate);
    });
  }
}

// ---------------------------------------------------------------- Weather ---

class WeatherState extends ChangeNotifier with Loadable {
  WeatherState(this.api);
  final CustomerApi api;

  WeatherInfo? weather;
  String selectedDistrict = 'srinagar';

  static const Map<String, String> kashmiriDistricts = {
    'srinagar': 'Srinagar',
    'baramulla': 'Baramulla',
    'anantnag': 'Anantnag',
    'pulwama': 'Pulwama',
    'shopian': 'Shopian',
    'budgam': 'Budgam',
    'ganderbal': 'Ganderbal',
    'kulgam': 'Kulgam',
    'kupwara': 'Kupwara',
    'bandipora': 'Bandipora',
  };

  Future<void> load({String? district, String? area}) async {
    if (district != null) {
      selectedDistrict = district;
    }
    await guard(() async {
      weather = await api.weather(district: selectedDistrict, area: area);
    });
  }
}

