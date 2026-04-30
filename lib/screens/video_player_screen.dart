import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:google_fonts/google_fonts.dart';

class VideoPlayerScreen extends StatefulWidget {
  final int movieId;
  final String movieTitle;
  final bool isTvShow;
  final int? seasonNumber;
  final int? episodeNumber;

  const VideoPlayerScreen({
    super.key, 
    required this.movieId,
    required this.movieTitle,
    this.isTvShow = false,
    this.seasonNumber,
    this.episodeNumber,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  InAppWebViewController? webViewController;
  bool isLoading = true;
  bool showOverlay = true;
  Timer? hideTimer;
  Timer? clockTimer;
  String currentTime = "";

  @override
  void initState() {
    super.initState();
    // Force landscape and hide status bar
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    _updateClock();
    _startOverlayTimer();
    
    clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateClock();
    });
  }

  void _updateClock() {
    final now = DateTime.now();
    int hour = now.hour;
    final String period = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    final String minute = now.minute.toString().padLeft(2, '0');
    if (mounted) {
      setState(() {
        currentTime = '$hour:$minute $period';
      });
    }
  }

  void _startOverlayTimer() {
    hideTimer?.cancel();
    hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && !isLoading) {
        setState(() {
          showOverlay = false;
        });
      }
    });
  }

  void _toggleOverlay() {
    setState(() {
      showOverlay = !showOverlay;
    });
    if (showOverlay) {
      _startOverlayTimer();
    }
  }

  @override
  void dispose() {
    hideTimer?.cancel();
    clockTimer?.cancel();
    // Restore portrait and system UI
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String subtitle = widget.isTvShow && widget.seasonNumber != null && widget.episodeNumber != null
        ? 'Season ${widget.seasonNumber} • Episode ${widget.episodeNumber}'
        : '';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. The Webview Player
          AnimatedOpacity(
            opacity: isLoading ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            child: InAppWebView(
              initialUrlRequest: URLRequest(
                url: WebUri("https://vidlink.pro/${widget.isTvShow ? 'tv/${widget.movieId}/${widget.seasonNumber ?? 1}/${widget.episodeNumber ?? 1}' : 'movie/${widget.movieId}'}?primaryColor=e50914&autoplay=true"),
              ),
              initialSettings: InAppWebViewSettings(
                mediaPlaybackRequiresUserGesture: false,
                allowsInlineMediaPlayback: true,
                iframeAllowFullscreen: true,
                transparentBackground: true,
                useShouldOverrideUrlLoading: true,
                supportMultipleWindows: true,
                javaScriptCanOpenWindowsAutomatically: false,
              ),
              onCreateWindow: (controller, createWindowAction) async {
                // Block all popups and new windows completely
                return false;
              },
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                var uri = navigationAction.request.url;
                if (uri != null && !uri.host.contains('vidlink.pro')) {
                  return NavigationActionPolicy.CANCEL;
                }
                return NavigationActionPolicy.ALLOW;
              },
              onWebViewCreated: (controller) {
                webViewController = controller;
              },
              onLoadStop: (controller, url) {
                setState(() {
                  isLoading = false;
                });
                _startOverlayTimer(); // Auto-hide overlay once loaded
              },
              onReceivedError: (controller, request, error) {
                setState(() {
                  isLoading = false;
                });
              },
              onReceivedHttpError: (controller, request, errorResponse) {
                setState(() {
                  isLoading = false;
                });
              },
            ),
          ),
          
          // 2. Loading Spinner
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFFE50914)),
            ),

          // 3. Invisible touch zone at the top to trigger overlay
          if (!isLoading)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: showOverlay ? 120 : 80,
              child: GestureDetector(
                onTap: _toggleOverlay,
                behavior: HitTestBehavior.translucent,
                child: Container(color: Colors.transparent),
              ),
            ),
            
          // 4. The Apple TV+ Top Overlay Bar
          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            top: showOverlay ? 0 : -120, // Slide up to hide
            left: 0,
            right: 0,
            child: IgnorePointer(
              ignoring: !showOverlay, // Let touches pass through when hidden
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.9),
                      Colors.black.withOpacity(0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(40, 30, 40, 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back Button (Chevron Down)
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 32),
                      ),
                    ),
                    const SizedBox(width: 24),
                    
                    // Title and Subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.movieTitle,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          if (subtitle.isNotEmpty)
                            Text(
                              subtitle,
                              style: GoogleFonts.inter(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    // Right side controls (Clock, Audio, Fullscreen)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // System Clock (Apple TV+ style)
                        Text(
                          currentTime,
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 35),
                        
                        // Audio & Subtitles Icon
                        GestureDetector(
                          onTap: _startOverlayTimer,
                          child: const Icon(Icons.subtitles_outlined, color: Colors.white, size: 30),
                        ),
                        const SizedBox(width: 30),
                        
                        // Fullscreen / Picture-in-Picture Icon
                        GestureDetector(
                          onTap: _startOverlayTimer,
                          child: const Icon(Icons.picture_in_picture_alt_outlined, color: Colors.white, size: 28),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
