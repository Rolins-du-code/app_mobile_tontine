// l'ecrant d'aonboarding de l'appkication poour la rendre plus actractive


import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme.dart';
// import '../../core/app_logo.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() =>
      _OnboardingScreenState();
}

class _OnboardingScreenState
    extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _pageCourante = 0;

  final List<_PageOnboarding> _pages = [
    _PageOnboarding(
      icone: Icons.group_outlined,
      titre: 'Gérez vos tontines\nen toute simplicité',
      description:
          'Créez et gérez vos tontines formelles '
          'ou informelles depuis votre téléphone. '
          'Cotisations, emprunts, solidarité — '
          'tout en un seul endroit.',
      couleur: AppColors.primary,
    ),
    _PageOnboarding(
      icone: Icons.payments_outlined,
      titre: 'Suivi financier\nen temps réel',
      description:
          'Enregistrez les paiements, suivez les '
          'cotisations et gérez les emprunts avec '
          'calcul automatique des intérêts. '
          'Exportez vos rapports en PDF ou CSV.',
      couleur: AppColors.success,
    ),
    _PageOnboarding(
      icone: Icons.favorite_outline,
      titre: 'Solidarité\net transparence',
      description:
          'Gérez votre fonds de solidarité de façon '
          'transparente. Chaque membre voit qui a été '
          'aidé, quand et pourquoi. La confiance '
          'au cœur de votre amicale.',
      couleur: AppColors.accent,
    ),
    _PageOnboarding(
      icone: Icons.lock_outline,
      titre: 'Sécurisé\net accessible',
      description:
          'Vos données sont protégées par un code PIN '
          'personnel. Accédez à vos tontines depuis '
          'n\'importe quel téléphone, sans perdre '
          'vos informations.',
      couleur: AppColors.primary,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _terminer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [

            //  Bouton passer 
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _terminer,
                child: const Text(
                  'Passer',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            // Pages 
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) =>
                    setState(() => _pageCourante = i),
                itemBuilder: (context, i) =>
                    _pages[i].build(context),
              ),
            ),

            //  Indicateurs 
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => AnimatedContainer(
                  duration:
                      const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(
                      horizontal: 4),
                  width:
                      _pageCourante == i ? 24 : 8,
                    height: 8,
                  decoration: BoxDecoration(
                    color: _pageCourante == i
                        ? AppColors.primary
                        : AppColors.border,
                    borderRadius:
                        BorderRadius.circular(4),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Bouton suivant / commencer
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24),
              child: ElevatedButton(
                onPressed: () {
                  if (_pageCourante <
                      _pages.length - 1) {
                    _pageController.nextPage(
                      duration: const Duration(
                          milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  } else {
                    _terminer();
                  }
                },
                child: Text(
                  _pageCourante < _pages.length - 1
                      ? 'Suivant'
                      : 'Commencer',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _PageOnboarding {
  final IconData icone;
  final String titre;
  final String description;
  final Color couleur;

  const _PageOnboarding({
    required this.icone,
    required this.titre,
    required this.description,
    required this.couleur,
  });

  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          // Logo + icône
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: couleur.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: couleur.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: couleur,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color:
                          couleur.withOpacity(0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  icone,
                  color: Colors.white,
                  size: 34,
                ),
              ),
            ],
          ),

          const SizedBox(height: 40),

          Text(
            titre,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.2,
              color: AppColors.textDark,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.muted,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}