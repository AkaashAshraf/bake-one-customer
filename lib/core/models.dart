double _d(dynamic v) => v == null ? 0 : (v is num ? v.toDouble() : double.tryParse('$v') ?? 0);
int _i(dynamic v) => v == null ? 0 : (v is num ? v.toInt() : int.tryParse('$v') ?? 0);
String? _s(dynamic v) {
  if (v == null) return null;
  final s = '$v'.trim();
  return s.isEmpty ? null : s;
}

List<T> _list<T>(dynamic v, T Function(Map<String, dynamic>) f) =>
    v is List ? v.whereType<Map<String, dynamic>>().map(f).toList() : <T>[];

class Business {
  final String name;
  final String? phone, email, address, website, whatsappUrl, logoUrl;

  Business({required this.name, this.phone, this.email, this.address, this.website, this.whatsappUrl, this.logoUrl});

  factory Business.fromJson(Map<String, dynamic> j) => Business(
        name: _s(j['name']) ?? 'Bake One',
        phone: _s(j['phone']),
        email: _s(j['email']),
        address: _s(j['address']),
        website: _s(j['website']),
        whatsappUrl: _s(j['whatsapp_url']),
        logoUrl: _s(j['logo_url']),
      );
}

class Slide {
  final int id;
  final String? title, subtitle;
  final String imageUrl;

  Slide({required this.id, this.title, this.subtitle, required this.imageUrl});

  factory Slide.fromJson(Map<String, dynamic> j) =>
      Slide(id: _i(j['id']), title: _s(j['title']), subtitle: _s(j['subtitle']), imageUrl: _s(j['image_url']) ?? '');
}

class ClientLogo {
  final int id;
  final String name;
  final String? logoUrl;

  ClientLogo({required this.id, required this.name, this.logoUrl});

  factory ClientLogo.fromJson(Map<String, dynamic> j) =>
      ClientLogo(id: _i(j['id']), name: _s(j['name']) ?? '', logoUrl: _s(j['logo_url']));
}

class SiteData {
  final Business business;
  final String? aboutText, aboutImageUrl, operationsText, operationsImageUrl, clientsText;
  final List<Slide> slides;
  final List<ClientLogo> clients;

  SiteData({
    required this.business,
    this.aboutText,
    this.aboutImageUrl,
    this.operationsText,
    this.operationsImageUrl,
    this.clientsText,
    required this.slides,
    required this.clients,
  });

  factory SiteData.fromJson(Map<String, dynamic> j) => SiteData(
        business: Business.fromJson((j['business'] as Map<String, dynamic>?) ?? {}),
        aboutText: _s(j['about_text']),
        aboutImageUrl: _s(j['about_image_url']),
        operationsText: _s(j['operations_text']),
        operationsImageUrl: _s(j['operations_image_url']),
        clientsText: _s(j['clients_text']),
        slides: _list(j['slides'], Slide.fromJson),
        clients: _list(j['clients'], ClientLogo.fromJson),
      );
}

class Product {
  final int id;
  final String name;
  final String? category, unit, description, imageUrl;
  final double standardPrice;

  /// Only set when loaded for a logged-in customer.
  final double? yourPrice;
  final bool hasSpecialPrice;
  final double savings;
  final int savingsPercent;

  Product({
    required this.id,
    required this.name,
    this.category,
    this.unit,
    this.description,
    this.imageUrl,
    required this.standardPrice,
    this.yourPrice,
    this.hasSpecialPrice = false,
    this.savings = 0,
    this.savingsPercent = 0,
  });

  double get price => yourPrice ?? standardPrice;
  bool get isDiscount => hasSpecialPrice && savings > 0;

