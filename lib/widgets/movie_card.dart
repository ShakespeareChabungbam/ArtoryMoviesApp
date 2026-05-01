import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette_generator/palette_generator.dart';
import '../models/tmdb_movie.dart';
import '../providers/my_list_provider.dart';
import '../models/tmdb_series.dart';
import '../services/tmdb_service.dart';
import '../screens/video_player_screen.dart';
import 'watermark.dart';

class MovieCard extends StatefulWidget {
  final TmdbMovie movie;
  final int index;
  final bool isLarge;

  const MovieCard({
    super.key,
    required this.movie,
    required this.index,
    this.isLarge = false,
  });

  @override
  State<MovieCard> createState() => _MovieCardState();
}

class _MovieCardState extends State<MovieCard> {
  double _rotateX = 0;
  double _rotateY = 0;
  double _scale = 1.0;

  void _playMovie(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => VideoPlayerScreen(
          movieId: widget.movie.id,
          movieTitle: widget.movie.title,
          isTvShow: widget.movie.isTvShow,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final fadeAnimation = CurvedAnimation(parent: animation, curve: Curves.easeOut);
          return FadeTransition(
            opacity: fadeAnimation,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0.0, 0.2), end: Offset.zero).animate(fadeAnimation),
              child: child,
            ),
          );
        },
      ),
    );
  }

  void _showDetails(BuildContext context) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 600),
      builder: (context) => MovieDetailsSheet(movie: widget.movie, onPlay: () => _playMovie(context)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isPad = screenWidth > 600;
    final baseWidth = widget.isLarge ? 140.0 : 110.0;
    final width = isPad ? baseWidth * 1.3 : baseWidth;
    final cardHeight = (widget.isLarge ? 210.0 : 165.0) * (isPad ? 1.3 : 1.0);

    return GestureDetector(
      onTap: () => _showDetails(context),
      onPanUpdate: (details) {
        setState(() {
          _rotateY = ((details.localPosition.dx / width) - 0.5) * 0.22;
          _rotateX = -(((details.localPosition.dy / cardHeight) - 0.5) * 0.22);
          _scale = 1.06;
        });
      },
      onPanEnd: (_) {
        setState(() {
          _rotateX = 0;
          _rotateY = 0;
          _scale = 1.0;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateX(_rotateX)
          ..rotateY(_rotateY)
          ..scale(_scale),
        transformAlignment: Alignment.center,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: width,
              height: cardHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: const Color(0xFF161616),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(_scale > 1.0 ? 0.55 : 0.25),
                    blurRadius: _scale > 1.0 ? 22 : 8,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: widget.movie.posterUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: widget.movie.posterUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: const Color(0xFF161616),
                        child: const Center(
                          child: CircularProgressIndicator(color: Color(0xFFE50914), strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) =>
                          const Center(child: Icon(Icons.movie, color: Colors.white24)),
                    )
                  : const Center(child: Icon(Icons.movie, color: Colors.white24)),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: width,
              child: Text(
                widget.movie.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ).animate().fade(delay: (widget.index * 50).ms, duration: 400.ms).slideX(begin: 0.1),
    );
  }
}


class MovieDetailsSheet extends ConsumerStatefulWidget {
  final TmdbMovie movie;
  final VoidCallback onPlay;

  const MovieDetailsSheet({super.key, required this.movie, required this.onPlay});

  @override
  ConsumerState<MovieDetailsSheet> createState() => _MovieDetailsSheetState();
}

class _MovieDetailsSheetState extends ConsumerState<MovieDetailsSheet> {
  List<TmdbSeason> _seasons = [];
  TmdbSeason? _selectedSeason;
  List<TmdbEpisode> _episodes = [];
  bool _isLoadingSeasons = false;
  bool _isLoadingEpisodes = false;
  bool _hasSeasonsError = false;
  bool _hasEpisodesError = false;
  Color? _dominantColor;

  @override
  void initState() {
    super.initState();
    _extractColor();
    if (widget.movie.isTvShow) {
      _fetchSeasons();
    }
  }

  Future<void> _extractColor() async {
    if (widget.movie.posterUrl.isNotEmpty) {
      try {
        final PaletteGenerator generator = await PaletteGenerator.fromImageProvider(
          CachedNetworkImageProvider(widget.movie.posterUrl),
        );
        if (mounted) {
          setState(() {
            _dominantColor = generator.dominantColor?.color ?? generator.vibrantColor?.color;
          });
        }
      } catch (e) {
        // ignore errors
      }
    }
  }

  Future<void> _fetchSeasons() async {
    setState(() {
      _isLoadingSeasons = true;
      _hasSeasonsError = false;
    });
    
    final seasons = await TmdbService.getTvSeasons(widget.movie.id);
    
    if (mounted) {
      if (seasons.isNotEmpty) {
        // Deduplicate seasons by seasonNumber to prevent DropdownButton duplicate value crash
        final uniqueSeasons = <int, TmdbSeason>{};
        for (var s in seasons) {
          uniqueSeasons[s.seasonNumber] = s;
        }
        
        setState(() {
          _seasons = uniqueSeasons.values.toList()
            ..sort((a, b) => a.seasonNumber.compareTo(b.seasonNumber));
          _selectedSeason = _seasons.first;
          _isLoadingSeasons = false;
        });
        _fetchEpisodes(_selectedSeason!.seasonNumber);
      } else {
        setState(() {
          _isLoadingSeasons = false;
          _hasSeasonsError = true;
        });
      }
    }
  }

  Future<void> _fetchEpisodes(int seasonNumber) async {
    setState(() {
      _isLoadingEpisodes = true;
      _hasEpisodesError = false;
    });
    
    final episodes = await TmdbService.getTvEpisodes(widget.movie.id, seasonNumber);
    
    if (mounted) {
      if (episodes.isEmpty) {
        setState(() {
          _isLoadingEpisodes = false;
          _hasEpisodesError = true;
        });
      } else {
        setState(() {
          _episodes = episodes;
          _isLoadingEpisodes = false;
        });
      }
    }
  }

  void _playEpisode(int seasonNumber, int episodeNumber) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => VideoPlayerScreen(
          movieId: widget.movie.id,
          movieTitle: widget.movie.title,
          isTvShow: true,
          seasonNumber: seasonNumber,
          episodeNumber: episodeNumber,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final fadeAnimation = CurvedAnimation(parent: animation, curve: Curves.easeOut);
          final slideAnimation = Tween<Offset>(begin: const Offset(0.0, 0.2), end: Offset.zero).animate(fadeAnimation);
          return FadeTransition(opacity: fadeAnimation, child: SlideTransition(position: slideAnimation, child: child));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.88,
        decoration: BoxDecoration(
          color: _dominantColor == null ? Colors.black.withOpacity(0.55) : null,
          gradient: _dominantColor != null
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _dominantColor!.withOpacity(0.6),
                    Colors.black.withOpacity(0.8),
                    Colors.black,
                  ],
                )
              : null,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.15), width: 1.5)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Image and gradient
              Stack(
                children: [
                  if (widget.movie.backdropUrl.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: widget.movie.backdropUrl,
                      height: 280,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 280,
                        color: const Color(0xFF161616),
                      ),
                      errorWidget: (context, url, error) => const SizedBox(),
                    ),
                  Container(
                    height: 280,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.6),
                          Colors.black.withOpacity(1.0),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 15,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Text(
                      widget.movie.title,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                        letterSpacing: -1,
                      ),
                    ).animate().fade(duration: 600.ms).slideY(begin: 0.3),
                  ),
                ],
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Meta info
                      Row(
                        children: [
                          const Icon(Icons.star, color: Color(0xFFF5C518), size: 18),
                          const SizedBox(width: 6),
                          Text(
                            widget.movie.voteAverage.toStringAsFixed(1),
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              widget.movie.isTvShow ? 'SERIES' : 'MOVIE',
                              style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'HD',
                              style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ).animate().fade(delay: 150.ms, duration: 600.ms).slideY(begin: 0.2),
                      
                      const SizedBox(height: 30),
                      
                      // Action Buttons Row
                      Row(
                        children: [
                          // Play Button
                          Expanded(
                            child: GestureDetector(
                              onTap: widget.onPlay,
                              child: Container(
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFE50914), Color(0xFFB20710)],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(color: const Color(0xFFE50914).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8)),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 34),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Play Now',
                                      style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                                    ),
                                  ],
                                ),
                              ),
                            ).animate().fade(delay: 250.ms, duration: 600.ms).scale(begin: const Offset(0.95, 0.95)),
                          ),
                          
                          const SizedBox(width: 15),
                          
                          // My List Button
                          Consumer(
                            builder: (context, ref, child) {
                              final moviesList = ref.watch(myListProvider);
                              final isInList = moviesList.any((m) => m.id == widget.movie.id);
                              
                              return GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  ref.read(myListProvider.notifier).toggleMovie(widget.movie);
                                },
                                child: Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                                  ),
                                  child: Icon(
                                    isInList ? Icons.check_rounded : Icons.add_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                              ).animate().fade(delay: 300.ms, duration: 600.ms).scale(begin: const Offset(0.95, 0.95));
                            },
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 30),
                      
                      Text(
                        'Overview',
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                      ).animate().fade(delay: 350.ms, duration: 600.ms),
                      
                      const SizedBox(height: 12),
                      
                      Text(
                        widget.movie.overview,
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.75), 
                          fontSize: 15, 
                          height: 1.6,
                          letterSpacing: 0.2,
                        ),
                      ).animate().fade(delay: 450.ms, duration: 600.ms),
                      
                      const SizedBox(height: 30),

                      // Episodes Section (if TV Show)
                      if (widget.movie.isTvShow) ...[
                        if (_isLoadingSeasons)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(child: CircularProgressIndicator(color: Color(0xFFE50914))),
                          )
                        else if (_hasSeasonsError)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Column(
                                children: [
                                  Text(
                                    'Season details not found.',
                                    style: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
                                  ),
                                  const SizedBox(height: 10),
                                  GestureDetector(
                                    onTap: _fetchSeasons,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        'Retry',
                                        style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else if (_seasons.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Episodes',
                                style: GoogleFonts.inter(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<TmdbSeason>(
                                  dropdownColor: const Color(0xFF161616),
                                  value: _selectedSeason,
                                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
                                  style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                                  onChanged: (TmdbSeason? newValue) {
                                    if (newValue != null && newValue != _selectedSeason) {
                                      setState(() {
                                        _selectedSeason = newValue;
                                      });
                                      _fetchEpisodes(newValue.seasonNumber);
                                    }
                                  },
                                  items: _seasons.map<DropdownMenuItem<TmdbSeason>>((TmdbSeason season) {
                                    return DropdownMenuItem<TmdbSeason>(
                                      value: season,
                                      child: Text(season.name),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ).animate().fade(delay: 550.ms, duration: 600.ms),
                        
                        const SizedBox(height: 16),
                        
                        if (_isLoadingEpisodes)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: CircularProgressIndicator(color: Color(0xFFE50914)),
                            ),
                          )
                        else if (_hasEpisodesError)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Column(
                                children: [
                                  Text(
                                    'No episodes found.',
                                    style: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
                                  ),
                                  const SizedBox(height: 12),
                                  GestureDetector(
                                    onTap: () {
                                      if (_selectedSeason != null) {
                                        _fetchEpisodes(_selectedSeason!.seasonNumber);
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        'Retry',
                                        style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _episodes.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final ep = _episodes[index];
                              return GestureDetector(
                                onTap: () => _playEpisode(_selectedSeason!.seasonNumber, ep.episodeNumber),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Episode Thumbnail
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: ep.stillUrl.isNotEmpty
                                            ? CachedNetworkImage(
                                                imageUrl: ep.stillUrl,
                                                width: 130,
                                                height: 75,
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) => Container(
                                                  width: 130,
                                                  height: 75,
                                                  color: const Color(0xFF161616),
                                                ),
                                                errorWidget: (context, url, error) => Container(
                                                  width: 130,
                                                  height: 75,
                                                  color: const Color(0xFF161616),
                                                  child: const Center(child: Icon(Icons.error_outline, color: Colors.white54)),
                                                ),
                                              )
                                            : Container(
                                                width: 130,
                                                height: 75,
                                                color: Colors.white.withOpacity(0.1),
                                                child: const Icon(Icons.movie, color: Colors.white24),
                                              ),
                                      ),
                                      const SizedBox(width: 16),
                                      
                                      // Episode Details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    '${ep.episodeNumber}. ${ep.name}',
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: GoogleFonts.inter(
                                                      color: Colors.white,
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                                const Icon(Icons.play_circle_outline, color: Colors.white70, size: 22),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              ep.overview,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.inter(
                                                color: Colors.white.withOpacity(0.6),
                                                fontSize: 12,
                                                height: 1.4,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ).animate().fade(duration: 600.ms),
                        ],
                      ],
                      const SizedBox(height: 30),
                      const WatermarkFooter(),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
