import 'package:flutter/material.dart';
import '../../models/account.dart';
import '../../services/api_service.dart';

class ChartOfAccountsPage extends StatefulWidget {
  const ChartOfAccountsPage({super.key});

  @override
  State<ChartOfAccountsPage> createState() => _ChartOfAccountsPageState();
}

class _ChartOfAccountsPageState extends State<ChartOfAccountsPage> {
  final ApiService _apiService = ApiService();
  List<Account> _accounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    setState(() => _isLoading = true);
    final accs = await _apiService.fetchAccounts();
    setState(() {
      _accounts = accs;
      _isLoading = false;
    });
  }

  void _showAddAccountDialog() {
    final numberController = TextEditingController();
    final nameController = TextEditingController();
    String selectedType = 'charge';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Ajouter un compte"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: numberController,
                decoration: const InputDecoration(labelText: "Numéro de compte (ex: 601)"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Nom du compte"),
              ),
              DropdownButton<String>(
                value: selectedType,
                isExpanded: true,
                items: ['charge', 'produit', 'banque', 'tiers']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t.toUpperCase())))
                    .toList(),
                onChanged: (val) => setState(() => selectedType = val!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("ANNULER")),
            ElevatedButton(
              onPressed: () async {
                if (numberController.text.isNotEmpty && nameController.text.isNotEmpty) {
                  final newAcc = Account(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    number: numberController.text,
                    name: nameController.text,
                    type: selectedType,
                    accountNumber: numberController.text,
                  );
                  await _apiService.createAccount(newAcc);
                  Navigator.pop(ctx);
                  _loadAccounts();
                }
              },
              child: const Text("AJOUTER"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Plan Comptable", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _accounts.length,
              itemBuilder: (ctx, idx) {
                final acc = _accounts[idx];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getTypeColor(acc.type).withOpacity(0.1),
                    child: Text(acc.number.substring(0, 1), style: TextStyle(color: _getTypeColor(acc.type), fontWeight: FontWeight.bold)),
                  ),
                  title: Text(acc.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text("Compte n° ${acc.number} (${acc.type})"),
                  trailing: const Icon(Icons.chevron_right, size: 16),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAccountDialog,
        backgroundColor: const Color(0xFF49F6C7),
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'charge': return Colors.red;
      case 'produit': return Colors.green;
      case 'banque': return Colors.blue;
      case 'tiers': return Colors.orange;
      default: return Colors.grey;
    }
  }
}
