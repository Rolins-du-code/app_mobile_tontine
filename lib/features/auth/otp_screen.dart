import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';
import 'pin_screen.dart';

class OtpScreen extends StatefulWidget {
  final String telephone;

  const OtpScreen({super.key, required this.telephone});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  // Un contrôleur par case OTP
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());

  // Un FocusNode par case (pour passer auto à la suivante)
  final List<FocusNode> _focusNodes =
      List.generate(6, (_) => FocusNode());

  // Compte à rebours pour "Renvoyer le code"
  int _secondsLeft = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          _canResend = true;
        }
      });
      return _secondsLeft > 0;
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  // Récupère le code complet (les 6 chiffres collés)
  String get _codeComplet =>
      _controllers.map((c) => c.text).join();

  void _verifier() {
    if (_codeComplet.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entrez les 6 chiffres du code')),
      );
      return;
    }

    // Pour l'instant on accepte n'importe quel code à 6 chiffres
    // Plus tard Firebase vérifiera le vrai code SMS
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PinScreen(telephone: widget.telephone),
      ),
    );
  }

  void _onChiffreSaisi(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      // Passe automatiquement à la case suivante
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      // Revient à la case précédente si on efface
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Icône 
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.sms_outlined,
                    color: AppColors.primary,
                    size: 32,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              //  Titre
              const Center(
                child: Text(
                  'Vérifiez votre téléphone',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Code envoyé au +237 ${widget.telephone}',
                  style: const TextStyle(color: AppColors.muted),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 24),

              //  Indicateur d'étapes 
              _StepIndicator(currentStep: 2, totalSteps: 3),

              const SizedBox(height: 36),

              // Cases OTP 
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 46,
                    height: 54,
                    child: TextFormField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        counterText: '',
                        contentPadding: EdgeInsets.zero,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: _controllers[index].text.isNotEmpty
                                ? AppColors.primary
                                : AppColors.border,
                            width: _controllers[index].text.isNotEmpty ? 2 : 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (value) => _onChiffreSaisi(value, index),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 24),

              // Compte à rebours / Renvoyer
              Center(
                child: _canResend
                    ? TextButton(
                        onPressed: () {
                          setState(() {
                            _secondsLeft = 60;
                            _canResend = false;
                            for (final c in _controllers) c.clear();
                          });
                          _startTimer();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Code renvoyé !')),
                          );
                        },
                        child: const Text(
                          'Renvoyer le code',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : Text(
                        'Renvoyer le code (00:${_secondsLeft.toString().padLeft(2, '0')})',
                        style: const TextStyle(color: AppColors.muted),
                      ),
              ),

              const Spacer(),
                 //  Bouton Vérifier
              ElevatedButton(
                onPressed: _codeComplet.length == 6 ? _verifier : null,
                child: const Text(
                  'Vérifier',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}



// Indicateur d'étapes (réutilisé) 
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