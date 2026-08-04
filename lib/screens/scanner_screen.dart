import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:ekaadh_mobile/core/theme.dart';
import 'package:ekaadh_mobile/services/auth_service.dart';
import 'package:ekaadh_mobile/services/check_in_service.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({
    super.key,
    required this.auth,
    required this.event,
  });

  final AuthService auth;
  final StaffEventSummary event;

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  late final CheckInService _service = CheckInService(widget.auth);
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  bool _busy = false;
  CheckInResult? _result;
  final _manualController = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    _manualController.dispose();
    super.dispose();
  }

  Future<void> _handlePayload(String raw) async {
    if (_busy || _result != null) return;
    final payload = raw.trim();
    if (payload.isEmpty) return;

    setState(() => _busy = true);
    try {
      final result = await _service.scan(
        payload: payload,
        eventId: widget.event.id,
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _busy = false;
      });
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _result = null);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _result = const CheckInResult(
          result: 'invalid',
          message: 'Could not reach check-in server.',
          ticket: null,
        );
      });
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _result = null);
      });
    }
  }

  void _onDetect(BarcodeCapture capture) {
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final value = barcodes.first.rawValue;
    if (value != null) {
      _handlePayload(value);
    }
  }

  Color get _resultColor {
    switch (_result?.result) {
      case 'valid':
        return EkaadhColors.brand;
      case 'used':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFFEF4444);
    }
  }

  String get _resultTitle {
    switch (_result?.result) {
      case 'valid':
        return 'Admit';
      case 'used':
        return 'Already Checked In';
      default:
        return 'Invalid Ticket';
    }
  }

  IconData get _resultIcon {
    switch (_result?.result) {
      case 'valid':
        return Icons.check_circle;
      case 'used':
        return Icons.warning_amber_rounded;
      default:
        return Icons.cancel;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EkaadhColors.dark,
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.event.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              '${widget.event.ticketsCheckedIn}/${widget.event.ticketsTotal} in',
                              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _controller.toggleTorch(),
                        icon: const Icon(Icons.flash_on, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Center(
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      border: Border.all(color: EkaadhColors.brand.withValues(alpha: 0.85), width: 3),
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  decoration: BoxDecoration(
                    color: EkaadhColors.dark.withValues(alpha: 0.93),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Align QR inside the frame',
                        style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _manualController,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Or enter EKD-… code',
                                hintStyle: const TextStyle(color: Color(0xFF4B5563)),
                                filled: true,
                                fillColor: const Color(0xFF111827),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _busy
                                ? null
                                : () => _handlePayload(_manualController.text),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: EkaadhColors.brand,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text('Check'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_busy)
            const ColoredBox(
              color: Color(0x66000000),
              child: Center(child: CircularProgressIndicator(color: EkaadhColors.brand)),
            ),
          if (_result != null)
            ColoredBox(
              color: _resultColor.withValues(alpha: 0.95),
              child: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_resultIcon, color: Colors.white, size: 72),
                        const SizedBox(height: 16),
                        Text(
                          _resultTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _result!.message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        if (_result!.ticket != null) ...[
                          const SizedBox(height: 20),
                          Text(
                            _result!.ticket!.holderName ?? 'Guest',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            _result!.ticket!.ticketTypeName,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _result!.ticket!.ticketCode,
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                        const SizedBox(height: 28),
                        TextButton(
                          onPressed: () => setState(() => _result = null),
                          child: const Text(
                            'Scan next',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