  factory Product.fromJson(Map<String, dynamic> j) => Product(
        id: _i(j['id']),
        name: _s(j['name']) ?? 'Product',
        category: _s(j['category']),
        unit: _s(j['unit']),
        description: _s(j['description']),
        imageUrl: _s(j['image_url']),
        standardPrice: _d(j['standard_price']),
        yourPrice: j['your_price'] == null ? null : _d(j['your_price']),
        hasSpecialPrice: j['has_special_price'] == true,
        savings: _d(j['savings']),
        savingsPercent: _i(j['savings_percent']),
      );
}

class Catalog {
  final List<String> categories;
  final List<Product> products;

  Catalog({required this.categories, required this.products});

  factory Catalog.fromJson(Map<String, dynamic> j) => Catalog(
        categories: (j['categories'] is List) ? (j['categories'] as List).map((e) => '$e').toList() : <String>[],
        products: _list(j['products'], Product.fromJson),
      );
}

class Customer {
  final int id;
  final String name;
  final String? email, contact, address;

  Customer({required this.id, required this.name, this.email, this.contact, this.address});

  String get firstName => name.trim().split(RegExp(r'\s+')).first;
  String get initial => name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

  factory Customer.fromJson(Map<String, dynamic> j) => Customer(
        id: _i(j['id']),
        name: _s(j['name']) ?? 'Customer',
        email: _s(j['email']),
        contact: _s(j['contact']),
        address: _s(j['address']),
      );
}

class Invoice {
  final int id;
  final String number;
  final String? date, type;
  final double total, balanceDue;
  final bool isPaid;

  Invoice({required this.id, required this.number, this.date, this.type, required this.total, required this.balanceDue, required this.isPaid});

  bool get isCredit => type == 'cr';
  String get typeLabel => isCredit ? 'Credit' : 'Cash';

  factory Invoice.fromJson(Map<String, dynamic> j) => Invoice(
        id: _i(j['id']),
        number: _s(j['invoice_number']) ?? '#${j['id']}',
        date: _s(j['invoice_date']),
        type: _s(j['type']),
        total: _d(j['total_price']),
        balanceDue: _d(j['balance_due']),
        isPaid: j['is_paid'] == true,
      );
}

class InvoiceItem {
  final String productName;
  final String? unit;
  final int quantity;
  final double unitPrice, standardPrice, lineTotal;

  InvoiceItem({required this.productName, this.unit, required this.quantity, required this.unitPrice, required this.standardPrice, required this.lineTotal});

  factory InvoiceItem.fromJson(Map<String, dynamic> j) => InvoiceItem(
        productName: _s(j['product_name']) ?? 'Product',
        unit: _s(j['unit']),
        quantity: _i(j['quantity']),
        unitPrice: _d(j['unit_price']),
        standardPrice: _d(j['standard_price']),
        lineTotal: _d(j['line_total']),
      );
}

class InvoicePayment {
  final double amount;
  final String? collectedAt;
  final bool isPartial;
  final String batchKey;

  InvoicePayment({required this.amount, this.collectedAt, required this.isPartial, required this.batchKey});

  factory InvoicePayment.fromJson(Map<String, dynamic> j) => InvoicePayment(
        amount: _d(j['amount']),
        collectedAt: _s(j['collected_at']),
        isPartial: j['is_partial'] == true,
        batchKey: _s(j['batch_key']) ?? '',
      );
}

class InvoiceDetail {
  final Invoice invoice;
  final String? notes;
  final List<InvoiceItem> items;
  final List<InvoicePayment> payments;
  final Business business;

  InvoiceDetail({required this.invoice, this.notes, required this.items, required this.payments, required this.business});

  double get paid => payments.fold(0.0, (s, p) => s + p.amount);

  factory InvoiceDetail.fromJson(Map<String, dynamic> j) => InvoiceDetail(
        invoice: Invoice.fromJson(j),
        notes: _s(j['notes']),
        items: _list(j['items'], InvoiceItem.fromJson),
        payments: _list(j['payments'], InvoicePayment.fromJson),
        business: Business.fromJson((j['business'] as Map<String, dynamic>?) ?? {}),
      );
}

