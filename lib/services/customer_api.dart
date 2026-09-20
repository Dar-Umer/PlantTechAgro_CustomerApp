import '../core/api_client.dart';
import '../models/models.dart';

Map<String, dynamic> _map(dynamic v) =>
    v is Map<String, dynamic> ? v : <String, dynamic>{};

/// One place for every `/api/*` customer endpoint (see Laravel
/// `routes/api.php`). UI talks to providers; providers talk to this class.
class CustomerApi {
  CustomerApi(this.client);
  final ApiClient client;

  // ---------------------------------------------------------- app config ---
  Future<AppConfigModel> appConfig() async {
    final res = await client.get('/app-config');
    return AppConfigModel.fromJson(_map(res['app_config']));
  }

  // ----------------------------------------------------------------- auth ---
  Future<({String token, AppUser user, AppConfigModel config})> login(
    String phone,
    String password,
  ) async {
    final res = await client.post('/auth/login', {
      'phone': phone,
      'password': password,
    });
    return (
      token: res['token'].toString(),
      user: AppUser.fromJson(_map(res['user'])),
      config: AppConfigModel.fromJson(_map(res['app_config'])),
    );
  }

  Future<void> logout() async {
    try {
      await client.post('/auth/logout');
    } catch (_) {
      // Token may already be invalid — still clear local session.
    }
  }

  Future<({String message, String? debugOtp})> requestOtp(String phone) async {
    final res = await client.post('/auth/forgot', {'phone': phone});
    return (
      message: (res['message'] ?? '').toString(),
      debugOtp: res['debug_otp']?.toString(),
    );
  }

  Future<String> verifyOtp(String phone, String code) async {
    final res = await client.post('/auth/verify-otp', {
      'phone': phone,
      'code': code,
    });
    return (res['message'] ?? 'OTP verified.').toString();
  }

  Future<String> resetPassword(
    String phone,
    String code,
    String password,
    String confirm,
  ) async {
    final res = await client.post('/auth/reset-password', {
      'phone': phone,
      'code': code,
      'password': password,
      'password_confirmation': confirm,
    });
    return (res['message'] ?? 'Password updated.').toString();
  }

  // -------------------------------------------------------------- profile ---
  Future<({AppUser user, AppConfigModel config})> me() async {
    final res = await client.get('/me');
    return (
      user: AppUser.fromJson(_map(res['user'])),
      config: AppConfigModel.fromJson(_map(res['app_config'])),
    );
  }

  Future<AppUser> updateProfile({
    required String name,
    String? email,
    String? address,
    String? area,
  }) async {
    final res = await client.put('/me', {
      'name': name,
      'email': email,
      'address': address,
      'area': area,
    });
    return AppUser.fromJson(_map(res['user']));
  }

  Future<String> changePassword(String current, String next, String confirm) async {
    final res = await client.put('/me/password', {
      'current_password': current,
      'password': next,
      'password_confirmation': confirm,
    });
    return (res['message'] ?? 'Password changed.').toString();
  }

  // --------------------------------------------------------------- ledger ---
  Future<CustomerLedgerStatement> ledger({String? from, String? to}) async {
    final res = await client.get('/me/ledger', query: {
      if (from != null && from.isNotEmpty) 'from': from,
      if (to != null && to.isNotEmpty) 'to': to,
    });
    return CustomerLedgerStatement.fromJson(_map(res));
  }

  // ------------------------------------------------------------ dashboard ---
  Future<({
    DashboardStats stats,
    List<WorkOrderSummary> recentOrders,
    List<InvoiceSummary> recentInvoices,
    SupportInfo support,
    WeatherInfo? weather,
    AppConfigModel config,
  })> dashboard() async {
    final res = await client.get('/dashboard');
    return (
      stats: DashboardStats.fromJson(_map(res['stats'])),
      recentOrders: ((res['recent_work_orders'] as List?) ?? [])
          .map((e) => WorkOrderSummary.fromJson(_map(e)))
          .toList(),
      recentInvoices: ((res['recent_invoices'] as List?) ?? [])
          .map((e) => InvoiceSummary.fromJson(_map(e)))
          .toList(),
      support: SupportInfo.fromJson(_map(res['support'])),
      weather: res['weather'] == null ? null : WeatherInfo.fromJson(_map(res['weather'])),
      config: AppConfigModel.fromJson(_map(res['app_config'])),
    );
  }

