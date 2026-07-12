// écran de création de la tontine par les membres autorisés

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme.dart';

class FormalTontineScreen extends StatefulWidget {
  const FormalTontineScreen({super.key});

  @override
  State<FormalTontineScreen> createState() => _FormalTontineScreen();
}

class _FormalTontineScreen extends State<FormalTontineScreen> {
  final _montantController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();

  final _descriptionController = TextEditingController();
  final _solidariteController = TextEditingController(text: '15000');
  final _collationController = TextEditingController(text: '2000');
  final _penaliteController = TextEditingController(text: '0');

  // int? _palierSelectionne;
  int _dureeMois = 10;
  bool _solidariteActive = true;
  bool _collationActive = true;
  bool _penaliteActive = false;
  bool _isLoading = false;

  // final List<int> _paliers = [5000, 10000, 100000];

  @override
  void initState() {
    super.initState();
    _montantController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _montantController.dispose();
    _nomController.dispose();
    _descriptionController.dispose();
    _solidariteController.dispose();
    _collationController.dispose();
    _penaliteController.dispose();
    super.dispose();
  }

  // fonction adapte pour la gestion des erreurs
  Future<void> _creerTontine() async {
    if (!_formKey.currentState!.validate()) return;
    if (_montantController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un montant')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vous n\'êtes pas connecté')),
        );
        setState(() => _isLoading = false);
        return;
      }

      // final uid = user.uid;

      // Récupère le document membre

      // final user = FirebaseAuth.instance.currentUser!;
      final uid = user.uid;

      //cherche d'abord par uid (nouveau systeme)

      DocumentSnapshot membreDoc = await FirebaseFirestore.instance
          .collection('membres')
          .doc(uid)
          .get();

      // si pas trouver chercher par email fictif(migration)

      if (!membreDoc.exists) {
        final email = user.email ?? ' ';
        final telephone = email.replaceAll('@monamicale.app', ' ');

        final resultat = await FirebaseFirestore.instance
            .collection('membres')
            .where('telephone', isEqualTo: telephone)
            .limit(1)
            .get();

        if (resultat.docs.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil introuvable, contactez le bureau'),
            ),
          );
          setState(() => _isLoading = false);
          return;
        }
        // Migration: copie le document sous le nouvel UID

        final ancienDoc = resultat.docs.first;
        final data = ancienDoc.data() as Map<String, dynamic>;

        await FirebaseFirestore.instance
            .collection('membres')
            .doc(uid)
            .set(data);
        membreDoc = await FirebaseFirestore.instance
            .collection('membres')
            .doc(uid)
            .get();
      }

      final nomMembre = membreDoc['nom'] as String;
      final roleMembre = membreDoc['role'] as String;

      // final membreDoc = await FirebaseFirestore.instance
      //     .collection('membres')
      //     .doc(uid)
      //     .get();

      // if (!membreDoc.exists) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(content: Text('Profil introuvable (UID: $uid)')),
      //   );
      //   setState(() => _isLoading = false);
      //   return;
      // }

      // final nomMembre = membreDoc['nom'] as String;
      // final roleMembre = membreDoc['role'] as String;
      final montant = int.tryParse(_montantController.text.trim()) ?? 0;

      // Crée la tontine
      final tontineRef = await FirebaseFirestore.instance
          .collection('tontines')
          .add({
            'type': 'formelle',
            'nom': _nomController.text.trim(),
            'description': _descriptionController.text.trim(),
            'palier': montant,
            'dureeMois': _dureeMois,
            'moisCourant': 1,
            'statut': 'actif',
            'createurUid': uid,
            'createurNom': nomMembre,
            'dateCreation': FieldValue.serverTimestamp(),
            'tauxInteret': 3.0,
            'ordreRedistribution': 'fixe',
            'solidariteActive': _solidariteActive,
            'montantSolidarite': _solidariteActive
                ? int.tryParse(_solidariteController.text) ?? 15000
                : 0,
            'collationActive': _collationActive,
            'montantCollation': _collationActive
                ? int.tryParse(_collationController.text) ?? 2000
                : 0,
            'penaliteActive': _penaliteActive,
            'montantPenalite': _penaliteActive
                ? int.tryParse(_penaliteController.text) ?? 0
                : 0,
          });

      // Crée l'adhésion du créateur
      await FirebaseFirestore.instance
          .collection('tontines')
          .doc(tontineRef.id)
          .collection('adhesions')
          .doc(uid)
          .set({
            'membreUid': uid,
            'membreNom': nomMembre,
            'role': roleMembre,
            'dateAdhesion': FieldValue.serverTimestamp(),
            'statut': 'actif',
            'ordre': 1,
          });
      await FirebaseFirestore.instance.collection('membres').doc(uid).update({
        'tontines': FieldValue.arrayUnion([tontineRef.id]),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tontine créée avec succès !'),
          backgroundColor: Color.fromARGB(255, 76, 160, 79),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur détaillée : $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Ajoute l'id de la tontine dans le document membre

  // Future<void> _creerTontine() async {
  //   if (!_formKey.currentState!.validate()) return;

  //   setState(() => _isLoading = true);

  //   try {
  //     final uid = FirebaseAuth.instance.currentUser!.uid;
  //     final membreDoc = await FirebaseFirestore.instance
  //         .collection('membres')
  //         .doc(uid)
  //         .get();

  //     await FirebaseFirestore.instance.collection('tontines').add({
  //       'type': 'formelle',
  //       'nom': _nomController.text.trim(),
  //       'description': _descriptionController.text.trim(),
  //       'palier': int.tryParse(_montantController.text) ?? 0,
  //       'dureeMois': _dureeMois,
  //       'moisCourant': 1,
  //       'statut': 'actif',
  //       'createurUid': uid,
  //       'createurNom': membreDoc['nom'],
  //       'dateCreation': FieldValue.serverTimestamp(),
  //       'tauxInteret': 3.0,
  //       'ordreRedistribution': 'fixe',
  //       // Solidarité
  //       'solidariteActive': _solidariteActive,
  //       'montantSolidarite': _solidariteActive
  //           ? int.tryParse(_solidariteController.text) ?? 15000
  //           : 0,
  //       // Collation
  //       'collationActive': _collationActive,
  //       'montantCollation': _collationActive
  //           ? int.tryParse(_collationController.text) ?? 2000
  //           : 0,
  //       // Pénalité
  //       'penaliteActive': _penaliteActive,
  //       'montantPenalite': _penaliteActive
  //           ? int.tryParse(_penaliteController.text) ?? 0
  //           : 0,
  //     });

  //     if (!mounted) return;
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Tontine créée avec succès !')),
  //     );
  //     Navigator.pop(context);
  //   } catch (e) {
  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(SnackBar(content: Text('Erreur : $e')));
  //   } finally {
  //     setState(() => _isLoading = false);
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Nouvelle tontine',
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //  Nom
                _label('Nom de la tontine'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nomController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'Ex : MonAmicale — Groupe A',
                    prefixIcon: Icon(Icons.group_outlined),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Veuillez entrer un nom'
                      : null,
                ),

                const SizedBox(height: 20),

                //  Description
                _label('Description (optionnel)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Décrivez cette tontine...',
                  ),
                ),

                const SizedBox(height: 20),

                //  Palier
                _label('Montant de cotisation (FCFA)'),
                const SizedBox(height: 9),
                TextFormField(
                  controller: _montantController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    hintText: 'Ex : 5000, 10000, 50000...',
                    prefixIcon: Icon(Icons.payment_outlined),
                    suffixText: 'FCFA',
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Veuillez entrer un montant';
                    }
                    if ((int.tryParse(v) ?? 0) <= 0) return 'Montant invalide';
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                //  Durée
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _label('Durée du cycle'),
                    Text(
                      '$_dureeMois mois',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _dureeMois.toDouble(),
                  min: 3,
                  max: 24,
                  divisions: 21,
                  activeColor: AppColors.primary,
                  label: '$_dureeMois mois',
                  onChanged: (v) => setState(() => _dureeMois = v.toInt()),
                ),

                const SizedBox(height: 8),

                // ── Solidarité
                _SectionOptionelle(
                  titre: 'Fonds de solidarité',
                  sousTitre:
                      'Contribution périodique pour soutenir les membres',
                  active: _solidariteActive,
                  onToggle: (v) => setState(() => _solidariteActive = v),
                  child: _solidariteActive
                      ? _champMontant(
                          controller: _solidariteController,
                          label: 'Montant (FCFA)',
                          hint: 'Ex : 15000',
                        )
                      : const SizedBox.shrink(),
                ),

                const SizedBox(height: 12),

                //  Collation
                _SectionOptionelle(
                  titre: 'Collation mensuelle',
                  sousTitre: 'Contribution mensuelle pour la collation',
                  active: _collationActive,
                  onToggle: (v) => setState(() => _collationActive = v),
                  child: _collationActive
                      ? _champMontant(
                          controller: _collationController,
                          label: 'Montant (FCFA)',
                          hint: 'Ex : 2000',
                        )
                      : const SizedBox.shrink(),
                ),

                const SizedBox(height: 12),

                //  Pénalité
                _SectionOptionelle(
                  titre: 'Pénalité (bavardage, retard…)',
                  sousTitre: 'Sanction configurable appliquée en réunion',
                  active: _penaliteActive,
                  onToggle: (v) => setState(() => _penaliteActive = v),
                  child: _penaliteActive
                      ? _champMontant(
                          controller: _penaliteController,
                          label: 'Montant (FCFA)',
                          hint: 'Ex : 500',
                        )
                      : const SizedBox.shrink(),
                ),

                const SizedBox(height: 20),

                //  Récapitulatif
                if (_montantController.text.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
                      ),
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
                          'Cotisation mensuelle',
                          '${_montantController.text.isEmpty ? '-' : _montantController.text} FCFA',
                        ),
                        _ligne('Durée', '$_dureeMois mois'),
                        _ligne(
                          'Cagnotte totale',
                          '${(int.tryParse(_montantController.text.trim()) ?? 0) * _dureeMois} FCFA',
                        ),
                        if (_solidariteActive)
                          _ligne(
                            'Solidarité',
                            '${_solidariteController.text} FCFA',
                          ),
                        if (_collationActive)
                          _ligne(
                            'Collation / mois',
                            '${_collationController.text} FCFA',
                          ),
                        if (_penaliteActive)
                          _ligne(
                            'Pénalité',
                            '${_penaliteController.text} FCFA',
                          ),
                      ],
                    ),
                  ),

                const SizedBox(height: 32),

                // Bouton créer
                ElevatedButton(
                  onPressed: _isLoading ? null : _creerTontine,
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

  //  Widgets helpers

  Widget _label(String texte) {
    return Text(
      texte,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 13,
        color: AppColors.muted,
      ),
    );
  }

  Widget _champMontant({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          suffixText: 'FCFA',
        ),
      ),
    );
  }

  Widget _ligne(String label, String valeur) {
    return Padding(
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
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

//  Widget section optionnelle réutilisable
class _SectionOptionelle extends StatelessWidget {
  final String titre;
  final String sousTitre;
  final bool active;
  final ValueChanged<bool> onToggle;
  final Widget child;

  const _SectionOptionelle({
    required this.titre,
    required this.sousTitre,
    required this.active,
    required this.onToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 2,
            ),
            title: Text(
              titre,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
              ),
            ),
            subtitle: Text(
              sousTitre,
              style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
            ),
            trailing: Switch(
              value: active,
              onChanged: onToggle,
              activeColor: AppColors.primary,
            ),
          ),
          if (active)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: child,
            ),
        ],
      ),
    );
  }
}
