 // dashboard pour le tresorier de la tontine 

 import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mon_amical/features/dashboard/parametres_tontine_screen.dart';
import '../../core/theme.dart';
import 'tabs/accueil_tab.dart';
import 'tabs/cotisations_tab.dart';
import 'tabs/emprunts_tab.dart';
import 'tabs/membres_tab.dart';
import 'tabs/solidarite_tab.dart';

class DashboardTontineScreen extends StatefulWidget {
  final String tontineId;
  final String role;

  const DashboardTontineScreen({
    super.key,
    required this.tontineId,
    required this.role,
  });

  @override
  State<DashboardTontineScreen> createState() =>
      _DashboardTontineScreenState();
}

class _DashboardTontineScreenState
    extends State<DashboardTontineScreen> {
  int _ongletActif = 0;

  bool get _estBureau => [
        'president',
        'tresorier',
        'secretaire_general',
        'commissaire_comptes',
      ].contains(widget.role);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tontines')
          .doc(widget.tontineId)
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
        final progression =
            dureeMois > 0 ? moisCourant / dureeMois : 0.0;

        // Liste des onglets
        final onglets = [
          AccueilTab(
            tontineId: widget.tontineId,
            role: widget.role,
            tontineData: t,
            estBureau: _estBureau,
          ),
          CotisationsTab(
            tontineId: widget.tontineId,
            role: widget.role,
            tontineData: t,
            estBureau: _estBureau,
          ),
          EmpruntsTab(
            tontineId: widget.tontineId,
            role: widget.role,
            estBureau: _estBureau,
            tontineData: t,
          ),
          MembresTab(
            tontineId: widget.tontineId,
            role: widget.role,
            tontineData: t,
            estBureau: _estBureau,
          ),
          SolidariteTab(
            tontineId: widget.tontineId,
            tontineData: t,
            estBureau: _estBureau,
          ),
        ];

        return Scaffold(
          backgroundColor: const Color.fromARGB(255, 233, 239, 248),

          // AppBar 
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios,
                  color: Colors.white, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nomTontine,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'Mois $moisCourant / $dureeMois',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progression,
                          backgroundColor:
                              Colors.white.withOpacity(0.3),
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                          minHeight: 3,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Badge rôle
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.role,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
                if (_estBureau)
              IconButton(
                icon: const Icon(Icons.settings_outlined,
                    color: Colors.white, size: 20),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ParametresTontineScreen(
                      tontineId: widget.tontineId,
                      tontineData: t,
                    ),
                  ),
                ),
              ),
            ],
          
          ),

          // Corps 
          body: IndexedStack(
            index: _ongletActif,
            children: onglets,
          ),

          // Navigation bas 
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _ongletActif,
            onTap: (i) => setState(() => _ongletActif = i),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.muted,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
            unselectedLabelStyle: const TextStyle(fontSize: 11),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Accueil',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.payments_outlined),
                activeIcon: Icon(Icons.payments),
                label: 'Cotisations',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.handshake_outlined),
                activeIcon: Icon(Icons.handshake),
                label: 'Emprunts',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_outline),
                activeIcon: Icon(Icons.people),
                label: 'Membres',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite_outline),
                activeIcon: Icon(Icons.favorite),
                label: 'Solidarité',
              )
            ],
          ),
        );
      },
    );
  }
}