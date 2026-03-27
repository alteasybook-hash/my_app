import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../models/invoice.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final ApiService _apiService = ApiService();
  final Color primaryColor = const Color(0xFF49F6C7);

  // Données simulées pour la vue
  double _totalRevenu = 45200.00;
  double _totalDepenses = 12300.50;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("RAPPORTS & ANALYSE",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- RÉSUMÉ PERFORMANCE ---
            _buildPerformanceCard(),
            const SizedBox(height: 30),

            _buildSectionTitle("EXPORTS POUR L'EXPERT COMPTABLE"),
            const SizedBox(height: 15),

            // --- OPTIONS D'EXPORT ---
            _buildExportTile(
                "Journal des Achats",
                "Toutes vos factures fournisseurs (Format Excel)",
                Icons.file_download,
                    () => _exportData('achats')
            ),
            _buildExportTile(
                "Journal des Ventes",
                "Vos factures clients et devis acceptés",
                Icons.file_present_rounded,
                    () => _exportData('ventes')
            ),
            _buildExportTile(
                "Grand Livre (PDF)",
                "Synthèse complète pour la liasse fiscale",
                Icons.picture_as_pdf_rounded,
                    () => _exportData('pdf')
            ),

            const SizedBox(height: 30),
            _buildSectionTitle("ANALYSE MENSUELLE"),
            const SizedBox(height: 15),

            // Graphique simplifié (Placeholder pour un widget type fl_chart)
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.withOpacity(0.1))
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bar_chart_rounded, color: Colors.grey, size: 40),
                    Text("Graphique des flux de trésorerie", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: Color(0xFF232435),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 10))]
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStat("REVENUS", "+${_totalRevenu.toStringAsFixed(0)} €", primaryColor),
              Container(width: 1, height: 40, color: Colors.white24),
              _buildStat("DÉPENSES", "-${_totalDepenses.toStringAsFixed(0)} €", Colors.redAccent),
            ],
          ),
          const Divider(height: 40, color: Colors.white10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("BÉNÉFICE NET", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
              Text("${(_totalRevenu - _totalDepenses).toStringAsFixed(2)} €",
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 1)),
        const SizedBox(height: 5),
        Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1));
  }

  Widget _buildExportTile(String title, String sub, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: Colors.grey.withOpacity(0.1))
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.black),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(sub, style: const TextStyle(fontSize: 11)),
        trailing: const Icon(Icons.download_rounded, size: 20),
        onTap: onTap,
      ),
    );
  }

  // --- LOGIQUE D'EXPORT ---
  void _exportData(String type) {
    // Ici, on appelle le service d'export (comme celui que tu as dans ton fichier precompta.derniertxt.txt)
    // qui va transformer le cache de l'ApiService en fichier Excel ou PDF téléchargeable.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Génération de l'export $type en cours...")),
    );
  }
}
