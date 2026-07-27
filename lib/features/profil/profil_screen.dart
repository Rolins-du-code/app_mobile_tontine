// pour modifier le profil des utilisateur 

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../core/theme.dart';
import '../../core/app_logo.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  final _nomController = TextEditingController();
  final _telController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _membre;

  final uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final doc = await FirebaseFirestore.instance
        .collection('membres')
        .doc(uid)
        .get();
    setState(() {
      _membre = doc.data();
      _nomController.text = _membre?['nom'] ?? '';
      _telController.text =
          _membre?['telephone'] ?? '';
    });
  }

  Future<void> _sauvegarder() async {
    if (_nomController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('membres')
          .doc(uid)
          .update({
        'nom': _nomController.text.trim(),
        'telephone':
            _telController.text.trim().replaceAll(' ', ''),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil mis à jour !'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _changerPin() {
    String pin1 = '';
    String pin2 = '';
    int etape = 1;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(etape == 1
              ? 'Nouveau code PIN'
              : 'Confirmez le PIN'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                etape == 1
                    ? 'Entrez votre nouveau PIN à 4 chiffres'
                    : 'Retapez le même PIN',
                style:
                    const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final rempli = etape == 1
                      ? i < pin1.length
                      : i < pin2.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 8),
                    width: 14, height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: rempli
                          ? AppColors.primary
                          : Colors.transparent,
                      border: Border.all(
                          color: AppColors.primary,
                          width: 1.6),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics:
                    const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.6,
                children: [
                  ...['1','2','3','4','5','6','7','8','9']
                      .map((c) => GestureDetector(
                    onTap: () {
                      setS(() {
                        if (etape == 1 &&
                            pin1.length < 4) {
                          pin1 += c;
                        } else if (etape == 2 &&
                            pin2.length < 4) {
                          pin2 += c;
                        }
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: AppColors.border),
                        borderRadius:
                            BorderRadius.circular(8),
                        color: AppColors.card,
                      ),
                      child: Center(
                        child: Text(c,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight:
                                    FontWeight.w700)),
                      ),
                    ),
                  )),
                  const SizedBox(),
                  GestureDetector(
                    onTap: () => setS(() {
                      if (etape == 1 && pin1.length < 4) {
                        pin1 += '0';
                      } else if (etape == 2 &&
                          pin2.length < 4) {
                        pin2 += '0';
                      }
                    }),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: AppColors.border),
                        borderRadius:
                            BorderRadius.circular(8),
                        color: AppColors.card,
                      ),
                      child: const Center(
                          child: Text('0',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight:
                                      FontWeight.w700))),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setS(() {
                      if (etape == 1 && pin1.isNotEmpty) {
                        pin1 = pin1.substring(
                            0, pin1.length - 1);
                      } else if (etape == 2 &&
                          pin2.isNotEmpty) {
                        pin2 = pin2.substring(
                            0, pin2.length - 1);
                      }
                    }),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: AppColors.border),
                        borderRadius:
                            BorderRadius.circular(8),
                        color: AppColors.card,
                      ),
                      child: const Center(
                        child: Icon(
                            Icons.backspace_outlined,
                            size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            if ((etape == 1 && pin1.length == 4) ||
                (etape == 2 && pin2.length == 4))
              ElevatedButton(
                onPressed: () async {
                  if (etape == 1) {
                    setS(() => etape = 2);
                  } else {
                    if (pin1 == pin2) {
                      Navigator.pop(ctx);
                      final hash = sha256
                          .convert(utf8.encode(pin1))
                          .toString();
                      // Met à jour Firebase Auth
                      await FirebaseAuth.instance
                          .currentUser!
                          .updatePassword(hash);
                      // Met à jour Firestore
                      await FirebaseFirestore.instance
                          .collection('membres')
                          .doc(uid)
                          .update({'pinHash': hash});
                      if (mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          const SnackBar(
                            content:
                                Text('PIN mis à jour !'),
                            backgroundColor:
                                AppColors.success,
                          ),
                        );
                      }
                    } else {
                      setS(() {
                        pin1 = '';
                        pin2 = '';
                        etape = 1;
                      });
                      ScaffoldMessenger.of(ctx)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Les PIN ne correspondent pas'),
                        ),
                      );
                    }
                  }
                },
                child: Text(etape == 1
                    ? 'Suivant'
                    : 'Confirmer'),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon profil',
            style:
                TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _membre == null
          ? const Center(
              child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [

                  // Avatar
                  const AppLogo(size: 80),
                  const SizedBox(height: 12),
                  Text(
                    _membre?['nom'] ?? '',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary
                          .withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: Text(
                      _membre?['role'] ?? '',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Informations 
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius:
                          BorderRadius.circular(16),
                      border: Border.all(
                          color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text('Informations',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          )),
                        const SizedBox(height: 16),

                        const Text('Nom complet',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                            fontWeight: FontWeight.w600,
                          )),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _nomController,
                          textCapitalization:
                              TextCapitalization.words,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(
                                Icons.person_outline),
                          ),
                        ),

                        const SizedBox(height: 16),

                        const Text('Numéro de téléphone',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                            fontWeight: FontWeight.w600,
                          )),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _telController,
                          keyboardType:
                              TextInputType.phone,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(
                                Icons.phone_outlined),
                            prefixText: '+237 ',
                          ),
                        ),

                        const SizedBox(height: 20),

                        ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : _sauvegarder,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20, width: 20,
                                  child:
                                      CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ))
                              : const Text(
                                  'Enregistrer'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  //  Sécurité 
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius:
                          BorderRadius.circular(16),
                      border: Border.all(
                          color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text('Sécurité',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          )),
                        const SizedBox(height: 16),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primary
                                  .withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(
                                      10),
                            ),
                            child: const Icon(
                                Icons.lock_outline,
                                color: AppColors.primary),
                          ),
                          title: const Text(
                              'Changer le code PIN',
                            style: TextStyle(
                                fontWeight:
                                    FontWeight.w600)),
                          subtitle: const Text(
                              '4 chiffres',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.muted)),
                          trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: AppColors.muted),
                          onTap: _changerPin,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Déconnexion 
                  OutlinedButton.icon(
                    onPressed: () async {
                      await FirebaseAuth.instance
                          .signOut();
                      if (!mounted) return;
                      Navigator.pushReplacementNamed(
                          context, '/');
                    },
                    icon: const Icon(Icons.logout,
                        color: AppColors.danger),
                    label: const Text('Se déconnecter',
                      style: TextStyle(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: AppColors.danger),
                      minimumSize:
                          const Size(double.infinity, 48),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}