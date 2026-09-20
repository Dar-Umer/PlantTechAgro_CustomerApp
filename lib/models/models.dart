import '../core/config.dart';

Map<String, dynamic> _map(dynamic v) =>
    v is Map<String, dynamic> ? v : <String, dynamic>{};

double _dbl(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

int _int(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

// ---------------------------------------------------------------- User ---

class AppUser {
  AppUser({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.address,
    this.area,
    this.status = '',
  });

  final int id;
  final String name;
  final String phone;
  final String? email;
  final String? address;
  final String? area;
  final String status;

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: _int(j['id']),
        name: (j['name'] ?? '').toString(),
        phone: (j['phone'] ?? '').toString(),
        email: j['email']?.toString(),
        address: j['address']?.toString(),
        area: j['area']?.toString(),
        status: (j['status'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'address': address,
        'area': area,
        'status': status,
      };
}

// ------------------------------------------------------------ App config ---

class SupportInfo {
  SupportInfo({this.phone = '', this.email = '', this.address = '', this.hours = ''});
  final String phone;
  final String email;
  final String address;
  final String hours;

  factory SupportInfo.fromJson(Map<String, dynamic> j) => SupportInfo(
        phone: (j['phone'] ?? '').toString(),
        email: (j['email'] ?? '').toString(),
        address: (j['address'] ?? '').toString(),
        hours: (j['hours'] ?? '').toString(),
      );
}

class ThemeConfig {
  ThemeConfig({
    this.palette = const {},
    this.fontFamily = 'Inter',
    this.logoUrl,
  });
  final Map<String, String> palette;
  final String fontFamily;
  final String? logoUrl;

  factory ThemeConfig.fromJson(Map<String, dynamic> j) {
    final rawPal = j['palette'];
    final Map<String, String> pal = {};
    if (rawPal is Map) {
      rawPal.forEach((k, v) => pal[k.toString()] = v.toString());
    }
    return ThemeConfig(
      palette: pal,
      fontFamily: (j['font_family'] ?? 'Inter').toString(),
      logoUrl: ApiConfig.resolveMedia(j['logo_url']?.toString()),
    );
  }
}

class AppConfigModel {
  AppConfigModel({
    this.appName = 'PTA',
    this.currency = '₹',
    SupportInfo? support,
    CompanyInfo? company,
    MobileInfo? mobile,
    ThemeConfig? theme,
  })  : support = support ?? SupportInfo(),
        company = company ?? CompanyInfo(),
        mobile = mobile ?? MobileInfo(),
        theme = theme ?? ThemeConfig();
  final String appName;
  final String currency;
  final SupportInfo support;
  final CompanyInfo company;
  final MobileInfo mobile;
  final ThemeConfig theme;

  factory AppConfigModel.fromJson(Map<String, dynamic> j) {
    final m = _map(j['mobile']);
    final app = _map(j['app']);
    final t = _map(j['theme']);
    return AppConfigModel(
      appName: (m['name'] ?? app['name'] ?? 'PTA').toString(),
      currency: (j['currency'] ?? '₹').toString(),
      support: SupportInfo.fromJson(_map(j['support'])),
      company: CompanyInfo.fromJson(_map(j['company'])),
      mobile: MobileInfo.fromJson(m),
      theme: ThemeConfig.fromJson(t),
    );
  }
}

class CompanyInfo {
  CompanyInfo({
    this.name = '',
    this.address = '',
    this.phone = '',
    this.email = '',
    this.gstNo = '',
    this.terms = '',
  });
  final String name;
  final String address;
  final String phone;
  final String email;
  final String gstNo;
  final String terms;

  factory CompanyInfo.fromJson(Map<String, dynamic> j) => CompanyInfo(
        name: (j['name'] ?? '').toString(),
        address: (j['address'] ?? '').toString(),
        phone: (j['phone'] ?? '').toString(),
        email: (j['email'] ?? '').toString(),
        gstNo: (j['gst_no'] ?? '').toString(),
        terms: (j['terms'] ?? '').toString(),
      );
}

/// `mobile.*` update-gating + release metadata (spec §3.1).
class MobileInfo {
  MobileInfo({
    this.name = '',
    this.splashTagline = '',
    this.version = '1.0.0',
    this.buildNumber = '1',
    this.minimumSupported = '1.0.0',
    this.forceUpdate = false,
    this.maintenanceMode = false,
    this.androidUpdateUrl = '',
    this.iosUpdateUrl = '',
    this.releaseNotes = '',
    this.appPalette = '',
    this.appFontFamily = '',
    this.appLogoUrl,
  });
  final String name;
  final String splashTagline;
  final String version;
  final String buildNumber;
  final String minimumSupported;
  final bool forceUpdate;
  final bool maintenanceMode;
  final String androidUpdateUrl;
  final String iosUpdateUrl;
  final String releaseNotes;
  final String appPalette;
  final String appFontFamily;
  final String? appLogoUrl;

  factory MobileInfo.fromJson(Map<String, dynamic> j) => MobileInfo(
        name: (j['name'] ?? '').toString(),
        splashTagline: (j['splash_tagline'] ?? '').toString(),
        version: (j['version'] ?? '1.0.0').toString(),
        buildNumber: (j['build_number'] ?? '1').toString(),
        minimumSupported: (j['minimum_supported'] ?? '1.0.0').toString(),
        forceUpdate: j['force_update'] == true,
        maintenanceMode: j['maintenance_mode'] == true,
        androidUpdateUrl: (j['android_update_url'] ?? '').toString(),
        iosUpdateUrl: (j['ios_update_url'] ?? '').toString(),
        releaseNotes: (j['release_notes'] ?? '').toString(),
        appPalette: (j['app_palette'] ?? '').toString(),
        appFontFamily: (j['app_font_family'] ?? '').toString(),
        appLogoUrl: ApiConfig.resolveMedia(j['app_logo_url']?.toString()),
      );
}

/// Numeric dot-separated version comparison: -1 / 0 / 1.
int compareVersions(String a, String b) {
  final pa = a.split('.').map((e) => int.tryParse(e) ?? 0).toList();
  final pb = b.split('.').map((e) => int.tryParse(e) ?? 0).toList();
  final len = pa.length > pb.length ? pa.length : pb.length;
  for (var i = 0; i < len; i++) {
    final x = i < pa.length ? pa[i] : 0;
    final y = i < pb.length ? pb[i] : 0;
    if (x != y) return x < y ? -1 : 1;
  }
  return 0;
}

// --------------------------------------------------------------- Weather ---

class WeatherDailyForecast {
  WeatherDailyForecast({
    required this.date,
    this.tempMax,
    this.tempMin,
    this.precipSum,
    this.rainProbMax,
    this.windMax,
    this.uvMax,
  });

  final String date;
  final double? tempMax;
  final double? tempMin;
  final double? precipSum;
  final int? rainProbMax;
  final double? windMax;
  final double? uvMax;

  factory WeatherDailyForecast.fromJson(Map<String, dynamic> j) =>
      WeatherDailyForecast(
        date: (j['date'] ?? '').toString(),
        tempMax: j['temp_max'] != null ? _dbl(j['temp_max']) : null,
        tempMin: j['temp_min'] != null ? _dbl(j['temp_min']) : null,
        precipSum: j['precip_sum'] != null ? _dbl(j['precip_sum']) : null,
        rainProbMax: j['rain_prob_max'] != null ? _int(j['rain_prob_max']) : null,
        windMax: j['wind_max'] != null ? _dbl(j['wind_max']) : null,
        uvMax: j['uv_max'] != null ? _dbl(j['uv_max']) : null,
      );
}

class WeatherInfo {
  WeatherInfo({
    this.area = '',
    this.district = '',
    this.temperature,
    this.feelsLike,
    this.condition = '',
    this.humidity,
    this.windSpeed,
    this.precipitation,
    this.advisory = '',
    this.level = '',
    this.messages = const [],
    this.daily = const [],
  });
  final String area;
  final String district;
  final double? temperature;
  final double? feelsLike;
  final String condition;
  final double? humidity;
  final double? windSpeed;
  final double? precipitation;
  final String advisory;
  final String level;
  final List<String> messages;
  final List<WeatherDailyForecast> daily;

  /// Backend shape (WeatherService::forArea):
  /// `{location: {label, district, lat, lon}, current: {temp, label,
  /// humidity, wind, ...}, advisory: {level, messages: [...]}, daily: [...]}`.
  /// Also tolerates the flat legacy shape.
  factory WeatherInfo.fromJson(Map<String, dynamic> j) {
    final loc = _map(j['location']);
    final cur = _map(j['current']);
    final adv = _map(j['advisory']);

    String area = '';
    final locLabel = loc['label']?.toString() ?? '';
    final locDistrict = loc['district']?.toString() ?? '';
    if (locLabel.isNotEmpty) {
      area = locLabel;
    } else if (locDistrict.isNotEmpty) {
      area = locDistrict;
    } else {
      final flat = j['area'] ?? j['location'];
      if (flat is String) area = flat;
    }

    final rawMessages = adv['messages'];
    final List<String> messagesList = [];
    String advisory = '';
    if (rawMessages is List && rawMessages.isNotEmpty) {
      for (final m in rawMessages) {
        messagesList.add(m.toString());
      }
      advisory = messagesList.first;
    } else {
      advisory =
          (j['advisory'] is String ? j['advisory'] : null)?.toString() ??
              (j['advice']?.toString() ?? '');
      if (advisory.isNotEmpty) messagesList.add(advisory);
    }

    double? temp;
    double? feelsLike;
    double? precip;
    if (cur['temp'] != null) {
      temp = _dbl(cur['temp']);
    } else if (j['temperature'] != null) {
      temp = _dbl(j['temperature']);
    }
    if (cur['feels_like'] != null) {
      feelsLike = _dbl(cur['feels_like']);
    }
    if (cur['precipitation'] != null) {
      precip = _dbl(cur['precipitation']);
    }

    final condition = (cur['label'] ?? j['condition'] ?? j['description'] ?? '')
        .toString();

    final rawDaily = j['daily'];
    final List<WeatherDailyForecast> dailyList = [];
    if (rawDaily is List) {
      for (final item in rawDaily) {
        if (item is Map<String, dynamic>) {
          dailyList.add(WeatherDailyForecast.fromJson(item));
        } else if (item is Map) {
          dailyList.add(WeatherDailyForecast.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    return WeatherInfo(
      area: area,
      district: locDistrict,
      temperature: temp,
      feelsLike: feelsLike,
      condition: condition,
      humidity: cur['humidity'] != null
          ? _dbl(cur['humidity'])
          : (j['humidity'] == null ? null : _dbl(j['humidity'])),
      windSpeed: cur['wind'] != null
          ? _dbl(cur['wind'])
          : (j['wind_speed'] == null ? null : _dbl(j['wind_speed'])),
      precipitation: precip,
      advisory: advisory,
      level: (adv['level']?.toString() ?? ''),
      messages: messagesList,
      daily: dailyList,
    );
  }
}

// -------------------------------------------------------------- Dashboard ---

class DashboardStats {
  DashboardStats({
    this.workOrdersTotal = 0,
    this.workOrdersActive = 0,
    this.workOrdersInProgress = 0,
    this.workOrdersCompleted = 0,
    this.invoicesTotal = 0,
    this.outstandingBalance = 0,
    this.overdueBalance = 0,
    this.collectedThisMonth = 0,
    this.unreadNotifications = 0,
  });
  final int workOrdersTotal;
  final int workOrdersActive;
  final int workOrdersInProgress;
  final int workOrdersCompleted;
  final int invoicesTotal;
  final double outstandingBalance;
  final double overdueBalance;
  final double collectedThisMonth;
  final int unreadNotifications;

  factory DashboardStats.fromJson(Map<String, dynamic> j) => DashboardStats(
        workOrdersTotal: _int(j['work_orders_total']),
        workOrdersActive: _int(j['work_orders_active']),
        workOrdersInProgress: _int(j['work_orders_in_progress']),
        workOrdersCompleted: _int(j['work_orders_completed']),
        invoicesTotal: _int(j['invoices_total']),
        outstandingBalance: _dbl(j['outstanding_balance']),
        overdueBalance: _dbl(j['overdue_balance']),
        collectedThisMonth: _dbl(j['collected_this_month']),
        unreadNotifications: _int(j['unread_notifications']),
      );
}

// ------------------------------------------------------------- Work order ---

class WoInvoiceRef {
  WoInvoiceRef({
    required this.id,
    required this.number,
    required this.status,
    this.statusLabel = '',
    this.grandTotal = 0,
    this.balanceDue = 0,
  });
  final int id;
  final String number;
  final String status;
  final String statusLabel;
  final double grandTotal;
  final double balanceDue;

  factory WoInvoiceRef.fromJson(Map<String, dynamic> j) => WoInvoiceRef(
        id: _int(j['id']),
        number: (j['number'] ?? '').toString(),
        status: (j['status'] ?? '').toString(),
        statusLabel: (j['status_label'] ?? j['status'] ?? '').toString(),
        grandTotal: _dbl(j['grand_total']),
        balanceDue: _dbl(j['balance_due']),
      );
}

class WorkOrderSummary {
  WorkOrderSummary({
    required this.id,
    required this.number,
    this.customerName = '',
    this.serviceName = '',
    this.status = '',
    this.statusLabel = '',
    this.statusColor = 'gray',
    this.assignedTo,
    this.stagesTotal = 0,
    this.stagesCompleted = 0,
    this.progressPercent = 0,
    this.createdAt,
    this.startedAt,
    this.completedAt,
    this.invoice,
  });
  final int id;
  final String number;
  final String customerName;
  final String serviceName;
  final String status;
  final String statusLabel;
  final String statusColor;
  final String? assignedTo;
  final int stagesTotal;
  final int stagesCompleted;
  final int progressPercent;
  final String? createdAt;
  final String? startedAt;
  final String? completedAt;
  final WoInvoiceRef? invoice;

  factory WorkOrderSummary.fromJson(Map<String, dynamic> j) => WorkOrderSummary(
        id: _int(j['id']),
        number: (j['number'] ?? '').toString(),
        customerName: (j['customer_name'] ?? '').toString(),
        serviceName: (j['service_name'] ?? '').toString(),
        status: (j['status'] ?? '').toString(),
        statusLabel: (j['status_label'] ?? j['status'] ?? '').toString(),
        statusColor: (j['status_color'] ?? 'gray').toString(),
        assignedTo: j['assigned_to']?.toString(),
        stagesTotal: _int(j['stages_total']),
        stagesCompleted: _int(j['stages_completed']),
        progressPercent: _int(j['progress_percent']),
        createdAt: j['created_at']?.toString(),
        startedAt: j['started_at']?.toString(),
        completedAt: j['completed_at']?.toString(),
        invoice: j['invoice'] == null
            ? null
            : WoInvoiceRef.fromJson(_map(j['invoice'])),
      );
}

class StageProduct {
  StageProduct({
    required this.name,
    this.unit = '',
    this.quantity = 0,
    this.rate = 0,
    this.gstRate = 0,
    this.total = 0,
  });
  final String name;
  final String unit;
  final double quantity;
  final double rate;
  final double gstRate;
  final double total;

  factory StageProduct.fromJson(Map<String, dynamic> j) => StageProduct(
        name: (j['name'] ?? '').toString(),
        unit: (j['unit'] ?? '').toString(),
        quantity: _dbl(j['quantity']),
        rate: _dbl(j['rate']),
        gstRate: _dbl(j['gst_rate']),
        total: _dbl(j['total']),
      );
}

class StageAttachment {
  StageAttachment({required this.id, this.type = '', this.name = '', this.url});
  final int id;
  final String type;
  final String name;
  final String? url;

  factory StageAttachment.fromJson(Map<String, dynamic> j) => StageAttachment(
        id: _int(j['id']),
        type: (j['type'] ?? '').toString(),
        name: (j['original_name'] ?? '').toString(),
        url: ApiConfig.resolveMedia(j['url']?.toString()),
      );
}

class WorkOrderStage {
  WorkOrderStage({
    required this.id,
    required this.name,
    this.description,
    this.sortOrder = 0,
    this.status = '',
    this.statusLabel = '',
    this.statusColor = 'gray',
    this.completedAt,
    this.notes,
    this.requiresPhoto = false,
    this.minPhotos = 0,
    this.requiresPdf = false,
    this.products = const [],
    this.attachments = const [],
  });
  final int id;
  final String name;
  final String? description;
  final int sortOrder;
  final String status;
  final String statusLabel;
  final String statusColor;
  final String? completedAt;
  final String? notes;
  final bool requiresPhoto;
  final int minPhotos;
  final bool requiresPdf;
  final List<StageProduct> products;
  final List<StageAttachment> attachments;

  factory WorkOrderStage.fromJson(Map<String, dynamic> j) => WorkOrderStage(
        id: _int(j['id']),
        name: (j['name'] ?? '').toString(),
        description: j['description']?.toString(),
        sortOrder: _int(j['sort_order']),
        status: (j['status'] ?? '').toString(),
        statusLabel: (j['status_label'] ?? j['status'] ?? '').toString(),
        statusColor: (j['status_color'] ?? 'gray').toString(),
        completedAt: j['completed_at']?.toString(),
        notes: j['notes']?.toString(),
        requiresPhoto: j['requires_photo'] == true || j['requires_photo'] == 1,
        minPhotos: _int(j['min_photos']),
        requiresPdf: j['requires_pdf'] == true || j['requires_pdf'] == 1,
        products: ((j['products'] as List?) ?? [])
            .map((e) => StageProduct.fromJson(_map(e)))
            .toList(),
        attachments: ((j['attachments'] as List?) ?? [])
            .map((e) => StageAttachment.fromJson(_map(e)))
            .toList(),
      );
}

class WorkOrderDetail extends WorkOrderSummary {
  WorkOrderDetail({
    required super.id,
    required super.number,
    super.customerName = '',
    super.serviceName = '',
    super.status = '',
    super.statusLabel = '',
    super.statusColor = 'gray',
    super.assignedTo,
    super.stagesTotal = 0,
    super.stagesCompleted = 0,
    super.progressPercent = 0,
    super.createdAt,
    super.startedAt,
    super.completedAt,
    super.invoice,
    this.notes,
    this.stages = const [],
  });
  final String? notes;
  final List<WorkOrderStage> stages;

  factory WorkOrderDetail.fromJson(Map<String, dynamic> j) {
    final s = WorkOrderSummary.fromJson(j);
    return WorkOrderDetail(
      id: s.id,
      number: s.number,
      customerName: s.customerName,
      serviceName: s.serviceName,
      status: s.status,
      statusLabel: s.statusLabel,
      statusColor: s.statusColor,
      assignedTo: s.assignedTo,
      stagesTotal: s.stagesTotal,
      stagesCompleted: s.stagesCompleted,
      progressPercent: s.progressPercent,
      createdAt: s.createdAt,
      startedAt: s.startedAt,
      completedAt: s.completedAt,
      invoice: s.invoice,
      notes: j['notes']?.toString(),
      stages: ((j['stages'] as List?) ?? [])
          .map((e) => WorkOrderStage.fromJson(_map(e)))
          .toList(),
    );
  }
}

// --------------------------------------------------------------- Invoice ---

class InvoiceSummary {
  InvoiceSummary({
    required this.id,
    required this.number,
    this.workOrderId,
    this.invoiceDate,
    this.dueDate,
    this.status = '',
    this.statusLabel = '',
    this.statusColor = 'gray',
    this.subtotal = 0,
    this.discountTotal = 0,
    this.gstTotal = 0,
    this.grandTotal = 0,
    this.amountPaid = 0,
    this.balanceDue = 0,
    this.isOverdue = false,
  });
  final int id;
  final String number;
  final int? workOrderId;
  final String? invoiceDate;
  final String? dueDate;
  final String status;
  final String statusLabel;
  final String statusColor;
  final double subtotal;
  final double discountTotal;
  final double gstTotal;
  final double grandTotal;
  final double amountPaid;
  final double balanceDue;
  final bool isOverdue;

  factory InvoiceSummary.fromJson(Map<String, dynamic> j) => InvoiceSummary(
        id: _int(j['id']),
        number: (j['number'] ?? '').toString(),
        workOrderId: j['work_order_id'] == null ? null : _int(j['work_order_id']),
        invoiceDate: j['invoice_date']?.toString(),
        dueDate: j['due_date']?.toString(),
        status: (j['status'] ?? '').toString(),
        statusLabel: (j['status_label'] ?? j['status'] ?? '').toString(),
        statusColor: (j['status_color'] ?? 'gray').toString(),
        subtotal: _dbl(j['subtotal']),
        discountTotal: _dbl(j['discount_total']),
        gstTotal: _dbl(j['gst_total']),
        grandTotal: _dbl(j['grand_total']),
        amountPaid: _dbl(j['amount_paid']),
        balanceDue: _dbl(j['balance_due']),
        isOverdue: j['is_overdue'] == true,
      );
}

class InvoiceItem {
  InvoiceItem({
    required this.name,
    this.unit = '',
    this.qty = 0,
    this.rate = 0,
    this.discount = 0,
    this.gstRate = 0,
    this.total = 0,
  });
  final String name;
  final String unit;
  final double qty;
  final double rate;
  final double discount;
  final double gstRate;
  final double total;

  factory InvoiceItem.fromJson(Map<String, dynamic> j) => InvoiceItem(
        name: (j['name'] ?? '').toString(),
        unit: (j['unit'] ?? '').toString(),
        qty: _dbl(j['qty']),
        rate: _dbl(j['rate']),
        discount: _dbl(j['discount']),
        gstRate: _dbl(j['gst_rate']),
        total: _dbl(j['total']),
      );
}

class InvoicePayment {
  InvoicePayment({
    required this.id,
    this.amount = 0,
    this.method = '',
    this.methodLabel = '',
    this.paidAt,
    this.reference,
    this.note,
  });
  final int id;
  final double amount;
  final String method;
  final String methodLabel;
  final String? paidAt;
  final String? reference;
  final String? note;

  factory InvoicePayment.fromJson(Map<String, dynamic> j) => InvoicePayment(
        id: _int(j['id']),
        amount: _dbl(j['amount']),
        method: (j['method'] ?? '').toString(),
        methodLabel: (j['method_label'] ?? j['method'] ?? '').toString(),
        paidAt: j['paid_at']?.toString(),
        reference: j['reference']?.toString(),
        note: j['note']?.toString(),
      );
}

class InvoiceDetail extends InvoiceSummary {
  InvoiceDetail({
    required super.id,
    required super.number,
    super.workOrderId,
    super.invoiceDate,
    super.dueDate,
    super.status = '',
    super.statusLabel = '',
    super.statusColor = 'gray',
    super.subtotal = 0,
    super.discountTotal = 0,
    super.gstTotal = 0,
    super.grandTotal = 0,
    super.amountPaid = 0,
    super.balanceDue = 0,
    super.isOverdue = false,
    this.workOrderNumber,
    this.terms,
    this.notes,
    this.items = const [],
    this.payments = const [],
  });
  final String? workOrderNumber;
  final String? terms;
  final String? notes;
  final List<InvoiceItem> items;
  final List<InvoicePayment> payments;

  factory InvoiceDetail.fromJson(Map<String, dynamic> j) {
    final s = InvoiceSummary.fromJson(j);
    return InvoiceDetail(
      id: s.id,
      number: s.number,
      workOrderId: s.workOrderId,
      invoiceDate: s.invoiceDate,
      dueDate: s.dueDate,
      status: s.status,
      statusLabel: s.statusLabel,
      statusColor: s.statusColor,
      subtotal: s.subtotal,
      discountTotal: s.discountTotal,
      gstTotal: s.gstTotal,
      grandTotal: s.grandTotal,
      amountPaid: s.amountPaid,
      balanceDue: s.balanceDue,
      isOverdue: s.isOverdue,
      workOrderNumber: j['work_order_number']?.toString(),
      terms: j['terms']?.toString(),
      notes: j['notes']?.toString(),
      items: ((j['items'] as List?) ?? [])
          .map((e) => InvoiceItem.fromJson(_map(e)))
          .toList(),
      payments: ((j['payments'] as List?) ?? [])
          .map((e) => InvoicePayment.fromJson(_map(e)))
          .toList(),
    );
  }
}

// --------------------------------------------------------------- Service ---

class ServiceModel {
  ServiceModel({
    required this.id,
    required this.name,
    this.slug = '',
    this.description,
    this.category = '',
    this.icon = '',
    this.image,
    this.sortOrder = 0,
  });
  final int id;
  final String name;
  final String slug;
  final String? description;
  final String category;
  final String icon;
  final String? image;
  final int sortOrder;

  factory ServiceModel.fromJson(Map<String, dynamic> j) => ServiceModel(
        id: _int(j['id']),
        name: (j['name'] ?? '').toString(),
        slug: (j['slug'] ?? '').toString(),
        description: j['description']?.toString(),
        category: (j['category'] ?? '').toString(),
        icon: (j['icon'] ?? '').toString(),
        image: ApiConfig.resolveMedia(j['image']?.toString()),
        sortOrder: _int(j['sort_order']),
      );
}

// --------------------------------------------------------------- Product ---

class ProductModel {
  ProductModel({
    required this.id,
    required this.name,
    this.sku = '',
    this.hsnCode,
    this.description,
    this.image,
    this.unit = '',
    this.mrp,
    this.price = 0,
    this.gstRate = 0,
    this.inStock = false,
    this.stockQty = 0,
  });
  final int id;
  final String name;
  final String sku;
  final String? hsnCode;
  final String? description;
  final String? image;
  final String unit;
  final double? mrp;
  final double price;
  final double gstRate;
  final bool inStock;
  final double stockQty;

  factory ProductModel.fromJson(Map<String, dynamic> j) {
    final rawStock = j['in_stock'];
    return ProductModel(
      id: _int(j['id']),
      name: (j['name'] ?? '').toString(),
      sku: (j['sku'] ?? '').toString(),
      hsnCode: j['hsn_code']?.toString(),
      description: j['description']?.toString(),
      image: ApiConfig.resolveMedia(j['image']?.toString()),
      unit: (j['unit'] ?? '').toString(),
      mrp: j['mrp'] == null ? null : _dbl(j['mrp']),
      price: _dbl(j['price']),
      gstRate: _dbl(j['gst_rate']),
      inStock: rawStock is bool
          ? rawStock
          : (rawStock is num ? rawStock > 0 : _dbl(rawStock) > 0),
      stockQty: _dbl(j['stock_qty']),
    );
  }
}

// --------------------------------------------------------------- Ledger ---

class LedgerTransaction {
  LedgerTransaction({
    required this.date,
    this.createdAt,
    required this.type,
    required this.reference,
    required this.description,
    this.debit = 0,
    this.credit = 0,
    this.runningBalance = 0,
  });

  final String date;
  final String? createdAt;
  final String type; // 'invoice' | 'payment'
  final String reference;
  final String description;
  final double debit;
  final double credit;
  final double runningBalance;

  bool get isInvoice => type == 'invoice';
  bool get isPayment => type == 'payment';

  factory LedgerTransaction.fromJson(Map<String, dynamic> j) =>
      LedgerTransaction(
        date: (j['date'] ?? '').toString(),
        createdAt: j['created_at']?.toString(),
        type: (j['type'] ?? '').toString(),
        reference: (j['reference'] ?? '').toString(),
        description: (j['description'] ?? '').toString(),
        debit: _dbl(j['debit']),
        credit: _dbl(j['credit']),
        runningBalance: _dbl(j['running_balance']),
      );
}

class CustomerLedgerStatement {
  CustomerLedgerStatement({
    this.from = '',
    this.to = '',
    this.openingBalance = 0,
    this.closingBalance = 0,
    this.totalDebit = 0,
    this.totalCredit = 0,
    this.transactions = const [],
  });

  final String from;
  final String to;
  final double openingBalance;
  final double closingBalance;
  final double totalDebit;
  final double totalCredit;
  final List<LedgerTransaction> transactions;

  factory CustomerLedgerStatement.fromJson(Map<String, dynamic> j) {
    final rawList = j['transactions'];
    final List<LedgerTransaction> txs = [];
    if (rawList is List) {
      for (final item in rawList) {
        if (item is Map<String, dynamic>) {
          txs.add(LedgerTransaction.fromJson(item));
        } else if (item is Map) {
          txs.add(LedgerTransaction.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    return CustomerLedgerStatement(
      from: (j['from'] ?? '').toString(),
      to: (j['to'] ?? '').toString(),
      openingBalance: _dbl(j['opening_balance']),
      closingBalance: _dbl(j['closing_balance']),
      totalDebit: _dbl(j['total_debit']),
      totalCredit: _dbl(j['total_credit']),
      transactions: txs,
    );
  }
}

// ---------------------------------------------------------- Notification ---

class AppNotification {
  AppNotification({
    required this.id,
    this.title = '',
    this.body = '',
    this.type = '',
    this.readAt,
    this.createdAt,
  });
  final String id;
  final String title;
  final String body;
  final String type;
  final String? readAt;
  final String? createdAt;

  bool get isRead => readAt != null;

  factory AppNotification.fromJson(Map<String, dynamic> j) {
    final data = _map(j['data']);
    return AppNotification(
      id: j['id'].toString(),
      title: (data['title'] ?? data['subject'] ?? 'Notification').toString(),
      body: (data['body'] ?? data['message'] ?? '').toString(),
      type: (data['type'] ?? '').toString(),
      readAt: j['read_at']?.toString(),
      createdAt: j['created_at']?.toString(),
    );
  }
}

// -------------------------------------------------------------- Pagination ---

class Paged<T> {
  Paged({required this.items, this.currentPage = 1, this.lastPage = 1, this.total = 0});
  final List<T> items;
  final int currentPage;
  final int lastPage;
  final int total;

  bool get hasMore => currentPage < lastPage;
}
