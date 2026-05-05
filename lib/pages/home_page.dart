import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'entreprise.dart';
import 'budget_page.dart';
import 'taches_page.dart';
import 'rdv_page.dart';
import '../l10n/app_localizations.dart';
import '../models/invoice.dart';
import '../services/api_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Color primaryColor = const Color(0xFF49F6C7);
  final ApiService _apiService = ApiService();
  List<Invoice> _pendingPdpInvoices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPdpData();
  }

  Future<void> _loadPdpData() async {
    try {
      final purchases = await _apiService.fetchInvoices(InvoiceType.achat);
      
      if (mounted) {
        setState(() {
          // On filtre les factures reçues via PDP qui attendent une action
          _pendingPdpInvoices = purchases.where((inv) => 
            inv.pdpStatus == PdpStatus.received
          ).toList()..sort((a, b) => b.date.compareTo(a.date));
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _validateInvoice(Invoice inv) async {
    await _apiService.updateInvoice(inv.id, {
      'pdpStatus': 'confirmed',
      'status': 'validated'
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Facture ${inv.number} acceptée"), backgroundColor: Colors.green)
    );
    _loadPdpData();
  }

  Future<void> _rejectInvoice(Invoice inv) async {
    await _apiService.updateInvoice(inv.id, {
      'pdpStatus': 'none',
      'status': 'rejected'
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Facture ${inv.number} rejetée"), backgroundColor: Colors.red)
    );
    _loadPdpData();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
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
      body: RefreshIndicator(
        onRefresh: _loadPdpData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. ALERTES PDP ACTIONNABLES ---
              _buildActionablePDPNotifications(t),

              // --- 2. GRILLE DES 4 CARRÉS ---
              Padding(
                padding: const EdgeInsets.all(20),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  children: [
                    _buildMenuCard(context, t.entreprise, Icons.business_center_outlined, "Gestion Pro", const EntreprisePage()),
                    _buildMenuCard(context, t.budget, Icons.account_balance_wallet_outlined, "Finances", const BudgetPage()),
                    _buildMenuCard(context, t.taches, Icons.checklist_rtl_outlined, "To-do list", const TachesPage()),
                    _buildMenuCard(context, t.rdv, Icons.calendar_month_outlined, "Calendrier", const RdvPage()),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // --- 3. RÉSUMÉ GLOBAL ---
              _buildGlobalStats(t),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionablePDPNotifications(AppLocalizations t) {
    if (_pendingPdpInvoices.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(Icons.auto_awesome, color: primaryColor.withOpacity(0.5), size: 24),
            const SizedBox(width: 15),
            const Text("Aucune facture PDP en attente.", style: TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      );
    }

    return Column(
      children: _pendingPdpInvoices.map((inv) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.mark_as_unread, color: primaryColor, size: 20),
                const SizedBox(width: 10),
                Text("FACTURE PDP REÇUE", style: TextStyle(color: Colors.grey[400], fontSize: 10, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text("${inv.amountTTC.toStringAsFixed(2)} ${inv.currency}", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              "${inv.supplierOrClientName} - N° ${inv.number}",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            Text(
              "Compte de charge : ${inv.expenseAccount ?? 'N/A'}",
              style: TextStyle(color: Colors.grey[400], fontSize: 11),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _validateInvoice(inv),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text("ACCEPTER", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _rejectInvoice(inv),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text("REJETER", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      )).toList(),
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

  Widget _buildGlobalStats(AppLocalizations t) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.reports.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
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
