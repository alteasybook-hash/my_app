import 'package:flutter/material.dart';
import 'entreprise.dart';
import 'budget_page.dart';
import 'taches_page.dart';
import 'rdv_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Color primaryColor = const Color(0xFF49F6C7);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "alt.",
          style: TextStyle(
            color: Colors.black,
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. ALERTES IA (Haut de page) ---
            _buildIAAlerts(),

            // --- 2. GRILLE DES 4 CARRÉS (Fonctionnalités) ---
            Padding(
              padding: const EdgeInsets.all(20),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                children: [
                  _buildMenuCard(context, "Entreprise", Icons.business_center_outlined, "Gestion Pro", const EntreprisePage()),
                  _buildMenuCard(context, "Budget", Icons.account_balance_wallet_outlined, "Finances", const BudgetPage()),
                  _buildMenuCard(context, "Tâches", Icons.checklist_rtl_outlined, "To-do list", const TachesPage()),
                  _buildMenuCard(context, "RDV", Icons.calendar_month_outlined, "Calendrier", const RdvPage()),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- 3. INFORMATIONS GLOBALES (Bas de page, plus petit) ---
            _buildGlobalStats(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildIAAlerts() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, color: primaryColor, size: 24),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("NOTIFICATIONS IA", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text("3 rapprochements en attente & 1 facture à payer demain.", 
                  style: TextStyle(color: Colors.white, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, String title, IconData icon, String subtitle, Widget destination) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => destination)),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.grey.withOpacity(0.15), width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.black, size: 30),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("RÉSUMÉ GLOBAL", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 15),
          Row(
            children: [
              _buildSmallStat("Trésorerie", "12 450 €", primaryColor),
              _buildSmallStat("Factures", "1 200 €", Colors.redAccent),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildSmallStat("Encaissement", "4 500 €", primaryColor),
              _buildSmallStat("TVA", "890 €", Colors.orangeAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 10)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
