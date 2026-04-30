import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/tmdb_movie.dart';
import 'movie_card.dart';

class Carousel extends StatelessWidget {
  final String title;
  final String? badge;
  final List<TmdbMovie> movies;
  final bool isLarge;

  const Carousel({
    super.key,
    required this.title,
    this.badge,
    required this.movies,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    if (movies.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE50914), Colors.orange],
                    ),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE50914).withOpacity(0.3),
                        blurRadius: 10,
                      )
                    ],
                  ),
                  child: Text(
                    badge!.toUpperCase(),
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(
          // Increase height to accommodate poster + spacing + title text
          height: ((isLarge ? 210.0 : 165.0) * (MediaQuery.of(context).size.width > 600 ? 1.3 : 1.0)) + 45.0,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: movies.length,
            itemBuilder: (context, index) {
              return MovieCard(
                movie: movies[index],
                index: index,
                isLarge: isLarge,
              );
            },
          ),
        ),
        const SizedBox(height: 25),
      ],
    );
  }
}
