// ecrant pour les tontine informel les totine reserver au jeunne qui ne possaide pas trop de paramettre

 import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme.dart';

class InformalTontineScreen extends StatefulWidget {
  const InformalTontineScreen({super.key});

  @override
  State<InformalTontineScreen> createState() =>
      _InformalTontineScreenState();
}

class _InformalTontineScreenState extends State<InformalTontineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _montantController = TextEditingController();
  final _penaliteController = TextEditingController(text: '500');

  // Fréquence
  String _frequence = 'hebdomadaire';
  final List<Map<String, String>> _frequences = [
    {'valeur': 'hebdomadaire', 'label': 'Chaque semaine'},
    {'valeur': 'bimensuelle', 'label': 'Toutes les 2 semaines'},
    {'valeur': 'mensuelle', 'label': 'Chaque mois'},
  ];

  // Jour limite
  String _jourLimite = 'samedi';
  final List<String> _jours = [
    'lundi', 'mardi', 'mercredi', 'jeudi',
    'vendredi', 'samedi', 'dimanche'
  ];

  // Heure limite
  TimeOfDay _heureLimite = const TimeOfDay(hour: 20, minute: 0);

  // Pénalité
  bool _penaliteActive = true;
  int _delaiGraceHeures = 0;

  // Reconduction
  bool _reconductionAuto = false;

  bool _isLoading = false;

  @override
  void dispose() {
    _nomController.dispose();
    _montantController.dispose();
    _penaliteController.dispose();
    super.dispose();
  }

  Future<void> _choisirHeure() async {
    final heure = await showTimePicker(
      context: context,
      initialTime: _heureLimite,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (heure != null) setState(() => _heureLimite = heure);
  }

  Future<void> _creerTontine() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final membreDoc = await FirebaseFirestore.instance
          .collection('membres')
          .doc(uid)
          .get();

      await FirebaseFirestore.instance.collection('tontines').add({
        'type': 'informelle',
        'nom': _nomController.text.trim(),
        'montantCotisation': int.tryParse(
                _montantController.text) ?? 0,
        'frequence': _frequence,
        'jourLimite': _jourLimite,
        'heureLimite':
            '${_heureLimite.hour.toString().padLeft(2, '0')}:'
            '${_heureLimite.minute.toString().padLeft(2, '0')}',
        'penaliteActive': _penaliteActive,
        'montantPenalite': _penaliteActive
            ? int.tryParse(_penaliteController.text) ?? 0
            : 0,
        'delaiGraceHeures': _delaiGraceHeures,
        'reconductionAuto': _reconductionAuto,
        'statut': 'actif',
        'tourCourant': 1,
        'createurUid': uid,
        'createurNom': membreDoc['nom'],
        'dateCreation': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tontine créée avec succès !')),
      );
      Navigator.pop(context);
      Navigator.pop(context); // ← revient à l'écran de choix
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tontine informelle',
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
          padding: const EdgeInsets.symmetric(
              horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Nom 
                _label('Nom du groupe'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nomController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'Ex : Tontine amis lycée',
                    prefixIcon: Icon(Icons.group_outlined),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Veuillez entrer un nom'
                      : null,
                ),

                const SizedBox(height: 20),

                //  Montant 
                _label('Montant de cotisation (FCFA)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _montantController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly
                  ],
                  decoration: const InputDecoration(
                    hintText: 'Ex : 5000',
                    prefixIcon: Icon(Icons.payments_outlined),
                    suffixText: 'FCFA',
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Veuillez entrer un montant';
                    }
                    if ((int.tryParse(v) ?? 0) <= 0) {
                      return 'Montant invalide';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Fréquence
                _label('Fréquence de cotisation'),
                const SizedBox(height: 10),
                ..._frequences.map((f) {
                  final sel = _frequence == f['valeur'];
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _frequence = f['valeur']!),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: sel
                            ? AppColors.success.withOpacity(0.08)
                            : AppColors.card,
                        border: Border.all(
                          color: sel
                              ? AppColors.success
                              : AppColors.border,
                          width: sel ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            sel
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: sel
                                ? AppColors.success
                                : AppColors.muted,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            f['label']!,
                            style: TextStyle(
                              fontWeight: sel
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: sel
                                  ? AppColors.success
                                  : AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 20),

                //  Délai limite 
                _label('Délai limite de paiement'),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Jour',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.muted)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _jourLimite,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                            items: _jours.map((j) =>
                              DropdownMenuItem(
                                value: j,
                                child: Text(
                                  j[0].toUpperCase() + j.substring(1),
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ).toList(),
                            onChanged: (v) =>
                                setState(() => _jourLimite = v!),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Heure',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.muted)),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: _choisirHeure,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 13),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                border: Border.all(
                                    color: AppColors.border),
                                borderRadius:
                                    BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${_heureLimite.hour.toString().padLeft(2, '0')}:${_heureLimite.minute.toString().padLeft(2, '0')}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Icon(Icons.access_time,
                                      size: 16,
                                      color: AppColors.muted),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                //  Délai de grâce 
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _label('Délai de grâce'),
                    Text(
                      _delaiGraceHeures == 0
                          ? 'Aucun'
                          : '$_delaiGraceHeures h après la limite',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
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
                  activeColor: AppColors.success,
                  label: _delaiGraceHeures == 0
                      ? 'Aucun'
                      : '$_delaiGraceHeures h',
                  onChanged: (v) =>
                      setState(() => _delaiGraceHeures = v.toInt()),
                ),

                const SizedBox(height: 8),

                // Pénalité 
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        title: const Text('Pénalité de retard',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5)),
                        subtitle: const Text(
                          'Montant ajouté automatiquement après le délai',
                          style: TextStyle(
                              fontSize: 11.5,
                              color: AppColors.muted)),
                        trailing: Switch(
                          value: _penaliteActive,
                          onChanged: (v) =>
                              setState(() => _penaliteActive = v),
                          activeColor: AppColors.success,
                        ),
                      ),
                      if (_penaliteActive)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                              14, 0, 14, 14),
                          child: TextFormField(
                            controller: _penaliteController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Montant pénalité (FCFA)',
                              hintText: 'Ex : 500',
                              suffixText: 'FCFA',
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
                     //  Reconduction 
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    title: const Text(
                      'Reconduction automatique',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5),
                    ),
                    subtitle: const Text(
                      'Relance le cycle automatiquement après le '
                      'dernier tour',
                      style: TextStyle(
                          fontSize: 11.5, color: AppColors.muted),
                    ),
                    trailing: Switch(
                      value: _reconductionAuto,
                      onChanged: (v) =>
                          setState(() => _reconductionAuto = v),
                      activeColor: AppColors.success,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                //  Récapitulatif 
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.success.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Récapitulatif',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        )),
                      const SizedBox(height: 8),
                      _ligne('Fréquence', _frequences.firstWhere(
                          (f) => f['valeur'] == _frequence)['label']!),
                      _ligne('Délai limite',
                          '${_jourLimite[0].toUpperCase()}${_jourLimite.substring(1)} à ${_heureLimite.hour.toString().padLeft(2, '0')}:${_heureLimite.minute.toString().padLeft(2, '0')}'),
                      if (_penaliteActive)
                        _ligne('Pénalité de retard',
                            '${_penaliteController.text} FCFA'),
                      _ligne('Reconduction',
                          _reconductionAuto ? 'Automatique' : 'Manuelle'),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                //  Bouton créer
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                  ),
                  onPressed: _isLoading ? null : _creerTontine,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Créer la tontine',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String texte) => Text(
    texte,
    style: const TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 13,
      color: AppColors.muted,
    ),
  );
 Widget _ligne(String label, String valeur) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
          style: const TextStyle(
              fontSize: 13, color: AppColors.muted)),
        Text(valeur,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          )),
      ],
    ),
  );
}