 // dashboard pour le tresorier de la tontine 

 import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme.dart';

class DashboardTontineScreen extends StatelessWidget {
  final String tontineId;
  final String role;

  const DashboardTontineScreen({
    super.key,
    required this.tontineId,
    required this.role,
  });

  bool get _estBureau => [
        'president',
        'tresorier',
        'secretaire_general',
        'commissaire_comptes',
      ].contains(role);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tontines')
          .doc(tontineId)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final t = snap.data!.data() as Map<String, dynamic>;
        final nomTontine = t['nom'] as String? ?? '';
        final moisCourant = t['moisCourant'] as int? ?? 1;
        final dureeMois = t['dureeMois'] as int? ?? 10;
        final palier = t['palier'] as int? ?? 0;
        final solidariteActive = t['solidariteActive'] as bool? ?? false;
        final montantSolidarite = t['montantSolidarite'] as int? ?? 0;
        final collationActive = t['collationActive'] as bool? ?? false;
        final montantCollation = t['montantCollation'] as int? ?? 0;
        final progression = dureeMois > 0 ? moisCourant / dureeMois : 0.0;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [

              //  AppBar personnalisée 
              SliverAppBar(
                expandedHeight: 160,
                pinned: true,
                backgroundColor: AppColors.primary,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios,
                      color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        24, 60, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          nomTontine,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              'Mois $moisCourant / $dureeMois',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progression,
                                  backgroundColor:
                                      Colors.white.withOpacity(0.3),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                                  minHeight: 5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([

                    //  Caisse du mois 
                    _SectionTitre(
                        titre: 'Caisse du mois',
                        icone: Icons.account_balance_wallet_outlined),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('tontines')
                          .doc(tontineId)
                          .collection('cotisations')
                          .where('mois', isEqualTo: moisCourant)
                          .where('statut', isEqualTo: 'paye')
                          .snapshots(),
                      builder: (context, snapCotis) {
                        final nbPayes =
                            snapCotis.data?.docs.length ?? 0;
                        final totalCollecte = nbPayes * palier;
                        return _CarteInfo(
                          valeur: '$totalCollecte FCFA',
                          sousTitre: '$nbPayes paiements reçus ce mois',
                          couleur: AppColors.success,
                          icone: Icons.trending_up,
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    //  Cotisations 
                    _SectionTitre(
                        titre: 'Cotisations — Mois $moisCourant',
                        icone: Icons.payments_outlined),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('tontines')
                          .doc(tontineId)
                          .collection('adhesions')
                          .snapshots(),
                      builder: (context, snapMembres) {
                        final totalMembres =
                            snapMembres.data?.docs.length ?? 0;

                        return StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('tontines')
                              .doc(tontineId)
                              .collection('cotisations')
                              .where('mois', isEqualTo: moisCourant)
                              .where('statut', isEqualTo: 'paye')
                              .snapshots(),
                          builder: (context, snapPayes) {
                            final nbPayes =
                                snapPayes.data?.docs.length ?? 0;
                            final nbEnRetard =
                                totalMembres - nbPayes;

                            return Row(
                              children: [
                                Expanded(
                                  child: _CarteStatut(
                                    valeur: '$nbPayes',
                                    label: 'À jour',
                                    couleur: AppColors.success,
                                    fond: AppColors.successBg,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _CarteStatut(
                                        valeur:
                                        '${nbEnRetard < 0 ? 0 : nbEnRetard}',
                                    label: 'En retard',
                                    couleur: AppColors.danger,
                                    fond: AppColors.dangerBg,
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),

                    // Bouton enregistrer paiement
                    if (_estBureau) ...[
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () {
                          // À implémenter : écran enregistrement paiement
                        },
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Enregistrer un paiement'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(
                              color: AppColors.primary),
                          minimumSize: const Size(double.infinity, 46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    //  Emprunts 
                    _SectionTitre(
                        titre: 'Emprunts',
                        icone: Icons.handshake_outlined),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('tontines')
                          .doc(tontineId)
                          .collection('emprunts')
                          .where('statut', isEqualTo: 'en_attente')
                          .snapshots(),
                      builder: (context, snapEmprunts) {
                        final nbAttente =
                            snapEmprunts.data?.docs.length ?? 0;
                        return _CarteInfo(
                          valeur: '$nbAttente demande(s)',
                          sousTitre: nbAttente == 0
                              ? 'Aucune demande en attente'
                              : 'En attente de validation',
                          couleur: nbAttente > 0
                              ? AppColors.accent
                              : AppColors.muted,
                          icone: Icons.pending_outlined,
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // Solidarité 
                    if (solidariteActive) ...[
                      _SectionTitre(
                          titre: 'Fonds de solidarité',
                          icone: Icons.favorite_outline),
                      _CarteInfo(
                        valeur: '$montantSolidarite FCFA / 3 mois',
                        sousTitre: 'Contribution par membre',
                        couleur: AppColors.primary,
                        icone: Icons.shield_outlined,
                        // Montant total caisse visible bureau uniquement
                        badge: _estBureau
                            ? 'Voir le solde'
                            : null,
                        onBadgeTap: _estBureau
                            ? () {
                                // À implémenter : écran solidarité
                              }
                            : null,
                      ),
                      const SizedBox(height: 20),
                    ],
                          // Collation 
                    if (collationActive) ...[
                      _SectionTitre(
                          titre: 'Collation mensuelle',
                          icone: Icons.restaurant_outlined),
                      _CarteInfo(
                        valeur: '$montantCollation FCFA / mois',
                        sousTitre: 'Par membre',
                        couleur: AppColors.success,
                        icone: Icons.payments_outlined,
                      ),
                      const SizedBox(height: 20),
                    ],

                    //  Prochaine réunion 
                    _SectionTitre(
                        titre: 'Prochaine réunion',
                        icone: Icons.calendar_month_outlined),
                    _CarteProchaineMeeting(),

                    const SizedBox(height: 20),

                    //  Membres 
                    _SectionTitre(
                        titre: 'Membres',
                        icone: Icons.people_outline),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('tontines')
                          .doc(tontineId)
                          .collection('adhesions')
                          .snapshots(),
                      builder: (context, snap) {
                        final membres = snap.data?.docs ?? [];
                        return Container(
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: AppColors.border),
                          ),
                          child: Column(
                            children: [
                              ...membres.take(5).map((m) {
                                final data = m.data()
                                    as Map<String, dynamic>;
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors
                                        .primary
                                        .withOpacity(0.12),
                                    child: Text(
                                      (data['membreNom']
                                                  as String? ??
                                              '?')[0]
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight:
                                            FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    data['membreNom'] as String? ??
                                        '',
                                    style: const TextStyle(
                                        fontWeight:
                                            FontWeight.w600,
                                        fontSize: 13.5),
                                  ),
                                  subtitle: Text(
                                    data['role'] as String? ?? '',
                                    style: const TextStyle(
                                        fontSize: 11.5,
                                        color: AppColors.muted),
                                  ),
                                  trailing: Text(
                                      '#${data['ordre'] ?? '—'}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                      fontSize: 13,
                                    ),
                                  ),
                                );
                              }),
                              if (membres.length > 5)
                                TextButton(
                                  onPressed: () {
                                    // À implémenter : liste complète
                                  },
                                  child: Text(
                                    'Voir tous (${membres.length})',
                                    style: const TextStyle(
                                        color: AppColors.primary),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 30),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

//  Widgets réutilisables 

class _SectionTitre extends StatelessWidget {
  final String titre;
  final IconData icone;

  const _SectionTitre({required this.titre, required this.icone});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icone, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            titre,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _CarteInfo extends StatelessWidget {
  final String valeur;
  final String sousTitre;
  final Color couleur;
  final IconData icone;
  final String? badge;
  final VoidCallback? onBadgeTap;

  const _CarteInfo({
    required this.valeur,
    required this.sousTitre,
    required this.couleur,
    required this.icone,
    this.badge,
    this.onBadgeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              color: couleur.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icone, color: couleur, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  valeur,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: couleur,
                  ),
                ),
                Text(
                  sousTitre,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          if (badge != null)
            GestureDetector(
              onTap: onBadgeTap,
              child: Container(
                    padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CarteStatut extends StatelessWidget {
  final String valeur;
  final String label;
  final Color couleur;
  final Color fond;

  const _CarteStatut({
    required this.valeur,
    required this.label,
    required this.couleur,
    required this.fond,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: fond,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: couleur.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            valeur,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: couleur,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: couleur,
            ),
          ),
        ],
      ),
    );
  }
}

class _CarteProchaineMeeting extends StatelessWidget {
  const _CarteProchaineMeeting();

  DateTime _prochainPremierMercredi() {
    final now = DateTime.now();
    DateTime date = DateTime(now.year, now.month, 1);
    while (date.weekday != DateTime.wednesday) {
      date = date.add(const Duration(days: 1));
    }
    if (date.isBefore(now)) {
      final moisSuivant = DateTime(now.year, now.month + 1, 1);
      date = moisSuivant;
      while (date.weekday != DateTime.wednesday) {
        date = date.add(const Duration(days: 1));
      }
    }
    return date;
  }

  @override
  Widget build(BuildContext context) {
    final date = _prochainPremierMeeting();
    final diff = date.difference(DateTime.now()).inDays;
    final mois = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre',
      'décembre'
    ];

    return Container(
      padding: const EdgeInsets.all(16),
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
              color: AppColors.accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.event,
                color: AppColors.accent, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mercredi ${date.day} ${mois[date.month - 1]}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                diff == 0
                    ? 'Aujourd\'hui !'
                    : 'Dans $diff jour${diff > 1 ? 's' : ''}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
      DateTime _prochainPremierMeeting() {
    final now = DateTime.now();
    DateTime date = DateTime(now.year, now.month, 1);
    while (date.weekday != DateTime.wednesday) {
      date = date.add(const Duration(days: 1));
    }
    if (date.isBefore(now)) {
      final moisSuivant = DateTime(now.year, now.month + 1, 1);
      date = moisSuivant;
      while (date.weekday != DateTime.wednesday) {
        date = date.add(const Duration(days: 1));
      }
    }
    return date;
  }
}