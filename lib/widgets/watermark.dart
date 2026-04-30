import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WatermarkFooter extends StatelessWidget {
  const WatermarkFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.apple,
                color: Colors.white38,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'ArtoryMovies',
                style: GoogleFonts.inter(
                  color: Colors.white38,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Developed by shakespeare Chabungbam',
            style: GoogleFonts.inter(
              color: Colors.white24,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
