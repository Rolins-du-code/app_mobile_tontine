// page de connexion pour ceux qui revienne après une première connexion ( après le splash screen )

// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';
import 'register_screen.dart';
// importation lier la connexion dans firebase
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _telController = TextEditingController();
  String _pin = '';

  @override
  void dispose() {
    _telController.dispose();
    super.dispose();
  }

  void _onChiffreAppuye(String chiffre) {
    if (_pin.length >= 4) return;
    setState(() => _pin += chiffre);

    if (_pin.length == 4) {
      Future.delayed(const Duration(milliseconds: 200), _seConnecter);
    }
  }

  void _onEffacer() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  // void _seConnecter() {
  //   if (_telController.text.trim().isEmpty) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Entrez votre numéro de téléphone')),
  //     );
  //     setState(() => _pin = '');
  //     return;
  //   }

  //   // Pour l'instant : pas de vérification réelle, Firebase viendra plus tard
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(content: Text('Connexion réussie (simulation)')),
  //   );

  //   // Plus tard : Navigator.pushReplacementNamed(context, '/hub');
  //   setState(() => _pin = '');
  // }

  Future<void> _seConnecter() async {
    if (_telController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entrez votre numero de téléphone ')),
      );
      setState(() => _pin = '');
      return;
    }
    // Hache de PIN entre pour le compare a celui stocké
    final pinHache = sha256.convert(utf8.encode(_pin)).toString();
    final telephone = _telController.text.trim().replaceAll(' ', ' ');

    try {
      //chercher les membre par numero de telephone dans firestorm
      final resultat = await FirebaseFirestore.instance
          .collection('membres')
          .where('telephone', isEqualTo: telephone)
          .limit(1)
          .get();
      if (resultat.docs.isEmpty) {
        // Aucun compte trouver avec  ce numéro

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucun compte trouvé pour ce numéro')),
        );
        setState(() => _pin = '');
        return;
      }

      final membre = resultat.docs.first;

      if (membre['pinHash'] != pinHache) {
        // PIN Incorrect
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Code PIN Incorrect')));
        setState(() => _pin = '');
      }

      //PIN correct - reconnecter l'utilisateur anonymement avec son UID
      await FirebaseAuth.instance.signInAnonymously();

      if (!mounted) return;

      //PIN COrrect: naviger vers le hub (à créer)
      // rediriger selon le role
      final role = membre['role'];
      if (role == 'president' ||
          role == 'tresorier' ||
          role == 'secretaire_general' ||
          role == 'commisaire_compte') {
        Navigator.pushReplacementNamed(context, '/bureau');
      } else {
        Navigator.pushReplacementNamed(context, '/hub');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur de connexion : $e')));
      setState(() => _pin = '');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Logo
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Center(
                  child: Text(
                    'MA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              const Text(
                'MonAmicale',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const Text(
                'Vos tontines, simplement.',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),

              const SizedBox(height: 32),

              //  Champ téléphone
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Numéro de téléphone',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.muted,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _telController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: 'Ex : 6 77 12 34 56',
                  prefixIcon: Icon(Icons.phone_outlined),
                  prefixText: '+237 ',
                ),
              ),

              const SizedBox(height: 24),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Code PIN',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.muted,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              //  Points du PIN
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final rempli = index < _pin.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: rempli ? AppColors.primary : Colors.transparent,
                      border: Border.all(color: AppColors.primary, width: 1.8),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 24),

              // Clavier numérique
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: [
                  ...[
                    '1',
                    '2',
                    '3',
                    '4',
                    '5',
                    '6',
                    '7',
                    '8',
                    '9',
                  ].map((c) => _toucheChiffre(c)),
                  const SizedBox(),
                  _toucheChiffre('0'),
                  _toucheEffacer(),
                ],
              ),

              const SizedBox(height: 24),

              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => RegisterScreen()),
                  );
                },
                child: const Text(
                  'Pas encore de compte ? Créer un compte',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(height: 12),
              const Text(
                'PIN oublié ? Contactez votre trésorier.',
                style: TextStyle(fontSize: 11, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toucheChiffre(String chiffre) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          HapticFeedback.lightImpact();
          _onChiffreAppuye(chiffre);
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              chiffre,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _toucheEffacer() {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          HapticFeedback.lightImpact();
          _onEffacer();
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(child: Icon(Icons.backspace_outlined, size: 20)),
        ),
      ),
    );
  }
}
