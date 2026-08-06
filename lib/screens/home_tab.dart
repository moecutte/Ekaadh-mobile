import 'package:flutter/material.dart';
import 'package:ekaadh_mobile/core/theme.dart';
import 'package:ekaadh_mobile/core/locale_scope.dart';
import 'package:ekaadh_mobile/models/event_model.dart';
import 'package:ekaadh_mobile/screens/event_detail_screen.dart';
import 'package:ekaadh_mobile/services/auth_service.dart';
import 'package:ekaadh_mobile/services/event_service.dart';
import 'package:ekaadh_mobile/widgets/design_network_image.dart';
import 'package:ekaadh_mobile/widgets/ekaadh_logo.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({
    super.key,
    required this.userName,
    this.auth,
    this.onOpenSearch,
  });

  final String userName;
  final AuthService? auth;
  final VoidCallback? onOpenSearch;

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final _service = EventService();
  String _category = 'all';
  List<EventModel> _featured = const [];
  List<EventModel> _upcoming = const [];
  bool _initialLoading = true;
  bool _upcomingLoading = false;
  Object? _error;

  static const _catKeys = ['all', 'Music', 'Sports', 'Comedy', 'Tech', 'Food'];

  String get _categoryApiValue =>
      _category == 'all' || _category == 'All' ? 'All' : _category;

  @override
  void initState() {
    super.initState();
    _category = 'all';
    _load();
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
      final upcoming = await _service.list(
        category: _categoryApiValue == 'All' ? null : _categoryApiValue,
      );
      if (!mounted) return;
      setState(() {
        _featured = featured;
        _upcoming = upcoming;
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
            '${l10n.t('could_not_load')}\n$_error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: EkaadhColors.muted),
          ),
          TextButton(onPressed: _load, child: Text(l10n.t('retry'))),
        ],
      );
    }

    String catLabel(String key) => key == 'all' ? l10n.t('all') : key;

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
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: EkaadhColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.notifications_none_rounded, color: EkaadhColors.muted, size: 22),
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
          child: SizedBox(
            height: 52,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              scrollDirection: Axis.horizontal,
              itemCount: _catKeys.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final c = _catKeys[i];
                final active = c == _category;
                return ChoiceChip(
                  label: Text(catLabel(c)),
                  selected: active,
                  onSelected: (_) => _selectCategory(c),
                  selectedColor: EkaadhColors.brand,
                  labelStyle: TextStyle(
                    color: active ? Colors.white : EkaadhColors.muted,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  backgroundColor: Colors.white,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                );
              },
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
            child: SizedBox(
              height: 150,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: _featured.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) {
                  final e = _featured[i];
                  return GestureDetector(
                    onTap: () => _open(e),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: SizedBox(
                        width: 224,
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
                              left: 14,
                              right: 14,
                              bottom: 12,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(e.eventDateLabel ?? '', style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)),
                                  Text(e.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                                ],
                              ),
                            ),
                            if (e.category != null)
                              Positioned(
                                top: 10,
                                right: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                                  decoration: BoxDecoration(color: EkaadhColors.brand, borderRadius: BorderRadius.circular(999)),
                                  child: Text(e.category!, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
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
          ),
        ],
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(l10n.t('upcoming_events'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
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
                  if (event.category != null)
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
