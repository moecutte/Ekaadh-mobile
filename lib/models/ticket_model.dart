import 'package:ekaadh_mobile/core/media_url.dart';
import 'package:ekaadh_mobile/models/private_event_model.dart';

class TicketModel {
  final int id;
  final String ticketCode;
  final String? holderName;
  final String ticketTypeName;
  final String status;
  final String qrPayload;
  final String? publicUrl;
  final bool isUpcoming;
  final String? eventTitle;
  final String? eventCover;
  final String? eventDateLabel;
  final String? eventTimeLabel;
  final String? venue;
  final String? orderNumber;
  final bool isPrivate;
  final TicketInvitationDesign? invitationDesign;

  const TicketModel({
    required this.id,
    required this.ticketCode,
    required this.holderName,
    required this.ticketTypeName,
    required this.status,
    required this.qrPayload,
    required this.publicUrl,
    required this.isUpcoming,
    required this.eventTitle,
    required this.eventCover,
    required this.eventDateLabel,
    required this.eventTimeLabel,
    required this.venue,
    required this.orderNumber,
    this.isPrivate = false,
    this.invitationDesign,
  });

  bool get isOverlayInvite =>
      isPrivate && (invitationDesign?.isOverlay ?? false);

  /// Cover / invitation artwork for list thumbnails.
  String? get displayImage =>
      invitationDesign?.resolvedThumbnailUrl ??
      invitationDesign?.resolvedGraphicUrl ??
      eventCover;

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    final event = json['event'] as Map<String, dynamic>?;
    final designJson = json['invitation_design'] as Map<String, dynamic>?;
    return TicketModel(
      id: json['id'] as int,
      ticketCode: json['ticket_code'] as String,
      holderName: json['holder_name'] as String?,
      ticketTypeName: json['ticket_type_name'] as String,
      status: json['status'] as String,
      qrPayload: json['qr_payload'] as String? ?? json['ticket_code'] as String,
      publicUrl: json['public_url'] as String?,
      isUpcoming: json['is_upcoming'] as bool? ?? true,
      eventTitle: event?['title'] as String?,
      eventCover: MediaUrl.resolve(event?['cover_image'] as String?),
      eventDateLabel: event?['event_date_label'] as String?,
      eventTimeLabel: event?['event_time_label'] as String?,
      venue: event?['venue'] as String?,
      orderNumber: json['order_number'] as String?,
      isPrivate: event?['is_private'] as bool? ?? false,
      invitationDesign: designJson == null
          ? null
          : TicketInvitationDesign.fromJson(designJson),
    );
  }
}

class TicketInvitationDesign {
  final String renderMode;
  final String? graphicUrl;
  final String? thumbnailUrl;
  final String cardBg;
  final String text;
  final String muted;
  final String accent;
  final List<InvitationDesignFieldOption> fields;
  final Map<String, String> fieldValues;

  const TicketInvitationDesign({
    required this.renderMode,
    required this.graphicUrl,
    required this.thumbnailUrl,
    required this.cardBg,
    required this.text,
    required this.muted,
    required this.accent,
    required this.fields,
    required this.fieldValues,
  });

  bool get isOverlay =>
      renderMode == 'overlay' &&
      (graphicUrl?.trim().isNotEmpty ?? false);

  String? get resolvedGraphicUrl => MediaUrl.resolve(graphicUrl);
  String? get resolvedThumbnailUrl => MediaUrl.resolve(thumbnailUrl);

  List<InvitationDesignFieldOption> get cardFields =>
      fields.where((f) => f.showOnCard).toList();

  TicketDesignOption toDesignOption() {
    return TicketDesignOption(
      id: 'ticket-overlay',
      name: 'Invitation',
      category: 'standard',
      label: '',
      description: '',
      accent: accent,
      headerFrom: '#0f1a2e',
      headerTo: '#323891',
      cardBg: cardBg,
      text: text,
      muted: muted,
      border: '#e2e8f0',
      ornament: '',
      badge: '',
      inviteLine: '',
      requestLine: '',
      graphicUrl: graphicUrl,
      thumbnailUrl: thumbnailUrl ?? graphicUrl,
      renderMode: renderMode,
      fields: fields,
    );
  }

  factory TicketInvitationDesign.fromJson(Map<String, dynamic> json) {
    final rawValues = json['field_values'] as Map<String, dynamic>? ?? {};
    return TicketInvitationDesign(
      renderMode: json['render_mode'] as String? ?? 'overlay',
      graphicUrl: json['graphic_url'] as String?,
      thumbnailUrl:
          json['thumbnail_url'] as String? ?? json['graphic_url'] as String?,
      cardBg: json['card_bg'] as String? ?? '#ffffff',
      text: json['text'] as String? ?? '#0f1a2e',
      muted: json['muted'] as String? ?? '#64748b',
      accent: json['accent'] as String? ?? '#323891',
      fields: (json['fields'] as List<dynamic>? ?? [])
          .map((e) => InvitationDesignFieldOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      fieldValues: rawValues.map((k, v) => MapEntry(k, '$v')),
    );
  }
}
