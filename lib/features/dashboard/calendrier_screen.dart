// pour faciliter la gestion des evenements de la reunion, on a besoin d'un calendrier pour planifier les evenements et les reunions

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme.dart';
import '../../core/notification_service.dart';

class CalendrierScreen extends StatefulWidget {
  final String tontineId;
  final Map<String, dynamic> tontineData;
  final bool estBureau;

  const CalendrierScreen({
    super.key,
    required this.tontineId,
    required this.tontineData,
    required this.estBureau,
  });

  @override
  State<CalendrierScreen> createState() =>
      _CalendrierScreenState();
}

class _CalendrierScreenState
    extends State<CalendrierScreen> {
  DateTime _moisAffiche = DateTime.now();
  DateTime? _jourSelectionne;

  // Types d'événements
  final List<Map<String, dynamic>> _typesEvenements = [
    {'valeur': 'reunion', 'label': 'Réunion',
      'icone': Icons.people_outline,
      'couleur': AppColors.primary},
    {'valeur': 'solidarite', 'label': 'Solidarité',
      'icone': Icons.favorite_outline,
      'couleur': AppColors.danger},
    {'valeur': 'emprunt', 'label': 'Emprunt',
      'icone': Icons.handshake_outlined,
      'couleur': AppColors.accent},
    {'valeur': 'cotisation', 'label': 'Cotisation',
      'icone': Icons.payments_outlined,
      'couleur': AppColors.success},
    {'valeur': 'autre', 'label': 'Autre',
      'icone': Icons.event_outlined,
      'couleur': AppColors.muted},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendrier',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (widget.estBureau)
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => _ajouterEvenement(
                  _jourSelectionne ?? DateTime.now()),
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tontines')
            .doc(widget.tontineId)
            .collection('evenements')
            .snapshots(),
        builder: (context, snap) {
          final evenements = snap.data?.docs ?? [];

          // Groupe les événements par date
          final Map<String, List<Map<String, dynamic>>>
              parDate = {};
          for (final e in evenements) {
            final data =
                e.data() as Map<String, dynamic>;
            final date = data['date'] as Timestamp?;
            if (date == null) continue;
            final d = date.toDate();
            final cle =
                '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
            parDate.putIfAbsent(cle, () => []);
            parDate[cle]!
                .add({...data, 'id': e.id});
          }

          return Column(
            children: [
              //  Calendrier 
              _Calendrier(
                moisAffiche: _moisAffiche,
                jourSelectionne: _jourSelectionne,
                evenementsParDate: parDate,
                onMoisChange: (m) =>
                    setState(() => _moisAffiche = m),
                onJourTap: (j) =>
                    setState(() => _jourSelectionne = j),
              ),

              const Divider(height: 1),

              // ── Événements du jour sélectionné ──
              Expanded(
                child: _jourSelectionne == null
                    ? _tousLesEvenements(
                        parDate, evenements)
                    : _evenementsDuJour(
                      _jourSelectionne!, parDate),
              ),
            ],
          );
        },
      ),
      floatingActionButton: widget.estBureau
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              onPressed: () => _ajouterEvenement(
                  _jourSelectionne ?? DateTime.now()),
              icon: const Icon(Icons.add,
                  color: Colors.white),
              label: const Text('Événement',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700)),
            )
          : null,
    );
  }

  Widget _tousLesEvenements(
    Map<String, List<Map<String, dynamic>>> parDate,
    List<QueryDocumentSnapshot> evenements,
  ) {
    if (evenements.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available,
                size: 50, color: AppColors.muted),
            SizedBox(height: 12),
            Text('Aucun événement programmé',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
            SizedBox(height: 6),
            Text(
                'Appuyez sur + pour ajouter un événement.',
                style:
                    TextStyle(color: AppColors.muted)),
          ],
        ),
      );
    }

    // Trie les événements par date
    final tous = evenements
        .map((e) =>
            {...e.data() as Map<String, dynamic>, 'id': e.id})
        .toList()
      ..sort((a, b) {
        final da = (a['date'] as Timestamp).toDate();
        final db = (b['date'] as Timestamp).toDate();
        return da.compareTo(db);
      });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tous.length,
      itemBuilder: (context, i) =>
          _CarteEvenement(
        data: tous[i],
        tontineId: widget.tontineId,
        estBureau: widget.estBureau,
        typesEvenements: _typesEvenements,
      ),
    );
  }

  Widget _evenementsDuJour(
    DateTime jour,
    Map<String, List<Map<String, dynamic>>> parDate,
  ) {
    final cle =
        '${jour.year}-${jour.month.toString().padLeft(2, '0')}-${jour.day.toString().padLeft(2, '0')}';
    final evts = parDate[cle] ?? [];

    return Column(
      children: [
        // En-tête du jour
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 20, vertical: 12),
          color: AppColors.background,
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDateComplete(jour),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              if (widget.estBureau)
                GestureDetector(
                  onTap: () =>
                      _ajouterEvenement(jour),
                  child: const Text(
                    '+ Ajouter',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: evts.isEmpty
              ? const Center(
                  child: Text(
                    'Aucun événement ce jour.',
                    style: TextStyle(
                        color: AppColors.muted),
                  ))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: evts.length,
                  itemBuilder: (context, i) =>
                      _CarteEvenement(
                    data: evts[i],
                    tontineId: widget.tontineId,
                    estBureau: widget.estBureau,
                    typesEvenements: _typesEvenements,
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _ajouterEvenement(
      DateTime dateInitiale) async {
    final titreCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime dateChoisie = dateInitiale;
    TimeOfDay heureChoisie = const TimeOfDay(
        hour: 10, minute: 0);
    String typeChoisi = 'reunion';
    bool notifierTous = true;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 20,
            bottom: MediaQuery.of(ctx)
                    .viewInsets
                    .bottom +
                24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // Titre du sheet
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Nouvel événement',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight:
                              FontWeight.w700)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () =>
                        Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Titre
              TextFormField(
                controller: titreCtrl,
                textCapitalization:
                    TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Titre de l\'événement',
                  hintText: 'Ex : Réunion mensuelle',
                  prefixIcon:
                      Icon(Icons.title_outlined),
                ),
              ),
              const SizedBox(height: 12),

              // Description
              TextFormField(
                controller: descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description (optionnel)',
                  prefixIcon:
                      Icon(Icons.notes_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // Type d'événement
              const Text('Type',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: AppColors.muted)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _typesEvenements
                    .map((t) {
                  final sel =
                      typeChoisi == t['valeur'];
                  return GestureDetector(
                    onTap: () => setS(
                        () => typeChoisi =
                            t['valeur'] as String),
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6),
                      decoration: BoxDecoration(
                        color: sel
                            ? (t['couleur']
                                    as Color)
                                .withOpacity(0.15)
                            : AppColors.background,
                        border: Border.all(
                          color: sel
                              ? t['couleur'] as Color
                              : AppColors.border,
                          width: sel ? 2 : 1,
                        ),
                        borderRadius:
                            BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize:
                            MainAxisSize.min,
                        children: [
                          Icon(t['icone'] as IconData,
                              size: 14,
                              color: sel
                                  ? t['couleur']
                                      as Color
                                  : AppColors.muted),
                          const SizedBox(width: 6),
                          Text(t['label'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: sel
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: sel
                                    ? t['couleur']
                                        as Color
                                    : AppColors.muted,
                              )),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Date et heure
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final d =
                            await showDatePicker(
                          context: ctx,
                          initialDate: dateChoisie,
                          firstDate: DateTime.now()
                              .subtract(const Duration(
                                  days: 1)),
                          lastDate: DateTime.now().add(
                              const Duration(days: 365)),
                        );
                        if (d != null) {
                          setS(() =>
                              dateChoisie = d);
                        }
                      },
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          border: Border.all(
                              color: AppColors.border),
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                                Icons
                                    .calendar_today_outlined,
                                size: 16,
                                color: AppColors.muted),
                            const SizedBox(width: 8),
                            Text(
                              '${dateChoisie.day}/${dateChoisie.month}/${dateChoisie.year}',
                              style: const TextStyle(
                                  fontWeight:
                                      FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final h =
                            await showTimePicker(
                          context: ctx,
                          initialTime: heureChoisie,
                        );
                        if (h != null) {
                          setS(
                              () => heureChoisie = h);
                        }
                      },
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          border: Border.all(
                              color: AppColors.border),
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                                Icons.access_time,
                                size: 16,
                                color: AppColors.muted),
                            const SizedBox(width: 8),
                            Text(
                              '${heureChoisie.hour.toString().padLeft(2, '0')}:${heureChoisie.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                  fontWeight:
                                      FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Notifier tous les membres
              Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  border:
                      Border.all(color: AppColors.border),
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: SwitchListTile(
                  title: const Text(
                    'Notifier tous les membres',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                  ),
                  subtitle: const Text(
                    'Une notification sera envoyée à tous',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.muted),
                  ),
                  value: notifierTous,
                  activeColor: AppColors.primary,
                  onChanged: (v) =>
                      setS(() => notifierTous = v),
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () async {
                  if (titreCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(ctx)
                        .showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Entrez un titre')),
                    );
                    return;
                  }
                  Navigator.pop(ctx);
                  await _sauvegarderEvenement(
                    titre: titreCtrl.text.trim(),
                    description:
                        descCtrl.text.trim(),
                    date: DateTime(
                      dateChoisie.year,
                      dateChoisie.month,
                      dateChoisie.day,
                      heureChoisie.hour,
                      heureChoisie.minute,
                    ),
                    type: typeChoisi,
                    notifierTous: notifierTous,
                  );
                },
                child: const Text('Enregistrer',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sauvegarderEvenement({
    required String titre,
    required String description,
    required DateTime date,
    required String type,
    required bool notifierTous,
  }) async {
    final uid =
        FirebaseAuth.instance.currentUser!.uid;
    final membreDoc = await FirebaseFirestore.instance
        .collection('membres')
        .doc(uid)
        .get();
    final createur =
        membreDoc['nom'] as String? ?? '';
    final nomTontine =
        widget.tontineData['nom'] as String? ?? '';

    // Sauvegarde l'événement
    await FirebaseFirestore.instance
        .collection('tontines')
        .doc(widget.tontineId)
        .collection('evenements')
        .add({
      'titre': titre,
      'description': description,
      'date': Timestamp.fromDate(date),
      'type': type,
      'createurUid': uid,
      'createurNom': createur,
      'dateCreation': FieldValue.serverTimestamp(),
    });

    // Notifie tous les membres si demandé
    if (notifierTous) {
      final moisEvenement = [
        'janvier', 'février', 'mars', 'avril',
        'mai', 'juin', 'juillet', 'août',
        'septembre', 'octobre', 'novembre', 'décembre'
      ];
      await NotificationService.envoyerATous(
        tontineId: widget.tontineId,
        tontineNom: nomTontine,
        titre: '📅 $titre',
        message:
            'Le ${date.day} ${moisEvenement[date.month - 1]} '
            'à ${date.hour.toString().padLeft(2, '0')}:'
            '${date.minute.toString().padLeft(2, '0')} — '
            '${description.isNotEmpty ? description : 'Événement programmé par $createur'}',
        type: type,
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Événement ajouté !'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  String _formatDateComplete(DateTime d) {
    final jours = [
      'Lundi', 'Mardi', 'Mercredi', 'Jeudi',
      'Vendredi', 'Samedi', 'Dimanche'
    ];
    final mois = [
      'janvier', 'février', 'mars', 'avril',
      'mai', 'juin', 'juillet', 'août',
      'septembre', 'octobre', 'novembre', 'décembre'
    ];
    return '${jours[d.weekday - 1]} ${d.day} ${mois[d.month - 1]} ${d.year}';
  }
}

//  Widget Calendrier 
class _Calendrier extends StatelessWidget {
  final DateTime moisAffiche;
  final DateTime? jourSelectionne;
  final Map<String, List<Map<String, dynamic>>>
      evenementsParDate;
  final void Function(DateTime) onMoisChange;
  final void Function(DateTime) onJourTap;

  const _Calendrier({
    required this.moisAffiche,
    required this.jourSelectionne,
    required this.evenementsParDate,
    required this.onMoisChange,
    required this.onJourTap,
  });

  @override
  Widget build(BuildContext context) {
    final mois = [
      'Janvier', 'Février', 'Mars', 'Avril',
      'Mai', 'Juin', 'Juillet', 'Août',
      'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    final premierJour =
        DateTime(moisAffiche.year, moisAffiche.month, 1);
    final dernierJour = DateTime(
        moisAffiche.year, moisAffiche.month + 1, 0);
    final decalage = premierJour.weekday - 1;
  return Container(
      color: AppColors.card,
      padding: const EdgeInsets.fromLTRB(
          16, 8, 16, 12),
      child: Column(
        children: [
          // Navigation mois
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(
                    Icons.chevron_left_outlined),
                onPressed: () => onMoisChange(
                  DateTime(moisAffiche.year,
                      moisAffiche.month - 1),
                ),
              ),
              Text(
                '${mois[moisAffiche.month - 1]} ${moisAffiche.year}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              IconButton(
                icon: const Icon(
                    Icons.chevron_right_outlined),
                onPressed: () => onMoisChange(
                  DateTime(moisAffiche.year,
                      moisAffiche.month + 1),
                ),
              ),
            ],
          ),

          // Jours de la semaine
          Row(
            children: ['L', 'M', 'M', 'J',
                    'V', 'S', 'D']
                .map((j) => Expanded(
                      child: Center(
                        child: Text(j,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.muted,
                            )),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 4),

          // Grille des jours
          GridView.builder(
            shrinkWrap: true,
            physics:
                const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount:
                decalage + dernierJour.day,
            itemBuilder: (context, i) {
              if (i < decalage) {
                return const SizedBox.shrink();
              }
              final jour = i - decalage + 1;
              final date = DateTime(moisAffiche.year,
                  moisAffiche.month, jour);
              final cle =
                  '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
              final aEvenements =
                  evenementsParDate.containsKey(cle);
              final estAujourdhui =
                  date.year == DateTime.now().year &&
                      date.month ==
                          DateTime.now().month &&
                      date.day == DateTime.now().day;
              final estSelectionne =
                  jourSelectionne != null &&
                      date.year ==
                          jourSelectionne!.year &&
                      date.month ==
                          jourSelectionne!.month &&
                      date.day == jourSelectionne!.day;

              return GestureDetector(
                onTap: () => onJourTap(date),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: estSelectionne
                        ? AppColors.primary
                        : estAujourdhui
                            ? AppColors.primary
                                .withOpacity(0.12)
                            : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        '$jour',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: estAujourdhui ||
                                  estSelectionne
                              ? FontWeight.w800
                              : FontWeight.w400,
                          color: estSelectionne
                              ? Colors.white
                              : estAujourdhui
                                  ? AppColors.primary
                                  : AppColors.textDark,
                        ),
                      ),
                      if (aEvenements)
                        Positioned(
                          bottom: 3,
                          child: Container(
                            width: 4, height: 4,
                            decoration: BoxDecoration(
                              color: estSelectionne
                                  ? Colors.white
                                  : AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

//  Carte événement 
class _CarteEvenement extends StatelessWidget {
  final Map<String, dynamic> data;
  final String tontineId;
  final bool estBureau;
  final List<Map<String, dynamic>> typesEvenements;

  const _CarteEvenement({
    required this.data,
    required this.tontineId,
    required this.estBureau,
    required this.typesEvenements,
  });

  @override
  Widget build(BuildContext context) {
    final titre = data['titre'] as String? ?? '';
    final description =
        data['description'] as String? ?? '';
    final type = data['type'] as String? ?? 'autre';
    final id = data['id'] as String? ?? '';
    final date = data['date'] != null
        ? (data['date'] as Timestamp).toDate()
        : DateTime.now();

    final typeInfo = typesEvenements.firstWhere(
      (t) => t['valeur'] == type,
      orElse: () => typesEvenements.last,
    );
    final couleur = typeInfo['couleur'] as Color;
    final icone = typeInfo['icone'] as IconData;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: couleur.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: couleur.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icone,
                color: couleur, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(titre,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  '${date.day}/${date.month}/${date.year} '
                  'à ${date.hour.toString().padLeft(2, '0')}:'
                  '${date.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted),
              ),
                if (description.isNotEmpty)
                  Text(description,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted)),
              ],
            ),
          ),
          if (estBureau)
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: AppColors.danger, size: 20),
              onPressed: () =>
                  _supprimer(context, id),
            ),
        ],
      ),
    );
  }

  Future<void> _supprimer(
      BuildContext context, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer'),
        content: const Text(
            'Supprimer cet événement ?'),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger),
            onPressed: () =>
                Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    await FirebaseFirestore.instance
        .collection('tontines')
        .doc(tontineId)
        .collection('evenements')
        .doc(id)
        .delete();
  }
}