// section empreunts pour le dashboard du tresorier de la tontine

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme.dart';

class EmpruntsTab extends StatelessWidget {
  final String tontineId;
  final String role;
  final bool estBureau;

  const EmpruntsTab({
    super.key,
    required this.tontineId,
    required this.role,
    required this.estBureau,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tontines')
          .doc(tontineId)
          .collection('emprunts')
          .orderBy('dateCreation', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(
              child: CircularProgressIndicator());
        }

        final emprunts = snap.data!.docs;

        if (emprunts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.handshake_outlined,
                    size: 60,
                    color: AppColors.muted.withOpacity(0.4)),
                const SizedBox(height: 16),
                const Text(
                  'Aucun emprunt',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Les demandes d\'emprunt apparaîtront ici',
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
            final e =
                emprunts[i].data() as Map<String, dynamic>;
            final statut = e['statut'] as String? ?? '';
            final montant = e['montant'] as int? ?? 0;
            final demandeurNom =
                e['demandeurNom'] as String? ?? '';

            Color couleurStatut;
            String labelStatut;
            switch (statut) {
              case 'en_attente':
                couleurStatut = AppColors.accent;
                labelStatut = 'En attente';
                break;
              case 'approuve':
                couleurStatut = AppColors.success;
                labelStatut = 'Approuvé';
                break;
              case 'rembourse':
                couleurStatut = AppColors.muted;
                labelStatut = 'Remboursé';
                break;
              default:
                couleurStatut = AppColors.danger;
                labelStatut = 'Refusé';
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color:
                          couleurStatut.withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.handshake_outlined,
                        color: couleurStatut, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          demandeurNom,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '$montant FCFA',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          couleurStatut.withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: Text(
                      labelStatut,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: couleurStatut,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}