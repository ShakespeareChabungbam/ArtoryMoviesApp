import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/my_list_provider.dart';
import '../widgets/movie_card.dart';
import '../widgets/watermark.dart';

class MyListScreen extends ConsumerWidget {
  const MyListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movies = ref.watch(myListProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount = screenWidth > 800 ? 6 : (screenWidth > 600 ? 5 : 3);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'My List',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: movies.isEmpty
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
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.add, color: Colors.white.withOpacity(0.3), size: 40),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Your List is Empty',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Add movies and shows to your list so\nyou can easily find them later.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 14,
                                height: 1.4,
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
                        return MovieCard(movie: movies[index], index: index);
                      },
                      childCount: movies.length,
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
    );
  }
}
