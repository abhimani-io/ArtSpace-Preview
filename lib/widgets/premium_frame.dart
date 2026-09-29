import 'package:flutter/material.dart';

class PremiumFrame extends StatelessWidget {
  final Widget child;

  const PremiumFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9F6), // Realistic slightly warm off-white matting
        border: Border.all(
          color: const Color(0xFF181818), // Very dark matte-black frame
          width: 2.0, // THIN elegant frame
        ),
        boxShadow: [
          // 1. Ambient soft shadow (large, centered)
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 30,
            spreadRadius: 5,
            offset: const Offset(0, 15),
          ),
          // 2. Directional strong shadow (mimicking a light source from above)
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 15,
            spreadRadius: -2,
            offset: const Offset(0, 20),
          ),
          // 3. Contact tight shadow (right at the edge of the frame)
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 4,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4), // THIN matting padding
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The actual artwork with a subtle inner bevel shadow
          Container(
            foregroundDecoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.black.withValues(alpha: 0.25), width: 1.0),
                left: BorderSide(color: Colors.black.withValues(alpha: 0.25), width: 1.0),
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.6), width: 0.5),
                right: BorderSide(color: Colors.white.withValues(alpha: 0.6), width: 0.5),
              ),
            ),
            child: child,
          ),
          // Subtle glass reflection / glare overlay to make it look physical
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.25),
                    Colors.white.withValues(alpha: 0.0),
                    Colors.white.withValues(alpha: 0.0),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                  stops: const [0.0, 0.4, 0.7, 1.0],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
