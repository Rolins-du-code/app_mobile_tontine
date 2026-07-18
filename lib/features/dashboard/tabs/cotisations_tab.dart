// onglet reserver au cotisations pour le dashboard du tresorier de la tontine

 import 'package:flutter/material.dart';
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

  // Calcule si le délai est dépassé selon la config
  bool _delaiDepasse(Map<String, dynamic> data) {
    final now = DateTime.now();
    final jourLimite =
        data['jourLimite'] as String? ?? 'mercredi';
    final heureLimiteStr =
        data['heureLimite'] as String? ?? '20:00';
    final delaiGrace =
        data['delaiGraceHeures'] as int? ?? 0;

    final jours = [
      'lundi', 'mardi', 'mercredi', 'jeudi',
      'vendredi', 'samedi', 'dimanche',
    ];
    final jourNum = jours.indexOf(jourLimite) + 1;

    // Trouve le jour limite dans la semaine courante
    DateTime limite = now;
    while (limite.weekday != jourNum) {
      limite =
          limite.subtract(const Duration(days: 1));
    }

    final parts = heureLimiteStr.split(':');
    limite = DateTime(
      limite.year, limite.month, limite.day,
      int.tryParse(parts[0]) ?? 20,
      int.tryParse(parts[1]) ?? 0,
    );

    // Ajoute le délai de grâce
    limite = limite.add(Duration(hours: delaiGrace));

    return now.isAfter(limite);
  }

  @override
  Widget build(BuildContext context) {
    final moisCourant =
        tontineData['moisCourant'] as int? ?? 1;
    final palier = tontineData['palier'] as int? ?? 0;
    final depasse = _delaiDepasse(tontineData);

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

            //  En-tête 
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
                        'Mois $moisCourant',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '$palier FCFA / membre',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                  // Statut du délai
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: depasse
                          ? AppColors.dangerBg
                          : AppColors.accent
                              .withOpacity(0.12),
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                          child: Text(
                      depasse
                          ? '⏰ Délai dépassé'
                          : '⏳ En cours',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: depasse
                            ? AppColors.danger
                            : AppColors.accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            //  Liste membres 
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                itemCount: membres.length,
                itemBuilder: (context, i) {
                  final m = membres[i].data()
                      as Map<String, dynamic>;
                  final membreUid =
                      m['membreUid'] as String? ?? '';

                  return FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('tontines')
                        .doc(tontineId)
                        .collection('cotisations')
                        .where('membreUid',
                            isEqualTo: membreUid)
                        .where('mois',
                            isEqualTo: moisCourant)
                        .limit(1)
                        .get(),
                    builder: (context, snapCotis) {
                      final paye = snapCotis.hasData &&
                          snapCotis.data!.docs.isNotEmpty;

                      // Détermine le statut
                      String label;
                      Color couleur;
                      Color fond;

                      if (paye) {
                        label = 'À jour';
                        couleur = AppColors.success;
                        fond = AppColors.successBg;
                      } else if (depasse) {
                        label = 'En retard';
                        couleur = AppColors.danger;
                        fond = AppColors.dangerBg;
                      } else {
                        label = 'En attente';
                        couleur = AppColors.accent;
                        fond = AppColors.accent
                            .withOpacity(0.12);
                      }

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
                                    fontWeight:
                                        FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Nom + rôle
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
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
                                    m['role'] as String? ??
                                        '',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Statut + action bureau
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding:
                                      const EdgeInsets
                                          .symmetric(
                                      horizontal: 10,
                                      vertical: 4),
                                  decoration: BoxDecoration(
                                    color: fond,
                                    borderRadius:
                                        BorderRadius.circular(
                                            20),
                                  ),
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight:
                                          FontWeight.w700,
                                      color: couleur,
                                    ),
                                  ),
                                ),
                                // Bouton Marquer payé (bureau)
                                if (estBureau && !paye)
                                  GestureDetector(
                                    onTap: () =>
                                        _marquerPaye(
                                      context,
                                      membreUid,
                                      m['membreNom']
                                              as String? ??
                                          '',
                                      moisCourant,
                                      palier,
                                    ),
                                    child: const Padding(
                                          padding:
                                          EdgeInsets.only(
                                              top: 4),
                                      child: Text(
                                        '+ Marquer payé',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          color:
                                              AppColors.primary,
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
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _marquerPaye(
    BuildContext context,
    String membreUid,
    String membreNom,
    int mois,
    int montant,
  ) async {
    // Confirmation
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmer le paiement'),
        content: Text(
            'Marquer $membreNom comme ayant payé $montant FCFA pour le mois $mois ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('tontines')
          .doc(tontineId)
          .collection('cotisations')
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
            content:
                Text('$membreNom marqué payé !'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    }
  }
}