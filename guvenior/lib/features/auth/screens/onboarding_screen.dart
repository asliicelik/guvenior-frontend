import 'package:concentric_transition/concentric_transition.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import 'login_screen.dart';

final pages = [
  const OnboardingPage(
    icon: Icons.auto_graph,
    title: "Finansal gökyüzüne\nhoş geldin ✨",
    subtitle: "Harcamalarını takip et,\ngeleceğini şekillendir.",
    bgColor: Color(0xFF1A0D2E),
    textColor: AppColors.softPeach,
    accentColor: AppColors.peach,
  ),
  const OnboardingPage(
    icon: Icons.psychology_outlined,
    title: "Duygularınla\nharcıyor musun? 🧠",
    subtitle: "AI koçun seni yargılamadan\nanaliz eder ve yönlendirir.",
    bgColor: Color(0xFF0D1A2E),
    textColor: AppColors.softSky,
    accentColor: AppColors.sky,
  ),
  const OnboardingPage(
    icon: Icons.rocket_launch_outlined,
    title: "Geleceğini\nşimdi planla 🚀",
    subtitle: "Avrupa tatili mi? Araba mı?\nHedefine kaç ay kaldığını gör.",
    bgColor: Color(0xFF0D1A1A),
    textColor: Color(0xFF85FFDA),
    accentColor: Color(0xFF00E5A0),
  ),
];

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: ConcentricPageView(
        colors: pages.map((p) => p.bgColor).toList(),
        radius: screenWidth * 0.12,
        scaleFactor: 1.8,
        nextButtonBuilder: (context) => Container(
          width: screenWidth * 0.12,
          height: screenWidth * 0.12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.peachSkyGradient,
            boxShadow: [
              BoxShadow(
                color: AppColors.peach.withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(Icons.arrow_forward, color: Colors.white),
        ),
        onFinish: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        },
        itemCount: pages.length,
        itemBuilder: (index) {
          final page = pages[index % pages.length];
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),
                  Container(
                    width: screenHeight * 0.18,
                    height: screenHeight * 0.18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: page.accentColor.withOpacity(0.15),
                      border: Border.all(
                        color: page.accentColor.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      page.icon,
                      size: screenHeight * 0.09,
                      color: page.accentColor,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.06),
                  Text(
                    page.title,
                    style: GoogleFonts.inter(
                      color: page.textColor,
                      fontSize: screenHeight * 0.038,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Text(
                    page.subtitle,
                    style: GoogleFonts.inter(
                      color: page.textColor.withOpacity(0.6),
                      fontSize: screenHeight * 0.02,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color bgColor;
  final Color textColor;
  final Color accentColor;

  const OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.bgColor,
    required this.textColor,
    required this.accentColor,
  });
}
