import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/tmdb_movie.dart';
import '../services/tmdb_service.dart';
import '../widgets/movie_card.dart';
import '../widgets/watermark.dart';
import '../widgets/movie_skeleton.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<TmdbMovie> _results = [];
  bool _isLoading = false;
  Timer? _debounce;
  String _filter = 'All'; // 'All', 'Movies', 'Series'

  String _lastSearchQuery = '';
  bool _hasError = false;

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch();
    });
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.length > 2) {
      _lastSearchQuery = query;
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
      
      try {
        final results = await TmdbService.search(query);
        
        // Ignore if the query has changed since the request started
        if (_lastSearchQuery != query) return;
        
        final filteredResults = results.where((movie) {
          if (_filter == 'Movies') return !movie.isTvShow;
          if (_filter == 'Series') return movie.isTvShow;
          return true;
        }).toList();

        setState(() {
          _results = filteredResults;
          _isLoading = false;
        });
      } catch (e) {
        if (_lastSearchQuery == query) {
          setState(() {
            _results = [];
            _isLoading = false;
            _hasError = true;
          });
        }
      }
    } else {
      setState(() {
        _results = [];
        _hasError = false;
        _isLoading = false;
      });
    }
  }

  void _setFilter(String filter) {
    setState(() {
      _filter = filter;
    });
    if (_searchController.text.trim().length > 2) {
      _performSearch();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount = screenWidth > 800 ? 6 : (screenWidth > 600 ? 5 : 3);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search movies, series...',
                    hintStyle: GoogleFonts.inter(color: Colors.white.withOpacity(0.3)),
                    prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.5)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                ),
              ),
            ),
            
            // Filter Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: ['All', 'Movies', 'Series'].map((filter) {
                  final isSelected = _filter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => _setFilter(filter),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFE50914) : Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          filter,
                          style: GoogleFonts.inter(
                            color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),
            
            Expanded(
              child: _isLoading
                  ? CustomScrollView(
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.all(20),
                          sliver: SliverGrid(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              childAspectRatio: 1 / 1.65,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 15,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                return const MovieSkeleton();
                              },
                              childCount: crossAxisCount * 3, // Show a few rows of skeletons
                            ),
                          ),
                        ),
                      ],
                    )
                  : _results.isEmpty
                      ? CustomScrollView(
                          slivers: [
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          _hasError
                                              ? 'Network error. Please try again.'
                                              : _searchController.text.trim().isEmpty
                                                  ? 'Find your next favorite movie.'
                                                  : 'No results found.',
                                          style: GoogleFonts.inter(
                                            color: Colors.white.withOpacity(0.5),
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const WatermarkFooter(),
                                  SizedBox(height: 56 + MediaQuery.of(context).viewPadding.bottom + 20), // padding for bottom nav
                                ],
                              ),
                            )
                          ],
                        )
                      : CustomScrollView(
                          slivers: [
                            SliverPadding(
                              padding: const EdgeInsets.all(20),
                              sliver: SliverGrid(
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  childAspectRatio: 1 / 1.65,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 15,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    return MovieCard(movie: _results[index], index: index);
                                  },
                                  childCount: _results.length,
                                ),
                              ),
                            ),
                            const SliverToBoxAdapter(
                              child: WatermarkFooter(),
                            ),
                            SliverToBoxAdapter(
                              child: SizedBox(height: 56 + MediaQuery.of(context).viewPadding.bottom + 20), // padding for bottom nav
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
