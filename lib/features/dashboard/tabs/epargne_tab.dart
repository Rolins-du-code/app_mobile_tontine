import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme.dart';

class EpargneTab extends StatelessWidget {
  final String tontineId;
  final Map<String, dynamic> tontineData;
  final String role;
  final bool estBureau;

  const EpargneTab({
    super.key,
    required this.tontineId,
    required this.tontineData,
    required this.role,
    required this.estBureau,
  });

  bool get _voitTout => [
        'tresorier',
        'secretaire_general',
        'commissaire_comptes',
        'president',
      ].contains(role);

  bool get _peutEnregistrer => [
        'tresorier',
        'secretaire_general',
        'commissaire_comptes',
      ].contains(role);

  @override
  Widget build(BuildContext context) {
    final epargneActive =
        tontineData['epargneActive'] as bool? ?? false;

    if (!epargneActive) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.savings_outlined,
                size: 60, color: AppColors.muted),
            SizedBox(height: 16),
            Text('Épargne désactivée',
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

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final taux = (tontineData['tauxInteret'] as num?)?.toDouble() ?? 3.0;
    final moisCourant = tontineData['moisCourant'] as int? ?? 1;
    final dureeMois = tontineData['dureeMois'] as int? ?? 10;
    final moisRestants = dureeMois - moisCourant;

    return Builder(
      builder: (innerContext) => DefaultTabController(
        length: _voitTout ? 2 : 1,
        child: Column(
          children: [
            Container(
              color: AppColors.card,
              child: TabBar(
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.muted,
                indicatorColor: AppColors.primary,
                tabs: [
                  const Tab(text: 'Mon épargne'),
                  if (_voitTout) const Tab(text: 'Vue globale'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _MonEpargne(
                    tontineId: tontineId,
                    uid: uid,
                    taux: taux,
                    moisCourant: moisCourant,
                    moisRestants: moisRestants,
                    peutEnregistrer: _peutEnregistrer,
                  ),
                  if (_voitTout)
                    _VueGlobale(
                      tontineId: tontineId,
                      taux: taux,
                      moisRestants: moisRestants,
                      role: role,
                      peutEnregistrer: _peutEnregistrer,
                      moisCourant: moisCourant,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Mon épargne ──
class _MonEpargne extends StatelessWidget {
  final String tontineId;
  final String uid;
  final double taux;
  final int moisCourant;
  final int moisRestants;
  final bool peutEnregistrer;

  const _MonEpargne({
    required this.tontineId,
    required this.uid,
    required this.taux,
    required this.moisCourant,
    required this.moisRestants,
    required this.peutEnregistrer,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tontines')
          .doc(tontineId)
          .collection('epargnes')
          .doc(uid)
          .collection('versements')
          .snapshots(),
      builder: (context, snap) {
        final versements = snap.data?.docs ?? [];
        final totalEpargne = versements.fold<int>(
          0,
          (sum, v) =>
              sum +
              ((v.data() as Map<String, dynamic>)['montant'] as int? ?? 0),
        );
        final interets = totalEpargne * (taux / 100) * moisRestants;
        final totalFinal = totalEpargne + interets;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Carte résumé
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF4F8BFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Mon épargne totale',
                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('$totalEpargne FCFA',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        )),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Intérêts (fin de cycle)',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 11)),
                              Text('+${interets.toStringAsFixed(0)} FCFA',
                                  style: const TextStyle(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  )),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Total estimé',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 11)),
                              Text('${totalFinal.toStringAsFixed(0)} FCFA',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  )),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Récupérable à la fin du cycle ($moisRestants mois restants)',
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 11),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const Text('Historique de mes versements',
                  style:
                      TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 10),

              if (versements.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('Aucun versement enregistré pour le moment.',
                        style: TextStyle(color: AppColors.muted)),
                  ),
                )
              else
                ...versements.map((v) {
                  final d = v.data() as Map<String, dynamic>;
                  final montant = d['montant'] as int? ?? 0;
                  final mois = d['mois'] as int? ?? 0;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.savings_outlined,
                              color: AppColors.success, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text('Mois $mois',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                        ),
                        Text('$montant FCFA',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: AppColors.success,
                            )),
                      ],
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

// ── Vue globale (Bureau) ──
class _VueGlobale extends StatelessWidget {
  final String tontineId;
  final double taux;
  final int moisRestants;
  final String role;
  final bool peutEnregistrer;
  final int moisCourant;

  const _VueGlobale({
    required this.tontineId,
    required this.taux,
    required this.moisRestants,
    required this.role,
    required this.peutEnregistrer,
    required this.moisCourant,
  });

  void _ouvrirModalNouveauVersement(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _FormulaireSaisieEpargne(
        tontineId: tontineId,
        moisCourant: moisCourant,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tontines')
          .doc(tontineId)
          .collection('epargnes')
          .snapshots(),
      builder: (context, snap) {
        final epargnes = snap.data?.docs ?? [];

        return Stack(
          children: [
            Column(
              children: [
                if (role == 'tresorier' || role == 'president')
                  FutureBuilder<int>(
                    future: _calculerTotal(epargnes),
                    builder: (context, snapT) {
                      final total = snapT.data ?? 0;
                      return Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Caisse épargne totale',
                                    style: TextStyle(
                                        fontSize: 12, color: AppColors.muted)),
                                Text('$total FCFA',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                    )),
                              ],
                            ),
                            const Icon(Icons.lock_outline,
                                color: AppColors.muted, size: 16),
                          ],
                        ),
                      );
                    },
                  ),
                Expanded(
                  child: epargnes.isEmpty
                      ? const Center(
                          child: Text('Aucun épargnant.',
                              style: TextStyle(color: AppColors.muted)))
                      : ListView.builder(
                          padding: const EdgeInsets.only(
                              left: 16, right: 16, bottom: 80),
                          itemCount: epargnes.length,
                          itemBuilder: (context, i) {
                            final e = epargnes[i].data()
                                as Map<String, dynamic>;
                            final nom = e['membreNom'] as String? ?? '';
                            final uid = epargnes[i].id;

                            return FutureBuilder<QuerySnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('tontines')
                                  .doc(tontineId)
                                  .collection('epargnes')
                                  .doc(uid)
                                  .collection('versements')
                                  .get(),
                              builder: (context, snapV) {
                                final vers = snapV.data?.docs ?? [];
                                final total = vers.fold<int>(
                                  0,
                                  (s, v) =>
                                      s +
                                      ((v.data() as Map<String,
                                              dynamic>)['montant'] as int? ??
                                          0),
                                );
                                final interets =
                                    total * (taux / 100) * moisRestants;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppColors.card,
                                    borderRadius: BorderRadius.circular(12),
                                    border:
                                        Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: AppColors.primary
                                            .withOpacity(0.12),
                                        child: Text(
                                          nom.isNotEmpty
                                              ? nom[0].toUpperCase()
                                              : '?',
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
                                            Text(nom,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 13.5)),
                                            Text('${vers.length} versement(s)',
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    color: AppColors.muted)),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text('$total FCFA',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 14,
                                                color: AppColors.primary,
                                              )),
                                          Text(
                                              '+${interets.toStringAsFixed(0)} intérêts',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: AppColors.accent,
                                                fontWeight: FontWeight.w600,
                                              )),
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
            ),
            if (peutEnregistrer)
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton.extended(
                  onPressed: () => _ouvrirModalNouveauVersement(context),
                  backgroundColor: AppColors.primary,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Saisir épargne',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<int> _calculerTotal(List<QueryDocumentSnapshot> epargnes) async {
    int total = 0;
    for (final e in epargnes) {
      final vers = await FirebaseFirestore.instance
          .collection('tontines')
          .doc(tontineId)
          .collection('epargnes')
          .doc(e.id)
          .collection('versements')
          .get();
      for (final v in vers.docs) {
        total += (v.data())['montant'] as int? ?? 0;
      }
    }
    return total;
  }
}

//  Formulaire de Saisie d'Épargne (Trésorière / Secrétaire / Commissaire) ──
class _FormulaireSaisieEpargne extends StatefulWidget {
  final String tontineId;
  final int moisCourant;

  const _FormulaireSaisieEpargne({
    required this.tontineId,
    required this.moisCourant,
  });

  @override
  State<_FormulaireSaisieEpargne> createState() =>
      __FormulaireSaisieEpargneState();
}

class __FormulaireSaisieEpargneState extends State<_FormulaireSaisieEpargne> {
  final _montantController = TextEditingController();
  String? _selectedMembreUid;
  String? _selectedMembreNom;
  bool _isLoading = false;

  @override
  void dispose() {
    _montantController.dispose();
    super.dispose();
  }

  Future<void> _enregistrerEpargne() async {
    final montant = int.tryParse(_montantController.text) ?? 0;

    if (_selectedMembreUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un membre')),
      );
      return;
    }

    if (montant <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un montant valide')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final epargneRef = FirebaseFirestore.instance
          .collection('tontines')
          .doc(widget.tontineId)
          .collection('epargnes')
          .doc(_selectedMembreUid);

      await epargneRef.set({
        'membreNom': _selectedMembreNom ?? '',
        'membreUid': _selectedMembreUid,
        'derniereMaj': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await epargneRef.collection('versements').add({
        'mois': widget.moisCourant,
        'montant': montant,
        'date': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Versement de $montant FCFA enregistré pour $_selectedMembreNom !'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Enregistrer un versement d\'épargne',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('tontines')
                .doc(widget.tontineId)
                .collection('adhesions')
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) return const CircularProgressIndicator();
              final docs = snap.data!.docs;

              return DropdownButtonFormField<String>(
                value: _selectedMembreUid,
                hint: const Text('Sélectionner le membre'),
                items: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final nom = data['membreNom'] as String? ?? 'Membre';
                  return DropdownMenuItem<String>(
                    value: doc.id,
                    child: Text(nom),
                    onTap: () => _selectedMembreNom = nom,
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedMembreUid = val),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.person_outline),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _montantController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              hintText: 'Montant versé (FCFA)',
              suffixText: 'FCFA',
              prefixIcon: Icon(Icons.savings_outlined),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _enregistrerEpargne,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Valider le versement',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}