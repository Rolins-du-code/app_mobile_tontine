// solidarite visible par le bureau et les membres de l'association selon certain critaire 


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme.dart';

class SolidariteTab extends StatelessWidget {
  final String tontineId;
  final Map<String, dynamic> tontineData;
  final bool estBureau;

  const SolidariteTab({
    super.key,
    required this.tontineId,
    required this.tontineData,
    required this.estBureau,
  });

  @override
  Widget build(BuildContext context) {
    final solidariteActive =
        tontineData['solidariteActive'] as bool? ?? false;

    if (!solidariteActive) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border,
                size: 60, color: AppColors.muted),
            SizedBox(height: 16),
            Text('Solidarité désactivée',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            SizedBox(height: 8),
            Text('Activez-la dans les paramètres.',
                style: TextStyle(color: AppColors.muted)),
          ],
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tontines')
          .doc(tontineId)
          .collection('periodes_solidarite')
          .orderBy('dateCreation', descending: true)
          .snapshots(),
      builder: (context, snapPeriodes) {
        if (!snapPeriodes.hasData) {
          return const Center(
              child: CircularProgressIndicator());
        }

        final periodes = snapPeriodes.data!.docs;

        return DefaultTabController(
          length: 2,
          child: Column(
            children: [

              //  Onglets internes 
              Container(
                color: AppColors.card,
                child: const TabBar(
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.muted,
                  indicatorColor: AppColors.primary,
                  tabs: [
                    Tab(text: 'Cotisations'),
                    Tab(text: 'Décaissements'),
                  ],
                ),
              ),

              Expanded(
                child: TabBarView(
                  children: [

                    //  Tab Cotisations solidarité 
                    _CotisationsSolidarite(
                      tontineId: tontineId,
                      tontineData: tontineData,
                      estBureau: estBureau,
                      periodes: periodes,
                    ),

                    //  Tab Décaissements 
                    _Decaissements(
                      tontineId: tontineId,
                      estBureau: estBureau,
                      tontineData: tontineData,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

//  Cotisations solidarité 
class _CotisationsSolidarite extends StatelessWidget {
  final String tontineId;
  final Map<String, dynamic> tontineData;
  final bool estBureau;
  final List<QueryDocumentSnapshot> periodes;

  const _CotisationsSolidarite({
    required this.tontineId,
    required this.tontineData,
    required this.estBureau,
    required this.periodes,
  });

  @override
  Widget build(BuildContext context) {
    final montant =
        tontineData['montantSolidarite'] as int? ?? 0;

    return Column(
      children: [
        // En-tête + bouton nouvelle période
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 20, vertical: 12),
          color: AppColors.background,
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${periodes.length} période(s)',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              if (estBureau)
                ElevatedButton.icon(
                  onPressed: () =>
                      _nouvellePeriode(context),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Nouvelle période'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    textStyle:
                        const TextStyle(fontSize: 12),
                    minimumSize: Size.zero,
                  ),
                ),
            ],
          ),
        ),

        // Liste des périodes
        Expanded(
          child: periodes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.history,
                          size: 50,
                          color: AppColors.muted),
                      const SizedBox(height: 12),
                      const Text('Aucune période',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        )),
                      const SizedBox(height: 8),
                      if (estBureau)
                        const Text(
                          'Démarrez une nouvelle période\n'
                          'de collecte.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: AppColors.muted),
                        ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: periodes.length,
                  itemBuilder: (context, i) {
                    final p = periodes[i].data()
                        as Map<String, dynamic>;
                    final periodeId = periodes[i].id;
                    final label = p['label']
                            as String? ??
                        'Période ${i + 1}';
                    final active =
                        p['active'] as bool? ?? false;

                    return GestureDetector(
                      onTap: () => _ouvrirPeriode(
                        context,
                        periodeId,
                        label,
                        montant,
                        active,
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(
                            bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius:
                              BorderRadius.circular(14),
                          border: Border.all(
                            color: active
                                ? AppColors.primary
                                    .withOpacity(0.4)
                                : AppColors.border,
                            width: active ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: active
                                    ? AppColors.primary
                                        .withOpacity(0.1)
                                    : AppColors.muted
                                        .withOpacity(0.1),
                                borderRadius:
                                    BorderRadius.circular(
                                        12),
                              ),
                              child: Icon(
                                active
                                    ? Icons.lock_open_outlined
                                    : Icons.lock_outlined,
                                color: active
                                    ? AppColors.primary
                                    : AppColors.muted,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(label,
                                    style: const TextStyle(
                                      fontWeight:
                                          FontWeight.w700,
                                      fontSize: 14,
                                    )),
                                  Text(
                                    '$montant FCFA / membre',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4),
                              decoration: BoxDecoration(
                                color: active
                                    ? AppColors.successBg
                                    : AppColors.muted
                                        .withOpacity(0.1),
                                borderRadius:
                                    BorderRadius.circular(
                                        20),
                              ),
                              child: Text(
                                active
                                    ? 'En cours'
                                    : 'Fermée',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: active
                                      ? AppColors.success
                                      : AppColors.muted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _nouvellePeriode(
      BuildContext context) async {
    final labelController = TextEditingController(
      text:
          'Période ${periodes.length + 1}',
    );

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nouvelle période'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Donnez un nom à cette période de collecte.',
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: labelController,
              decoration: const InputDecoration(
                labelText: 'Nom de la période',
                hintText: 'Ex : Trimestre 1 — 2026',
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
            child: const Text('Créer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Ferme la période active si elle existe
    for (final p in periodes) {
      final data = p.data() as Map<String, dynamic>;
      if (data['active'] == true) {
        await FirebaseFirestore.instance
            .collection('tontines')
            .doc(tontineId)
            .collection('periodes_solidarite')
            .doc(p.id)
            .update({'active': false});
      }
    }

    // Crée la nouvelle période
    await FirebaseFirestore.instance
        .collection('tontines')
        .doc(tontineId)
        .collection('periodes_solidarite')
        .add({
      'label': labelController.text.trim(),
      'active': true,
      'dateCreation': FieldValue.serverTimestamp(),
    });
  }

  void _ouvrirPeriode(
    BuildContext context,
    String periodeId,
    String label,
    int montant,
    bool active,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _DetailPeriodePage(
          tontineId: tontineId,
          periodeId: periodeId,
          label: label,
          montant: montant,
          active: active,
          estBureau: estBureau,
        ),
      ),
    );
  }
}

//  Détail d'une période 
class _DetailPeriodePage extends StatelessWidget {
  final String tontineId;
  final String periodeId;
  final String label;
  final int montant;
  final bool active;
  final bool estBureau;

  const _DetailPeriodePage({
    required this.tontineId,
    required this.periodeId,
    required this.label,
    required this.montant,
    required this.active,
    required this.estBureau,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tontines')
            .doc(tontineId)
            .collection('adhesions')
            .orderBy('ordre')
            .snapshots(),
        builder: (context, snapMembres) {
          if (!snapMembres.hasData) {
            return const Center(
                child: CircularProgressIndicator());
          }

          final membres = snapMembres.data!.docs;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('tontines')
                .doc(tontineId)
                .collection('periodes_solidarite')
                .doc(periodeId)
                .collection('paiements')
                .snapshots(),
            builder: (context, snapPaiements) {
              final paiements =
                  snapPaiements.data?.docs ?? [];
              final uidsPaies = paiements
                  .map((p) =>
                      (p.data()
                          as Map<String, dynamic>)[
                      'membreUid'] as String)
                  .toSet();

              final nbPaies = uidsPaies.length;
              final totalCaisse = nbPaies * montant;

              return Column(
                children: [

                  // Résumé (montant caisse = bureau only)
                  if (estBureau)
                    Container(
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
                                'Total en caisse',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.muted,
                                ),
                              ),
                              Text(
                                '$totalCaisse FCFA',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight:
                                      FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.end,
                            children: [
                              Text(
                                '$nbPaies / ${membres.length}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight:
                                      FontWeight.w800,
                                  color: AppColors.success,
                                ),
                              ),
                              const Text(
                                'membres à jour',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  // Liste membres
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16),
                      itemCount: membres.length,
                      itemBuilder: (context, i) {
                        final m = membres[i].data() as Map<String, dynamic>;  

                        final uid =
                            m['membreUid'] as String? ??
                                '';
                        final paye =
                            uidsPaies.contains(uid);

                        return Container(
                          margin: const EdgeInsets.only(
                              bottom: 8),
                          padding:
                              const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius:
                                BorderRadius.circular(12),
                            border: Border.all(
                              color: paye
                                  ? AppColors.success
                                      .withOpacity(0.3)
                                  : AppColors.border,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: paye
                                    ? AppColors.success
                                        .withOpacity(0.12)
                                    : AppColors.muted
                                        .withOpacity(0.1),
                                child: Text(
                                  (m['membreNom']
                                              as String? ??
                                          '?')[0]
                                      .toUpperCase(),
                                  style: TextStyle(
                                    color: paye
                                        ? AppColors.success
                                        : AppColors.muted,
                                    fontWeight:
                                        FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  m['membreNom']
                                          as String? ??
                                      '',
                                  style: const TextStyle(
                                    fontWeight:
                                        FontWeight.w600,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ),
                              if (paye)
                                const Icon(
                                    Icons.check_circle,
                                    color:
                                        AppColors.success,
                                    size: 20)
                              else if (estBureau &&
                                  active)
                                GestureDetector(
                                  onTap: () =>
                                      _marquerPaye(
                                    context,
                                    uid,
                                    m['membreNom']
                                            as String? ??
                                        '',
                                    montant,
                                  ),
                                  child: Container(
                                    padding:
                                        const EdgeInsets
                                            .symmetric(
                                            horizontal: 10,
                                            vertical: 5),
                                    decoration:
                                        BoxDecoration(
                                      color: AppColors
                                          .primary,
                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                                  20),
                                    ),
                                    child: const Text(
                                      'Marquer payé',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color:
                                            Colors.white,
                                        fontWeight:
                                            FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  padding:
                                      const EdgeInsets
                                          .symmetric(
                                          horizontal: 10,
                                          vertical: 4),
                                  decoration:
                                      BoxDecoration(
                                    color: AppColors
                                        .dangerBg,
                                    borderRadius:
                                        BorderRadius
                                            .circular(20),
                                  ),
                                  child: const Text(
                                    'En attente',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight:
                                          FontWeight.w700,
                                      color:
                                          AppColors.danger,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _marquerPaye(
    BuildContext context,
    String membreUid,
    String membreNom,
    int montant,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmer'),
        content: Text(
            'Marquer $membreNom comme ayant payé $montant FCFA ?'),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await FirebaseFirestore.instance
        .collection('tontines')
        .doc(tontineId)
        .collection('periodes_solidarite')
        .doc(periodeId)
        .collection('paiements')
        .add({
      'membreUid': membreUid,
      'membreNom': membreNom,
      'montant': montant,
      'datePaiement': FieldValue.serverTimestamp(),
    });
      if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$membreNom marqué payé !'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}

//  Décaissements 
class _Decaissements extends StatelessWidget {
  final String tontineId;
  final bool estBureau;
  final Map<String, dynamic> tontineData;

  const _Decaissements({
    required this.tontineId,
    required this.estBureau,
    required this.tontineData,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        // Bouton enregistrer (bureau)
        if (estBureau)
          Padding(
            padding: const EdgeInsets.fromLTRB(
                16, 12, 16, 0),
            child: ElevatedButton.icon(
              onPressed: () =>
                  _enregistrerDecaissement(context),
              icon: const Icon(Icons.add),
              label: const Text(
                  'Enregistrer un décaissement'),
              style: ElevatedButton.styleFrom(
                minimumSize:
                    const Size(double.infinity, 46),
              ),
            ),
          ),

        const SizedBox(height: 8),

        // Liste décaissements
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('tontines')
                .doc(tontineId)
                .collection('decaissements')
                .orderBy('date', descending: true)
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(
                    child: CircularProgressIndicator());
              }

              final docs = snap.data!.docs;

              if (docs.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Icon(Icons.volunteer_activism,
                          size: 50,
                          color: AppColors.muted),
                      SizedBox(height: 12),
                      Text('Aucun décaissement',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        )),
                      SizedBox(height: 6),
                      Text(
                        'L\'historique apparaîtra ici.',
                        style: TextStyle(
                            color: AppColors.muted),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final d = docs[i].data()
                      as Map<String, dynamic>;
                  final beneficiaire =
                      d['beneficiaire'] as String? ??
                          '';
                  final montant =
                      d['montant'] as int? ?? 0;
                  final motif =
                      d['motif'] as String? ?? '';
                  final date = d['date'] != null
                      ? (d['date']
                              as Timestamp)
                          .toDate()
                      : DateTime.now();

                  return Container(
                    margin: const EdgeInsets.only(
                        bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius:
                          BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primary
                                .withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(
                                    12),
                          ),
                          child: const Icon(
                            Icons
                                .volunteer_activism_outlined,
                            color: AppColors.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                beneficiaire,
                                style: const TextStyle(
                                  fontWeight:
                                      FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                motif,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.muted,
                                ),
                              ),
                              Text(
                                '${date.day}/${date.month}/${date.year}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '$montant FCFA',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: AppColors.primary,
                          ),
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
  }

  Future<void> _enregistrerDecaissement(
      BuildContext context) async {
    final beneficiaireController =
        TextEditingController();
    final montantController = TextEditingController();
    final motifController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Enregistrer un décaissement'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: beneficiaireController,
                decoration: const InputDecoration(
                  labelText: 'Bénéficiaire',
                  hintText: 'Nom du membre aidé',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: montantController,
                keyboardType: TextInputType.number,
                  inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly
                ],
                decoration: const InputDecoration(
                  labelText: 'Montant (FCFA)',
                  suffixText: 'FCFA',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: motifController,
                decoration: const InputDecoration(
                  labelText: 'Motif',
                  hintText:
                      'Ex : Naissance, Hospitalisation…',
                ),
              ),
            ],
          ),
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

    if (beneficiaireController.text.trim().isEmpty ||
        montantController.text.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Veuillez remplir tous les champs'),
          ),
        );
      }
      return;
    }

    await FirebaseFirestore.instance
        .collection('tontines')
        .doc(tontineId)
        .collection('decaissements')
        .add({
      'beneficiaire':
          beneficiaireController.text.trim(),
      'montant':
          int.tryParse(montantController.text) ?? 0,
      'motif': motifController.text.trim(),
      'date': FieldValue.serverTimestamp(),
      'enregistrePar':
          FirebaseAuth.instance.currentUser?.uid ?? '',
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Décaissement enregistré !'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}