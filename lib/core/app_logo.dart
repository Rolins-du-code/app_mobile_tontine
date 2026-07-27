// ici on cree le logo de l'application pour qu'elle soit attraiyante 


import 'package:flutter/material.dart';
import 'theme.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool dark;

  const AppLogo({
    super.key,
    this.size = 80,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? [
                  const Color(0xFF1A3A6B),
                  const Color(0xFF2563EB),
                ]
              : [
                  AppColors.primary,
                  const Color(0xFF4F8BFF),
                ],
        ),
        borderRadius: BorderRadius.circular(size * 0.24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.35),
            blurRadius: size * 0.2,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Cercle décoratif en arrière-plan
          Positioned(
            top: -size * 0.1,
            right: -size * 0.1,
            child: Container(
              width: size * 0.6,
              height: size * 0.6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          // Initiales
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'MA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: size * 0.01,
                  height: 1,
                ),
              ),
              Container(
                width: size * 0.4,
                height: 2,
                margin: EdgeInsets.only(top: size * 0.04),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}