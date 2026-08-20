import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ekaadh_mobile/core/theme.dart';
import 'package:ekaadh_mobile/core/locale_scope.dart';
import 'package:ekaadh_mobile/models/event_model.dart';
import 'package:ekaadh_mobile/screens/event_detail_screen.dart';
import 'package:ekaadh_mobile/screens/notifications_screen.dart';
import 'package:ekaadh_mobile/services/auth_service.dart';
import 'package:ekaadh_mobile/services/event_service.dart';
import 'package:ekaadh_mobile/services/notification_service.dart';
import 'package:ekaadh_mobile/widgets/design_network_image.dart';
import 'package:ekaadh_mobile/widgets/ekaadh_logo.dart';
import 'package:ekaadh_mobile/core/user_facing_error.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({
    super.key,
    required this.userName,
    this.auth,
    this.onOpenSearch,
    this.onRequestSignIn,
  });

  final String userName;
  final AuthService? auth;
  final VoidCallback? onOpenSearch;
  final VoidCallback? onRequestSignIn;

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final _service = EventService();
  String _category = 'all';
  List<String> _homeCategories = const ['Music', 'Sports', 'Comedy', 'Tech'];
  List<EventModel> _featured = const [];
  List<EventModel> _upcoming = const [];
  bool _upcomingIsPastFallback = false;
  bool _initialLoading = true;
  bool _upcomingLoading = false;
  Object? _error;
  int _unreadNotifications = 0;

  static const _fallbackCategories = ['Music', 'Sports', 'Comedy', 'Tech'];

  String get _categoryApiValue =>
      _category == 'all' || _category == 'All' ? 'All' : _category;

  @override
  void initState() {
    super.initState();
    _category = 'all';
    _load();
    _loadUnread();
  }

  Future<void> _load({bool categoryOnly = false}) async {
    if (categoryOnly) {
      setState(() => _upcomingLoading = true);
    } else {
      setState(() {
        _initialLoading = true;
        _error = null;
      });
    }

    try {
      late final List<EventModel> featured;
      if (categoryOnly) {
        featured = _featured;
      } else {
        featured = await _service.list(featured: true);
      }
      final page = await _service.search(
        category: _categoryApiValue == 'All' ? null : _categoryApiValue,
        when: 'upcoming',
      );
      var listing = page.events;
      var isPastFallback = false;
      if (listing.isEmpty) {
        listing = await _service.list(
          category: _categoryApiValue == 'All' ? null : _categoryApiValue,
          when: 'past',
        );
        isPastFallback = listing.isNotEmpty;
      }
      if (!mounted) return;
      setState(() {
        _featured = featured;
        if (!categoryOnly) {
          final fromApi = page.categories.where((c) => c != 'All').take(4).toList();
          _homeCategories = fromApi.isNotEmpty ? fromApi : _fallbackCategories;
          if (_category != 'all' && !_homeCategories.contains(_category)) {
            _category = 'all';
          }
        }
        _upcoming = listing;
        _upcomingIsPastFallback = isPastFallback;
        _initialLoading = false;
        _upcomingLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (!categoryOnly) {
          _error = e;
          _initialLoading = false;
        }
        _upcomingLoading = false;
      });
    }
  }

  void _selectCategory(String category) {
    if (category == _category) return;
    setState(() => _category = category);
    _load(categoryOnly: true);
  }

  void _open(EventModel event) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EventDetailScreen(slug: event.slug, auth: widget.auth)),
    );
  }

  Future<void> _loadUnread() async {
    final token = widget.auth?.token;
    if (token == null) {
      if (mounted) setState(() => _unreadNotifications = 0);
      return;
    }
    try {
      final count = await NotificationService(token: token).unreadCount();
      if (mounted) setState(() => _unreadNotifications = count);
    } catch (_) {}
  }

  Future<void> _openNotifications() async {
    if (widget.auth?.token == null) {
      widget.onRequestSignIn?.call();
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotificationsScreen(auth: widget.auth!),
      ),
    );
    await _loadUnread();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: EkaadhColors.surface,
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: EkaadhColors.brand,
          onRefresh: () => _load(),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final l10n = LocaleScope.of(context);

    if (_initialLoading) {
      return const Center(child: CircularProgressIndicator(color: EkaadhColors.brand));
    }
    if (_error != null) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          const Icon(Icons.wifi_off, size: 40, color: EkaadhColors.soft),
          const SizedBox(height: 12),
          Text(
            UserFacingError.message(_error, t: l10n.t),
            textAlign: TextAlign.center,
            style: const TextStyle(color: EkaadhColors.muted),
          ),
          TextButton(onPressed: _load, child: Text(l10n.t('retry'))),
        ],
      );
    }

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Compact ENG/SOM toggle in the home header as well.
        SliverToBoxAdapter(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: EkaadhLogo(height: 32),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: EkaadhColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8E4)),
                      ),
                      padding: const EdgeInsets.all(2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _HomeLangChip(
                            label: l10n.t('eng'),
                            selected: l10n.code == 'en',
                            onTap: () => l10n.setLocale('en'),
                          ),
                          _HomeLangChip(
                            label: l10n.t('som'),
                            selected: l10n.code == 'so',
                            onTap: () => l10n.setLocale('so'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: EkaadhColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: _openNotifications,
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              const Icon(Icons.notifications_none_rounded, color: EkaadhColors.muted, size: 22),
                              if (_unreadNotifications > 0)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    width: 9,
                                    height: 9,
                                    decoration: const BoxDecoration(
                                      color: EkaadhColors.danger,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: widget.onOpenSearch,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    decoration: BoxDecoration(
                      color: EkaadhColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8E4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, size: 20, color: EkaadhColors.soft),
                        const SizedBox(width: 10),
                        Text(
                          l10n.t('search_events'),
                          style: const TextStyle(color: EkaadhColors.soft, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.t('categories'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: EkaadhColors.dark,
                        ),
                      ),
                    ),
                    Material(
                      color: EkaadhColors.brandLight,
                      borderRadius: BorderRadius.circular(999),
                      child: InkWell(
                        onTap: widget.onOpenSearch,
                        borderRadius: BorderRadius.circular(999),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: Text(
                            l10n.t('all'),
                            style: const TextStyle(
                              color: EkaadhColors.brand,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    for (var i = 0; i < _homeCategories.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(
                        child: _CategoryIconTile(
                          label: _homeCategories[i],
                          icon: _iconForCategory(_homeCategories[i]),
                          selected: _category == _homeCategories[i],
                          onTap: () => _selectCategory(_homeCategories[i]),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
        if (_featured.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              child: Text(l10n.t('featured'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
            ),
          ),
          SliverToBoxAdapter(
            child: _FeaturedSlider(
              key: ValueKey(_featured.map((e) => e.id).join(',')),
              events: _featured,
              onOpen: _open,
            ),
          ),
        ],
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _upcomingIsPastFallback ? l10n.t('past_events') : l10n.t('upcoming_events'),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                  ),
                ),
                if (_upcomingLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: EkaadhColors.brand),
                  ),
              ],
            ),
          ),
        ),
        if (_upcoming.isEmpty && !_upcomingLoading)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Text(
                l10n.t('no_events_category'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: EkaadhColors.muted, fontWeight: FontWeight.w600),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            sliver: SliverList.separated(
              itemCount: _upcoming.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (_, i) {
                final e = _upcoming[i];
                return Opacity(
                  opacity: _upcomingLoading ? 0.55 : 1,
                  child: _EventCard(event: e, onTap: () => _open(e)),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, required this.onTap});
  final EventModel event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = LocaleScope.of(context);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 170,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DesignNetworkImage(
                    url: event.coverImage,
                    fallbackColor: const Color(0xFFE2E8E4),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                      child: Column(
                        children: [
                          Text(event.eventMonth ?? '', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: EkaadhColors.brand)),
                          Text(event.eventDay ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, height: 1)),
                        ],
                      ),
                    ),
                  ),
                  if (event.isExpired)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(999)),
                        child: Text(l10n.t('expired'), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                      ),
                    )
                  else if (event.category != null)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(color: EkaadhColors.brand, borderRadius: BorderRadius.circular(999)),
                        child: Text(event.category!, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    [event.venue, event.city].where((e) => e != null && e.isNotEmpty).join(', '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: EkaadhColors.soft, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(event.eventTimeLabel ?? '', style: const TextStyle(color: EkaadhColors.soft, fontSize: 12)),
                      if (event.startingPrice != null)
                        Text(
                          '${l10n.t('from_price')} \$${event.startingPrice!.toStringAsFixed(0)}',
                          style: const TextStyle(color: EkaadhColors.brand, fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedSlider extends StatefulWidget {
  const _FeaturedSlider({
    super.key,
    required this.events,
    required this.onOpen,
  });

  final List<EventModel> events;
  final ValueChanged<EventModel> onOpen;

  @override
  State<_FeaturedSlider> createState() => _FeaturedSliderState();
}

class _FeaturedSliderState extends State<_FeaturedSlider> {
  late final PageController _controller;
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.9);
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _timer?.cancel();
    if (widget.events.length < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_index + 1) % widget.events.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = LocaleScope.of(context);
    final events = widget.events;

    return Column(
      children: [
        SizedBox(
          height: 188,
          child: PageView.builder(
            controller: _controller,
            itemCount: events.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) {
              final e = events[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: GestureDetector(
                  onTap: () => widget.onOpen(e),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        DesignNetworkImage(
                          url: e.coverImage,
                          fallbackColor: const Color(0xFFE2E8E4),
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black54],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 14,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e.eventDateLabel ?? '',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                e.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (e.isExpired)
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                l10n.t('expired'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        if (e.category != null)
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                              decoration: BoxDecoration(
                                color: EkaadhColors.brand,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                e.category!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (events.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(events.length, (i) {
              final active = i == _index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 18 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: active ? EkaadhColors.brand : const Color(0xFFD5DBE6),
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

class _CategoryIconTile extends StatelessWidget {
  const _CategoryIconTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 12, 6, 10),
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: selected ? EkaadhColors.brand : EkaadhColors.brandLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: selected ? Colors.white : EkaadhColors.brand,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  color: selected ? EkaadhColors.brand : EkaadhColors.dark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _iconForCategory(String name) {
  final key = name.toLowerCase();
  if (key.contains('music') || key.contains('concert')) return Icons.music_note_rounded;
  if (key.contains('sport')) return Icons.sports_soccer_rounded;
  if (key.contains('comedy') || key.contains('theatre') || key.contains('theater')) {
    return Icons.theater_comedy_rounded;
  }
  if (key.contains('tech') || key.contains('it ')) return Icons.memory_rounded;
  if (key.contains('food') || key.contains('culinary')) return Icons.restaurant_rounded;
  if (key.contains('business')) return Icons.business_center_rounded;
  if (key.contains('culture') || key.contains('art')) return Icons.palette_rounded;
  if (key.contains('educat') || key.contains('school')) return Icons.school_rounded;
  if (key.contains('government') || key.contains('gov')) return Icons.account_balance_rounded;
  if (key.contains('ngo')) return Icons.volunteer_activism_rounded;
  return Icons.category_rounded;
}

class _HomeLangChip extends StatelessWidget {
  const _HomeLangChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? EkaadhColors.brand : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: selected ? Colors.white : EkaadhColors.muted,
          ),
        ),
      ),
    );
  }
}
