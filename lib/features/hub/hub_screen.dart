//liste uniquement les tontines auxquelles l'uttilisateur a souscrit

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme.dart';
import 'create_tontine_screen.dart';
import '../dashboard/dashboard_tontine_screen.dart';

class HubScreen extends StatelessWidget {
  const HubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [

            //  En-tête 
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('membres')
                        .doc(uid)
                        .get(),
                    builder: (context, snap) {
                      final nom = snap.hasData
                          ? snap.data!['nom'] as String
                          : '';
                      final prenom = nom.split(' ').first;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bonjour, $prenom 👋',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Text(
                            'Vos tontines',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  // Avatar + Déconnexion
                  Row(
                    children: [
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('membres')
                            .doc(uid)
                            .get(),
                        builder: (context, snap) {
                          final nom = snap.hasData
                              ? snap.data!['nom'] as String
                              : '?';
                          final initiales = nom
                              .split(' ')
                              .take(2)
                              .map((e) => e.isNotEmpty ? e[0] : '')
                              .join()
                              .toUpperCase();
                          return Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(
                                initiales,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: const Icon(Icons.logout),
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          if (context.mounted) {
                            Navigator.pushReplacementNamed(context, '/');
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            //  Liste des tontines 
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('membres')
                    .doc(uid)
                    .snapshots(),
                builder: (context, snapMembre) {
                  if (snapMembre.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (!snapMembre.hasData ||
                      !snapMembre.data!.exists) {
                    return _EcranVide(
                      onCreer: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const CreateTontineScreen(),
                        ),
                      ),
                    );
                  }

                  final data = snapMembre.data!.data()
                      as Map<String, dynamic>;
                  final tontineIds =
                      List<String>.from(data['tontines'] ?? []);

                  if (tontineIds.isEmpty) {
                    return _EcranVide(
                      onCreer: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const CreateTontineScreen(),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 8),
                    itemCount: tontineIds.length,
                    itemBuilder: (context, index) {
                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('tontines')
                            .doc(tontineIds[index])
                            .get(),
                        builder: (context, snapTontine) {
                          if (!snapTontine.hasData) {
                            return const SizedBox(height: 80);
                          }
                          if (!snapTontine.data!.exists) {
                            return const SizedBox.shrink();
                          }

                          final t = snapTontine.data!;
                          final tData = t.data()
                              as Map<String, dynamic>;

                          return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('tontines')
                                .doc(tontineIds[index])
                                .collection('adhesions')
                                .doc(uid)
                                .get(),
                            builder: (context, snapAdhesion) {
                              final role = snapAdhesion.hasData &&
                                      snapAdhesion.data!.exists
                                  ? snapAdhesion.data!['role']
                                      as String
                                  : 'membre';
                              final ordre = snapAdhesion.hasData &&
                                      snapAdhesion.data!.exists
                                  ? snapAdhesion.data!['ordre']
                                      as int? ?? 0
                                  : 0;

                              return _CarteTontine(
                                tontineId: t.id,
                                nom: tData['nom'] ?? '',
                                type: tData['type'] ?? 'formelle',
                                palier: tData['palier'] ?? 0,
                                moisCourant:
                                    tData['moisCourant'] ?? 1,
                                dureeMois: tData['dureeMois'] ?? 10,
                                role: role,
                                ordre: ordre,
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),

      //  Bouton flottant
      floatingActionButton: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('membres')
            .doc(uid)
            .get(),
        builder: (context, snap) {
          if (!snap.hasData) return const SizedBox.shrink();
          final role = snap.data!['role'] as String;
          final estBureau = [
            'president',
            'tresorier',
            'secretaire_general',
            'commissaire_comptes'
          ].contains(role);

          if (!estBureau) return const SizedBox.shrink();

          return FloatingActionButton.extended(
            backgroundColor: AppColors.primary,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CreateTontineScreen(),
              ),
            ),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Nouvelle tontine',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        },
      ),
    );
  }
}

//  Carte tontine cliquable 
class _CarteTontine extends StatelessWidget {
  final String tontineId;
  final String nom;
  final String type;
  final int palier;
  final int moisCourant;
  final int dureeMois;
  final String role;
  final int ordre;

  const _CarteTontine({
    required this.tontineId,
    required this.nom,
    required this.type,
    required this.palier,
    required this.moisCourant,
    required this.dureeMois,
    required this.role,
    required this.ordre,
  });

  @override
  Widget build(BuildContext context) {
    final progression =
        dureeMois > 0 ? moisCourant / dureeMois : 0.0;
    final estFormelle = type == 'formelle';
    final couleur =
        estFormelle ? AppColors.primary : AppColors.success;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardTontineScreen(
            tontineId: tontineId,
            role: role,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type + rôle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: couleur.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    estFormelle ? 'Formelle' : 'Informelle',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: couleur,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    role,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Nom
            Text(
              nom,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 4),

            // Infos
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  estFormelle
                      ? 'Mois $moisCourant / $dureeMois · $palier FCFA'
                      : 'Tour $moisCourant / $dureeMois · $palier FCFA',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.muted,
                  ),
                ),
                // Rang du membre
                if (ordre > 0)
                  Text(
                    'Rang #$ordre',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: couleur,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            // Barre de progression
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: progression,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(couleur),
                minHeight: 5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//  Écran vide 
class _EcranVide extends StatelessWidget {
  final VoidCallback onCreer;

  const _EcranVide({required this.onCreer});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.group_outlined,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Aucune tontine',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Vous n\'êtes membre d\'aucune tontine '
              'pour le moment.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onCreer,
              icon: const Icon(Icons.add),
              label: const Text('Créer une tontine'),
            ),
          ],
        ),
      ),
    );
  }
}