import 'package:flutter/material.dart';
import 'package:ekaadh_mobile/models/event_model.dart';
import 'package:ekaadh_mobile/screens/checkout_screen.dart';
import 'package:ekaadh_mobile/services/auth_service.dart';

/// Entry point for buying tickets — opens the stepped checkout wizard
/// (Select Tickets → Your Details → Payment), matching the website flow.
class TicketSelectionScreen extends StatelessWidget {
  const TicketSelectionScreen({super.key, required this.event, this.auth});

  final EventModel event;
  final AuthService? auth;

  @override
  Widget build(BuildContext context) {
    return CheckoutScreen(event: event, auth: auth);
  }
}
