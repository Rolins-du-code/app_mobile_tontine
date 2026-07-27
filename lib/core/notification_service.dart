// notification presente sur l'application pour les different manipulation

import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final _db = FirebaseFirestore.instance;

  // Envoie une notification à un membre
  static Future<void> envoyer({
    required String membreUid,
    required String titre,
    required String message,
    required String type,
    required String tontineId,
    required String tontineNom,
  }) async {
    await _db
        .collection('membres')
        .doc(membreUid)
        .collection('notifications')
        .add({
      'titre': titre,
      'message': message,
      'type': type,
      'lu': false,
      'date': FieldValue.serverTimestamp(),
      'tontineId': tontineId,
      'tontineNom': tontineNom,
    });
  }

  // Envoie à tous les membres d'une tontine
  static Future<void> envoyerATous({
    required String tontineId,
    required String tontineNom,
    required String titre,
    required String message,
    required String type,
    List<String>? exclure,
  }) async {
    final adhesions = await _db
        .collection('tontines')
        .doc(tontineId)
        .collection('adhesions')
        .get();

    for (final doc in adhesions.docs) {
      final uid = doc['membreUid'] as String? ?? '';
      if (uid.isEmpty) continue;
      if (exclure != null && exclure.contains(uid)) {
        continue;
      }
      await envoyer(
        membreUid: uid,
        titre: titre,
        message: message,
        type: type,
        tontineId: tontineId,
        tontineNom: tontineNom,
      );
    }
  }

  // Marque une notification comme lue
  static Future<void> marquerLue({
    required String membreUid,
    required String notifId,
  }) async {
    await _db
        .collection('membres')
        .doc(membreUid)
        .collection('notifications')
        .doc(notifId)
        .update({'lu': true});
  }

  // Marque toutes comme lues
  static Future<void> marquerToutesLues(
      String membreUid) async {
    final notifs = await _db
        .collection('membres')
        .doc(membreUid)
        .collection('notifications')
        .where('lu', isEqualTo: false)
        .get();

    for (final doc in notifs.docs) {
      await doc.reference.update({'lu': true});
    }
  }
}