class PaymentBatch {
  final String batchKey;
  final double total;
  final String? collectedAt, invoiceNumbers;
  final int invoiceCount;
  final bool isPartial;

  PaymentBatch({required this.batchKey, required this.total, this.collectedAt, this.invoiceNumbers, required this.invoiceCount, required this.isPartial});

  factory PaymentBatch.fromJson(Map<String, dynamic> j) => PaymentBatch(
        batchKey: _s(j['batch_key']) ?? '',
        total: _d(j['total_amount']),
        collectedAt: _s(j['collected_at']),
        invoiceNumbers: _s(j['invoice_numbers']),
        invoiceCount: _i(j['invoice_count']),
        isPartial: j['is_partial'] == true,
      );
}

class PaymentLine {
  final double amount;
  final bool isPartial;
  final Invoice? invoice;

  PaymentLine({required this.amount, required this.isPartial, this.invoice});

  factory PaymentLine.fromJson(Map<String, dynamic> j) => PaymentLine(
        amount: _d(j['amount']),
        isPartial: j['is_partial'] == true,
        invoice: j['invoice'] is Map<String, dynamic> ? Invoice.fromJson(j['invoice'] as Map<String, dynamic>) : null,
      );
}

class PaymentDetail {
  final String batchKey;
  final double total;
  final String? collectedAt, notes;
  final List<PaymentLine> lines;

  PaymentDetail({required this.batchKey, required this.total, this.collectedAt, this.notes, required this.lines});

  factory PaymentDetail.fromJson(Map<String, dynamic> j) => PaymentDetail(
        batchKey: _s(j['batch_key']) ?? '',
        total: _d(j['total_amount']),
        collectedAt: _s(j['collected_at']),
        notes: _s(j['notes']),
        lines: _list(j['lines'], PaymentLine.fromJson),
      );
}

class Dashboard {
  final Customer customer;
  final double outstanding;
  final int invoiceCount, unpaidCount, specialPriceCount;
  final List<Invoice> recentInvoices;
  final List<Invoice> unpaidInvoices;
  final List<PaymentBatch> recentPayments;

  Dashboard({
    required this.customer,
    required this.outstanding,
    required this.invoiceCount,
    required this.unpaidCount,
    required this.specialPriceCount,
    required this.recentInvoices,
    required this.unpaidInvoices,
    required this.recentPayments,
  });

  double get paidRatio => invoiceCount == 0 ? 0 : (invoiceCount - unpaidCount) / invoiceCount;

  factory Dashboard.fromJson(Map<String, dynamic> j) => Dashboard(
        customer: Customer.fromJson((j['customer'] as Map<String, dynamic>?) ?? {}),
        outstanding: _d(j['outstanding_balance']),
        invoiceCount: _i(j['invoice_count']),
        unpaidCount: _i(j['unpaid_count']),
        specialPriceCount: _i(j['special_price_count']),
        recentInvoices: _list(j['recent_invoices'], Invoice.fromJson),
        // Older servers don't send unpaid_invoices - fall back to recent ones.
        unpaidInvoices: j['unpaid_invoices'] is List
            ? _list(j['unpaid_invoices'], Invoice.fromJson)
            : _list(j['recent_invoices'], Invoice.fromJson).where((i) => !i.isPaid).toList(),
        recentPayments: _list(j['recent_payments'], PaymentBatch.fromJson),
      );
}

class Paged<T> {
  final List<T> items;
  final int currentPage, lastPage, total;

  Paged({required this.items, required this.currentPage, required this.lastPage, required this.total});

  bool get hasMore => currentPage < lastPage;

  factory Paged.fromJson(Map<String, dynamic> j, T Function(Map<String, dynamic>) f) {
    final meta = (j['meta'] as Map<String, dynamic>?) ?? {};
    return Paged(
      items: _list(j['data'], f),
      currentPage: _i(meta['current_page']),
      lastPage: _i(meta['last_page']),
      total: _i(meta['total']),
    );
  }
}
