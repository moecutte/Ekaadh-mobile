import 'package:ekaadh_mobile/core/media_url.dart';

class PrivateEventTicketType {
  final int id;
  final String name;
  final double price;
  final int remaining;
  final int quantityAvailable;
  final int quantitySold;
  final int maxPerOrder;

  const PrivateEventTicketType({
    required this.id,
    required this.name,
    required this.price,
    required this.remaining,
    required this.quantityAvailable,
    required this.quantitySold,
    required this.maxPerOrder,
  });

  factory PrivateEventTicketType.fromJson(Map<String, dynamic> json) {
    return PrivateEventTicketType(
      id: json['id'] as int,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      remaining: json['remaining'] as int? ?? 0,
      quantityAvailable: json['quantity_available'] as int? ?? 0,
      quantitySold: json['quantity_sold'] as int? ?? 0,
      maxPerOrder: json['max_per_order'] as int? ?? 10,
    );
  }
}

class PrivateEventModel {
  final int id;
  final String title;
  final String slug;
  final String? description;
  final String? venue;
  final String? address;
  final String? city;
  final String? eventDate;
  final String? eventDateLabel;
  final String? eventTime;
  final String? eventTimeLabel;
  final String? coverImage;
  final String status;
  final int capacity;
  final int invited;
  final int remaining;
  final String? ticketDesign;
  final TicketDesignOption? design;
  final Map<String, String> invitationFieldValues;
  final List<PrivateEventTicketType> ticketTypes;
  final Map<String, dynamic>? pendingOrder;
  final bool paymentSandbox;
  final List<PrivateEventTestWallet> testWallets;

  const PrivateEventModel({
    required this.id,
    required this.title,
    required this.slug,
    required this.description,
    required this.venue,
    required this.address,
    required this.city,
    required this.eventDate,
    required this.eventDateLabel,
    required this.eventTime,
    required this.eventTimeLabel,
    required this.coverImage,
    required this.status,
    required this.capacity,
    required this.invited,
    required this.remaining,
    required this.ticketDesign,
    required this.design,
    this.invitationFieldValues = const {},
    required this.ticketTypes,
    required this.pendingOrder,
    this.paymentSandbox = false,
    this.testWallets = const [],
  });

  bool get isPaid => status == 'published';
  bool get awaitsPayment => status == 'draft' || pendingOrder != null;

  /// True when the event date is before today (local). No date = still valid.
  bool get isExpired {
    final raw = eventDate?.trim();
    if (raw == null || raw.isEmpty) return false;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return false;
    final day = DateTime(parsed.year, parsed.month, parsed.day);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return day.isBefore(today);
  }

  bool get isUpcoming => !isExpired;

