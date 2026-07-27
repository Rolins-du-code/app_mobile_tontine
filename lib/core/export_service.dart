// service d'exportation des donnees  genere

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ExportService {
  static final _db = FirebaseFirestore.instance;

  //  Export PDF complet d'une tontine 
  static Future<void> exporterTontinePDF({
    required String tontineId,
    required Map<String, dynamic> tontineData,
  }) async {
    final pdf = pw.Document();
    final nomTontine =
        tontineData['nom'] as String? ?? '';
    final palier =
        tontineData['palier'] as int? ?? 0;
    final moisCourant =
        tontineData['moisCourant'] as int? ?? 1;
    final dureeMois =
        tontineData['dureeMois'] as int? ?? 10;

    // Récupère les membres
    final membresSnap = await _db
        .collection('tontines')
        .doc(tontineId)
        .collection('adhesions')
        .orderBy('ordre')
        .get();

    // Récupère les cotisations du mois courant
    final cotisSnap = await _db
        .collection('tontines')
        .doc(tontineId)
        .collection('cotisations')
        .where('mois', isEqualTo: moisCourant)
        .get();

    final uidsPaies = cotisSnap.docs
        .map((d) =>
            (d.data())['membreUid'] as String)
        .toSet();

    // Récupère les emprunts
    final empruntsSnap = await _db
        .collection('tontines')
        .doc(tontineId)
        .collection('emprunts')
        .get();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [

          //  En-tête 
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue800,
              borderRadius:
                  const pw.BorderRadius.all(
                      pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment:
                  pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  nomTontine,
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Rapport — Mois $moisCourant / $dureeMois · $palier FCFA / membre',
                  style: const pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 12,
                  ),
                ),
                pw.Text(
                  'Généré le ${_dateFormat(DateTime.now())}',
                  style: const pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // Résumé 
          pw.Text('Résumé',
              style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              _carteResume('Membres',
                  '${membresSnap.docs.length}'),
              pw.SizedBox(width: 12),
              _carteResume('À jour',
                  '${uidsPaies.length}'),
              pw.SizedBox(width: 12),
              _carteResume('En retard',
                '${membresSnap.docs.length - uidsPaies.length}'),
              pw.SizedBox(width: 12),
              _carteResume('Collecté',
                '${uidsPaies.length * palier} FCFA'),
            ],
          ),

          pw.SizedBox(height: 20),
//  Cotisations 
          pw.Text('Cotisations — Mois $moisCourant',
              style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(
                color: PdfColors.grey300),
            children: [
              // En-tête
              pw.TableRow(
                decoration: const pw.BoxDecoration(
                    color: PdfColors.blue800),
                children: [
                  _cellule('Rang', header: true),
                  _cellule('Membre', header: true),
                  _cellule('Rôle', header: true),
                  _cellule('Statut', header: true),
                ],
              ),
              // Lignes
              ...membresSnap.docs.map((m) {
                final data = m.data();
                final paye = uidsPaies
                    .contains(data['membreUid']);
                return pw.TableRow(
                  children: [
                    _cellule(
                        '#${data['ordre'] ?? '—'}'),
                    _cellule(
                        data['membreNom'] as String? ??
                            ''),
                    _cellule(
                        data['role'] as String? ?? ''),
                    _cellule(
                      paye ? 'À jour ✓' : 'En retard',
                      color: paye
                          ? PdfColors.green800
                          : PdfColors.red800,
                    ),
                  ],
                );
              }),
            ],
          ),

          pw.SizedBox(height: 20),

          // ── Emprunts ──────────────────────────
          if (empruntsSnap.docs.isNotEmpty) ...[
            pw.Text('Emprunts',
                style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(
                  color: PdfColors.grey300),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                      color: PdfColors.blue800),
                  children: [
                    _cellule('Membre', header: true),
                    _cellule('Montant', header: true),
                    _cellule('Durée', header: true),
                    _cellule('Remboursé', header: true),
                    _cellule('Statut', header: true),
                  ],
                ),
                ...empruntsSnap.docs.map((e) {
                  final data = e.data();
                  final montant =
                      data['montant'] as int? ?? 0;
                  final rembourse =
                      data['montantRembourse']
                          as int? ?? 0;
                  final statut =
                      data['statut'] as String? ?? '';
                  return pw.TableRow(
                    children: [
                      _cellule(data['demandeurNom']
                              as String? ?? ''),
                      _cellule('$montant FCFA'),
                      _cellule(
                          '${data['dureeMois']} mois'),
                      _cellule('$rembourse FCFA'),
                      _cellule(statut),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 20),
          ],

          // ── Pied de page ──────────────────────
          pw.Divider(),
          pw.Text(
            'Document généré par MonAmicale · '
            'Confidentiel',
            style: const pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );
// Sauvegarde et partage
    final dir =
        await getApplicationDocumentsDirectory();
    final date = DateTime.now();
    final fichier = File(
      '${dir.path}/${nomTontine.replaceAll(' ', '_')}'
      '_${date.day}-${date.month}-${date.year}.pdf',
    );
    await fichier.writeAsBytes(
        await pdf.save());

    await Share.shareXFiles(
      [XFile(fichier.path)],
      text: 'Rapport tontine $nomTontine',
    );
  }

  // Export CSV des cotisations 
  static Future<void> exporterCSV({
    required String tontineId,
    required Map<String, dynamic> tontineData,
  }) async {
    final nomTontine =
        tontineData['nom'] as String? ?? '';
    final moisCourant =
        tontineData['moisCourant'] as int? ?? 1;

    final membresSnap = await _db
        .collection('tontines')
        .doc(tontineId)
        .collection('adhesions')
        .orderBy('ordre')
        .get();

    final cotisSnap = await _db
        .collection('tontines')
        .doc(tontineId)
        .collection('cotisations')
        .where('mois', isEqualTo: moisCourant)
        .get();

    final uidsPaies = cotisSnap.docs
        .map((d) =>
            (d.data())['membreUid'] as String)
        .toSet();

    // Génère le CSV
    final buffer = StringBuffer();
    buffer.writeln(
        'Rang,Nom,Rôle,Cotisation Mois $moisCourant');

    for (final m in membresSnap.docs) {
      final data = m.data();
      final paye =
          uidsPaies.contains(data['membreUid']);
      buffer.writeln(
        '${data['ordre'] ?? ''},'
        '${data['membreNom'] ?? ''},'
        '${data['role'] ?? ''},'
        '${paye ? 'Payé' : 'En attente'}',
      );
    }

    final dir =
        await getApplicationDocumentsDirectory();
    final date = DateTime.now();
    final fichier = File(
      '${dir.path}/${nomTontine.replaceAll(' ', '_')}'
      '_${date.day}-${date.month}-${date.year}.csv',
    );
    await fichier.writeAsString(buffer.toString());

    await Share.shareXFiles(
      [XFile(fichier.path)],
      text: 'Export CSV $nomTontine',
    );
  }

  //Widgets PDF helpers 
  static pw.Widget _carteResume(
      String label, String valeur) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: PdfColors.blue50,
          borderRadius: const pw.BorderRadius.all(
              pw.Radius.circular(6)),
        ),
        child: pw.Column(
          crossAxisAlignment:
              pw.CrossAxisAlignment.start,
          children: [
            pw.Text(valeur,
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                )),
            pw.Text(label,
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey700,
                )),
          ],
        ),
      ),
    );
  }

  static pw.Widget _cellule(
    String texte, {
    bool header = false,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(
          horizontal: 8, vertical: 6),
      child: pw.Text(
        texte,
        style: pw.TextStyle(
          fontSize: header ? 10 : 9,
          fontWeight: header
              ? pw.FontWeight.bold
              : pw.FontWeight.normal,
          color: header
              ? PdfColors.white
              : (color ?? PdfColors.black),
        ),
      ),
    );
  }

  static String _dateFormat(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';
}