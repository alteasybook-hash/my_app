import 'package:flutter/material.dart';
import '../../models/invoice.dart';
import '../../models/entity.dart';
import '../../models/supplier.dart';
import '../../models/account_fr.dart';
import '../../services/api_service.dart';
import '../../widgets/invoice_dialogs.dart';

class ClientsFacturationPage extends StatefulWidget {
  const ClientsFacturationPage({super.key});

  @override
  State<ClientsFacturationPage> createState() => _ClientsFacturationPageState();
}

class _ClientsFacturationPageState extends State<ClientsFacturationPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  final Color primaryColor = const Color(0xFF49F6C7);

  List<Supplier> _clients = [];
  List<Invoice> _invoices = [];
  List<Entity> _entities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final clients = await _apiService.fetchCustomers();
      final invoices = await _apiService.fetchInvoices(InvoiceType.vente);
      final entities = await _apiService.fetchEntities();
      setState(() {
        _clients = clients;
        _invoices = invoices;
        _entities = entities;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Erreur chargement ClientsPage: $e");
      setState(() => _isLoading = false);
    }
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
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
              _buildClientsView(),
              _buildFacturesView(),
            ],
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            _showAddClientForm();
          } else {
            _showCreateInvoiceForm();
          }
        },
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _buildClientsView() {
    if (_clients.isEmpty) return const Center(child: Text("Aucun client enregistré"));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _clients.length,
      itemBuilder: (context, index) {
        final client = _clients[index];
        final entity = _entities.firstWhere((e) => e.id == client.entityId, orElse: () => Entity(id: '', name: 'Inconnue', email: '', address: '', idNumber: ''));
        return _buildClientCard(client, entity.name);
      },
    );
  }

  Widget _buildClientCard(Supplier client, String entityName) {
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
          child: Text(client.name.substring(0, 1), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ),
        title: Text(client.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(client.email, style: const TextStyle(fontSize: 12)),
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
              child: Text("Entité: $entityName", style: const TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }

  Widget _buildFacturesView() {
    if (_invoices.isEmpty) return const Center(child: Text("Aucune facture de vente"));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _invoices.length,
      itemBuilder: (context, index) {
        final inv = _invoices[index];
        return _buildInvoiceCard(inv);
      },
    );
  }

  Widget _buildInvoiceCard(Invoice inv) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: ListTile(
        title: Text(inv.number, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(inv.supplierOrClientName),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text("${inv.amountTTC.toStringAsFixed(2)} ${inv.currency}", style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: inv.status == InvoiceStatus.paid ? primaryColor.withOpacity(0.3) : Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(inv.status.toString().split('.').last.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddClientForm() async {
    final newClient = await InvoiceDialogs.showPartnerForm(
      context: context, 
      type: InvoiceType.vente, 
      accounts: Account.allAccounts, 
      entities: _entities
    );
    if (newClient != null) {
      await _apiService.createCustomer(newClient);
      _loadData();
    }
  }

  void _showCreateInvoiceForm() {
    InvoiceDialogs.showInvoiceForm(
      context: context,
      type: InvoiceType.vente,
      entities: _entities,
      partners: _clients,
      accounts: Account.allAccounts,
      quotes: [],
      onSave: (inv) async {
        await _apiService.createInvoice(inv);
        _loadData();
      },
      onTriggerIA: (l, a, p, s) {},
    );
  }
}
