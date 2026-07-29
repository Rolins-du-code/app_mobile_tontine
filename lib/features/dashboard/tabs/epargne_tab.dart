// page reserve a la gestion des epargne

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme.dart';

class EpargneTab extends StatelessWidget {
  final String tontineId;
  final Map<String, dynamic> tontineData;
  final String role;
  final bool estBureau;

  const EpargneTab({
    super.key,
    required this.tontineId,
    required this.tontineData,
    required this.role,
    required this.estBureau,
  });

  // Rôles qui voient TOUTES les épargnes
  bool get _voitTout => [
    'tresorier',
    'secretaire_general',
    'commissaire_comptes',
    'president',
  ].contains(role);

  @override
  Widget build(BuildContext context) {
    final epargneActive =
        tontineData['epargneActive'] as bool? ?? false;

    if (!epargneActive) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.savings_outlined,
                size: 60, color: AppColors.muted),
            SizedBox(height: 16),
            Text('Épargne désactivée',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      );
    }

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final taux =
        (tontineData['tauxInteret'] as num?)
            ?.toDouble() ?? 3.0;
    final moisCourant =
        tontineData['moisCourant'] as int? ?? 1;
    final dureeMois =
        tontineData['dureeMois'] as int? ?? 10;
    final moisRestants = dureeMois - moisCourant;

    return DefaultTabController(
      length: _voitTout ? 2 : 1,
      child: Column(
        children: [
          Container(
            color: AppColors.card,
            child: TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.muted,
              indicatorColor: AppColors.primary,
              tabs: [
                const Tab(text: 'Mon épargne'),
                if (_voitTout)
                  const Tab(text: 'Vue globale'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _MonEpargne(
                  tontineId: tontineId,
                  uid: uid,
                  taux: taux,
                  moisCourant: moisCourant,
                  moisRestants: moisRestants,
                ),
                if (_voitTout)
                  _VueGlobale(
                    tontineId: tontineId,
                    taux: taux,
                    moisRestants: moisRestants,
                    role: role,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

//  Mon épargne (visible par tous) 
class _MonEpargne extends StatefulWidget {
  final String tontineId;
  final String uid;
  final double taux;
  final int moisCourant;
  final int moisRestants;

  const _MonEpargne({
    required this.tontineId,
    required this.uid,
    required this.taux,
    required this.moisCourant,
    required this.moisRestants,
  });

  @override
  State<_MonEpargne> createState() => _MonEpargneState();
}

class _MonEpargneState extends State<_MonEpargne> {
  final _montantController = TextEditingController();

  @override
  void dispose() {
    _montantController.dispose();
    super.dispose();
  }

  Future<void> _verser() async {
    final montant =
        int.tryParse(_montantController.text) ?? 0;

    if (montant <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Entrez un montant valide')),
      );
      return;
    }

    final membreDoc = await FirebaseFirestore.instance
        .collection('membres')
        .doc(widget.uid)
        .get();
        await FirebaseFirestore.instance
        .collection('tontines')
        .doc(widget.tontineId)
        .collection('epargnes')
        .doc(widget.uid)
        .set({
      'membreNom': membreDoc['nom'],
      'membreUid': widget.uid,
      'derniereMaj': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await FirebaseFirestore.instance
        .collection('tontines')
        .doc(widget.tontineId)
        .collection('epargnes')
        .doc(widget.uid)
        .collection('versements')
        .add({
      'mois': widget.moisCourant,
      'montant': montant,
      'date': FieldValue.serverTimestamp(),
    });

    _montantController.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$montant FCFA épargnés !'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tontines')
          .doc(widget.tontineId)
          .collection('epargnes')
          .doc(widget.uid)
          .collection('versements')
          .snapshots(),
      builder: (context, snap) {
        final versements = snap.data?.docs ?? [];
        final totalEpargne = versements.fold<int>(
          0,
          (sum, v) =>
              sum +
              ((v.data() as Map<String,
                      dynamic>)['montant'] as int? ?? 0),
        );
        final interets = totalEpargne *
            (widget.taux / 100) *
            widget.moisRestants;
        final totalFinal = totalEpargne + interets;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              //  Carte résumé 
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.primary,
                      Color(0xFF4F8BFF),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius:
                      BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text('Mon épargne totale',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('$totalEpargne FCFA',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      )),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color:
                            Colors.white.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Intérêts (fin de cycle)',
                                style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11)),
                              Text(
                                '+${interets.toStringAsFixed(0)} FCFA',
                                style: const TextStyle(
                                  color: AppColors.accent,
                                  fontWeight:
                                      FontWeight.w700,
                                  fontSize: 14,
                                )),
                            ],
                          ),
                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.end,
                            children: [
                              const Text('Total estimé',
                                style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11)),
                              Text(
                                '${totalFinal.toStringAsFixed(0)} FCFA',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight:
                                      FontWeight.w700,
                                  fontSize: 14,
                                )),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Récupérable à la fin du cycle '
                      '(${widget.moisRestants} mois restants)',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                      )),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              //  Nouveau versement 
              const Text('Faire un versement',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15)),
              const SizedBox(height: 6),
              const Text(
                'Montant libre — facultatif chaque mois.',
                style: TextStyle(
                    fontSize: 12,
                    color: AppColors.muted)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _montantController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter
                            .digitsOnly
                      ],
                      decoration: const InputDecoration(
                        hintText: 'Montant (FCFA)',
                        suffixText: 'FCFA',
                        prefixIcon:
                            Icon(Icons.savings_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _verser,
                    style: ElevatedButton.styleFrom(
                        minimumSize:
                            const Size(80, 56)),
                    child: const Text('Épargner'),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              //  Historique des versements 
              const Text('Historique de mes versements',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15)),
              const SizedBox(height: 10),
                if (versements.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'Aucun versement pour l\'instant.',
                      style: TextStyle(
                          color: AppColors.muted)),
                  ),
                )
              else
                ...versements.map((v) {
                  final data =
                      v.data() as Map<String, dynamic>;
                  final montant =
                      data['montant'] as int? ?? 0;
                  final mois =
                      data['mois'] as int? ?? 0;

                  return Container(
                    margin:
                        const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius:
                          BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.success
                                .withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(10),
                          ),
                          child: const Icon(
                              Icons.savings_outlined,
                              color: AppColors.success,
                              size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text('Mois $mois',
                            style: const TextStyle(
                                fontWeight:
                                    FontWeight.w600,
                                fontSize: 13)),
                        ),
                        Text('$montant FCFA',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: AppColors.success,
                          )),
                      ],
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

//  Vue globale (Trésorier/Secrétaire/Commissaire) 
class _VueGlobale extends StatelessWidget {
  final String tontineId;
  final double taux;
  final int moisRestants;
  final String role;

  const _VueGlobale({
    required this.tontineId,
    required this.taux,
    required this.moisRestants,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tontines')
          .doc(tontineId)
          .collection('epargnes')
          .snapshots(),
      builder: (context, snap) {
        final epargnes = snap.data?.docs ?? [];

        return Column(
          children: [

            // Total caisse épargne (trésorier uniquement)
            if (role == 'tresorier' ||
                role == 'president')
              FutureBuilder<int>(
                future: _calculerTotal(epargnes),
                builder: (context, snapTotal) {
                  final total = snapTotal.data ?? 0;
                  return Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                      color: AppColors.primary
                          .withOpacity(0.06),
                      borderRadius:
                          BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.primary
                            .withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Caisse épargne totale',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.muted)),
                            Text(
                              '$total FCFA',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight:
                                    FontWeight.w800,
                                color: AppColors.primary,
                              )),
                          ],
                        ),
                        const Icon(
                          Icons.lock_outline,
                          color: AppColors.muted,
                          size: 16,
                        ),
                      ],
                    ),
                  );
                },
              ),

            // Liste des épargnants
            Expanded(
              child: epargnes.isEmpty
                  ? const Center(
                      child: Text(
                        'Aucun épargnant pour l\'instant.',
                        style: TextStyle(
                            color: AppColors.muted),
                      ))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16),
                      itemCount: epargnes.length,
                      itemBuilder: (context, i) {
                        final e = epargnes[i].data()
                            as Map<String, dynamic>;
                        final nom = e['membreNom']
                                as String? ??
                            '';
                        final uid = epargnes[i].id;

                        return FutureBuilder<
                            QuerySnapshot>(
                          future: FirebaseFirestore
                              .instance
                              .collection('tontines')
                              .doc(tontineId)
                              .collection('epargnes')
                              .doc(uid)
                              .collection('versements')
                              .get(),
                          builder: (context, snapV) {
                            final versements =
                                snapV.data?.docs ?? [];
                            final total =
                                versements.fold<int>(
                              0,
                              (s, v) =>
                                  s +
                                  ((v.data() as Map<
                                              String,
                                              dynamic>)[
                                          'montant']
                                      as int? ?? 0),
                            );
                            final interets = total *
                                (taux / 100) *
                                moisRestants;
                                  return Container(
                              margin: const EdgeInsets
                                  .only(bottom: 8),
                              padding:
                                  const EdgeInsets.all(
                                      14),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius:
                                    BorderRadius.circular(
                                        12),
                                border: Border.all(
                                    color:
                                        AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor:
                                        AppColors.primary
                                            .withOpacity(
                                                0.12),
                                    child: Text(
                                      nom.isNotEmpty
                                          ? nom[0]
                                              .toUpperCase()
                                          : '?',
                                      style:
                                          const TextStyle(
                                        color: AppColors
                                            .primary,
                                        fontWeight:
                                            FontWeight.w700,
                                      )),
                                  ),
                                  const SizedBox(
                                      width: 12),
                                  Expanded(
                                    child:
                                        Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,
                                      children: [
                                        Text(nom,
                                          style: const TextStyle(
                                              fontWeight:
                                                  FontWeight
                                                      .w600,
                                              fontSize:
                                                  13.5)),
                                        Text(
                                          '${versements.length} versement(s)',
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors
                                                  .muted)),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .end,
                                    children: [
                                      Text(
                                        '$total FCFA',
                                        style:
                                            const TextStyle(
                                          fontWeight:
                                              FontWeight
                                                  .w800,
                                          fontSize: 14,
                                              color: AppColors
                                              .primary,
                                        )),
                                      Text(
                                        '+${interets.toStringAsFixed(0)} intérêts',
                                        style:
                                            const TextStyle(
                                          fontSize: 10,
                                          color: AppColors
                                              .accent,
                                          fontWeight:
                                              FontWeight
                                                  .w600,
                                        )),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<int> _calculerTotal(
      List<QueryDocumentSnapshot> epargnes) async {
    int total = 0;
    for (final e in epargnes) {
      final versements = await FirebaseFirestore.instance
          .collection('tontines')
          .doc(tontineId)
          .collection('epargnes')
          .doc(e.id)
          .collection('versements')
          .get();
      for (final v in versements.docs) {
        total += (v.data())['montant']
            as int? ?? 0;
      }
    }
    return total;
  }
}