  Future<WeatherInfo?> weather({String? area, String? district}) async {
    final res = await client.get('/weather', query: {
      if (area case final a) 'area': a,
      if (district case final d) 'district': d,
    });
    if (res['weather'] == null) return null;
    return WeatherInfo.fromJson(_map(res['weather']));
  }

  // -------------------------------------------------------------- services ---
  Future<List<ServiceModel>> services() async {
    final res = await client.get('/services');
    return ((res['services'] as List?) ?? [])
        .map((e) => ServiceModel.fromJson(_map(e)))
        .toList();
  }

  // -------------------------------------------------------------- products ---
  Future<Paged<ProductModel>> products({String? q, int page = 1}) async {
    final res = await client.get('/products', query: {
      if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
      'page': page,
    });
    final p = _map(res['pagination']);
    return Paged(
      items: ((res['products'] as List?) ?? [])
          .map((e) => ProductModel.fromJson(_map(e)))
          .toList(),
      currentPage: (p['current_page'] as num?)?.toInt() ?? page,
      lastPage: (p['last_page'] as num?)?.toInt() ?? page,
      total: (p['total'] as num?)?.toInt() ?? 0,
    );
  }

  // ------------------------------------------------------------ work orders ---
  Future<Paged<WorkOrderSummary>> workOrders({String? status, int page = 1}) async {
    final res = await client.get('/work-orders', query: {
      if (status != null && status.isNotEmpty) 'status': status,
      'page': page,
    });
    final p = _map(res['pagination']);
    return Paged(
      items: ((res['work_orders'] as List?) ?? [])
          .map((e) => WorkOrderSummary.fromJson(_map(e)))
          .toList(),
      currentPage: (p['current_page'] as num?)?.toInt() ?? page,
      lastPage: (p['last_page'] as num?)?.toInt() ?? page,
      total: (p['total'] as num?)?.toInt() ?? 0,
    );
  }

  Future<WorkOrderDetail> workOrder(int id) async {
    final res = await client.get('/work-orders/$id');
    return WorkOrderDetail.fromJson(_map(res['work_order']));
  }

  Future<({String message, WorkOrderSummary order})> bookService(
    int serviceId,
    String? notes,
  ) async {
    final res = await client.post('/work-orders', {
      'service_id': serviceId,
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    });
    return (
      message: (res['message'] ?? 'Request submitted.').toString(),
      order: WorkOrderSummary.fromJson(_map(res['work_order'])),
    );
  }

  // --------------------------------------------------------------- invoices ---
  Future<Paged<InvoiceSummary>> invoices({String? status, int page = 1}) async {
    final res = await client.get('/invoices', query: {
      if (status != null && status.isNotEmpty) 'status': status,
      'page': page,
    });
    final p = _map(res['pagination']);
    return Paged(
      items: ((res['invoices'] as List?) ?? [])
          .map((e) => InvoiceSummary.fromJson(_map(e)))
          .toList(),
      currentPage: (p['current_page'] as num?)?.toInt() ?? page,
      lastPage: (p['last_page'] as num?)?.toInt() ?? page,
      total: (p['total'] as num?)?.toInt() ?? 0,
    );
  }

  Future<InvoiceDetail> invoice(int id) async {
    final res = await client.get('/invoices/$id');
    return InvoiceDetail.fromJson(_map(res['invoice']));
  }

  // ---------------------------------------------------------- notifications ---
  Future<({List<AppNotification> items, int unread})> notifications() async {
    final res = await client.get('/notifications');
    return (
      items: ((res['notifications'] as List?) ?? [])
          .map((e) => AppNotification.fromJson(_map(e)))
          .toList(),
      unread: (res['unread_count'] as num?)?.toInt() ?? 0,
    );
  }

  Future<int> markRead(String id) async {
    final res = await client.post('/notifications/$id/read');
    return (res['unread_count'] as num?)?.toInt() ?? 0;
  }

  Future<void> markAllRead() async {
    await client.post('/notifications/read-all');
  }
}
