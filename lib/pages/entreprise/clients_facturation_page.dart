import 'package:flutter/material.dart';

class ClientsFacturationPage extends StatefulWidget {
  const ClientsFacturationPage({super.key});

  @override
  State<ClientsFacturationPage> createState() => _ClientsFacturationPageState();
}

class _ClientsFacturationPageState extends State<ClientsFacturationPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Color primaryColor = const Color(0xFF49F6C7);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Clients & Facturation',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: primaryColor,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Clients'),
            Tab(text: 'Factures'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildClientsView(),
          _buildFacturesView(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            _showAddClientSheet();
          } else {
            _showCreateInvoiceSheet();
          }
        },
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _buildClientsView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildClientCard('Tech Solutions Inc.', 'contact@techsolutions.com', 'Paris, France'),
        _buildClientCard('Design Studio', 'hello@designstudio.io', 'Berlin, Germany'),
      ],
    );
  }

  Widget _buildClientCard(String name, String email, String location) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: primaryColor.withOpacity(0.2),
          child: Text(name.substring(0, 1), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$email\n$location', style: const TextStyle(fontSize: 12)),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }

  Widget _buildFacturesView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInvoiceCard('INV-2024-001', 'Tech Solutions Inc.', '1 500.00 €', 'Payée'),
        _buildInvoiceCard('INV-2024-002', 'Design Studio', '2 300.00 €', 'En attente'),
      ],
    );
  }

  Widget _buildInvoiceCard(String ref, String client, String amount, String status) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: ListTile(
        title: Text(ref, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(client),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(amount, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: status == 'Payée' ? primaryColor.withOpacity(0.3) : Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(status, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddClientSheet() {
    // Simulation simple pour le MVP
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ouverture du formulaire client...')),
    );
  }

  void _showCreateInvoiceSheet() {
    // Simulation simple pour le MVP
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ouverture du générateur de facture...')),
    );
  }
}
