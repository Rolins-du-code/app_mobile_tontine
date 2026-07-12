// page de création du code PIN, c'est la troisième étape du processus d'authentification ( après le splash screen, l'enregistrement et la vérification OTP )
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';

class PinScreen extends StatefulWidget {
  final String telephone;
  final String nom;

  const PinScreen({super.key, required this.telephone, required this.nom});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  // On stocke le PIN tapé (string de chiffres)
  String _pin = '';

  // Étape interne : créer le PIN, puis le confirmer
  bool _modeConfirmation = false;
  String _pinTemporaire = '';

  void _onChiffreAppuye(String chiffre) {
    if (_pin.length >= 4) return;

    setState(() {
      _pin += chiffre;
    });

    // Quand les 4 chiffres sont entrés
    if (_pin.length == 4) {
      Future.delayed(const Duration(milliseconds: 200), _onPinComplet);
    }
  }

  void _onEffacer() {
    if (_pin.isEmpty) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  void _onPinComplet() {
    if (!_modeConfirmation) {
      // Première saisie : on passe en mode confirmation
      setState(() {
        _pinTemporaire = _pin;
        _pin = '';
        _modeConfirmation = true;
      });
    } else {
      // Confirmation : on vérifie que ça correspond
      if (_pin == _pinTemporaire) {
        _terminerInscription();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Les codes ne correspondent pas, recommencez'),
          ),
        );
        setState(() {
          _pin = '';
          _pinTemporaire = '';
          _modeConfirmation = false;
        });
      }
    }
  }

  Future<void> _terminerInscription() async {
    final pinHache = sha256.convert(utf8.encode(_pin)).toString();

    try {
      // Crée un vrai compte Firebase avec email fictif + pin hache
      final telephone = widget.telephone.replaceAll(' ', ' ');
      final emailFictif = '$telephone@monamical.app';

      final UserCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailFictif,
            password: pinHache,
          );

      final uid = UserCredential.user!.uid;

      //Sauvegarde le profil dans FireStore
      await FirebaseFirestore.instance.collection('membres').doc(uid).set({
        'nom': widget.nom,
        'telephone': telephone,
        'role': 'membre',
        'telephoneVérifié': false,
        'statutValidation': 'en_attente',
        'dateInscription': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Compte créé !'),
          content: const Text(
            'Votre compte a été créé avec succès. '
            'Vous pourrez rejoindre une tontine dès '
            'que votre numéro sera validé par le bureau. ',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: const Text('Continuer'),
            ),
          ],
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Erreur lors de la création du compte';
      if (e.code == 'email-already-in-use') {
        message = 'Ce numéro est déjà associé à un compte ';
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }
  // void _terminerInscription() {
  //   // Ici, plus tard : on hachera le PIN et on l'enverra à Firebase
  //   // Pour l'instant on affiche juste une confirmation
  //   showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (_) => AlertDialog(
  //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  //       title: const Text('Compte créé !'),
  //       content: const Text(
  //         'Votre compte a été créé avec succès. '
  //         'Vous pourrez rejoindre une tontine dès que votre numéro '
  //         'sera validé par le bureau.',
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () {
  //             // Plus tard : navigation vers le Hub
  //             Navigator.popUntil(context, (route) => route.isFirst);
  //           },
  //           child: const Text('Continuer'),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textDark),
          onPressed: () {
            if (_modeConfirmation) {
              // Si on est en confirmation, on revient à la création
              setState(() {
                _modeConfirmation = false;
                _pin = '';
                _pinTemporaire = '';
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 8),

              //  Icône
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.lock_outline,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),

              const SizedBox(height: 20),
              //  Titre dynamique
              Text(
                _modeConfirmation
                    ? 'Confirmez votre code PIN'
                    : 'Créez votre code PIN',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _modeConfirmation
                    ? 'Retapez le même code'
                    : '4 chiffres, à utiliser à chaque connexion',
                style: const TextStyle(color: AppColors.muted),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              //  Indicateur d'étapes
              _StepIndicator(currentStep: 3, totalSteps: 3),

              const SizedBox(height: 40),

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

              const Spacer(),

              //  Clavier numérique
              _Keypad(onChiffre: _onChiffreAppuye, onEffacer: _onEffacer),

              const SizedBox(height: 16),

              const Text(
                'Ce code vous sera redemandé à chaque connexion',
                style: TextStyle(fontSize: 11, color: AppColors.muted),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// Clavier numérique réutilisable
class _Keypad extends StatelessWidget {
  final void Function(String) onChiffre;
  final VoidCallback onEffacer;

  const _Keypad({required this.onChiffre, required this.onEffacer});

  @override
  Widget build(BuildContext context) {
    // Liste des touches : null = case vide, 'back' = effacer
    final touches = [
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '',
      '0',
      'back',
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: touches.map((touche) {
        if (touche.isEmpty) {
          return const SizedBox(); // case vide
        }

        if (touche == 'back') {
          return _KeypadButton(
            child: const Icon(Icons.backspace_outlined, size: 20),
            onTap: onEffacer,
          );
        }

        return _KeypadButton(
          child: Text(
            touche,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          onTap: () => onChiffre(touche),
        );
      }).toList(),
    );
  }
}

class _KeypadButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const _KeypadButton({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          HapticFeedback.lightImpact(); // petite vibration au toucher
          onTap();
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

// Indicateur d'étapes (réutilisé une 3e fois)
class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const _StepIndicator({required this.currentStep, required this.totalSteps});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ÉTAPE $currentStep SUR $totalSteps',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.muted,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(totalSteps, (index) {
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: index < totalSteps - 1 ? 6 : 0),
                height: 4,
                decoration: BoxDecoration(
                  color: index < currentStep
                      ? AppColors.primary
                      : AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
