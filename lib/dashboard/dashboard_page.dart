import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/invoice.dart';
import '../models/task.dart';
import '../models/employee.dart';
import '../services/api_service.dart';
import '../pages/entreprise.dart';
import '../pages/rdv_page.dart';
import '../pages/budget_page.dart';
import '../pages/settings_page.dart';
import '../pages/taches_page.dart';
import '../widgets/reminder_dialog.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final ApiService _apiService = ApiService();
  
  List<Invoice> _unpaidCustomerInvoices = [];
  List<Invoice> _unpaidSupplierInvoices = [];
  List<Task> _tasks = [];
  List<Employee> _newEmployees = [];
  
  bool _isLoading = true;
  int _selectedIndex = 0;
  final Color primaryColor = const Color(0xFF49F6C7);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final achats = await _apiService.fetchInvoices(InvoiceType.achat);
      final ventes = await _apiService.fetchInvoices(InvoiceType.vente);
      final t = await _apiService.fetchTasks();
      final employees = await _apiService.fetchEmployees();
      
      final now = DateTime.now();
      
      if (mounted) {
        setState(() {
          _unpaidSupplierInvoices = achats.where((i) => !i.isPaid).toList();
          _unpaidCustomerInvoices = ventes.where((i) => !i.isPaid).toList();
          _tasks = t.where((task) => !task.isDone).toList();
          
          _newEmployees = employees.where((e) {
            final start = e.startDate;
            return (start.year == now.year && start.month == now.month && start.day == now.day) ||
                   (start.isAfter(now) && start.isBefore(now.add(const Duration(days: 7))));
          }).toList();
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildHomeContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // BARRE D'AIDE IA (Remplace "Services")
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Color(0xFF232435),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
          ),
          child: const Row(
            children: [
              Icon(Icons.auto_awesome, color: Color(0xFF49F6C7), size: 20),
              SizedBox(width: 12),
              Text("Comment puis-je vous aider ?", style: TextStyle(color: Colors.white, fontSize: 14)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildServiceCard("Entreprise", Icons.business, const EntreprisePage()),
            _buildServiceCard("Budget", Icons.account_balance_wallet, const BudgetPage()),
            _buildServiceCard("Tâches", Icons.check_circle_outline, const TachesPage()),
            _buildServiceCard("RDV", Icons.calendar_today, const RdvPage()),
          ],
        ),
        const SizedBox(height: 24),
        
        // SECTION ALERTES IA
        _buildAIPrioritySection(),
        
        const SizedBox(height: 24),
        
        if (_unpaidCustomerInvoices.isNotEmpty || _unpaidSupplierInvoices.isNotEmpty) 
          _buildUrgentInvoicesSection(),
      ],
    );
  }

  Widget _buildAIPrioritySection() {
    List<Widget> alerts = [];

    if (_unpaidCustomerInvoices.isNotEmpty) {
      alerts.add(_buildBandeau(
        title: "Relance client requise",
        color: Colors.redAccent,
        content: "${_unpaidCustomerInvoices.length} facture(s) client en attente de paiement.",
        onDone: () => _showCelebration("Relance effectuée !"),
      ));
    }

    if (_unpaidSupplierInvoices.isNotEmpty) {
       alerts.add(_buildBandeau(
        title: "Paiement fournisseur",
        color: Colors.orange,
        content: "${_unpaidSupplierInvoices.length} facture(s) fournisseur à régler prochainement.",
        onDone: () => _showCelebration("Paiement planifié !"),
      ));
    }

    if (_newEmployees.isNotEmpty) {
      final emp = _newEmployees.first;
      alerts.add(_buildBandeau(
        title: "IA : Optimisation RH",
        color: const Color(0xFF49F6C7),
        content: "Arrivée de ${emp.firstName} ${emp.lastName} prévue le ${DateFormat('dd/MM').format(emp.startDate)}.",
        onDone: () => _showCelebration("Accueil prêt !"),
      ));
    }

    final hour = DateTime.now().hour;
    if (hour >= 12 && hour < 14) {
      alerts.add(_buildBandeau(
        title: "Temps de pause",
        color: Colors.blueAccent,
        content: "Il est midi, l'IA vous suggère une pause déjeuner bien méritée.",
        onDone: () => _showCelebration("Bon appétit !"),
      ));
    }

    if (alerts.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF232435),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Alertes",
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          ...alerts,
        ],
      ),
    );
  }

  Widget _buildBandeau({required String title, required Color color, required String content, required VoidCallback onDone}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: InkWell(
        onTap: onDone,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 4,
              height: 38,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Color(0xFF49F6C7), fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUrgentInvoicesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text("Suivi des Paiements", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          
          if (_unpaidCustomerInvoices.isNotEmpty) ...[
            const Text("Clients à relancer :", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
            ..._unpaidCustomerInvoices.take(3).map((inv) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(inv.supplierOrClientName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              subtitle: Text("${inv.amountTTC}€ - Échéance: ${inv.dueDate != null ? DateFormat('dd/MM').format(inv.dueDate!) : 'N/A'}", style: const TextStyle(fontSize: 12)),
              trailing: ElevatedButton.icon(
                onPressed: () => _showReminderDialog(inv),
                icon: const Icon(Icons.auto_awesome, size: 14),
                label: const Text("RELANCER IA", style: TextStyle(fontSize: 11)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor.withOpacity(0.2),
                  foregroundColor: Colors.black87,
                  elevation: 0,
                ),
              ),
            )),
          ],
        ],
      ),
    );
  }

  void _showCelebration(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.stars, color: Colors.yellow),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showReminderDialog(Invoice inv) async {
    try {
      final result = await showDialog<String>(
        context: context,
        builder: (ctx) => ReminderDialog(
          invoice: inv,
          ai: _apiService.aiProvider,
        ),
      );

      if (result != null) {
        _showCelebration("Email de relance envoyé à ${inv.supplierOrClientName} !");
      }
    } catch (e) {
      debugPrint("Erreur relance: $e");
    }
  }

  Widget _buildServiceCard(String title, IconData icon, Widget page) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)).then((_) => _loadData()),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: Colors.black87),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomeContent(),
      const EntreprisePage(),
      const SettingsPage(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _selectedIndex == 0
          ? AppBar(
              title: const Text("alt.", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 24)),
              backgroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.business_outlined), activeIcon: Icon(Icons.business), label: 'Entreprise'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: 'Paramètres'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 10,
      ),
    );
  }
}
