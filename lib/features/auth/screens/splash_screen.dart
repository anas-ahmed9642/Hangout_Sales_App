import 'package:flutter/material.dart';

import '../../../shared/widgets/marble_background_painter.dart';
import '../../../app/theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6EC),
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: CastleWallPainter(),
            ),
          ),

          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.08),
                    Colors.black.withValues(alpha: 0.18),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black,
                        border: Border.all(
                          color: AppTheme.primaryColor,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.28),
                            blurRadius: 30,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.local_pizza_outlined,
                        color: AppTheme.primaryColor,
                        size: 48,
                      ),
                    ),

                    const SizedBox(height: 28),

                    const Text(
                      'HANGOUT PIZZA CLASSIC',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.2,
                        color: Colors.black,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'SALES MANAGER',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 4,
                        color: Colors.black.withValues(alpha: 0.5),
                      ),
                    ),

                    const SizedBox(height: 30),

                    const _OrnamentalDivider(),

                    const SizedBox(height: 30),

                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primaryColor,
                      ),
                    ),

                    const SizedBox(height: 18),

                    Text(
                      'Preparing your workspace...',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.black.withValues(alpha: 0.45),
                      ),
                    ),
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

class _OrnamentalDivider extends StatelessWidget {
  const _OrnamentalDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: AppTheme.primaryColor.withValues(alpha: 0.4),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Transform.rotate(
            angle: 0.785398,
            child: Container(
              width: 7,
              height: 7,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: AppTheme.primaryColor.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }
}