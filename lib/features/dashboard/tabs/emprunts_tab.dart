// section empreunts pour le dashboard du tresorier de la tontine

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import '../../../core/notification_service.dart';
import '../../../core/theme.dart';

class EmpruntsTab extends StatelessWidget {
  final String tontineId;
  final String role;
  final bool estBureau;
  final Map<String, dynamic> tontineData;

  const EmpruntsTab({
    super.key,
    required this.tontineId,
    required this.role,
    required this.estBureau,
    required this.tontineData,
  });

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return DefaultTabController(
      length: estBureau ? 3 : 2,
      child: Column(
        children: [
          Container(
            color: AppColors.card,
            child: TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.muted,
              indicatorColor: AppColors.primary,
              tabs: [
                const Tab(text: 'Mes emprunts'),
                const Tab(text: 'Demander'),
                if (estBureau) const Tab(text: 'Validation'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _MesEmprunts(tontineId: tontineId, uid: uid),
                _DemandeEmprunt(
                  tontineId: tontineId,
                  uid: uid,
                  tontineData: tontineData,
                ),
                if (estBureau)
                  _ValidationEmprunts(
                    tontineId: tontineId,
                    tontineData: tontineData, role: '$role',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

//  Mes emprunts
class _MesEmprunts extends StatelessWidget {
  final String tontineId;
  final String uid;

  const _MesEmprunts({required this.tontineId, required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tontines')
          .doc(tontineId)
          .collection('emprunts')
          .where('demandeurUid', isEqualTo: uid)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final emprunts = snap.data?.docs ?? [];

        if (emprunts.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.handshake_outlined,
                  size: 50,
                  color: AppColors.muted,
                ),
                SizedBox(height: 12),
                Text(
                  'Aucun emprunt',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 6),
                Text(
                  'Vos emprunts apparaîtront ici.',
                  style: TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: emprunts.length,
          itemBuilder: (context, i) {
            final e = emprunts[i].data() as Map<String, dynamic>;
            return _CarteEmprunt(
              data: e,
              afficherRemboursement: false,
              onRembourser: null,
            );
          },
        );
      },
    );
  }
}

//  Demande d'emprunt
class _DemandeEmprunt extends StatefulWidget {
  final String tontineId;
  final String uid;
  final Map<String, dynamic> tontineData;
  const _DemandeEmprunt({
    required this.tontineId,
    required this.uid,
    required this.tontineData,
  });

  @override
  State<_DemandeEmprunt> createState() => _DemandeEmpruntState();
}

class _DemandeEmpruntState extends State<_DemandeEmprunt> {
  final _formKey = GlobalKey<FormState>();
  final _montantController = TextEditingController();
  final _motifController = TextEditingController();
  int _dureeMois = 1;
  bool _isLoading = false;

  // Durée max = durée de la tontine (synchronisée)
  int get _dureeTontine => widget.tontineData['dureeMois'] as int? ?? 12;

  // Taux et type d'intérêt depuis la config tontine
  double get _taux =>
      (widget.tontineData['tauxInteret'] as num?)?.toDouble() ?? 3.0;
  String get _typeInteret =>
      widget.tontineData['typeInteret'] as String? ?? 'simple';
  bool get _interetsActifs => _taux > 0;

  @override
  void initState() {
    super.initState();
    // Durée par défaut = 1 mois mais max = durée tontine
    _dureeMois = 1;
    _montantController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _montantController.dispose();
    _motifController.dispose();
    super.dispose();
  }

  // Calcule le remboursement selon le type d'intérêt
  Map<String, double> _calculer(int capital) {
    if (capital <= 0 || !_interetsActifs) {
      return {
        'totalInterets': 0,
        'total': capital.toDouble(),
        'mensualite': capital / _dureeMois,
      };
    }

    final r = _taux / 100;
    double totalInterets;
    double mensualite;

    if (_typeInteret == 'simple') {
      totalInterets = capital * r * _dureeMois;
      mensualite = (capital + totalInterets) / _dureeMois;
    } else {
      // Intérêt composé
      if (r == 0) {
        mensualite = capital / _dureeMois;
        totalInterets = 0;
      } else {
        mensualite =
            capital *
            (r * pow(1 + r, _dureeMois)) /
            (pow(1 + r, _dureeMois) - 1);
        totalInterets = (mensualite * _dureeMois) - capital;
      }
    }

    return {
      'totalInterets': totalInterets,
      'total': capital + totalInterets,
      'mensualite': mensualite,
    };
  }

  Future<void> _soumettre() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Vérifie si un emprunt est déjà en cours
      final existant = await FirebaseFirestore.instance
          .collection('tontines')
          .doc(widget.tontineId)
          .collection('emprunts')
          .where('demandeurUid', isEqualTo: widget.uid)
          .where('statut', whereIn: ['en_attente', 'approuve'])
          .limit(1)
          .get();

      if (existant.docs.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vous avez déjà un emprunt en cours.'),
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      final membreDoc = await FirebaseFirestore.instance
          .collection('membres')
          .doc(widget.uid)
          .get();

      final nom = membreDoc['nom'] as String? ?? '';
      final capital = int.tryParse(_montantController.text.trim()) ?? 0;
      final calc = _calculer(capital);

      await FirebaseFirestore.instance
          .collection('tontines')
          .doc(widget.tontineId)
          .collection('emprunts')
          .add({
            'demandeurUid': widget.uid,
            'demandeurNom': nom,
            'montant': capital,
            'motif': _motifController.text.trim(),
            'dureeMois': _dureeMois,
            'statut': 'en_attente',
            'montantRembourse': 0,
            'tauxInteret': _taux,
            'typeInteret': _typeInteret,
            'totalInterets': calc['totalInterets']!.toStringAsFixed(0),
            'totalARembourser': calc['total']!.toStringAsFixed(0),
            'mensualiteEstimee': calc['mensualite']!.toStringAsFixed(0),
            'dateCreation': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;

      _montantController.clear();
      _motifController.clear();
      setState(() => _dureeMois = 1);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Demande envoyée ! En attente de validation.'),
          backgroundColor: AppColors.success,
        ),
      );
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
    final capital = int.tryParse(_montantController.text) ?? 0;
    final calc = _calculer(capital);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Faire une demande d\'emprunt',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Votre demande sera examinée par le trésorier.',
              style: TextStyle(fontSize: 13, color: AppColors.muted),
            ),

            const SizedBox(height: 24),

            // Montant
            const Text(
              'Montant souhaité',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _montantController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                hintText: 'Ex : 50000',
                prefixIcon: Icon(Icons.payments_outlined),
                suffixText: 'FCFA',
              ),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return 'Entrez un montant';
                }
                if ((int.tryParse(v) ?? 0) <= 0) {
                  return 'Montant invalide';
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            // ── Durée (synchronisée avec la tontine) ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Durée de remboursement',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.muted,
                  ),
                ),
                Text(
                  '$_dureeMois / $_dureeTontine mois',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            Slider(
              value: _dureeMois.toDouble(),
              // Max = durée de la tontine, pas 12 fixe
              min: 1,
              max: _dureeTontine.toDouble(),
              divisions: _dureeTontine - 1,
              activeColor: AppColors.primary,
              label: '$_dureeMois mois',
              onChanged: (v) => setState(() => _dureeMois = v.toInt()),
            ),
            Text(
              'Maximum : $_dureeTontine mois '
              '(durée de la tontine)',
              style: const TextStyle(fontSize: 11, color: AppColors.muted),
            ),

            const SizedBox(height: 20),

            //  Motif
            const Text(
              'Motif de l\'emprunt',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _motifController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText:
                    'Expliquez brièvement l\'objet '
                    'de votre demande...',
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Entrez un motif' : null,
            ),

            // ── Simulation (uniquement si taux > 0) ──
            if (capital > 0) ...[
              const SizedBox(height: 20),
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
                    Row(
                      children: [
                        const Icon(
                          Icons.calculate_outlined,
                          color: AppColors.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _interetsActifs
                              ? 'Simulation · intérêt $_typeInteret'
                              : 'Simulation · sans intérêt',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _ligne('Capital', '$capital FCFA'),
                    if (_interetsActifs) ...[
                      _ligne(
                        'Taux mensuel',
                        '${_taux.toStringAsFixed(1)} %'
                            ' · $_typeInteret',
                      ),
                      _ligne(
                        'Intérêts totaux',
                        '${calc['totalInterets']!.toStringAsFixed(0)} FCFA',
                      ),
                    ],
                    _ligne(
                      'Total à rembourser',
                      '${calc['total']!.toStringAsFixed(0)} FCFA',
                    ),
                    _ligne(
                      'Mensualité estimée',
                      '${calc['mensualite']!.toStringAsFixed(0)} FCFA / mois',
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _isLoading ? null : _soumettre,
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
                      'Soumettre la demande',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ligne(String label, String valeur) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        Text(
          valeur,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

// Validation (bureau)
class _ValidationEmprunts extends StatelessWidget {
  final String tontineId;
  final Map<String, dynamic> tontineData;
  final String role;

  const _ValidationEmprunts({
    required this.tontineId,
    required this.tontineData,
    required this.role,
  });

  // Ce que chaque rôle peut faire
  bool get _peutValiderTresorier =>
      role == 'tresorier';
  bool get _peutValiderCommissaire =>
      role == 'commissaire_comptes';
  bool get _peutApprouverPresident =>
      role == 'president';
  bool get _lectureSeule =>
      role == 'secretaire_general';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Bandeau rôle
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 10),
          color: AppColors.card,
          child: Row(
            children: [
              const Icon(Icons.info_outline,
                  size: 16, color: AppColors.muted),
              const SizedBox(width: 8),
              Text(
                _lectureSeule
                    ? 'Secrétaire — lecture seule'
                    : _peutValiderTresorier
                        ? 'Trésorier — valide la disponibilité des fonds'
                        : _peutValiderCommissaire
                            ? 'Commissaire — valide la conformité'
                            : 'Président — approuve l\'emprunt',
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.muted),
              ),
            ],
          ),
        ),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('tontines')
                .doc(tontineId)
                .collection('emprunts')
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator());
              }

              final emprunts =
                  snap.data?.docs ?? [];

              if (emprunts.isEmpty) {
                return const Center(
                  child: Text('Aucune demande.',
                    style: TextStyle(
                        color: AppColors.muted)),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: emprunts.length,
                itemBuilder: (context, i) {
                  final e = emprunts[i].data()
                      as Map<String, dynamic>;
                  final id = emprunts[i].id;
                  final statut =
                      e['statut'] as String? ??
                          '';
                  final valTresorier =
                      e['valideTresorier']
                          as bool? ?? false;
                  final valCommissaire =
                      e['valideCommissaire']
                          as bool? ?? false;

                  return _CarteEmpruntValidation(
                    data: e,
                    empruntId: id,
                    tontineId: tontineId,
                    role: role,
                    lectureSeule: _lectureSeule,
                    peutValiderTresorier:
                        _peutValiderTresorier &&
                            !valTresorier &&
                            statut == 'en_attente',
                    peutValiderCommissaire:
                        _peutValiderCommissaire &&
                            valTresorier &&
                            !valCommissaire &&
                            statut == 'en_attente',
                    peutApprouver:
                        _peutApprouverPresident &&
                        valTresorier &&
                            valCommissaire &&
                            statut == 'en_attente',
                    peutRembourser:
                        (role == 'tresorier' ||
                            role == 'president') &&
                            statut == 'approuve',
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CarteEmpruntValidation extends StatelessWidget {
  final Map<String, dynamic> data;
  final String empruntId;
  final String tontineId;
  final String role;
  final bool lectureSeule;
  final bool peutValiderTresorier;
  final bool peutValiderCommissaire;
  final bool peutApprouver;
  final bool peutRembourser;

  const _CarteEmpruntValidation({
    required this.data,
    required this.empruntId,
    required this.tontineId,
    required this.role,
    required this.lectureSeule,
    required this.peutValiderTresorier,
    required this.peutValiderCommissaire,
    required this.peutApprouver,
    required this.peutRembourser,
  });

  @override
  Widget build(BuildContext context) {
    final statut = data['statut'] as String? ?? '';
    final montant = data['montant'] as int? ?? 0;
    final demandeurNom =
        data['demandeurNom'] as String? ?? '';
    final motif = data['motif'] as String? ?? '';
    final dureeMois =
        data['dureeMois'] as int? ?? 1;
    final valTresorier =
        data['valideTresorier'] as bool? ?? false;
    final valCommissaire =
        data['valideCommissaire'] as bool? ?? false;
    final montantRembourse =
        data['montantRembourse'] as int? ?? 0;

    Color couleur;
    String label;
    switch (statut) {
      case 'en_attente':
        couleur = AppColors.accent;
        label = 'En attente';
        break;
      case 'approuve':
        couleur = AppColors.primary;
        label = 'Approuvé';
        break;
      case 'rembourse':
        couleur = AppColors.success;
        label = 'Remboursé';
        break;
      default:
        couleur = AppColors.danger;
        label = 'Refusé';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: couleur.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // En-tête
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Text(demandeurNom,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15)),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: couleur.withOpacity(0.1),
                  borderRadius:
                      BorderRadius.circular(20),
                ),
                child: Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: couleur)),
              ),
            ],
          ),

          const SizedBox(height: 6),
          Text('$montant FCFA · $dureeMois mois',
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.primary)),

          if (motif.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(motif,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.muted)),
          ],
               // ── Indicateur de progression 
          if (statut == 'en_attente') ...[
            const SizedBox(height: 12),
            const Text('Progression de validation',
              style: TextStyle(
                  fontSize: 11,
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                _etapeValidation(
                  label: 'Demande',
                  fait: true,
                  icone: Icons.assignment_outlined,
                ),
                _ligneConnexion(valTresorier),
                _etapeValidation(
                  label: 'Trésorier',
                  fait: valTresorier,
                  icone: Icons
                      .account_balance_wallet_outlined,
                ),
                _ligneConnexion(valCommissaire),
                _etapeValidation(
                  label: 'Commissaire',
                  fait: valCommissaire,
                  icone: Icons.fact_check_outlined,
                ),
                _ligneConnexion(statut == 'approuve'),
                _etapeValidation(
                  label: 'Président',
                  fait: statut == 'approuve',
                  icone: Icons.star_outline,
                ),
              ],
            ),
          ],

          // Barre remboursement
          if (statut == 'approuve' ||
              statut == 'rembourse') ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Remboursé : $montantRembourse / $montant FCFA',
                  style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.muted)),
                Text(
                  '${montant > 0 ? (montantRembourse / montant * 100).toStringAsFixed(0) : 0}%',
                  style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: montant > 0
                    ? montantRembourse / montant
                    : 0,
                backgroundColor: AppColors.border,
                valueColor:
                    AlwaysStoppedAnimation<Color>(
                        couleur),
                minHeight: 5,
              ),
            ),
          ],

          //  Actions selon le rôle 
          if (!lectureSeule) ...[
            const SizedBox(height: 12),

            if (peutValiderTresorier)
              _boutonAction(
                context,
                label: 'Valider (fonds disponibles)',
                couleur: AppColors.primary,
                onTap: () => _validerTresorier(context),
              ),

            if (peutValiderCommissaire)
              _boutonAction(
                context,
                label: 'Valider (conformité)',
                couleur: AppColors.primary,
                onTap: () =>
                    _validerCommissaire(context),
              ),

            if (peutApprouver)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          _decider(context, 'refuse'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            AppColors.danger,
                        side: const BorderSide(
                            color: AppColors.danger),
                      ),
                      child: const Text('Refuser'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          _decider(context, 'approuve'),
                      child: const Text('Approuver ✓'),
                    ),
                  ),
                ],
              ),

