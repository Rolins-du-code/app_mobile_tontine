//liste uniquement les tontines auxquelles l'uttilisateur a souscrit

 import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme.dart';
import 'create_tontine_screen.dart';

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
                  // Avatar
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
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Liste des tontines ────────────────
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                // Écoute en temps réel les tontines
                    // où l'utilisateur a une adhésion
                stream: FirebaseFirestore.instance
                    .collectionGroup('adhesions')
                    .where('membreUid', isEqualTo: uid)
                    .snapshots(),
                builder: (context, snapAdhesions) {
                  if (snapAdhesions.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final adhesions = snapAdhesions.data?.docs ?? [];

                  if (adhesions.isEmpty) {
                    return _EcranVide(
                      onCreer: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreateTontineScreen(),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 8),
                    itemCount: adhesions.length,
                    itemBuilder: (context, index) {
                      // Récupère l'ID de la tontine depuis le chemin
                      final tontineId = adhesions[index]
                          .reference
                          .parent
                          .parent!
                          .id;
                      final roleAdhesion =
                          adhesions[index]['role'] as String;

                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('tontines')
                            .doc(tontineId)
                            .get(),
                        builder: (context, snapTontine) {
                          if (!snapTontine.hasData) {
                            return const SizedBox(height: 80);
                          }
                          final t = snapTontine.data!;
                          return _CarteTontine(
                            tontineId: tontineId,
                            nom: t['nom'] ?? '',
                            type: t['type'] ?? 'formelle',
                            palier: t['palier'] ?? 0,
                            moisCourant: t['moisCourant'] ?? 1,
                            dureeMois: t['dureeMois'] ?? 10,
                            role: roleAdhesion,
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

      // Bouton flottant (bureau uniquement) 
      floatingActionButton: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('membres')
            .doc(uid)
            .get(),
        builder: (context, snap) {
          if (!snap.hasData) return const SizedBox.shrink();
          final role = snap.data!['role'] as String;
          final estBureau = [
            'president', 'tresorier',
            'secretaire_general', 'commissaire_comptes'
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
    //  Carte tontine 
class _CarteTontine extends StatelessWidget {
  final String tontineId;
  final String nom;
  final String type;
  final int palier;
  final int moisCourant;
  final int dureeMois;
  final String role;

  const _CarteTontine({
    required this.tontineId,
    required this.nom,
    required this.type,
    required this.palier,
    required this.moisCourant,
    required this.dureeMois,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final progression = dureeMois > 0
        ? moisCourant / dureeMois
        : 0.0;
    final estFormelle = type == 'formelle';
    final couleur = estFormelle
        ? AppColors.primary
        : AppColors.success;

    return Container(
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

          // Palier + progression
          Text(
            estFormelle
                ? 'Mois $moisCourant / $dureeMois · $palier FCFA'
                : 'Tour $moisCourant / $dureeMois · $palier FCFA',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.muted,
            ),
          ),

          const SizedBox(height: 10),

          // Barre de progression
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
      ),
    );
  }
}

// ── Écran vide (aucune tontine) ───────────────────────
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