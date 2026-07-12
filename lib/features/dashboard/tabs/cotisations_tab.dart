// onglet reserver au cotisations pour le dashboard du tresorier de la tontine

 import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme.dart';

class CotisationsTab extends StatelessWidget {
  final String tontineId;
  final String role;
  final Map<String, dynamic> tontineData;
  final bool estBureau;

  const CotisationsTab({
    super.key,
    required this.tontineId,
    required this.role,
    required this.tontineData,
    required this.estBureau,
  });

  @override
  Widget build(BuildContext context) {
    final moisCourant = tontineData['moisCourant'] as int? ?? 1;
    final palier = tontineData['palier'] as int? ?? 0;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tontines')
          .doc(tontineId)
          .collection('adhesions')
          .orderBy('ordre')
          .snapshots(),
      builder: (context, snapAdhesions) {
        if (!snapAdhesions.hasData) {
          return const Center(
              child: CircularProgressIndicator());
        }

        final membres = snapAdhesions.data!.docs;

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
                  Text(
                    'Mois $moisCourant · $palier FCFA/membre',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  if (estBureau)
                    ElevatedButton.icon(
                      onPressed: () {
                        // À implémenter
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Enregistrer'),
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

            // Liste membres + statut paiement
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                itemCount: membres.length,
                itemBuilder: (context, i) {
                  final m =
                      membres[i].data() as Map<String, dynamic>;
                  final membreUid =
                      m['membreUid'] as String? ?? '';

                  return FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('tontines')
                        .doc(tontineId)
                        .collection('cotisations')
                        .where('membreUid',
                            isEqualTo: membreUid)
                        .where('mois', isEqualTo: moisCourant)
                        .limit(1)
                        .get(),
                    builder: (context, snapCotis) {
                      final paye = snapCotis.hasData &&
                          snapCotis.data!.docs.isNotEmpty;

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
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.primary
                                    .withOpacity(0.1),
                                borderRadius:
                                    BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  '#${m['ordre'] ?? i + 1}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    m['membreNom'] as String? ??
                                        '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                  Text(
                                    m['role'] as String? ?? '',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Statut
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4),
                              decoration: BoxDecoration(
                                color: paye
                                    ? AppColors.successBg
                                    : AppColors.dangerBg,
                                borderRadius:
                                    BorderRadius.circular(20),
                              ),
                              child: Text(
                                paye ? 'À jour' : 'En retard',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: paye
                                      ? AppColors.success
                                      : AppColors.danger,
                                ),
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
      },
    );
  }
}