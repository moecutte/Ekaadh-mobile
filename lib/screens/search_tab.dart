import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ekaadh_mobile/core/theme.dart';
import 'package:ekaadh_mobile/models/event_model.dart';
import 'package:ekaadh_mobile/screens/event_detail_screen.dart';
import 'package:ekaadh_mobile/services/auth_service.dart';
import 'package:ekaadh_mobile/services/event_service.dart';

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
  List<EventModel> _suggestions = [];
  List<String> _categories = const [];
  List<String> _cities = const [];
  String _category = 'All';
  String _city = 'All';
  bool _loadingSuggestions = false;
  bool _showSuggestions = false;
  String _committedQuery = '';
  bool _hasActiveFilters = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _bootstrapFilters();
    _future = _service.list();
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
      final page = await _service.search();
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
      _hasActiveFilters = q.isNotEmpty || _category != 'All' || _city != 'All';
      _showSuggestions = false;
      _future = _service.list(
        q: q,
        category: _categoryParam,
        city: _cityParam,
      );
    });
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
      _hasActiveFilters = false;
      _future = _service.list();
    });
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

  InputDecoration _grayFieldDecoration({
    required Widget prefixIcon,
    String? hintText,
    Widget? suffixIcon,
    double radius = 16,
  }) {
    return EkaadhFields.decoration(
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      radius: radius,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryItems = ['All', ..._categories.where((c) => c != 'All')];
    final cityItems = ['All', ..._cities.where((c) => c != 'All')];

    return ColoredBox(
      color: EkaadhColors.surface,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Search', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 14),
                  TextField(
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
                    decoration: _grayFieldDecoration(
                      hintText: 'Search events...',
                      radius: 16,
                      prefixIcon: const Icon(Icons.search, color: EkaadhColors.soft),
                      suffixIcon: _controller.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close, color: EkaadhColors.soft),
                              onPressed: _clear,
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          key: ValueKey('category-$_category-${categoryItems.join('|')}'),
                          initialValue: categoryItems.contains(_category) ? _category : 'All',
                          isExpanded: true,
                          dropdownColor: Colors.white,
                          decoration: _grayFieldDecoration(
                            prefixIcon: const Icon(Icons.category_outlined, color: EkaadhColors.soft, size: 18),
                          ),
                          icon: const Icon(Icons.keyboard_arrow_down, color: EkaadhColors.soft),
                          style: const TextStyle(
                            color: EkaadhColors.muted,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          items: categoryItems
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(
                                    c == 'All' ? 'All Categories' : c,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() => _category = v);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          key: ValueKey('city-$_city-${cityItems.join('|')}'),
                          initialValue: cityItems.contains(_city) ? _city : 'All',
                          isExpanded: true,
                          dropdownColor: Colors.white,
                          decoration: _grayFieldDecoration(
                            prefixIcon: const Icon(Icons.location_on_outlined, color: EkaadhColors.soft, size: 18),
                          ),
                          icon: const Icon(Icons.keyboard_arrow_down, color: EkaadhColors.soft),
                          style: const TextStyle(
                            color: EkaadhColors.muted,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          items: cityItems
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(
                                    c == 'All' ? 'All Cities' : c,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() => _city = v);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: _runSearch,
                      style: FilledButton.styleFrom(
                        backgroundColor: EkaadhColors.brand,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                      child: const Text('Search'),
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
            Expanded(
              child: FutureBuilder<List<EventModel>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: EkaadhColors.brand));
                  }
                  if (snap.hasError) {
                    return Center(child: Text('${snap.error}', textAlign: TextAlign.center));
                  }
                  final events = snap.data ?? [];
                  if (events.isEmpty && _hasActiveFilters) {
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(20, 40, 20, 28),
                      children: [
                        const Icon(Icons.search_off, size: 48, color: EkaadhColors.soft),
                        const SizedBox(height: 12),
                        Text(
                          _committedQuery.isNotEmpty
                              ? 'No results for “$_committedQuery”'
                              : 'No events match these filters',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Try a different search, category, or city.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: EkaadhColors.muted),
                        ),
                      ],
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                    itemCount: events.length + 1,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE8EDEB)),
                    itemBuilder: (_, i) {
                      if (i == 0) {
                        final label = !_hasActiveFilters
                            ? 'Trending'
                            : '${events.length} result${events.length == 1 ? '' : 's'}';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8, top: 4),
                          child: Text(
                            label.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: EkaadhColors.soft,
                              letterSpacing: 1,
                            ),
                          ),
                        );
                      }
                      final e = events[i - 1];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: SizedBox(
                            width: 56,
                            height: 56,
                            child: e.coverImage != null
                                ? Image.network(e.coverImage!, fit: BoxFit.cover)
                                : const ColoredBox(color: Color(0xFFE2E8E4)),
                          ),
                        ),
                        title: Text(
                          e.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        subtitle: Text(
                          [
                            e.eventDateLabel,
                            e.city,
                            e.category,
                          ].where((s) => s != null && s.isNotEmpty).join(' · '),
                          style: const TextStyle(color: EkaadhColors.soft, fontSize: 12),
                        ),
                        trailing: e.startingPrice == null
                            ? null
                            : Text(
                                '\$${e.startingPrice!.toStringAsFixed(0)}',
                                style: const TextStyle(color: EkaadhColors.brand, fontWeight: FontWeight.w800),
                              ),
                        onTap: () => _openEvent(e),
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
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EDE9)),
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
                    'No suggestions for “$query”',
                    style: const TextStyle(color: EkaadhColors.muted, fontSize: 13),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(14, 10, 14, 4),
                      child: Text(
                        'SUGGESTIONS',
                        style: TextStyle(
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
                                tooltip: 'Use this search',
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
