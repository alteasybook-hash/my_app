import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class GlobalHistoryPage extends StatefulWidget {
  const GlobalHistoryPage({super.key});  @override
  State<GlobalHistoryPage> createState() => _GlobalHistoryPageState();
}

class _GlobalHistoryPageState extends State<GlobalHistoryPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _historyEntries = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final data = await _apiService.fetchHistory(); // Récupère tout le cache historique
    setState(() {
      _historyEntries = data;
      _historyEntries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _isLoading = false;
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Historique de l'entreprise", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildGroupedHistory(),
    );
  }

  Widget _buildGroupedHistory() {
    if (_historyEntries.isEmpty) {
      return const Center(child: Text("Aucun mouvement enregistré"));
    }

    // Groupement par mois
    Map<String, List<dynamic>> grouped = {};
    for (var entry in _historyEntries) {
      String month = DateFormat.yMMMM('fr_FR').format(entry.timestamp);
      if (!grouped.containsKey(month)) grouped[month] = [];
      grouped[month]!.add(entry);
    }

    return ListView(
      children: grouped.keys.map((month) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ligne de séparation par mois
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    month.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
                  ),
                  const Divider(thickness: 1),
                ],
              ),
            ),
            ...grouped[month]!.map((entry) => _buildHistoryTile(entry)).toList(),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildHistoryTile(dynamic entry) {
    return ListTile(
      dense: true,
      leading: Icon(
        entry.action.toString().contains('deleted') ? Icons.delete_outline : Icons.edit_note,
        color: entry.action.toString().contains('deleted') ? Colors.red : Colors.orange,
      ),
      title: Text(
        "${entry.documentNumber} (${entry.type.toString().split('.').last})",
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        "Le ${DateFormat('dd/MM à HH:mm').format(entry.timestamp)}",
        style: const TextStyle(fontSize: 11),
      ),
      trailing: const Icon(Icons.more_vert, size: 18),
    );
  }
}

// --- AJOUTEZ CETTE FONCTION ---
Widget _buildHistoryMiniBlock(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.only(top: 24.0),
    child: InkWell(
      onTap: () {
        // Lien vers la page d'historique
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const GlobalHistoryPage()));
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.black, // Case noire
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF49F6C7).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                  Icons.history_toggle_off_rounded, color: Color(0xFF49F6C7),
                  size: 24),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "HISTORIQUE GÉNÉRAL",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 0.5
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Suivi des modifications et suppressions",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white, size: 20),
          ],
        ),
      ),
    ),
  );
}