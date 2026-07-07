 import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'formal_tontine_screen.dart';
import 'informal_tontine_screen.dart';

class CreateTontineScreen extends StatelessWidget {
  const CreateTontineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Nouvelle tontine',
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const Text(
                'Quel type de tontine ?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choisissez le modèle qui correspond à votre groupe.',
                style: TextStyle(color: AppColors.muted),
              ),

              const SizedBox(height: 32),

              // Carte Tontine Formelle 
              _CartType(
                icon: Icons.business_outlined,
                titre: 'Tontine formelle',
                description:
                    'Réunions mensuelles avec bureau organisé '
                    '(Président, Trésorier, Secrétaire…). '
                    'Gestion des cotisations, emprunts, '
                    'solidarité et collation.',
                couleur: AppColors.primary,
                exemples: const [
                  'Amicale avec bureau',
                  'Association structurée',
                  'Groupe avec gros montants',
                ],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FormalTontineScreen(),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Carte Tontine Informelle 
              _CartType(
                icon: Icons.people_outline,
                titre: 'Tontine informelle',
                description:
                    'Groupe d\'amis ou collègues. '
                    'Paiement hebdomadaire avec délai limite. '
                    'Pénalité automatique en cas de retard.',
                couleur: AppColors.success,
                exemples: const [
                  'Groupe WhatsApp d\'amis',
                  'Collègues de bureau',
                  'Petit montant hebdomadaire',
                ],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const InformalTontineScreen(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Carte de type 
class _CartType extends StatelessWidget {
  final IconData icon;
  final String titre;
  final String description;
  final Color couleur;
  final List<String> exemples;
  final VoidCallback onTap;

  const _CartType({
    required this.icon,
    required this.titre,
    required this.description,
    required this.couleur,
    required this.exemples,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
       padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icône + Titre
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: couleur.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: couleur, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    titre,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios,
                size: 14, color: AppColors.muted
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              description,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.muted,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 12),

            // Exemples
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: exemples.map((e) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: couleur.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  e,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: couleur,
                  ),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
}