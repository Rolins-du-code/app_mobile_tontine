// page de notification pour l'utilisateur 


import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme.dart';
import '../../core/notification_service.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                NotificationService.marquerToutesLues(uid),
            child: const Text(
              'Tout lire',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('membres')
            .doc(uid)
            .collection('notifications')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState ==
              ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator());
          }

          final notifs = snap.data?.docs ?? [];

          if (notifs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none,
                      size: 60, color: AppColors.muted),
                  SizedBox(height: 16),
                  Text(
                    'Aucune notification',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Vos notifications apparaîtront ici.',
                    style:
                        TextStyle(color: AppColors.muted),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: notifs.length,
            itemBuilder: (context, i) {
              final n = notifs[i].data()
                  as Map<String, dynamic>;
              final notifId = notifs[i].id;
              final lu = n['lu'] as bool? ?? false;
              final titre =
                  n['titre'] as String? ?? '';
              final message =
                  n['message'] as String? ?? '';
              final tontineNom =
                  n['tontineNom'] as String? ?? '';
              final type =
                  n['type'] as String? ?? '';
              final date = n['date'] != null
                  ? (n['date'] as Timestamp).toDate()
                  : DateTime.now();

              return GestureDetector(
                onTap: () {
                  if (!lu) {
                    NotificationService.marquerLue(
                      membreUid: uid,
                      notifId: notifId,
                    );
                  }
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: lu
                        ? AppColors.card
                        : AppColors.primary
                            .withOpacity(0.05),
                    borderRadius:
                        BorderRadius.circular(14),
                    border: Border.all(
                      color: lu
                          ? AppColors.border
                          : AppColors.primary
                              .withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      // Icône selon le type
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: _couleur(type)
                              .withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _icone(type),
                          color: _couleur(type),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    titre,
                                    style: TextStyle(
                                      fontWeight: lu
                                          ? FontWeight.w600
                                          : FontWeight.w800,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ),
                                if (!lu)
                                  Container(
                                    width: 8, height: 8,
                                    decoration:
                                        const BoxDecoration(
                                      color:
                                          AppColors.primary,
                                      shape:
                                          BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              message,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.muted,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .spaceBetween,
                              children: [
                                Text(
                                  tontineNom,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.primary,
                                    fontWeight:
                                        FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  _formatDate(date),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _icone(String type) {
    switch (type) {
      case 'cotisation':
        return Icons.payments_outlined;
      case 'emprunt':
        return Icons.handshake_outlined;
      case 'solidarite':
        return Icons.favorite_outline;
      case 'collation':
        return Icons.restaurant_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _couleur(String type) {
    switch (type) {
      case 'cotisation':
        return AppColors.success;
      case 'emprunt':
        return AppColors.primary;
      case 'solidarite':
        return AppColors.danger;
      case 'collation':
        return AppColors.accent;
      default:
        return AppColors.muted;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) {
      return 'Il y a ${diff.inMinutes} min';
    } else if (diff.inHours < 24) {
      return 'Il y a ${diff.inHours} h';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}