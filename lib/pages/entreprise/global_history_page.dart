import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../widgets/professional_background.dart';

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
    final data = await _apiService.fetchHistory(); 
    if (mounted) {
      setState(() {
        _historyEntries = data;
        _historyEntries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ProfessionalBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent, // Pour voir le background dégradé
        appBar: AppBar(
          title: Text(
            "Historique de l'entreprise", 
            style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold)
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: isDark ? Colors.white : Colors.black, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor))
            : _buildGroupedHistory(),
      ),
    );
  }

  Widget _buildGroupedHistory() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_historyEntries.isEmpty) {
      return Center(
        child: Text(
          "Aucun mouvement enregistré",
          style: TextStyle(color: isDark ? Colors.white70 : Colors.grey),
        ),
      );
    }

    Map<String, List<dynamic>> grouped = {};
    for (var entry in _historyEntries) {
      String month = DateFormat.yMMMM('fr_FR').format(entry.timestamp);
      if (!grouped.containsKey(month)) grouped[month] = [];
      grouped[month]!.add(entry);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: grouped.keys.map((month) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 24, 0, 8),
              child: Text(
                month.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.2, color: Colors.blueGrey),
              ),
            ),
            const Divider(thickness: 0.5),
            ...grouped[month]!.map((entry) => _buildHistoryTile(entry)).toList(),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildHistoryTile(dynamic entry) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isDeleted = entry.action.toString().contains('deleted');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF232435) : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.withOpacity(0.1)),
      ),
      child: ListTile(
        dense: true,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (isDeleted ? Colors.red : Colors.orange).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isDeleted ? Icons.delete_outline : Icons.edit_note,
            color: isDeleted ? Colors.red : Colors.orange,
            size: 20,
          ),
        ),
        title: Text(
          "${entry.documentNumber} (${entry.type.toString().split('.').last})",
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
        ),
        subtitle: Text(
          "Le ${DateFormat('dd/MM à HH:mm').format(entry.timestamp)}",
          style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54),
        ),
        trailing: Icon(Icons.chevron_right, size: 16, color: isDark ? Colors.white24 : Colors.grey),
      ),
    );
  }
}
