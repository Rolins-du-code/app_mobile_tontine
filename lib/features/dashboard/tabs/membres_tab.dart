// section reserver au membres pour le dashboard du tresorier de la tontine


 import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme.dart';

class MembresTab extends StatelessWidget {
  final String tontineId;
  final String role;
  final bool estBureau;

  const MembresTab({
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
          .collection('adhesions')
          .orderBy('ordre')
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(
              child: CircularProgressIndicator());
        }

        final membres = snap.data!.docs;

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
                    '${membres.length} membre(s)',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  if (estBureau)
                    ElevatedButton.icon(
                      onPressed: () {
                        // À implémenter : ajouter un membre
                      },
                      icon: const Icon(Icons.person_add,
                          size: 16),
                      label: const Text('Ajouter'),
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

            // Liste
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                itemCount: membres.length,
                itemBuilder: (context, i) {
                  final m = membres[i].data()
                      as Map<String, dynamic>;
                  final nom =
                      m['membreNom'] as String? ?? '?';
                  final role = m['role'] as String? ?? '';
                  final ordre = m['ordre'] as int? ?? i + 1;
                  final initiale =
                      nom.isNotEmpty ? nom[0].toUpperCase() : '?';

                  return Container(
                    margin:
                        const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius:
                          BorderRadius.circular(12),
                      border:
                          Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        // Avatar
                        CircleAvatar(
                          backgroundColor: AppColors.primary
                              .withOpacity(0.12),
                          child: Text(
                            initiale,
                            style: const TextStyle(
                            color: AppColors.primary,
                              fontWeight: FontWeight.w700,
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
                                  nom,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13.5,
                                  ),
                                ),
                              Text(
                                role,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Rang
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.accent
                                .withOpacity(0.12),
                            borderRadius:
                                BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              '#$ordre',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.accent,
                              ),
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
  }
}