  factory PrivateEventModel.fromJson(Map<String, dynamic> json) {
    final types = (json['ticket_types'] as List<dynamic>? ?? [])
        .map((e) => PrivateEventTicketType.fromJson(e as Map<String, dynamic>))
        .toList();
    final designJson = json['design'] as Map<String, dynamic>?;

    return PrivateEventModel(
      id: json['id'] as int,
      title: json['title'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      venue: json['venue'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      eventDate: json['event_date'] as String?,
      eventDateLabel: json['event_date_label'] as String?,
      eventTime: json['event_time'] as String?,
      eventTimeLabel: json['event_time_label'] as String?,
      coverImage: MediaUrl.resolve(json['cover_image'] as String?),
      status: json['status'] as String? ?? 'draft',
      capacity: json['capacity'] as int? ?? 0,
      invited: json['invited'] as int? ?? 0,
      remaining: json['remaining'] as int? ?? 0,
      ticketDesign: json['ticket_design'] as String?,
      design: designJson == null ? null : TicketDesignOption.fromJson(designJson),
      invitationFieldValues: _stringMap(json['invitation_field_values']),
      ticketTypes: types,
      pendingOrder: _pendingOrderMap(json['pending_order']),
      paymentSandbox: json['payment_sandbox'] as bool? ?? false,
      testWallets: _parseTestWallets(json),
    );
  }

  static List<PrivateEventTestWallet> _parseTestWallets(Map<String, dynamic> json) {
    final parsed = (json['test_wallets'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(PrivateEventTestWallet.fromJson)
        .where((w) => w.local.isNotEmpty)
        .toList();
    if (parsed.isNotEmpty) return parsed;
    if (json['payment_sandbox'] == true) {
      return const [
        PrivateEventTestWallet(brand: 'EVCPlus', local: '611111111'),
        PrivateEventTestWallet(brand: 'ZAAD', local: '631111111'),
        PrivateEventTestWallet(brand: 'SAHAL', local: '901111111'),
      ];
    }
    return const [];
  }

  static Map<String, dynamic>? _pendingOrderMap(dynamic raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final nested = map['data'];
    if (map['id'] == null && nested is Map) {
      return Map<String, dynamic>.from(nested);
    }
    if (map['id'] == null && map['order_number'] == null) return null;
    return map;
  }

  static Map<String, String> _stringMap(dynamic raw) {
    if (raw is! Map) return const {};
    return raw.map((key, value) => MapEntry(key.toString(), value?.toString() ?? ''));
  }
}

class PrivateEventTestWallet {
  final String brand;
  final String local;

  const PrivateEventTestWallet({required this.brand, required this.local});

  factory PrivateEventTestWallet.fromJson(Map<String, dynamic> json) {
    return PrivateEventTestWallet(
      brand: json['brand'] as String? ?? '',
      local: json['local'] as String? ?? '',
    );
  }
}

class PrivateEventMeta {
  final double unitPrice;
  final double premiumDesignSurcharge;
  final double serviceFee;
  final int maxTickets;
  final List<String> cities;
  final List<PrivateEventCategoryOption> categories;
  final List<TicketDesignOption> standardDesigns;
  final List<TicketDesignOption> premiumDesigns;
  final String defaultDesign;

  const PrivateEventMeta({
    required this.unitPrice,
    required this.premiumDesignSurcharge,
    required this.serviceFee,
    required this.maxTickets,
    required this.cities,
    required this.categories,
    required this.standardDesigns,
    required this.premiumDesigns,
    required this.defaultDesign,
  });

  List<TicketDesignOption> get allDesigns => [...standardDesigns, ...premiumDesigns];

  List<TicketDesignOption> designsForCategory(int? categoryId) {
    if (categoryId == null) return const [];
    return allDesigns.where((d) => d.privateEventCategoryId == categoryId).toList();
  }

  List<TicketDesignOption> standardForCategory(int? categoryId) =>
      designsForCategory(categoryId).where((d) => !d.isPremium).toList();

  List<TicketDesignOption> premiumForCategory(int? categoryId) =>
      designsForCategory(categoryId).where((d) => d.isPremium).toList();

  factory PrivateEventMeta.fromJson(Map<String, dynamic> json) {
    final designs = json['designs'] as Map<String, dynamic>? ?? {};
    final all = (designs['all'] as List<dynamic>? ?? []);
    final standard = (designs['standard'] as List<dynamic>? ?? []);
    final premium = (designs['premium'] as List<dynamic>? ?? []);
    final parsedAll = (all.isNotEmpty ? all : [...standard, ...premium])
        .map((e) => TicketDesignOption.fromJson(e as Map<String, dynamic>))
        .toList();
    return PrivateEventMeta(
      unitPrice: (json['unit_price'] as num).toDouble(),
      premiumDesignSurcharge:
          (json['premium_design_surcharge'] as num?)?.toDouble() ?? 0,
      serviceFee: (json['service_fee'] as num).toDouble(),
      maxTickets: json['max_tickets'] as int? ?? 500,
      cities: (json['cities'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      categories: (json['categories'] as List<dynamic>? ?? [])
          .map((e) => PrivateEventCategoryOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      standardDesigns: parsedAll.where((d) => !d.isPremium).toList(),
      premiumDesigns: parsedAll.where((d) => d.isPremium).toList(),
      defaultDesign: designs['default']?.toString() ?? '',
    );
  }
}

class PrivateEventCategoryOption {
  final int id;
  final String name;
  final String slug;
  final bool requiresCoupleNames;

  const PrivateEventCategoryOption({
    required this.id,
    required this.name,
    required this.slug,
    required this.requiresCoupleNames,
  });

  factory PrivateEventCategoryOption.fromJson(Map<String, dynamic> json) {
    return PrivateEventCategoryOption(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String? ?? '',
      requiresCoupleNames: json['requires_couple_names'] as bool? ?? false,
    );
  }
}

class TicketDesignOption {
  final String id;
  final String name;
  final String category;
  final String label;
  final String description;
  final String accent;
  final String headerFrom;
  final String headerTo;
  final String cardBg;
  final String text;
  final String muted;
  final String border;
  final String ornament;
  final String badge;
  final String inviteLine;
  final String requestLine;
  final int? invitationDesignId;
  final int? privateEventCategoryId;
  final String? graphicUrl;
  final String? thumbnailUrl;
  final double? unitPrice;
  final String renderMode;
  final List<InvitationDesignFieldOption> fields;

  const TicketDesignOption({
    required this.id,
    required this.name,
    required this.category,
    required this.label,
    required this.description,
    required this.accent,
    required this.headerFrom,
    required this.headerTo,
    required this.cardBg,
    required this.text,
    required this.muted,
    required this.border,
    required this.ornament,
    required this.badge,
    required this.inviteLine,
    required this.requestLine,
    this.invitationDesignId,
    this.privateEventCategoryId,
    this.graphicUrl,
    this.thumbnailUrl,
    this.unitPrice,
    this.renderMode = 'blade',
    this.fields = const [],
  });

  bool get isPremium => category == 'premium';

  bool get isOverlay =>
      renderMode == 'overlay' &&
      (graphicUrl?.trim().isNotEmpty ?? false);

  List<InvitationDesignFieldOption> get buyerFields =>
      fields.where((f) => !f.isQr && !f.isAutoDateField).toList();

  List<InvitationDesignFieldOption> get autoDateFields =>
      fields.where((f) => f.isAutoDateField).toList();

  List<InvitationDesignFieldOption> get valueFields =>
      fields.where((f) => !f.isQr).toList();

  List<InvitationDesignFieldOption> get previewFields =>
      fields.where((f) => f.showOnCard).toList();

  String? get previewImageUrl {
    final thumb = MediaUrl.resolve(thumbnailUrl);
    if (thumb != null && thumb.isNotEmpty) return thumb;
    return MediaUrl.resolve(graphicUrl);
  }

  String? get resolvedGraphicUrl => MediaUrl.resolve(graphicUrl);

  factory TicketDesignOption.fromJson(Map<String, dynamic> json) {
    return TicketDesignOption(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? 'standard',
      label: json['label'] as String? ?? '',
      description: json['description'] as String? ?? '',
      accent: json['accent'] as String? ?? '#323891',
      headerFrom: json['header_from'] as String? ?? '#0f1a2e',
      headerTo: json['header_to'] as String? ?? '#323891',
      cardBg: json['card_bg'] as String? ?? '#ffffff',
      text: json['text'] as String? ?? '#0f1a2e',
      muted: json['muted'] as String? ?? '#64748b',
      border: json['border'] as String? ?? '#e2e8f0',
      ornament: json['ornament'] as String? ?? '',
      badge: json['badge'] as String? ?? '',
      inviteLine: json['invite_line'] as String? ?? '',
      requestLine: json['request_line'] as String? ?? '',
      invitationDesignId: json['invitation_design_id'] as int?,
      privateEventCategoryId: json['private_event_category_id'] as int?,
      graphicUrl: json['graphic_url'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String? ?? json['graphic_url'] as String?,
      unitPrice: (json['unit_price'] as num?)?.toDouble(),
      renderMode: json['render_mode'] as String? ?? 'blade',
      fields: (json['fields'] as List<dynamic>? ?? [])
          .map((e) => InvitationDesignFieldOption.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class InvitationDesignFieldOption {
  final String fieldKey;
  final String label;
  final String fieldType;
  final bool isRequired;
  final String? placeholder;
  final String? defaultText;
  final bool mapsToCouple;
  final bool showOnCard;
  final double posX;
  final double posY;
  final double boxWidth;
  final int fontSize;
  final String? fontFamily;
  final String fontWeight;
  final String fontStyle;
  final String? color;
  final String textAlign;

  const InvitationDesignFieldOption({
    required this.fieldKey,
    required this.label,
    required this.fieldType,
    required this.isRequired,
    required this.placeholder,
    required this.defaultText,
    required this.mapsToCouple,
    required this.showOnCard,
    required this.posX,
    required this.posY,
    required this.boxWidth,
    required this.fontSize,
    required this.fontFamily,
    required this.fontWeight,
    required this.fontStyle,
    required this.color,
    required this.textAlign,
  });

  bool get isQr => fieldType == 'qr';

  bool get isAutoDateField =>
      fieldType == 'date_month' ||
      fieldType == 'date_day' ||
      fieldType == 'date_year' ||
      fieldType == 'date_time';

  factory InvitationDesignFieldOption.fromJson(Map<String, dynamic> json) {
    return InvitationDesignFieldOption(
      fieldKey: json['field_key'] as String,
      label: json['label'] as String,
      fieldType: json['field_type'] as String? ?? 'text',
      isRequired: json['is_required'] as bool? ?? false,
      placeholder: json['placeholder'] as String?,
      defaultText: json['default_text'] as String?,
      mapsToCouple: json['maps_to_couple'] as bool? ?? false,
      showOnCard: json['show_on_card'] as bool? ?? true,
      posX: (json['pos_x'] as num?)?.toDouble() ?? 20,
      posY: (json['pos_y'] as num?)?.toDouble() ?? 30,
      boxWidth: (json['box_width'] as num?)?.toDouble() ?? 60,
      fontSize: json['font_size'] as int? ?? 18,
      fontFamily: json['font_family'] as String?,
      fontWeight: json['font_weight'] as String? ?? '400',
      fontStyle: json['font_style'] as String? ?? 'normal',
      color: json['color'] as String?,
      textAlign: json['text_align'] as String? ?? 'center',
    );
  }
}

class InvitationModel {
  final int id;
  final String? guestName;
  final String guestPhone;
  final int quantity;
  final String status;
  final String smsStatus;
  final String whatsappStatus;
  final String? deliveryChannel;
  final String? invitationUrl;
  final String? ticketTypeName;
  final int? ticketTypeId;
  final String? openedAt;

  const InvitationModel({
    required this.id,
    required this.guestName,
    required this.guestPhone,
    required this.quantity,
    required this.status,
    required this.smsStatus,
    required this.whatsappStatus,
    this.deliveryChannel,
    required this.invitationUrl,
    required this.ticketTypeName,
    required this.ticketTypeId,
    required this.openedAt,
  });

  bool get isActive => status == 'active';

  String deliveryLabel(String Function(String) t) {
    if (deliveryChannel == 'whatsapp') {
      return '${t('invite_channel_whatsapp')} · $whatsappStatus';
    }
    if (deliveryChannel == 'sms') {
      return '${t('invite_channel_sms')} · $smsStatus';
    }
    return '${t('invite_channel_sms')} $smsStatus · ${t('invite_channel_whatsapp')} $whatsappStatus';
  }

  factory InvitationModel.fromJson(Map<String, dynamic> json) {
    final type = json['ticket_type'] as Map<String, dynamic>?;
    return InvitationModel(
      id: json['id'] as int,
      guestName: json['guest_name'] as String?,
      guestPhone: json['guest_phone'] as String,
      quantity: json['quantity'] as int? ?? 1,
      status: json['status'] as String? ?? 'active',
      smsStatus: json['sms_status'] as String? ?? 'pending',
      whatsappStatus: json['whatsapp_status'] as String? ?? 'pending',
      deliveryChannel: json['delivery_channel'] as String?,
      invitationUrl: json['invitation_url'] as String?,
      ticketTypeName: type?['name'] as String?,
      ticketTypeId: type?['id'] as int?,
      openedAt: json['opened_at'] as String?,
    );
  }
}
