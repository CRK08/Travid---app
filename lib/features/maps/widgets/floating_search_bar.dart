import 'dart:async';
import 'package:flutter/material.dart';
import 'package:travid/services/search_service.dart';

class FloatingSearchBar extends StatefulWidget {
  final Function(Map<String, dynamic>) onPlaceSelected;

  const FloatingSearchBar({super.key, required this.onPlaceSelected});

  @override
  State<FloatingSearchBar> createState() => _FloatingSearchBarState();
}

class _FloatingSearchBarState extends State<FloatingSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final SearchService _searchService = SearchService();
  List<Map<String, dynamic>> _suggestions = [];
  Timer? _debounce;
  bool _isLoading = false;

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.trim().isEmpty) {
        setState(() => _suggestions = []);
        return;
      }

      setState(() => _isLoading = true);
      final results = await _searchService.searchPlaces(query);
      setState(() {
        _suggestions = results;
        _isLoading = false;
      });
    });
  }

  void _clearSearch() {
    _controller.clear();
    setState(() {
      _suggestions = [];
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search Input
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(30),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: _controller,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: "Search destinations...",
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _isLoading
                  ? const SizedBox(
                      width: 20, 
                      height: 20, 
                      child: Padding(
                        padding: EdgeInsets.all(10.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : (_controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: _clearSearch,
                        )
                      : const Icon(Icons.mic)), // Or null
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
          ),
        ),

        // Suggestions List (only if suggestions exist)
        if (_suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _suggestions.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final place = _suggestions[index];
                return ListTile(
                  leading: const Icon(Icons.location_on_outlined, size: 20),
                  title: Text(
                    place['display_name'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                  onTap: () {
                    widget.onPlaceSelected(place);
                    _clearSearch(); // Or keep text but hide suggestions?
                    // Better to clear suggestions but keep text focused on place name
                    _controller.text = place['display_name'].split(',')[0];
                    setState(() => _suggestions = []);
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}
