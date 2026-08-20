import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ekaadh_mobile/core/locale_scope.dart';
import 'package:ekaadh_mobile/core/theme.dart';
import 'package:ekaadh_mobile/models/event_model.dart';
import 'package:ekaadh_mobile/screens/event_detail_screen.dart';
import 'package:ekaadh_mobile/services/auth_service.dart';
import 'package:ekaadh_mobile/services/event_service.dart';
import 'package:ekaadh_mobile/widgets/design_network_image.dart';
import 'package:ekaadh_mobile/core/user_facing_error.dart';

class SearchTab extends StatefulWidget {
  const SearchTab({super.key, this.auth});

  final AuthService? auth;

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final _service = EventService();
  final _controller = TextEditingController();
  final _focus = FocusNode();

  late Future<List<EventModel>> _future;
  List<EventModel> _featured = const [];
  List<EventModel> _suggestions = [];
  List<String> _categories = const [];
  List<String> _cities = const [];
  String _category = 'All';
  String _city = 'All';
  String _when = 'upcoming';
  String _price = 'all';
  bool _loadingSuggestions = false;
  bool _showSuggestions = false;
  String _committedQuery = '';
  bool _showAllResults = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _bootstrapFilters();
    _future = _fetchEvents();
    _loadFeatured();
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
    _focus.addListener(() {
      if (!_focus.hasFocus) {
        Future<void>.delayed(const Duration(milliseconds: 120), () {
          if (mounted && !_focus.hasFocus) {
            setState(() => _showSuggestions = false);
          }
        });
      }
    });
  }

  Future<void> _bootstrapFilters() async {
    try {
      final page = await _service.search(when: _when, price: _price);
      if (!mounted) return;
      setState(() {
        _categories = page.categories;
        _cities = page.cities;
      });
    } catch (_) {
      // Filters stay empty; search still works without them.
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  String? get _categoryParam => _category == 'All' ? null : _category;
  String? get _cityParam => _city == 'All' ? null : _city;

  bool get _isBrowse =>
      _committedQuery.isEmpty &&
      _category == 'All' &&
      _city == 'All' &&
      _price == 'all' &&
      !_showAllResults;

  bool get _hasActiveFilters =>
      _committedQuery.isNotEmpty ||
      _category != 'All' ||
      _city != 'All' ||
      _price != 'all';

  Future<List<EventModel>> _fetchEvents({bool featured = false}) {
    return _service.list(
      q: _committedQuery,
      category: _categoryParam,
      city: _cityParam,
      when: _when,
      price: _price,
      featured: featured,
    );
  }

  Future<void> _loadFeatured() async {
    try {
      final featured = await _fetchEvents(featured: true);
      if (!mounted) return;
      setState(() => _featured = featured);
    } catch (_) {
      if (!mounted) return;
      setState(() => _featured = const []);
    }
  }

  void _refresh({bool resetShowAll = false}) {
    if (resetShowAll) {
      _showAllResults = false;
    }
    setState(() {
      _future = _fetchEvents();
    });
    if (_isBrowse) {
      _loadFeatured();
    }
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    final q = value.trim();
    if (q.isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
        _loadingSuggestions = false;
      });
      return;
    }

    setState(() {
      _showSuggestions = true;
      _loadingSuggestions = true;
    });

    _debounce = Timer(const Duration(milliseconds: 280), () async {
      try {
        final results = await _service.list(
          q: q,
          category: _categoryParam,
          city: _cityParam,
          when: _when,
          price: _price,
        );
        if (!mounted || _controller.text.trim() != q) return;
        setState(() {
          _suggestions = results.take(6).toList();
          _loadingSuggestions = false;
          _showSuggestions = true;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _suggestions = [];
          _loadingSuggestions = false;
        });
      }
    });
  }

  void _runSearch([String? override]) {
    _debounce?.cancel();
    final q = (override ?? _controller.text).trim();
    _focus.unfocus();
    setState(() {
      _committedQuery = q;
      _showAllResults = q.isNotEmpty;
      _showSuggestions = false;
    });
    _refresh();
  }

  void _clear() {
    _debounce?.cancel();
    _controller.clear();
    setState(() {
      _suggestions = [];
      _showSuggestions = false;
      _loadingSuggestions = false;
      _committedQuery = '';
      _category = 'All';
      _city = 'All';
      _when = 'upcoming';
      _price = 'all';
      _showAllResults = false;
    });
    _refresh();
  }

  void _selectWhen(String when) {
    if (_when == when) return;
    setState(() => _when = when);
    _refresh();
  }

  void _selectCategory(String category) {
    if (_category == category) return;
    setState(() {
      _category = category;
      _showAllResults = category != 'All' || _committedQuery.isNotEmpty || _price != 'all' || _city != 'All';
    });
    _refresh();
  }

  void _openEvent(EventModel e) {
    _focus.unfocus();
    setState(() => _showSuggestions = false);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EventDetailScreen(slug: e.slug, auth: widget.auth),
      ),
    );
  }

  void _applySuggestion(EventModel e) {
    _controller.text = e.title;
    _controller.selection = TextSelection.collapsed(offset: e.title.length);
    _runSearch(e.title);
  }

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<_FilterValues>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return _FiltersSheet(
          categories: _categories,
          cities: _cities,
          category: _category,
          city: _city,
          price: _price,
        );
      },
    );
    if (result == null || !mounted) return;
    setState(() {
      _category = result.category;
      _city = result.city;
      _price = result.price;
      _showAllResults = result.category != 'All' ||
          result.city != 'All' ||
          result.price != 'all' ||
          _committedQuery.isNotEmpty;
    });
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = LocaleScope.of(context);
    final categoryItems = ['All', ..._categories.where((c) => c != 'All')];
    final filtersOn = _price != 'all' || _city != 'All' || _category != 'All';

    return ColoredBox(
      color: EkaadhColors.surface,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.t('search'),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: EkaadhColors.dark,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          focusNode: _focus,
                          textInputAction: TextInputAction.search,
                          onChanged: _onQueryChanged,
                          onSubmitted: (_) => _runSearch(),
                          onTap: () {
                            if (_controller.text.trim().isNotEmpty) {
                              setState(() => _showSuggestions = true);
                            }
                          },
                          style: const TextStyle(
                            color: EkaadhColors.dark,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            hintText: l10n.t('search_placeholder'),
                            hintStyle: EkaadhTextStyles.fieldHint,
                            prefixIcon: const Icon(Icons.search, color: EkaadhColors.soft),
                            suffixIcon: _controller.text.isEmpty
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.close, color: EkaadhColors.soft),
                                    onPressed: _clear,
                                  ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(999),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(999),
                              borderSide: const BorderSide(color: Color(0xFFE8ECF1)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(999),
                              borderSide: const BorderSide(color: EkaadhColors.brand, width: 1.5),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Material(
                        color: EkaadhColors.brand,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          onTap: _openFilters,
                          borderRadius: BorderRadius.circular(16),
                          child: SizedBox(
                            width: 50,
                            height: 50,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                const Icon(Icons.tune, color: Colors.white, size: 22),
                                if (filtersOn)
                                  const Positioned(
                                    top: 10,
                                    right: 10,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: SizedBox(width: 7, height: 7),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categoryItems.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final c = categoryItems[i];
                        final selected = _category == c;
                        return _CategoryPill(
                          label: c == 'All' ? l10n.t('all') : c,
                          selected: selected,
                          onTap: () => _selectCategory(c),
                        );
                      },
                    ),
                  ),
                  if (_showSuggestions && _controller.text.trim().isNotEmpty)
                    _SuggestionPanel(
                      loading: _loadingSuggestions,
                      suggestions: _suggestions,
                      query: _controller.text.trim(),
                      onSelect: _applySuggestion,
                      onOpen: _openEvent,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: FutureBuilder<List<EventModel>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: EkaadhColors.brand));
                  }
                  if (snap.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          UserFacingError.message(snap.error, t: l10n.t),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  final events = snap.data ?? [];
                  if (_isBrowse) {
                    return _BrowseBody(
                      featured: _featured,
                      suggested: events,
                      onOpen: _openEvent,
                      onSeeAll: () {
                        setState(() => _showAllResults = true);
                        _refresh();
                      },
                    );
                  }
                  if (events.isEmpty) {
                    final emptyTitle = _committedQuery.isNotEmpty
                        ? '${l10n.t('no_results_for')} “$_committedQuery”'
                        : (_hasActiveFilters
                            ? l10n.t('no_events_filters')
                            : (_when == 'past' ? l10n.t('no_past_events') : l10n.t('no_upcoming_events')));
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(20, 40, 20, 28),
                      children: [
                        const Icon(Icons.search_off, size: 48, color: EkaadhColors.soft),
                        const SizedBox(height: 12),
                        Text(
                          emptyTitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.t('try_different_search'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: EkaadhColors.muted),
                        ),
                      ],
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                    itemCount: events.length + 1,
                    separatorBuilder: (_, i) => i == 0 ? const SizedBox(height: 12) : const SizedBox(height: 14),
                    itemBuilder: (_, i) {
                      if (i == 0) {
                        return _ResultsMeta(
                          count: events.length,
                          when: _when,
                          onWhenChanged: _selectWhen,
                        );
                      }
                      return _ResultEventCard(
                        event: events[i - 1],
                        onTap: () => _openEvent(events[i - 1]),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterValues {
  const _FilterValues({
    required this.category,
    required this.city,
    required this.price,
  });

  final String category;
  final String city;
  final String price;
}

class _FiltersSheet extends StatefulWidget {
  const _FiltersSheet({
    required this.categories,
    required this.cities,
    required this.category,
    required this.city,
    required this.price,
  });

  final List<String> categories;
  final List<String> cities;
  final String category;
  final String city;
  final String price;

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  late String _category = widget.category;
  late String _city = widget.city;
  late String _price = widget.price;

  @override
  Widget build(BuildContext context) {
    final l10n = LocaleScope.of(context);
    final categoryItems = ['All', ...widget.categories.where((c) => c != 'All')];
    final cityItems = ['All', ...widget.cities.where((c) => c != 'All')];
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 10, 20, 16 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD8DEE6),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.t('filters'),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: EkaadhColors.dark,
                    ),
                  ),
                ),
                Material(
                  color: Colors.white,
                  elevation: 2,
                  shadowColor: const Color(0x22000000),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(12),
                    child: const SizedBox(
                      width: 36,
                      height: 36,
                      child: Icon(Icons.close, size: 18, color: EkaadhColors.dark),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.t('filter_category'),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: EkaadhColors.dark),
            ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: categoryItems
                          .map(
                            (c) => _FilterChip(
                              label: c == 'All' ? l10n.t('all') : c,
                              selected: _category == c,
                              onTap: () => setState(() => _category = c),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.t('price_range'),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: EkaadhColors.dark),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _FilterChip(
                          label: l10n.t('all'),
                          selected: _price == 'all',
                          onTap: () => setState(() => _price = 'all'),
                        ),
                        _FilterChip(
                          label: l10n.t('free'),
                          selected: _price == 'free',
                          onTap: () => setState(() => _price = 'free'),
                        ),
                        _FilterChip(
                          label: l10n.t('price_paid'),
                          selected: _price == 'paid',
                          onTap: () => setState(() => _price = 'paid'),
                        ),
                      ],
                    ),
                    if (cityItems.length > 1) ...[
                      const SizedBox(height: 20),
                      Text(
                        l10n.t('filter_city'),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: EkaadhColors.dark),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: cityItems
                            .map(
                              (c) => _FilterChip(
                                label: c == 'All' ? l10n.t('all') : c,
                                selected: _city == c,
                                onTap: () => setState(() => _city = c),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 22),
                    SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    _FilterValues(category: _category, city: _city, price: _price),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: EkaadhColors.brand,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                child: Text(l10n.t('apply_filters')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? EkaadhColors.brand : Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: selected ? null : Border.all(color: const Color(0xFFE8ECF1)),
            boxShadow: selected
                ? null
                : const [BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(Icons.check, size: 14, color: Colors.white),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : EkaadhColors.dark,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? EkaadhColors.brand : Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: selected ? null : Border.all(color: const Color(0xFFE8ECF1)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : EkaadhColors.muted,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _BrowseBody extends StatelessWidget {
  const _BrowseBody({
    required this.featured,
    required this.suggested,
    required this.onOpen,
    required this.onSeeAll,
  });

  final List<EventModel> featured;
  final List<EventModel> suggested;
  final ValueChanged<EventModel> onOpen;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final l10n = LocaleScope.of(context);
    if (featured.isEmpty && suggested.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 40, 20, 28),
        children: [
          const Icon(Icons.search_off, size: 48, color: EkaadhColors.soft),
          const SizedBox(height: 12),
          Text(
            l10n.t('no_upcoming_events'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        if (featured.isNotEmpty) ...[
          _SectionHeader(title: l10n.t('popular_now')),
          SizedBox(
            height: 118,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: featured.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _SuggestedEventCard(
                event: featured[i],
                onTap: () => onOpen(featured[i]),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (suggested.isNotEmpty) ...[
          _SectionHeader(title: l10n.t('suggested_for_you'), onSeeAll: onSeeAll),
          SizedBox(
            height: 118,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: suggested.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _SuggestedEventCard(
                event: suggested[i],
                onTap: () => onOpen(suggested[i]),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.onSeeAll});

  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final l10n = LocaleScope.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: EkaadhColors.dark,
              ),
            ),
          ),
          if (onSeeAll != null)
            Material(
              color: EkaadhColors.brandLight,
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                onTap: onSeeAll,
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Text(
                    l10n.t('see_all'),
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
    );
  }
}

class _SuggestedEventCard extends StatelessWidget {
  const _SuggestedEventCard({required this.event, required this.onTap});

  final EventModel event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = LocaleScope.of(context);
    final location = [event.venue, event.city].where((e) => e != null && e.isNotEmpty).join(', ');

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 280,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 88,
                    height: 88,
                    child: DesignNetworkImage(
                      url: event.coverImage,
                      fallbackColor: const Color(0xFFE2E8E4),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (event.category != null && event.category!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: EkaadhColors.brandLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            event.category!.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: EkaadhColors.brand,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      const SizedBox(height: 6),
                      Text(
                        event.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: EkaadhColors.dark,
                        ),
                      ),
                      if (location.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 13, color: EkaadhColors.soft),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: EkaadhColors.muted, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        _eventPriceLabel(event, l10n.t),
                        style: const TextStyle(
                          color: EkaadhColors.brand,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultsMeta extends StatelessWidget {
  const _ResultsMeta({
    required this.count,
    required this.when,
    required this.onWhenChanged,
  });

  final int count;
  final String when;
  final ValueChanged<String> onWhenChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = LocaleScope.of(context);
    final countLabel = '$count ${count == 1 ? l10n.t('event_found') : l10n.t('events_found')}';
    final whenLabel = when == 'past' ? l10n.t('past') : l10n.t('upcoming');

    return Row(
      children: [
        Expanded(
          child: Text(
            countLabel,
            style: const TextStyle(
              color: EkaadhColors.muted,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        PopupMenuButton<String>(
          initialValue: when,
          onSelected: onWhenChanged,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          itemBuilder: (_) => [
            PopupMenuItem(value: 'upcoming', child: Text(l10n.t('upcoming'))),
            PopupMenuItem(value: 'past', child: Text(l10n.t('past'))),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFE8ECF1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  whenLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: EkaadhColors.dark,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down, size: 16, color: EkaadhColors.muted),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ResultEventCard extends StatelessWidget {
  const _ResultEventCard({required this.event, required this.onTap});

  final EventModel event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = LocaleScope.of(context);
    final location = [event.venue, event.city].where((e) => e != null && e.isNotEmpty).join(', ');
    final dateLabel = event.eventDate ?? event.eventDateLabel ?? '';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 168,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DesignNetworkImage(
                    url: event.coverImage,
                    fallbackColor: const Color(0xFFE2E8E4),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0x99000000)],
                      ),
                    ),
                  ),
                  if (event.category != null && event.category!.isNotEmpty)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: EkaadhColors.brand,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          event.category!.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  if (dateLabel.isNotEmpty)
                    Positioned(
                      left: 12,
                      bottom: 12,
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 12, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            dateLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: Text(
                      _eventPriceLabel(event, l10n.t),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: EkaadhColors.dark,
                    ),
                  ),
                  if (location.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 15, color: EkaadhColors.soft),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: EkaadhColors.muted, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Material(
                      color: EkaadhColors.brandLight,
                      borderRadius: BorderRadius.circular(999),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        child: Text(
                          l10n.t('view_event'),
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
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionPanel extends StatelessWidget {
  const _SuggestionPanel({
    required this.loading,
    required this.suggestions,
    required this.query,
    required this.onSelect,
    required this.onOpen,
  });

  final bool loading;
  final List<EventModel> suggestions;
  final String query;
  final ValueChanged<EventModel> onSelect;
  final ValueChanged<EventModel> onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = LocaleScope.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECF1)),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: loading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: EkaadhColors.brand),
                ),
              ),
            )
          : suggestions.isEmpty
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Text(
                    '${l10n.t('no_suggestions_for')} “$query”',
                    style: const TextStyle(color: EkaadhColors.muted, fontSize: 13),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                      child: Text(
                        l10n.t('suggestions').toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: EkaadhColors.soft,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    ...suggestions.map((e) {
                      return InkWell(
                        onTap: () => onOpen(e),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              const Icon(Icons.search, size: 18, color: EkaadhColors.soft),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      e.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                                    ),
                                    Text(
                                      [
                                        if (e.city != null && e.city!.isNotEmpty) e.city,
                                        if (e.category != null && e.category!.isNotEmpty) e.category,
                                      ].join(' · '),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: EkaadhColors.soft, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: l10n.t('use_this_search'),
                                onPressed: () => onSelect(e),
                                icon: const Icon(Icons.north_west, size: 16, color: EkaadhColors.soft),
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
    );
  }
}

String _eventPriceLabel(EventModel event, String Function(String) t) {
  if (event.isExpired) return t('expired');
  if (event.isFree) return t('free');
  if (event.startingPrice == null) return t('free');
  return '\$${event.startingPrice!.toStringAsFixed(0)}';
}