            if (peutRembourser)
              OutlinedButton.icon(
                onPressed: () =>
                    _rembourser(context, montant,
                        montantRembourse),
                icon: const Icon(Icons.payment,
                    size: 16),
                label: const Text(
                    'Enregistrer un remboursement'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(
                      color: AppColors.primary),
                  minimumSize:
                      const Size(double.infinity, 40),
                ),
              ),
          ],

          if (lectureSeule && statut == 'en_attente')
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color:
                    AppColors.muted.withOpacity(0.08),
                borderRadius:
                    BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.visibility_outlined,
                      size: 14,
                      color: AppColors.muted),
                  SizedBox(width: 6),
                  Text('Lecture seule',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.muted)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _etapeValidation({
    required String label,
    required bool fait,
    required IconData icone,
  }) {
    return Column(
      children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: fait
                ? AppColors.success
                : AppColors.border,
            shape: BoxShape.circle,
          ),
          child: Icon(
            fait ? Icons.check : icone,
            color: fait
                ? Colors.white
                : AppColors.muted,
            size: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
          style: TextStyle(
            fontSize: 9,
            color: fait
                ? AppColors.success
                : AppColors.muted,
            fontWeight: fait
                ? FontWeight.w700
                : FontWeight.w400,
          )),
      ],
    );
  }

  // ignore: unused_element
  Widget _ligneConnexion(bool active) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 14),
        color: active
            ? AppColors.success
            : AppColors.border,
      ),
    );
  }

  // ignore: unused_element
  Widget _boutonAction(
    BuildContext context, {
    required String label,
    required Color couleur,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: couleur,
        minimumSize: const Size(double.infinity, 42),
      ),
      child: Text(label,
        style: const TextStyle(
            fontWeight: FontWeight.w700)),
    );
  }

  // ignore: unused_element
  Future<void> _validerTresorier(
      BuildContext context) async {
      final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Validation Trésorier'),
        content: const Text(
            'Confirmez-vous que les fonds sont '
            'disponibles pour cet emprunt ?'),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, true),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
      final valDoc = await FirebaseFirestore.instance
    .collection('membres')
    .doc(FirebaseAuth.instance.currentUser!.uid)
    .get();

    await FirebaseFirestore.instance
        .collection('tontines')
        .doc(tontineId)
        .collection('emprunts')
        .doc(empruntId)
        .update({
      'valideTresorier': true,
      'dateTresorier': FieldValue.serverTimestamp(),
      'tresorierNom': valDoc['nom'] as String? ?? '',
    });
  }

  // ignore: unused_element
  Future<void> _validerCommissaire(
      BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Validation Commissaire'),
        content: const Text(
            'Confirmez-vous la conformité de '
            'cette demande d\'emprunt ?'),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, true),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
      final valDoc = await FirebaseFirestore.instance
    .collection('membres')
    .doc(FirebaseAuth.instance.currentUser!.uid)
    .get();
    await FirebaseFirestore.instance
        .collection('tontines')
        .doc(tontineId)
        .collection('emprunts')
        .doc(empruntId)
        .update({
      'valideCommissaire': true,
      'dateCommissaire': FieldValue.serverTimestamp(),
      'commissaireNom': valDoc['nom'] as String? ?? '',
    });
    
  }


  // ignore: unused_element
  Future<void> _rembourser(
    BuildContext context,
    int montantTotal,
    int dejaRembourse,
  ) async {
    final ctrl = TextEditingController();
    final reste = montantTotal - dejaRembourse;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title:
            const Text('Enregistrer un remboursement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Reste à rembourser : $reste FCFA',
              style: const TextStyle(
                  color: AppColors.muted)),
            const SizedBox(height: 14),
            TextFormField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly
              ],
              decoration: const InputDecoration(
                labelText: 'Montant versé',
                suffixText: 'FCFA',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, true),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final versement = int.tryParse(ctrl.text) ?? 0;
    final nouveauTotal = dejaRembourse + versement;
    final nouveauStatut =
        nouveauTotal >= montantTotal
            ? 'rembourse'
            : 'approuve';

    await FirebaseFirestore.instance
        .collection('tontines')
        .doc(tontineId)
        .collection('emprunts')
        .doc(empruntId)
        .update({
      'montantRembourse': nouveauTotal,
      'statut': nouveauStatut,
      'dernierRemboursement':
          FieldValue.serverTimestamp(),
    });
  }
  
  void _decider(BuildContext context, String s) {}
}

