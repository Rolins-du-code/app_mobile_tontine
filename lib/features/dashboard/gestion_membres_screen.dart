// fichier reserve a la gestion des membre d'une tontine 


import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme.dart';

class GestionMembresScreen extends StatelessWidget {
  final String tontineId;
  final String nomTontine;

  const GestionMembresScreen({
    super.key,
    required this.tontineId,
    required this.nomTontine,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Membres — $nomTontine',
          style: const TextStyle(
              fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
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

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: membres.length,
            itemBuilder: (context, i) {
              final m = membres[i].data()
                  as Map<String, dynamic>;
              final membreUid =
                  m['membreUid'] as String? ?? '';
              final nom =
                  m['membreNom'] as String? ?? '';
              final role =
                  m['role'] as String? ?? 'membre';
              final ordre =
                  m['ordre'] as int? ?? i + 1;
              final statut =
                  m['statut'] as String? ?? 'actif';

              return Container(
                margin:
                    const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius:
                      BorderRadius.circular(14),
                  border: Border.all(
                    color: statut == 'actif'
                        ? AppColors.border
                        : AppColors.danger
                            .withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [

                    // Rang
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary
                            .withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text('#$ordre',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          )),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Nom + rôle
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(nom,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            )),
                          Row(
                            children: [
                              Container(
                                margin:
                                    const EdgeInsets
                                        .only(top: 4),
                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                        horizontal: 8,
                                        vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors
                                      .accent
                                      .withOpacity(0.12),
                                  borderRadius:
                                      BorderRadius
                                          .circular(10),
                                ),
                                child: Text(role,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight:
                                        FontWeight.w700,
                                    color: AppColors.accent,
                                  )),
                              ),
                              if (statut == 'inactif')
                                Container(
                                  margin:
                                      const EdgeInsets
                                          .only(
                                          top: 4,
                                          left: 6),
                                  padding:
                                      const EdgeInsets
                                          .symmetric(
                                          horizontal: 8,
                                          vertical: 2),
                                  decoration:
                                      BoxDecoration(
                                    color: AppColors
                                        .dangerBg,
                                    borderRadius:
                                        BorderRadius
                                            .circular(10),
                                  ),
                                  child: const Text(
                                    'Inactif',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight:
                                          FontWeight.w700,
                                      color:
                                          AppColors.danger,
                                    )),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Menu actions
                    PopupMenuButton<String>(
                      icon: const Icon(
                          Icons.more_vert,
                          color: AppColors.muted),
                      onSelected: (action) =>
                          _traiterAction(
                        context,
                        action,
                        membreUid,
                        nom,
                        role,
                        statut,
                      ),
                      itemBuilder: (_) => [

                        // Changer le rôle
                        const PopupMenuItem(
                          value: 'role',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined,
                                  color: AppColors.primary,
                                  size: 18),
                              SizedBox(width: 10),
                              Text('Changer le rôle'),
                            ],
                          ),
                        ),
                            // Changer le rang
                        const PopupMenuItem(
                          value: 'rang',
                          child: Row(
                            children: [
                              Icon(Icons.swap_vert,
                                  color: AppColors.accent,
                                  size: 18),
                              SizedBox(width: 10),
                              Text('Modifier le rang'),
                            ],
                          ),
                        ),

                        // Activer/Désactiver
                        PopupMenuItem(
                          value: statut == 'actif'
                              ? 'desactiver'
                              : 'activer',
                          child: Row(
                            children: [
                              Icon(
                                statut == 'actif'
                                    ? Icons.pause_circle_outline
                                    : Icons.play_circle_outline,
                                color: statut == 'actif'
                                    ? AppColors.accent
                                    : AppColors.success,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Text(statut == 'actif'
                                  ? 'Désactiver'
                                  : 'Réactiver'),
                            ],
                          ),
                        ),

                        // Supprimer
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'supprimer',
                          child: Row(
                            children: [
                              Icon(
                                  Icons
                                      .person_remove_outlined,
                                  color: AppColors.danger,
                                  size: 18),
                              SizedBox(width: 10),
                              Text('Retirer de la tontine',
                                style: TextStyle(
                                    color: AppColors.danger)),
                            ],
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
    );
  }

  Future<void> _traiterAction(
    BuildContext context,
    String action,
    String membreUid,
    String nom,
    String roleActuel,
    String statut,
  ) async {
    switch (action) {
      case 'role':
        await _changerRole(
            context, membreUid, nom, roleActuel);
        break;
      case 'rang':
        await _changerRang(
            context, membreUid, nom);
        break;
      case 'desactiver':
        await _changerStatut(
            context, membreUid, nom, 'inactif');
        break;
      case 'activer':
        await _changerStatut(
            context, membreUid, nom, 'actif');
        break;
      case 'supprimer':
        await _retirerMembre(
            context, membreUid, nom);
        break;
    }
  }

  Future<void> _changerRole(
    BuildContext context,
    String membreUid,
    String nom,
    String roleActuel,
  ) async {
    final roles = [
      'membre',
      'president',
      'tresorier',
      'secretaire_general',
      'commissaire_comptes',
    ];

    String? roleChoisi = roleActuel;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text('Rôle de $nom'),
            content: Column(
            mainAxisSize: MainAxisSize.min,
            children: roles.map((r) =>
              RadioListTile<String>(
                value: r,
                groupValue: roleChoisi,
                title: Text(_labelRole(r)),
                activeColor: AppColors.primary,
                onChanged: (v) =>
                    setS(() => roleChoisi = v),
              ),
            ).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                if (roleChoisi != null &&
                    roleChoisi != roleActuel) {
                  await FirebaseFirestore.instance
                      .collection('tontines')
                      .doc(tontineId)
                      .collection('adhesions')
                      .doc(membreUid)
                      .update({'role': roleChoisi});

                  // Met aussi à jour le rôle global du membre
                  await FirebaseFirestore.instance
                      .collection('membres')
                      .doc(membreUid)
                      .update({'role': roleChoisi});

                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      SnackBar(
                        content: Text(
                            'Rôle de $nom mis à jour !'),
                        backgroundColor:
                            AppColors.success,
                      ),
                    );
                  }
                }
              },
              child: const Text('Confirmer'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changerRang(
    BuildContext context,
    String membreUid,
    String nom,
  ) async {
    final ctrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Rang de $nom'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Entrez le nouveau numéro de rang. '
              'Les autres membres seront '
              'réorganisés automatiquement.',
              style:
                  TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nouveau rang',
                hintText: 'Ex : 3',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final nouveauRang =
                  int.tryParse(ctrl.text);
              if (nouveauRang == null) return;

              await FirebaseFirestore.instance
                  .collection('tontines')
                  .doc(tontineId)
                  .collection('adhesions')
                  .doc(membreUid)
                  .update({'ordre': nouveauRang});

              if (context.mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  SnackBar(
                    content: Text(
                        'Rang de $nom modifié !'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }
  Future<void> _changerStatut(
    BuildContext context,
    String membreUid,
    String nom,
    String nouveauStatut,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(nouveauStatut == 'inactif'
            ? 'Désactiver $nom'
            : 'Réactiver $nom'),
        content: Text(
          nouveauStatut == 'inactif'
              ? '$nom ne pourra plus accéder à '
                'cette tontine mais ses données '
                'seront conservées.'
              : '$nom retrouvera son accès à '
                'cette tontine.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await FirebaseFirestore.instance
        .collection('tontines')
        .doc(tontineId)
        .collection('adhesions')
        .doc(membreUid)
        .update({'statut': nouveauStatut});

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(nouveauStatut == 'inactif'
              ? '$nom désactivé'
              : '$nom réactivé'),
          backgroundColor: nouveauStatut == 'inactif'
              ? AppColors.accent
              : AppColors.success,
        ),
      );
    }
  }

  Future<void> _retirerMembre(
    BuildContext context,
    String membreUid,
    String nom,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Retirer $nom'),
        content: Text(
          'Voulez-vous retirer $nom de cette tontine ? '
          'Son historique sera supprimé.\n\n'
          'Cette action est irréversible.',
        ),
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
            child: const Text('Retirer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Supprime l'adhésion
    await FirebaseFirestore.instance
        .collection('tontines')
        .doc(tontineId)
        .collection('adhesions')
        .doc(membreUid)
        .delete();

    // Retire l'ID tontine du profil membre
    await FirebaseFirestore.instance
        .collection('membres')
        .doc(membreUid)
        .update({
      'tontines': FieldValue.arrayRemove([tontineId]),
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$nom retiré de la tontine'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  // ignore: unused_element
  String _labelRole(String role) {
    switch (role) {
      case 'president':
        return 'Président';
      case 'tresorier':
        return 'Trésorier';
      case 'secretaire_general':
        return 'Secrétaire général';
      case 'commissaire_comptes':
        return 'Commissaire aux comptes';
      default:
        return 'Membre';
    }
  }
}