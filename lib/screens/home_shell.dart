import 'package:flutter/material.dart';
import 'package:ekaadh_mobile/core/theme.dart';
import 'package:ekaadh_mobile/core/locale_scope.dart';
import 'package:ekaadh_mobile/services/auth_service.dart';
import 'package:ekaadh_mobile/screens/home_tab.dart';
import 'package:ekaadh_mobile/screens/search_tab.dart';
import 'package:ekaadh_mobile/screens/my_tickets_tab.dart';
import 'package:ekaadh_mobile/screens/private_tickets_tab.dart';
import 'package:ekaadh_mobile/screens/profile_tab.dart';
import 'package:ekaadh_mobile/screens/login_screen.dart';
import 'package:ekaadh_mobile/screens/register_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.auth,
    required this.onSignedIn,
    required this.onSignOut,
  });

  final AuthService auth;
  final VoidCallback onSignedIn;
  final Future<void> Function() onSignOut;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  bool _hasPrivateEvents = false;

  void _goTo(int i) => setState(() => _index = i);

  Future<void> _openLogin() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LoginScreen(
          auth: widget.auth,
          onSignedIn: () {
            widget.onSignedIn();
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
          allowDismiss: true,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openRegister() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RegisterScreen(
          auth: widget.auth,
          onSignedIn: () {
            widget.onSignedIn();
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openSearch() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: EkaadhColors.surface,
          appBar: AppBar(
            backgroundColor: Colors.white,
            foregroundColor: EkaadhColors.dark,
            elevation: 0,
          ),
          body: SearchTab(auth: widget.auth),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = LocaleScope.of(context);
    final user = widget.auth.user;
    final signedIn = widget.auth.token != null && user != null;
    final pages = [
      HomeTab(
        userName: user?.name ?? l10n.t('guest'),
        auth: widget.auth,
        onOpenSearch: _openSearch,
      ),
      MyTicketsTab(
        auth: widget.auth,
        onRequestSignIn: _openLogin,
        active: _index == 1,
      ),
      PrivateTicketsTab(
        auth: widget.auth,
        onSignIn: _openLogin,
        onRegister: _openRegister,
        active: _index == 2,
        onHasEventsChanged: (hasEvents) {
          if (_hasPrivateEvents != hasEvents) {
            setState(() => _hasPrivateEvents = hasEvents);
          }
        },
      ),
      ProfileTab(
        auth: widget.auth,
        onSignOut: () async {
          await widget.onSignOut();
          if (mounted) setState(() => _hasPrivateEvents = false);
        },
        onSignIn: _openLogin,
        onRegister: _openRegister,
        onOpenTickets: () => _goTo(2),
        onOpenBooked: () => _goTo(1),
      ),
    ];

    final items = [
      (Icons.home_outlined, Icons.home_rounded, l10n.t('home')),
      (Icons.event_available_outlined, Icons.event_available, l10n.t('booked_events')),
      (Icons.confirmation_number_outlined, Icons.confirmation_number,
          signedIn && _hasPrivateEvents ? l10n.t('tickets') : l10n.t('create')),
      (Icons.person_outline, Icons.person, l10n.t('profile')),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF26215C),
          border: Border(
            top: BorderSide(color: Colors.black.withValues(alpha: 0.15)),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: Row(
              children: List.generate(items.length, (i) {
                final active = _index == i;
                final item = items[i];
                return Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _goTo(i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            active ? item.$2 : item.$1,
                            size: 24,
                            color: active
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.55),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.$3,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: item.$3.length > 8 ? 9 : 11,
                              fontWeight:
                                  active ? FontWeight.w800 : FontWeight.w600,
                              color: active
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.55),
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