// Carte emprunt réutilisable
class _CarteEmprunt extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool afficherRemboursement;
  final VoidCallback? onRembourser;
  final Widget? actionsValidation;

  const _CarteEmprunt({
    required this.data,
    required this.afficherRemboursement,
    required this.onRembourser,
  }) : actionsValidation = null;

  @override
  Widget build(BuildContext context) {
    final statut = data['statut'] as String? ?? '';
    final montant = data['montant'] as int? ?? 0;
    final montantRembourse = data['montantRembourse'] as int? ?? 0;
    final demandeurNom = data['demandeurNom'] as String? ?? '';
    final motif = data['motif'] as String? ?? '';
    final dureeMois = data['dureeMois'] as int? ?? 1;
    final typeInteret = data['typeInteret'] as String? ?? 'simple';
    final taux = (data['tauxInteret'] as num?)?.toDouble() ?? 0;
    final totalARembourser = data['totalARembourser'] as String?;
    final mensualite = data['mensualiteEstimee'] as String?;

    Color couleur;
    String label;
    switch (statut) {
      case 'en_attente':
        couleur = AppColors.accent;
        label = 'En attente';
        break;
      case 'approuve':
        couleur = AppColors.primary;
        label = 'Approuvé';
        break;
      case 'rembourse':
        couleur = AppColors.success;
        label = 'Remboursé';
        break;
      default:
        couleur = AppColors.danger;
        label = 'Refusé';
    }

    final progression = montant > 0 ? montantRembourse / montant : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: couleur.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                demandeurNom,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: couleur.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: couleur,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Text(
            '$montant FCFA · $dureeMois mois',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          // Intérêts si applicable
          if (taux > 0) ...[
            const SizedBox(height: 4),
            Text(
              'Intérêt $typeInteret · ${taux.toStringAsFixed(1)}%'
              '${totalARembourser != null ? ' · Total : $totalARembourser FCFA' : ''}',
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            if (mensualite != null)
              Text(
                'Mensualité : $mensualite FCFA',
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
          ],

          if (motif.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              motif,
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],

          // Barre de remboursement
          if (statut == 'approuve' || statut == 'rembourse') ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Remboursé : $montantRembourse / $montant FCFA',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.muted,
                  ),
                ),
                Text(
                  '${(progression * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progression,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(couleur),
                minHeight: 5,
              ),
            ),
          ],

          if (afficherRemboursement && onRembourser != null) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onRembourser,
              icon: const Icon(Icons.payment, size: 16),
              label: const Text('Enregistrer un remboursement'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                minimumSize: const Size(double.infinity, 40),
              ),
            ),
          ],

          if (actionsValidation != null) ...[
            const SizedBox(height: 10),
            actionsValidation!,
          ],
        ],
      ),
    );
  }
}
