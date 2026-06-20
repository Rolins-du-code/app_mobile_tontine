import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'otp_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Contrôleurs : permettent de lire ce que l'utilisateur tape
  final _nomController = TextEditingController();
  final _telController = TextEditingController();

  // Clé du formulaire : permet de valider les champs
  final _formKey = GlobalKey<FormState>();

  // Libère la mémoire quand l'écran est fermé
  @override
  void dispose() {
    _nomController.dispose();
    _telController.dispose();
    super.dispose();
  }

  // Appelée quand on appuie sur "Continuer"
  void _continuer() {
    if (_formKey.currentState!.validate()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpScreen(telephone: _telController.text.trim()),
        ),
      );
      // Pour l'instant on affiche juste un message
      // Plus tard : on navigue vers la vérification SMS
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Code SMS envoyé !')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                Center(
                  child: Container(
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
                ),

                const SizedBox(height: 20),

                // Titre
                const Center(
                  child: Text(
                    'Créer votre compte',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                ),
                const Center(
                  child: Text(
                    'Rejoignez votre première tontine',
                    style: TextStyle(color: AppColors.muted),
                  ),
                ),

                const SizedBox(height: 24),

                // Indicateur d'étapes
                _StepIndicator(currentStep: 1, totalSteps: 3),

                const SizedBox(height: 28),

                // Champ Nom
                const Text(
                  'Nom complet',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nomController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'Ex : votre nom',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez entrer votre nom complet';
                    }
                    if (value.trim().length < 3) {
                      return 'Nom trop court';
                    }
                    return null; // null = valide
                  },
                ),

                const SizedBox(height: 20),

                //  Champ Téléphone
                const Text(
                  'Numéro de téléphone',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.muted,
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
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez entrer votre numéro';
                    }
                    if (value.trim().length < 9) {
                      return 'Numéro invalide';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // Bouton Continuer
                ElevatedButton(
                  onPressed: _continuer,
                  child: const Text(
                    'Continuer',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),

                const SizedBox(height: 16),

                //  Lien connexion
                Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    child: RichText(
                      text: const TextSpan(
                        text: 'Vous avez déjà un compte ? ',
                        style: TextStyle(color: AppColors.muted),
                        children: [
                          TextSpan(
                            text: 'Se connecter',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Widget réutilisable : indicateur d'étapes ──────────
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
            final isActive = index < currentStep;
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: index < totalSteps - 1 ? 6 : 0),
                height: 4,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : AppColors.border,
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
