// collation est dans les reunion formel

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme.dart';

class CollationTab extends StatelessWidget {
  final String tontineId;
  final Map<String, dynamic> tontineData;
  final bool estBureau;

  const CollationTab({
    super.key,
    required this.tontineId,
    required this.tontineData,
    required this.estBureau,
  });

  @override
  Widget build(BuildContext context) {
    final collationActive =
        tontineData['collationActive'] as bool? ?? false;
    final montant =
        tontineData['montantCollation'] as int? ?? 0;
    final moisCourant =
        tontineData['moisCourant'] as int? ?? 1;

    if (!collationActive) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_outlined,
                size: 60, color: AppColors.muted),
            SizedBox(height: 16),
            Text('Collation désactivée',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            SizedBox(height: 8),
            Text('Activez-la dans les paramètres.',
                style:
                    TextStyle(color: AppColors.muted)),
          ],
        ),
      );
    }

    return Column(
      children: [

        // En-tête
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 20, vertical: 14),
          color: AppColors.card,
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mois $moisCourant · Collation',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '$montant FCFA / membre',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
              // Total collecté (bureau uniquement)
              if (estBureau)
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('tontines')
                      .doc(tontineId)
                      .collection('collation')
                      .where('mois',
                          isEqualTo: moisCourant)
                      .where('statut',
                          isEqualTo: 'paye')
                      .snapshots(),
                  builder: (context, snap) {
                    final nb =
                        snap.data?.docs.length ?? 0;
                    return Container(
                      padding:
                          const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.success
                            .withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${nb * montant} FCFA collectés',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
 //  Liste membres + statut 
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
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
                    .collection('collation')
                    .where('mois',
                        isEqualTo: moisCourant)
                    .where('statut', isEqualTo: 'paye')
                    .snapshots(),
                builder: (context, snapPaies) {
                  final uidsPaies = snapPaies
                          .data?.docs
                          .map((d) =>
                              (d.data() as Map<String,
                                  dynamic>)['membreUid']
                                  as String)
                          .toSet() ??
                      {};

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    itemCount: membres.length,
                    itemBuilder: (context, i) {
                      final m = membres[i].data()
                          as Map<String, dynamic>;
                      final uid =
                          m['membreUid'] as String? ??
                              '';
                      final paye =
                          uidsPaies.contains(uid);

                      return Container(
                        margin: const EdgeInsets.only(
                            bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
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
                            // Rang
                            Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.success
                                    .withOpacity(0.1),
                                borderRadius:
                                    BorderRadius.circular(
                                        8),
                              ),
                              child: Center(
                                child: Text(
                                  '#${m['ordre'] ?? i + 1}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight:
                                        FontWeight.w700,
                                    color: AppColors.success,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                          // Nom
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  Text(
                                    m['membreNom']
                                            as String? ??
                                        '',
                                    style: const TextStyle(
                                      fontWeight:
                                          FontWeight.w600,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                  Text(
                                    m['role']
                                            as String? ??
                                        '',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Statut + action
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.end,
                              children: [
                                if (paye)
                                  const Icon(
                                    Icons.check_circle,
                                    color:
                                        AppColors.success,
                                    size: 22,
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
                                          .accent
                                          .withOpacity(
                                              0.12),
                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                                  20),
                                    ),
                                    child: const Text(
                                      'En attente',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight:
                                            FontWeight.w700,
                                        color:
                                            AppColors.accent,
                                      ),
                                    ),
                                  ),

                                // Marquer payé (bureau)
                                if (estBureau && !paye)
                                  GestureDetector(
                                    onTap: () =>
                                        _marquerPaye(
                                      context,
                                      uid,
                                      m['membreNom']
                                        as String? ??
                                          '',
                                      moisCourant,
                                      montant,
                                    ),
                                    child: const Padding(
                                      padding:
                                          EdgeInsets.only(
                                              top: 4),
                                      child: Text(
                                        '+ Marquer payé',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          color: AppColors
                                              .success,
                                          fontWeight:
                                              FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _marquerPaye(
    BuildContext context,
    String membreUid,
    String membreNom,
    int mois,
    int montant,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmer'),
        content: Text(
          'Marquer $membreNom comme ayant payé '
          '$montant FCFA de collation pour le mois $mois ?',
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
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await FirebaseFirestore.instance
        .collection('tontines')
        .doc(tontineId)
        .collection('collation')
        .add({
      'membreUid': membreUid,
      'membreNom': membreNom,
      'mois': mois,
      'montant': montant,
      'statut': 'paye',
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