import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/tmdb_movie.dart';
import '../services/tmdb_service.dart';
import '../widgets/carousel.dart';
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
  bool _hasError = false;

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

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final results = await Future.wait([
      TmdbService.getTrending(),
      TmdbService.getAction(),
      TmdbService.getDrama(),
      TmdbService.getSciFi(),
      TmdbService.getHorror(),
      TmdbService.getComedy(),
      TmdbService.getPopularSeries(),
      TmdbService.getActionSeries(),
      TmdbService.getSciFiSeries(),
      TmdbService.getCrimeSeries(),
    ]);

    if (mounted) {
      // If the first crucial result (trending) is empty, consider it a network error
      if (results[0].isEmpty) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      } else {
        setState(() {
          _trending = results[0];
          _action = results[1];
          _drama = results[2];
          _sciFi = results[3];
          _horror = results[4];
          _comedy = results[5];
          _popularSeries = results[6];
          _actionSeries = results[7];
          _sciFiSeries = results[8];
          _crimeSeries = results[9];
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
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

    if (_hasError) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Failed to load content.',
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

    final TmdbMovie? heroMovie = _trending.isNotEmpty ? _trending.first : null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              // Hero Banner
              SliverToBoxAdapter(
                child: heroMovie != null ? _buildHero(heroMovie) : const SizedBox.shrink(),
              ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 10)),
              
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

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
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
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 10,
          bottom: 15,
          left: 20,
          right: 20,
        ),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(opacity),
          gradient: opacity < 1.0 
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.9),
                    Colors.transparent,
                  ],
                )
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'ARTORY',
              style: GoogleFonts.bebasNeue(
                color: Colors.white,
                fontSize: 28,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'MOVIES',
              style: GoogleFonts.inter(
                color: const Color(0xFFE50914),
                fontSize: 10,
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
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.65,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Parallax
          Positioned(
            top: -_scrollOffset * 0.5,
            left: 0,
            right: 0,
            bottom: 0,
            child: CachedNetworkImage(
              imageUrl: movie.posterUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: const Color(0xFF161616)),
              errorWidget: (context, url, error) => Container(color: const Color(0xFF161616)),
            ),
          ),

          // Fade gradient
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 300,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black,
                  ],
                ),
              ),
            ),
          ),

          // Content
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Text(
                  movie.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                    letterSpacing: -1,
                  ),
                ).animate().fade(duration: 800.ms).slideY(begin: 0.2),
                
                const SizedBox(height: 25),

                // Play Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
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
                            ),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              final fadeAnimation = CurvedAnimation(parent: animation, curve: Curves.easeOut);
                              final slideAnimation = Tween<Offset>(
                                begin: const Offset(0.0, 0.2),
                                end: Offset.zero,
                              ).animate(fadeAnimation);
                              return FadeTransition(
                                opacity: fadeAnimation,
                                child: SlideTransition(
                                  position: slideAnimation,
                                  child: child,
                                ),
                              );
                            },
                          ),
                        );
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.8,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE50914), // Artory Red
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.play_arrow, color: Colors.white, size: 28),
                            const SizedBox(width: 5),
                            Text(
                              'WATCH NOW',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ).animate().fade(delay: 200.ms).slideY(begin: 0.2),
              ],
            ),
          )
        ],
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
