// onglet tontine pour le dashboard du tresorier de la tontine

 import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme.dart';

class AccueilTab extends StatelessWidget {
  final String tontineId;
  final String role;
  final Map<String, dynamic> tontineData;
  final bool estBureau;

  const AccueilTab({
    super.key,
    required this.tontineId,
    required this.role,
    required this.tontineData,
    required this.estBureau,
  });

  @override
  Widget build(BuildContext context) {
    final palier = tontineData['palier'] as int? ?? 0;
    final moisCourant = tontineData['moisCourant'] as int? ?? 1;
    final solidariteActive =
        tontineData['solidariteActive'] as bool? ?? false;
    final montantSolidarite =
        tontineData['montantSolidarite'] as int? ?? 0;
    final collationActive =
        tontineData['collationActive'] as bool? ?? false;
    final montantCollation =
        tontineData['montantCollation'] as int? ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Caisse du mois 
          _Titre(titre: 'Caisse du mois',
              icone: Icons.account_balance_wallet_outlined),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('tontines')
                .doc(tontineId)
                .collection('cotisations')
                .where('mois', isEqualTo: moisCourant)
                .where('statut', isEqualTo: 'paye')
                .snapshots(),
            builder: (context, snap) {
              final nb = snap.data?.docs.length ?? 0;
              final total = nb * palier;
              return _CarteGrande(
                valeur: '$total FCFA',
                sous: '$nb paiements reçus ce mois',
                couleur: const Color.fromARGB(255, 34, 157, 79),
                icone: Icons.trending_up,
              );
            },
          ),

          const SizedBox(height: 20),

          //  Cotisations résumé 
          _Titre(titre: 'Cotisations', icone: Icons.payments_outlined),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('tontines')
                .doc(tontineId)
                .collection('adhesions')
                .snapshots(),
            builder: (context, snapM) {
              final total = snapM.data?.docs.length ?? 0;
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('tontines')
                    .doc(tontineId)
                    .collection('cotisations')
                    .where('mois', isEqualTo: moisCourant)
                    .where('statut', isEqualTo: 'paye')
                    .snapshots(),
                builder: (context, snapP) {
                  final payes = snapP.data?.docs.length ?? 0;
                  final retard =
                      (total - payes) < 0 ? 0 : total - payes;
                  return Row(
                    children: [
                      Expanded(
                        child: _CarteStat(
                          valeur: '$payes',
                          label: 'À jour',
                          couleur: AppColors.success,
                          fond: AppColors.successBg,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _CarteStat(
                          valeur: '$retard',
                          label: 'En retard',
                          couleur: const Color.fromARGB(255, 181, 46, 76),
                          fond: AppColors.dangerBg,
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),

          const SizedBox(height: 20),
                 //  Solidarité 
          if (solidariteActive) ...[
            _Titre(
                titre: 'Solidarité',
                icone: Icons.favorite_outline),
            _CarteGrande(
              valeur: '$montantSolidarite FCFA / 3 mois',
              sous: estBureau
                  ? 'Montant total en caisse visible ici'
                  : 'Contribution par membre',
              couleur: AppColors.primary,
              icone: Icons.shield_outlined,
            ),
            const SizedBox(height: 20),
          ],

          // Collation 
          if (collationActive) ...[
            _Titre(
                titre: 'Collation',
                icone: Icons.restaurant_outlined),
            _CarteGrande(
              valeur: '$montantCollation FCFA / mois',
              sous: 'Par membre',
              couleur: AppColors.success,
              icone: Icons.payments_outlined,
            ),
            const SizedBox(height: 20),
          ],

          //  Prochaine réunion
          _Titre(
              titre: 'Prochaine réunion',
              icone: Icons.calendar_month_outlined),
          _ProchaineMeeting(),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}


 //  Widgets communs 

class _Titre extends StatelessWidget {
  final String titre;
  final IconData icone;
  const _Titre({required this.titre, required this.icone});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icone, size: 17, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(titre,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark)),
        ],
      ),
    );
  }
}

class _CarteGrande extends StatelessWidget {
  final String valeur;
  final String sous;
  final Color couleur;
  final IconData icone;
  const _CarteGrande(
      {required this.valeur,
      required this.sous,
      required this.couleur,
      required this.icone});

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
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: couleur.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icone, color: couleur, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(valeur,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: couleur)),
              Text(sous,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.muted)),
            ],
          ),
        ],
      ),
    );
  }
}

class _CarteStat extends StatelessWidget {
  final String valeur;
  final String label;
  final Color couleur;
  final Color fond;
  const _CarteStat(
      {required this.valeur,
      required this.label,
      required this.couleur,
      required this.fond});

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
          Text(valeur,
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: couleur)),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: couleur)),
        ],
      ),
    );
  }
}

class _ProchaineMeeting extends StatelessWidget {
  const _ProchaineMeeting();

  DateTime _date() {
    final now = DateTime.now();
    DateTime d = DateTime(now.year, now.month, 1);
    while (d.weekday != DateTime.wednesday) {
      d = d.add(const Duration(days: 1));
    }
    if (d.isBefore(now)) {
      d = DateTime(now.year, now.month + 1, 1);
      while (d.weekday != DateTime.wednesday) {
        d = d.add(const Duration(days: 1));
      }
    }
    return d;
  }

  @override
  Widget build(BuildContext context) {
    final d = _date();
    final diff = d.difference(DateTime.now()).inDays;
    final mois = ['jan.','fév.','mars','avr.','mai','juin',
        'juil.','août','sept.','oct.','nov.','déc.'];
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
            width: 44, height: 44,
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
              Text('Mercredi ${d.day} ${mois[d.month - 1]}',
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
              Text(
                  diff == 0
                      ? "Aujourd'hui !"
                      : 'Dans $diff jour${diff > 1 ? 's' : ''}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.muted)),
            ],
          ),
        ],
      ),
    );
  }
}