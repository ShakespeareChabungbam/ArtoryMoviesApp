import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'category_details_screen.dart';
import '../widgets/watermark.dart';

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key});

  final List<Map<String, dynamic>> _categories = const [
    {'id': '28', 'name': 'Action', 'icon': Icons.flash_on, 'color': Color(0xFFE50914), 'isTv': false},
    {'id': '10759', 'name': 'Action & Adv (TV)', 'icon': Icons.explore, 'color': Color(0xFFF57C00), 'isTv': true},
    {'id': '878', 'name': 'Sci-Fi', 'icon': Icons.science, 'color': Color(0xFF00B4D8), 'isTv': false},
    {'id': '10765', 'name': 'Sci-Fi (TV)', 'icon': Icons.rocket_launch, 'color': Color(0xFF03045E), 'isTv': true},
    {'id': '27', 'name': 'Horror', 'icon': Icons.bloodtype, 'color': Color(0xFF8B0000), 'isTv': false},
    {'id': '35', 'name': 'Comedy', 'icon': Icons.sentiment_very_satisfied, 'color': Color(0xFFFFD700), 'isTv': false},
    {'id': '18', 'name': 'Drama', 'icon': Icons.theater_comedy, 'color': Color(0xFF9C27B0), 'isTv': false},
    {'id': '80', 'name': 'Crime (TV)', 'icon': Icons.local_police, 'color': Color(0xFF607D8B), 'isTv': true},
    {'id': '10749', 'name': 'Romance', 'icon': Icons.favorite, 'color': Color(0xFFE91E63), 'isTv': false},
    {'id': '16', 'name': 'Animation', 'icon': Icons.animation, 'color': Color(0xFF4CAF50), 'isTv': false},
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount = screenWidth > 800 ? 5 : (screenWidth > 600 ? 4 : 2);

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            flexibleSpace: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                  title: Text(
                    'Categories',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 1.5,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final cat = _categories[index];
                  return _buildCategoryCard(context, cat, index);
                },
                childCount: _categories.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: WatermarkFooter(),
          ),
          SliverToBoxAdapter(
            child: Builder(
              builder: (ctx) => SizedBox(
                height: 58 + MediaQuery.of(ctx).viewPadding.bottom + 20,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, Map<String, dynamic> cat, int index) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => CategoryDetailsScreen(
              genreId: cat['id'],
              genreName: cat['name'],
              isTv: cat['isTv'],
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeOutCirc;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(position: animation.drive(tween), child: child);
            },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: cat['color'].withOpacity(0.15),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -10,
                  bottom: -10,
                  child: Icon(
                    cat['icon'],
                    size: 80,
                    color: cat['color'].withOpacity(0.2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        cat['name'],
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ).animate().fade(duration: 500.ms, delay: (50 * index).ms).slideY(begin: 0.2, end: 0, curve: Curves.easeOutCirc),
    );
  }
}
