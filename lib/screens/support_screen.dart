import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ekaadh_mobile/core/locale_scope.dart';
import 'package:ekaadh_mobile/core/locale_service.dart';
import 'package:ekaadh_mobile/core/theme.dart';
import 'package:ekaadh_mobile/services/auth_service.dart';
import 'package:ekaadh_mobile/services/support_service.dart';
import 'package:ekaadh_mobile/widgets/ekaadh_toast.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key, required this.auth});

  final AuthService auth;

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen>
    with SingleTickerProviderStateMixin {
  late final SupportService _support = SupportService(auth: widget.auth);
  late final TabController _tabs = TabController(length: 2, vsync: this);

  List<SupportFaq> _faqs = [];
  bool _loadingFaqs = true;
  String? _faqError;
  int? _expandedFaqId;

  SupportConversation? _conversation;
  final List<SupportMessage> _messages = [];
  final TextEditingController _draft = TextEditingController();
  final ScrollController _scroll = ScrollController();
  Timer? _pollTimer;
  bool _sending = false;

  bool _faqsLoaded = false;

  @override
  void initState() {
    super.initState();
    _tabs.addListener(() {
      if (_tabs.index == 1) _openChat();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_faqsLoaded) {
      _faqsLoaded = true;
      _loadFaqs();
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _tabs.dispose();
    _draft.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadFaqs() async {
    setState(() {
      _loadingFaqs = true;
      _faqError = null;
    });
    try {
      final l10n = LocaleScope.of(context);
      final faqs = await _support.fetchFaqs(l10n.code);
      if (!mounted) return;
      setState(() {
        _faqs = faqs;
        _loadingFaqs = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingFaqs = false;
        _faqError = LocaleScope.of(context).t('support_load_error');
      });
    }
  }

  Future<void> _openChat() async {
    try {
      _conversation ??= await _support.ensureConversation();
      await _refreshMessages();
      _pollTimer ??= Timer.periodic(const Duration(seconds: 4), (_) {
        _refreshMessages();
      });
    } catch (_) {
      if (!mounted) return;
      await EkaadhToast.error(context, message: LocaleScope.of(context).t('support_load_error'));
    }
  }

  Future<void> _refreshMessages() async {
    final conv = _conversation;
    if (conv == null) return;
    try {
      final since = _messages.isEmpty ? 0 : _messages.last.id;
      final incoming = await _support.fetchMessages(
        conversationId: conv.id,
        since: since,
      );
      if (!mounted || incoming.isEmpty) return;
      setState(() {
        final ids = _messages.map((m) => m.id).toSet();
        for (final m in incoming) {
          if (!ids.contains(m.id)) _messages.add(m);
        }
      });
      _scrollToBottom();
    } catch (_) {}
  }

  Future<void> _send() async {
    final conv = _conversation;
    final text = _draft.text.trim();
    if (conv == null || text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _draft.clear();
    try {
      final msg = await _support.sendMessage(
        conversationId: conv.id,
        body: text,
      );
      if (!mounted) return;
      setState(() => _messages.add(msg));
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      await EkaadhToast.error(context, message: LocaleScope.of(context).t('support_send_error'));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = LocaleScope.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: EkaadhColors.dark,
        foregroundColor: Colors.white,
        title: Text(l10n.t('support')),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: l10n.t('support_faq_tab')),
            Tab(text: l10n.t('support_chat_tab')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildFaqTab(l10n),
          _buildChatTab(l10n),
        ],
      ),
    );
  }

  Widget _buildFaqTab(LocaleService l10n) {
    if (_loadingFaqs) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_faqError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_faqError!, style: const TextStyle(color: EkaadhColors.muted)),
            const SizedBox(height: 12),
            TextButton(onPressed: _loadFaqs, child: Text(l10n.t('retry'))),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        ..._faqs.map((faq) {
          final expanded = _expandedFaqId == faq.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => setState(() {
                  _expandedFaqId = expanded ? null : faq.id;
                }),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE8E8EE)),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        faq.question,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      if (expanded) ...[
                        const SizedBox(height: 10),
                        Text(
                          faq.answer,
                          style: const TextStyle(
                            color: EkaadhColors.muted,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => _tabs.animateTo(1),
            style: FilledButton.styleFrom(
              backgroundColor: EkaadhColors.brand,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(l10n.t('support_talk_to_human')),
          ),
        ),
      ],
    );
  }

  Widget _buildChatTab(LocaleService l10n) {
    final closed = _conversation?.status == 'closed';

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              final isCustomer = msg.senderType == 'customer';
              return Align(
                alignment: isCustomer
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width * 0.82,
                  ),
                  decoration: BoxDecoration(
                    color: isCustomer
                        ? EkaadhColors.brand
                        : (msg.senderType == 'system'
                              ? const Color(0xFFF3F4F6)
                              : const Color(0xFFF8FAFC)),
                    borderRadius: BorderRadius.circular(16),
                    border: isCustomer
                        ? null
                        : Border.all(color: const Color(0xFFE8E8EE)),
                  ),
                  child: Text(
                    msg.body,
                    style: TextStyle(
                      color: isCustomer ? Colors.white : EkaadhColors.dark,
                      height: 1.4,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (closed)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              l10n.t('support_closed'),
              style: const TextStyle(color: EkaadhColors.muted),
            ),
          )
        else
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _draft,
                      maxLength: 2000,
                      decoration: InputDecoration(
                        hintText: l10n.t('support_message_hint'),
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      minLines: 1,
                      maxLines: 4,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
