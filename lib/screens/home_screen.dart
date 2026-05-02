import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/tmdb_movie.dart';
import '../services/tmdb_service.dart';
import '../widgets/carousel.dart';
import '../widgets/continue_watching_carousel.dart';
import '../widgets/watermark.dart';
import 'video_player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  List<TmdbMovie> _trending = [];
  List<TmdbMovie> _action = [];
  List<TmdbMovie> _drama = [];
  List<TmdbMovie> _sciFi = [];
  List<TmdbMovie> _horror = [];
  List<TmdbMovie> _comedy = [];

  List<TmdbMovie> _popularSeries = [];
  List<TmdbMovie> _actionSeries = [];
  List<TmdbMovie> _sciFiSeries = [];
  List<TmdbMovie> _crimeSeries = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Hero carousel
  final PageController _heroPageController = PageController();
  Timer? _heroTimer;
  int _heroPage = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });
    _loadData();
  }

  void _startHeroTimer() {
    _heroTimer?.cancel();
    _heroTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || _trending.isEmpty) return;
      final next = (_heroPage + 1) % _trending.take(5).length;
      _heroPageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    Future<List<TmdbMovie>> safe(Future<List<TmdbMovie>> f) async {
      try { return await f; } catch (_) { return []; }
    }

    // Load trending first - if this fails, show error
    final trending = await safe(TmdbService.getTrending());
    if (!mounted) return;

    if (trending.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not connect to movie database.\nPlease check your internet and retry.';
      });
      return;
    }

    // Trending loaded — show page immediately, load rest in background
    setState(() {
      _trending = trending;
      _isLoading = false;
    });
    _startHeroTimer();

    // Load remaining categories one by one with small delays
    final categories = [
      () async { final r = await safe(TmdbService.getAction()); if (mounted) setState(() => _action = r); },
      () async { final r = await safe(TmdbService.getDrama()); if (mounted) setState(() => _drama = r); },
      () async { final r = await safe(TmdbService.getSciFi()); if (mounted) setState(() => _sciFi = r); },
      () async { final r = await safe(TmdbService.getHorror()); if (mounted) setState(() => _horror = r); },
      () async { final r = await safe(TmdbService.getComedy()); if (mounted) setState(() => _comedy = r); },
      () async { final r = await safe(TmdbService.getPopularSeries()); if (mounted) setState(() => _popularSeries = r); },
      () async { final r = await safe(TmdbService.getActionSeries()); if (mounted) setState(() => _actionSeries = r); },
      () async { final r = await safe(TmdbService.getSciFiSeries()); if (mounted) setState(() => _sciFiSeries = r); },
      () async { final r = await safe(TmdbService.getCrimeSeries()); if (mounted) setState(() => _crimeSeries = r); },
    ];

    for (final load in categories) {
      await load();
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  @override
  void dispose() {
    _heroTimer?.cancel();
    _heroPageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFE50914)),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage!,
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 16),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _loadData,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE50914),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    'Retry',
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final heroMovies = _trending.take(5).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              // Hero Carousel
              SliverToBoxAdapter(
                child: heroMovies.isNotEmpty
                    ? Stack(
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.65,
                            child: PageView.builder(
                              controller: _heroPageController,
                              itemCount: heroMovies.length,
                              onPageChanged: (page) => setState(() => _heroPage = page),
                              itemBuilder: (context, index) => _buildHero(heroMovies[index]),
                            ),
                          ),
                          // Dot indicators
                          Positioned(
                            bottom: 16,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(heroMovies.length, (i) {
                                final isActive = i == _heroPage;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOutCubic,
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  width: isActive ? 20 : 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: isActive ? const Color(0xFFE50914) : Colors.white38,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 10)),

              // Continue Watching (persisted history)
              const SliverToBoxAdapter(
                child: ContinueWatchingCarousel(),
              ),

              // Genre Quick Select
              SliverToBoxAdapter(
                child: _buildGenrePills()
                    .animate().fade(delay: 100.ms, duration: 600.ms).slideY(begin: 0.1),
              ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // Horizontal Rows
              SliverToBoxAdapter(
                child: Carousel(title: 'Trending Now', badge: 'HOT', movies: _trending.skip(1).toList(), isLarge: true)
                    .animate().fade(delay: 200.ms, duration: 600.ms).slideY(begin: 0.1),
              ),
              
              SliverToBoxAdapter(
                child: Carousel(title: 'Action & Adventure', movies: _action)
                    .animate().fade(delay: 300.ms, duration: 600.ms).slideY(begin: 0.1),
              ),
              
              SliverToBoxAdapter(
                child: Carousel(title: 'Drama', movies: _drama)
                    .animate().fade(delay: 400.ms, duration: 600.ms).slideY(begin: 0.1),
              ),
              
              SliverToBoxAdapter(
                child: Carousel(title: 'Sci-Fi & Fantasy', movies: _sciFi)
                    .animate().fade(delay: 500.ms, duration: 600.ms).slideY(begin: 0.1),
              ),
              
              SliverToBoxAdapter(
                child: Carousel(title: 'Popular TV Series', movies: _popularSeries)
                    .animate().fade(delay: 550.ms, duration: 600.ms).slideY(begin: 0.1),
              ),
              
              SliverToBoxAdapter(
                child: Carousel(title: 'Crime Series (Money Heist)', movies: _crimeSeries)
                    .animate().fade(delay: 600.ms, duration: 600.ms).slideY(begin: 0.1),
              ),
              
              SliverToBoxAdapter(
                child: Carousel(title: 'Action & Adventure Series', movies: _actionSeries)
                    .animate().fade(delay: 650.ms, duration: 600.ms).slideY(begin: 0.1),
              ),

              SliverToBoxAdapter(
                child: Carousel(title: 'Sci-Fi Series', movies: _sciFiSeries)
                    .animate().fade(delay: 700.ms, duration: 600.ms).slideY(begin: 0.1),
              ),

              SliverToBoxAdapter(
                child: Carousel(title: 'Horror Movies', movies: _horror)
                    .animate().fade(delay: 750.ms, duration: 600.ms).slideY(begin: 0.1),
              ),

              SliverToBoxAdapter(
                child: Carousel(title: 'Comedy Movies', movies: _comedy)
                    .animate().fade(delay: 800.ms, duration: 600.ms).slideY(begin: 0.1),
              ),
              
              const SliverToBoxAdapter(
                child: WatermarkFooter(),
              ),

              SliverToBoxAdapter(
                child: SizedBox(height: 58 + MediaQuery.of(context).viewPadding.bottom + 20),
              ),
            ],
          ),

          // Custom Navbar
          _buildNavbar(),
        ],
      ),
    );
  }

  Widget _buildNavbar() {
    final double opacity = (_scrollOffset / 200).clamp(0.0, 1.0);
    return Positioned(
      top: 0, left: 0, right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 10,
          bottom: 15, left: 20, right: 20,
        ),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(opacity),
          gradient: opacity < 1.0
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.85), Colors.transparent],
                )
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              'ARTORY',
              style: GoogleFonts.bebasNeue(
                color: Colors.white, fontSize: 28, letterSpacing: 2,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'MOVIES',
              style: GoogleFonts.inter(
                color: const Color(0xFFE50914),
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(TmdbMovie movie) {
    final heroHeight = MediaQuery.of(context).size.height * 0.65;
    final parallaxOffset = (_scrollOffset * 0.35).clamp(0.0, 80.0);

    return SizedBox(
      height: heroHeight,
      width: double.infinity,
      child: ClipRect(
        child: Stack(
          children: [
            // Parallax background — taller than container so it has room to move
            Positioned(
              top: -parallaxOffset,
              left: 0, right: 0,
              height: heroHeight + 90,
              child: CachedNetworkImage(
                imageUrl: movie.posterUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: const Color(0xFF161616)),
                errorWidget: (context, url, error) => Container(color: const Color(0xFF161616)),
              ),
            ),

            // Top gradient (for navbar readability)
            Positioned(
              top: 0, left: 0, right: 0,
              height: 160,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
              ),
            ),

            // Bottom gradient
            Positioned(
              bottom: 0, left: 0, right: 0,
              height: 320,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black],
                  ),
                ),
              ),
            ),

            // Hero content — left-aligned, Apple TV style
            Positioned(
              bottom: 24,
              left: 20, right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title,
                    textAlign: TextAlign.left,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                      letterSpacing: -0.5,
                    ),
                  ).animate().fade(duration: 800.ms).slideY(begin: 0.15),

                  const SizedBox(height: 8),

                  Text(
                    movie.isTvShow ? 'TV Series' : 'Movie',
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ).animate().fade(delay: 100.ms, duration: 600.ms),

                  const SizedBox(height: 20),

                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => VideoPlayerScreen(
                            movieId: movie.id,
                            movieTitle: movie.title,
                            isTvShow: movie.isTvShow,
                            posterPath: movie.posterPath,
                            backdropPath: movie.backdropPath,
                            voteAverage: movie.voteAverage,
                            overview: movie.overview,
                          ),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
                            return FadeTransition(
                              opacity: fade,
                              child: SlideTransition(
                                position: Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(fade),
                                child: child,
                              ),
                            );
                          },
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE50914),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE50914).withOpacity(0.4),
                            blurRadius: 20, offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 26),
                          const SizedBox(width: 6),
                          Text(
                            'WATCH NOW',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fade(delay: 200.ms).slideY(begin: 0.15),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenrePills() {
    final categories = [
      {'name': 'Action', 'emoji': '⚡'},
      {'name': 'Drama', 'emoji': '🎭'},
      {'name': 'Sci-Fi', 'emoji': '🚀'},
      {'name': 'Horror', 'emoji': '👻'},
      {'name': 'Comedy', 'emoji': '😂'},
    ];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          return Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                Text(cat['emoji']!, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Text(
                  cat['name']!,
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
