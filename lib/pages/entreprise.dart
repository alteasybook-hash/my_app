import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'entreprise/administration_page.dart';
import 'entreprise/rh_page.dart';
import 'entreprise/pre_compta_page.dart';
import 'entreprise/rapprochement_page.dart';
import 'entreprise/reports_page.dart';
import 'entreprise/global_history_page.dart';

class EntreprisePage extends StatelessWidget {
  final VoidCallback? onBack; // Ajout du paramètre
  const EntreprisePage({super.key, this.onBack});

  final Color primaryColor = const Color(0xFF49F6C7);

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: isDark ? primaryColor : Colors.black),
          onPressed: () {
            if (onBack != null) {
              onBack!(); // Utilisation du callback
            } else if (Navigator.of(context).canPop()) {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          t.entreprise,
          style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(t.gestionAdmin),
            _buildMenuCard(
              context,
              t.admin,
              t.adminSub,
              Icons.admin_panel_settings_outlined,
                  () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdministrationPage()),
                );
              },
            ),

            _buildMenuCard(
              context,
              t.rh,
              t.rhSub,
              Icons.people_alt_outlined,
                  () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RhPage()),
                );
              },
            ),

            const SizedBox(height: 24),
            _buildSectionTitle(t.comptaDocs),

            _buildMenuCard(
              context,
              t.preCompta,
              t.preComptaSub,
              Icons.receipt_long_outlined,
                  () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PreComptaPage()),
                );
              },
            ),

            _buildMenuCard(
              context,
              t.rapprochement,
              t.rapprochementSub,
              Icons.account_balance_outlined,
                  () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RapprochementPage()),
                );
              },
            ),

            const SizedBox(height: 24),
            _buildSectionTitle(t.analyses),

            _buildMenuCard(
              context,
              t.reports,
              t.reportsSub,
              Icons.analytics_outlined,
                  () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReportsPage()),
                );
              },
            ),

            _buildHistoryMiniBlock(context),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, String title, String subtitle,
      IconData icon, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF232435) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: isDark ? primaryColor : Colors.black),
        ),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle,
              style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[600], fontSize: 13)),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }

  Widget _buildHistoryMiniBlock(BuildContext context) {
    final t = AppLocalizations.of(context);
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const GlobalHistoryPage()),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFF232435),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.history_toggle_off_rounded, color: primaryColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.globalHistory,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t.globalHistorySub,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}
