import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/watch_history_provider.dart';
import '../models/tmdb_movie.dart';
import '../screens/video_player_screen.dart';
import '../widgets/movie_card.dart';

/// A horizontally scrolling "Continue Watching" section shown on the Home screen.
class ContinueWatchingCarousel extends ConsumerWidget {
  const ContinueWatchingCarousel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(watchHistoryProvider);
    if (history.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              Text(
                'Continue Watching',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE50914), Colors.deepOrange],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'RECENT',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: history.length,
            itemBuilder: (context, index) {
              return _ContinueWatchingCard(
                item: history[index],
                index: index,
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _ContinueWatchingCard extends ConsumerWidget {
  final WatchHistoryItem item;
  final int index;

  const _ContinueWatchingCard({required this.item, required this.index});

  void _playMovie(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            VideoPlayerScreen(
          movieId: item.movie.id,
          movieTitle: item.movie.title,
          isTvShow: item.movie.isTvShow,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final fade =
              CurvedAnimation(parent: animation, curve: Curves.easeOut);
          return FadeTransition(
            opacity: fade,
            child: SlideTransition(
              position: Tween<Offset>(
                      begin: const Offset(0.0, 0.15), end: Offset.zero)
                  .animate(fade),
              child: child,
            ),
          );
        },
      ),
    );
  }

  void _showDetails(BuildContext context, TmdbMovie movie) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 600),
      builder: (context) => MovieDetailsSheet(
        movie: movie,
        onPlay: () => _playMovie(context),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movie = item.movie;

    return GestureDetector(
      onTap: () => _showDetails(context, movie),
      child: Container(
        width: 220,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: const Color(0xFF161616),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Backdrop image
            Positioned.fill(
              child: movie.backdropUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: movie.backdropUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          Container(color: const Color(0xFF1E1E1E)),
                      errorWidget: (context, url, error) =>
                          Container(color: const Color(0xFF1E1E1E)),
                    )
                  : Container(color: const Color(0xFF1E1E1E)),
            ),

            // Dark gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.5),
                      Colors.black.withOpacity(0.95),
                    ],
                    stops: const [0.3, 0.65, 1.0],
                  ),
                ),
              ),
            ),

            // Play icon overlay (center)
            Positioned.fill(
              child: Center(
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withOpacity(0.4), width: 1.5),
                  ),
                  child: const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 24),
                ),
              ),
            ),

            // Red progress bar (always full as placeholder — could be extended with real time tracking)
            Positioned(
              bottom: 42,
              left: 0,
              right: 0,
              child: Container(
                height: 3,
                color: Colors.white10,
                child: FractionallySizedBox(
                  widthFactor: 0.4 + (index % 5) * 0.12, // simulated progress
                  alignment: Alignment.centerLeft,
                  child: Container(color: const Color(0xFFE50914)),
                ),
              ),
            ),

            // Movie title and time
            Positioned(
              bottom: 10,
              left: 12,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _timeAgo(item.watchedAt),
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Remove button (top right)
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  ref
                      .read(watchHistoryProvider.notifier)
                      .removeFromHistory(movie.id);
                },
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(Icons.close, color: Colors.white70, size: 14),
                ),
              ),
            ),

            // Type badge (top left)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  movie.isTvShow ? 'SERIES' : 'MOVIE',
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
