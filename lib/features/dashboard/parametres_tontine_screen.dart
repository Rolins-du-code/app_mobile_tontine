// interface pour modifier les paramètres de la tontine

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme.dart';

class ParametresTontineScreen extends StatefulWidget {
  final String tontineId;
  final Map<String, dynamic> tontineData;

  const ParametresTontineScreen({
    super.key,
    required this.tontineId,
    required this.tontineData,
  });

  @override
  State<ParametresTontineScreen> createState() =>
      _ParametresTontineScreenState();
}

class _ParametresTontineScreenState extends State<ParametresTontineScreen> {
  late String _jourLimite;
  late TimeOfDay _heureLimite;
  late int _delaiGraceHeures;
  late double _tauxInteret;
  late String _typeInteret;
  bool _isLoading = false;

  final List<String> _jours = [
    'lundi',
    'mardi',
    'mercredi',
    'jeudi',
    'vendredi',
    'samedi',
    'dimanche',
  ];

  @override
  void initState() {
    super.initState();
    // Charge les valeurs actuelles
    _jourLimite = widget.tontineData['jourLimite'] as String? ?? 'mercredi';
    _delaiGraceHeures = widget.tontineData['delaiGraceHeures'] as int? ?? 0;

    // Parse l'heure stockée "HH:mm"
    final hStr = widget.tontineData['heureLimite'] as String? ?? '20:00';
    final parts = hStr.split(':');
    _heureLimite = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 20,
      minute: int.tryParse(parts[1]) ?? 0,
    );
    _tauxInteret =
        (widget.tontineData['tauxInteret'] as num?)?.toDouble() ?? 3.0;
    _typeInteret = widget.tontineData['typeInteret'] as String? ?? 'simple';
  }

  Future<void> _sauvegarder() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('tontines')
          .doc(widget.tontineId)
          .update({
            'jourLimite': _jourLimite,
            'heureLimite':
                '${_heureLimite.hour.toString().padLeft(2, '0')}:'
                '${_heureLimite.minute.toString().padLeft(2, '0')}',
            'delaiGraceHeures': _delaiGraceHeures,
            'taux-Intéret': _tauxInteret,
            'type-Intéret': _typeInteret,
          });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paramètres mis à jour !'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur : $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Paramètres de la tontine',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Délai limite
              const Text(
                'Délai limite de paiement',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              const Text(
                'Modifiable à chaque session ou renouvellement.',
                style: TextStyle(fontSize: 13, color: AppColors.muted),
              ),
              const SizedBox(height: 20),

              const SizedBox(height: 28),

              const Text(
                'Paraétres des emprunts',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),

              const SizedBox(height: 6),
              const Text(
                'Applicable à tous les nouveaux emprunts.',
                style: TextStyle(fontSize: 13, color: AppColors.muted),
              ),
              const SizedBox(height: 20),

              // Taux d'interet
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Taux d\'intéret mensuel',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.muted,
                    ),
                  ),
                  Text(
                    '${_tauxInteret.toStringAsFixed(1)} %',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _tauxInteret,
                min: 0,
                max: 30,
                divisions: 40,
                activeColor: AppColors.primary,
                label: '${_tauxInteret.toStringAsFixed(1)} %',
                onChanged: (v) => setState(() => _tauxInteret = v),
              ),
              const SizedBox(height: 16),

              // Type d'interet
              const Text(
                'Type d\'interet',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 10),

              // Carte interet simple
              GestureDetector(
                onTap: () => setState(() => _typeInteret = 'simple'),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _typeInteret == 'simple'
                        ? AppColors.primary.withOpacity(0.06)
                        : AppColors.card,
                    border: Border.all(
                      color: _typeInteret == 'simple'
                          ? AppColors.primary
                          : AppColors.border,
                      width: _typeInteret == 'simple' ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _typeInteret == 'simple'
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: _typeInteret == 'simple'
                            ? AppColors.primary
                            : AppColors.muted,
                      ),

                      const SizedBox(height: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Interet simple ',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Calculé une fois sur le capital initial. \n'
                              'Ex : 100 000 x 3% x 4 mois = 12 000 FCFA d\'intérets',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.muted,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Carte d'interes composé
              GestureDetector(
                onTap: () => setState(() => _tauxInteret = 'compose' as double),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _typeInteret == 'compose'
                        ? AppColors.primary.withOpacity(0.06)
                        : AppColors.card,
                    border: Border.all(
                      color: _typeInteret == 'compose'
                          ? AppColors.primary
                          : AppColors.border,
                      width: _typeInteret == 'compose' ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _typeInteret == 'compose'
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: _typeInteret == 'compose'
                            ? AppColors.primary
                            : AppColors.muted,
                      ),
                      const SizedBox(height: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Interet compose',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Recalcule chaque mois sur le capital restant. \n'
                              'Génère plus d\'interets sur la durée.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.muted,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Jour
              const Text(
                'Jour limite',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _jourLimite,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
                items: _jours
                    .map(
                      (j) => DropdownMenuItem(
                        value: j,
                        child: Text(j[0].toUpperCase() + j.substring(1)),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _jourLimite = v!),
              ),

              const SizedBox(height: 20),

              // Heure
              const Text(
                'Heure limite',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final h = await showTimePicker(
                    context: context,
                    initialTime: _heureLimite,
                    builder: (context, child) => MediaQuery(
                      data: MediaQuery.of(
                        context,
                      ).copyWith(alwaysUse24HourFormat: true),
                      child: child!,
                    ),
                  );
                  if (h != null) {
                    setState(() => _heureLimite = h);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        color: AppColors.muted,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${_heureLimite.hour.toString().padLeft(2, '0')}:'
                        '${_heureLimite.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Appuyer pour modifier',
                        style: TextStyle(fontSize: 11, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Délai de grâce
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Délai de grâce',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.muted,
                    ),
                  ),
                  Text(
                    _delaiGraceHeures == 0
                        ? 'Aucun'
                        : '$_delaiGraceHeures h après la limite',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _delaiGraceHeures.toDouble(),
                min: 0,
                max: 48,
                divisions: 12,
                activeColor: AppColors.primary,
                label: _delaiGraceHeures == 0
                    ? 'Aucun'
                    : '$_delaiGraceHeures h',
                onChanged: (v) => setState(() => _delaiGraceHeures = v.toInt()),
              ),

              const SizedBox(height: 12),
              // Résumé
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Récapitulatif',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _ligne(
                      'Jour limite',
                      _jourLimite[0].toUpperCase() + _jourLimite.substring(1),
                    ),
                    _ligne(
                      'Heure limite',
                      '${_heureLimite.hour.toString().padLeft(2, '0')}:${_heureLimite.minute.toString().padLeft(2, '0')}',
                    ),
                    _ligne(
                      'Délai de grâce',
                      _delaiGraceHeures == 0
                          ? 'Aucun'
                          : '$_delaiGraceHeures heures',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isLoading ? null : _sauvegarder,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Enregistrer les modifications',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ligne(String label, String valeur) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.muted),
        ),
        Text(
          valeur,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}
