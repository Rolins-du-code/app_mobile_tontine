// interface pour ajouter un membre à la tontine

 import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme.dart';

class AjouterMembreScreen extends StatefulWidget {
  final String tontineId;

  const AjouterMembreScreen({
    super.key,
    required this.tontineId,
  });

  @override
  State<AjouterMembreScreen> createState() =>
      _AjouterMembreScreenState();
}

class _AjouterMembreScreenState
    extends State<AjouterMembreScreen> {
  final _telController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _membreTrouve;
  String? _uidTrouve;
  bool _rechercheFaite = false;

  @override
  void dispose() {
    _telController.dispose();
    super.dispose();
  }

  //recherche les membre automatiquement quand le numero est entre

  @override
  void initState() {
    super.initState();
    _telController.addListener(() {
      final numero = _telController.text
          .trim()
          .replaceAll(' ', '');
          // lance la recherche si le numero est complet (9 chiffres)
      if (numero.length == 9 && !_isLoading) {
        _rechercherMembre();
      }
    });
  }

  // Recherche le membre par numéro de téléphone
  Future<void> _rechercherMembre() async {
    if (_telController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _membreTrouve = null;
      _rechercheFaite = false;
    });

    final telephone =
        _telController.text.trim().replaceAll(' ', '');

    final resultat = await FirebaseFirestore.instance
        .collection('membres')
        .where('telephone', isEqualTo: telephone)
        .limit(1)
        .get();

    if (resultat.docs.isEmpty) {
      setState(() {
        _isLoading = false;
        _rechercheFaite = true;
        _membreTrouve = null;
      });
      return;
    }

    final doc = resultat.docs.first;

    // Vérifie si déjà membre de cette tontine
    final adhesionExiste = await FirebaseFirestore.instance
        .collection('tontines')
        .doc(widget.tontineId)
        .collection('adhesions')
        .doc(doc.id)
        .get();

    if (adhesionExiste.exists) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Ce membre fait déjà partie de cette tontine'),
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = false;
      _rechercheFaite = true;
      _membreTrouve = doc.data();
      _uidTrouve = doc.id;
    });
  }

  // Ajoute le membre à la tontine
  Future<void> _ajouterMembre(String roleChoisi) async {
    if (_membreTrouve == null || _uidTrouve == null) return;

    setState(() => _isLoading = true);

    try {
      // Récupère le nombre de membres actuels pour le rang
      final adhesions = await FirebaseFirestore.instance
          .collection('tontines')
          .doc(widget.tontineId)
          .collection('adhesions')
          .get();

      final nouvelOrdre = adhesions.docs.length + 1;

      // Crée l'adhésion
      await FirebaseFirestore.instance
          .collection('tontines')
          .doc(widget.tontineId)
          .collection('adhesions')
          .doc(_uidTrouve)
          .set({
        'membreUid': _uidTrouve,
        'membreNom': _membreTrouve!['nom'],
        'role': roleChoisi,
        'dateAdhesion': FieldValue.serverTimestamp(),
        'statut': 'actif',
        'ordre': nouvelOrdre,
      });

      // Ajoute l'ID tontine dans le document membre
      await FirebaseFirestore.instance
          .collection('membres')
          .doc(_uidTrouve)
          .update({
        'tontines':
            FieldValue.arrayUnion([widget.tontineId]),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${_membreTrouve!['nom']} ajouté avec succès !'),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
             // Dialogue de choix du rôle
  void _choisirRole() {
    final roles = [
      {'valeur': 'membre', 'label': 'Membre', 'icone': Icons.person_outline},
      {'valeur': 'tresorier', 'label': 'Trésorier', 'icone': Icons.account_balance_wallet_outlined},
      {'valeur': 'president', 'label': 'Président', 'icone': Icons.star_outline},
      {'valeur': 'secretaire_general', 'label': 'Secrétaire général', 'icone': Icons.edit_note_outlined},
      {'valeur': 'commissaire_comptes', 'label': 'Commissaire aux comptes', 'icone': Icons.fact_check_outlined},
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                'Choisir un rôle',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ...roles.map((r) => ListTile(
              leading: Icon(
                r['icone'] as IconData,
                color: AppColors.primary,
              ),
              title: Text(r['label'] as String),
              onTap: () {
                Navigator.pop(context);
                _ajouterMembre(r['valeur'] as String);
              },
            )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ajouter un membre',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const Text(
                'Rechercher par numéro de téléphone',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Le membre doit déjà avoir un compte MonAmicale.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.muted,
                ),
              ),

              const SizedBox(height: 20),

              //  Champ téléphone + bouton 
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _telController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: 'Ex : 688851949',
                        prefixIcon:
                            Icon(Icons.phone_outlined),
                        prefixText: '+237 ',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed:
                        _isLoading ? null : _rechercherMembre,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(56, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.search),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Résultat ────────────────────────
              if (_rechercheFaite && _membreTrouve == null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.dangerBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          AppColors.danger.withOpacity(0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: AppColors.danger, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Aucun compte trouvé pour ce numéro. '
                          'Le membre doit d\'abord s\'inscrire.',
                          style: TextStyle(
                            color: AppColors.danger,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              if (_membreTrouve != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.successBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color:
                          AppColors.success.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.success
                                .withOpacity(0.2),
                            child: Text(
                              (_membreTrouve!['nom']
                                          as String)[0]
                                      .toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.success,
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
                                  _membreTrouve!['nom']
                                      as String,
                                  style: const TextStyle(
                                    fontWeight:
                                        FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  '+237 ${_membreTrouve!['telephone']}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.check_circle,
                            color: AppColors.success,
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      ElevatedButton.icon(
                        onPressed: _choisirRole,
                        icon: const Icon(
                            Icons.person_add_outlined),
                        label: const Text(
                          'Ajouter à la tontine',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}