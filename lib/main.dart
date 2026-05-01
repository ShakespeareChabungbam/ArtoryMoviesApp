import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audio_session/audio_session.dart';

import 'screens/home_screen.dart';
import 'screens/search_screen.dart';
import 'screens/my_list_screen.dart';
import 'screens/category_screen.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    const ProviderScope(
      child: ArtoryMoviesApp(),
    ),
  );
}

class ArtoryMoviesApp extends StatelessWidget {
  const ArtoryMoviesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ArtoryMovies',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF000000), // Pure black
        primaryColor: const Color(0xFFE50914), // Artory Red
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}


class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const SearchScreen(),
    const CategoryScreen(),
    const MyListScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initAudioSession();
  }

  Future<void> _initAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
    } catch (e) {
      debugPrint('Failed to configure AudioSession: $e');
    }
  }

  void _onTap(int index) {
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _GlassNavBar(
        currentIndex: _currentIndex,
        onTap: _onTap,
      ),
    );
  }
}

class _GlassNavBar extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;

  const _GlassNavBar({required this.currentIndex, required this.onTap});

  static const _items = [
    (icon: Icons.home_outlined, activeIcon: Icons.home_filled, label: 'Home'),
    (icon: Icons.search_outlined, activeIcon: Icons.search, label: 'Search'),
    (icon: Icons.grid_view_outlined, activeIcon: Icons.grid_view_rounded, label: 'Categories'),
    (icon: Icons.bookmark_outline_rounded, activeIcon: Icons.bookmark_rounded, label: 'My List'),
  ];

  @override
  Widget build(BuildContext context) {
    // Use viewPadding (not padding) because extendBody=true causes padding.bottom to be 0
    final bottomPad = MediaQuery.of(context).viewPadding.bottom;
    final navContentHeight = 56.0;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.45),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.07), width: 0.5),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: navContentHeight,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: List.generate(_items.length, (i) {
                    final item = _items[i];
                    final isActive = i == currentIndex;
                    return GestureDetector(
                      onTap: () => onTap(i),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.white.withOpacity(0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                isActive ? item.activeIcon : item.icon,
                                key: ValueKey(isActive),
                                color: isActive ? Colors.white : Colors.white38,
                                size: 22,
                              ),
                            ),
                            const SizedBox(height: 3),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: GoogleFonts.inter(
                                color: isActive ? Colors.white : Colors.white38,
                                fontSize: 10,
                                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                              ),
                              child: Text(item.label),
                            ),
                            const SizedBox(height: 2),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutCubic,
                              height: 3,
                              width: isActive ? 18 : 0,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE50914),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
              // Safe area bottom padding
              SizedBox(height: bottomPad),
            ],
          ),
        ),
      ),
    );
  }
}

