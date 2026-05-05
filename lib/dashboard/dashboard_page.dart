import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../l10n/app_localizations.dart';
import '../models/invoice.dart';
import '../models/task.dart';
import '../models/entity.dart';
import '../services/api_service.dart';
import '../pages/entreprise.dart';
import '../pages/rdv_page.dart';
import '../pages/budget_page.dart';
import '../pages/settings_page.dart';
import '../pages/taches_page.dart';
import '../widgets/professional_background.dart';
import 'dart:convert';


class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final ApiService _apiService = ApiService();
  bool _notificationsEnabled = true;

  List<Invoice> _unpaidCustomerInvoices = [];
  List<Invoice> _unpaidSupplierInvoices = [];
  List<Invoice> _pendingPdpInvoices = [];
  List<String> _smartAlerts = [];
  List<Invoice> _allInvoices = [];

  bool _isLoading = true;
  int _selectedIndex = 0;
  final Color primaryColor = const Color(0xFF49F6C7);

  @override
  void initState() {
    super.initState();
    _loadData();

    Timer.periodic(const Duration(seconds: 10), (_) {
      _loadData();
    });
  }


  Future<void> _loadData() async {
    if (!mounted) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final achats = await _apiService.fetchInvoices(InvoiceType.achat);
      final ventes = await _apiService.fetchInvoices(InvoiceType.vente);
      final t = await _apiService.fetchTasks();
      _allInvoices = [...achats, ...ventes];

      _generateSmartAlerts(achats, ventes);

      if (mounted) {
        setState(() {
          _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
          _unpaidSupplierInvoices = achats.where((i) => !i.isPaid && (i.pdpStatus == PdpStatus.confirmed || i.pdpStatus == PdpStatus.none || i.status == InvoiceStatus.validated)).toList();
          _unpaidCustomerInvoices = ventes.where((i) => !i.isPaid).toList();
          _pendingPdpInvoices = achats.where((inv) => inv.pdpStatus == PdpStatus.received).toList()..sort((a, b) => b.date.compareTo(a.date));
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }



  void _generateSmartAlerts(List<Invoice> achats, List<Invoice> ventes) {
    _smartAlerts.clear();
    final now = DateTime.now();

    double mrr = ventes.where((i) => i.date.month == now.month && i.date.year == now.year).fold(0, (sum, i) => sum + i.amountTTC);
    if (mrr > 0) _smartAlerts.add("Situation Financière : Votre MRR ce mois-ci est de ${mrr.toStringAsFixed(2)} €.");

    final inactiveThreshold = now.subtract(const Duration(days: 45));
    final activeClientsIds = ventes.where((i) => i.date.isAfter(inactiveThreshold)).map((i) => i.supplierOrClientId).toSet();
    final allClientsIds = ventes.map((i) => i.supplierOrClientId).toSet();
    int inactiveCount = allClientsIds.length - activeClientsIds.length;
    if (inactiveCount > 0) _smartAlerts.add("Alerte Churn : $inactiveCount clients sont devenus inactifs récemment.");

    Map<String, List<int>> frequency = {};
    for (var inv in achats) {
      frequency[inv.supplierOrClientName] ??= [];
      if (!frequency[inv.supplierOrClientName]!.contains(inv.date.month)) {
        frequency[inv.supplierOrClientName]!.add(inv.date.month);
      }
    }

    frequency.forEach((name, months) {
      if (months.length >= 3) {
        bool hasCurrentMonth = achats.any((i) => i.supplierOrClientName == name && i.date.month == now.month && i.date.year == now.year);
        if (!hasCurrentMonth) {
          _smartAlerts.add("Facture non parvenue : Nous n'avons pas reçu la facture récurrente de $name ce mois-ci.");
        }
      }
    });
  }

  void _openAiAssistant() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "IA",
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (ctx, anim1, anim2) {
        return Align(
          alignment: Alignment.topCenter,
          child: _AiTopAssistant(
            invoices: _allInvoices,
            apiService: _apiService,
          ),
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, -1), end: const Offset(0, 0)).animate(anim1),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final List<Widget> pages = [
      ProfessionalBackground(child: _buildHomeContent()),
      EntreprisePage(onBack: () => _onItemTapped(0)),
      SettingsPage(onBack: () => _onItemTapped(0))
    ];
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: isDark ? const Color(0xFF232435) : Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.dashboard_outlined), label: t.home),
          BottomNavigationBarItem(icon: const Icon(Icons.business_outlined), label: t.entreprise),
          BottomNavigationBarItem(icon: const Icon(Icons.settings_outlined), label: t.settings),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    final t = AppLocalizations.of(context);
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GestureDetector(onTap: _openAiAssistant, child: _buildAIAssistanceBar()),
          const SizedBox(height: 20),
          if (_pendingPdpInvoices.isNotEmpty) _buildPdpNotificationSection(),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 1.5,
            children: [
              _buildServiceCard(t.entreprise, Icons.business, const EntreprisePage()),
              _buildServiceCard(t.budget, Icons.account_balance_wallet, const BudgetPage()),
              _buildServiceCard(t.taches, Icons.check_circle_outline, const TachesPage()),
              _buildServiceCard(t.rdv, Icons.calendar_today, const RdvPage()),
            ],
          ),
          const SizedBox(height: 24),
          if (_notificationsEnabled && _smartAlerts.isNotEmpty) _buildSmartAlertsSection(),
          const SizedBox(height: 24),
          if (_notificationsEnabled && (_unpaidCustomerInvoices.isNotEmpty || _unpaidSupplierInvoices.isNotEmpty)) _buildUrgentInvoicesSection(),
        ],
      ),
    );
  }

  Widget _buildAIAssistanceBar() {
    final t = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF232435) : Colors.white, borderRadius: BorderRadius.circular(30), border: Border.all(color: primaryColor.withOpacity(0.5), width: 1.5)),
      child: Row(children: [
        Icon(Icons.auto_awesome, color: primaryColor, size: 24),
        const SizedBox(width: 12),
        Expanded(child: Text(t.howCanIHelp, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 15, fontWeight: FontWeight.w500))),
        const Icon(Icons.mic_none, color: Colors.grey),
      ]),
    );
  }

  Widget _buildSmartAlertsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF232435), borderRadius: BorderRadius.circular(24)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("INTELLIGENCE alt.", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
        const SizedBox(height: 20),
        ..._smartAlerts.map((alert) => _buildBandeau(title: alert.split(':')[0], color: alert.contains('Facture') ? Colors.orange : primaryColor, content: alert.contains(':') ? alert.split(':')[1].trim() : alert, onDone: () {})),
      ]),
    );
  }

  Widget _buildBandeau({required String title, required Color color, required String content, required VoidCallback onDone}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(children: [
        Container(width: 4, height: 35, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)), const SizedBox(height: 2), Text(content, style: const TextStyle(color: Colors.white70, fontSize: 11))])),
      ]),
    );
  }

  Widget _buildUrgentInvoicesSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF232435) : Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("RELANCES PRIORITAIRES", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 12),
        ..._unpaidCustomerInvoices.take(2).map((inv) => ListTile(
          contentPadding: EdgeInsets.zero,
          title: Row(
            children: [
              Expanded(
                child: Text(
                  inv.supplierOrClientName,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
              _buildPdpStatusBadge(inv),
            ],
          ),
          subtitle: Text("${inv.amountTTC}€ - Impayée", style: const TextStyle(fontSize: 11)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () => _sendInvoice(inv),
                child: const Text(
                  "ENVOYER",
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _showCelebration("Relance envoyée à ${inv.supplierOrClientName}"),
                child: const Text(
                  "RELANCER",
                  style: TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
        )),
      ]),
    );
  }
  void _showCelebration(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.green[600], behavior: SnackBarBehavior.floating));
  }


  Future<void> _sendInvoice(Invoice inv) async {
    try {
      final result = await _apiService.sendInvoice(inv.id);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Facture envoyée via ${result['channel']} ✅"),
          backgroundColor: Colors.green,
        ),
      );

      _loadData(); // refresh
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur envoi : $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }




  Widget _buildServiceCard(String title, IconData icon, Widget page) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)).then((_) => _loadData()),
      child: Container(
        decoration: BoxDecoration(color: isDark ? const Color(0xFF232435) : Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 28, color: isDark ? primaryColor : Colors.black87), const SizedBox(height: 8), Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isDark ? Colors.white : Colors.black87))]),
      ),
    );
  }

  void _onItemTapped(int index) { setState(() => _selectedIndex = index); if (index == 0) _loadData(); }

  Widget _buildPdpNotificationSection() {
    return Column(
      children: _pendingPdpInvoices.map((inv) => Container(
        margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(Icons.mark_as_unread, color: primaryColor, size: 18), const SizedBox(width: 10), const Text("FACTURE PDP REÇUE", style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)), const Spacer(), Text("${inv.amountTTC} ${inv.currency}", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 12))]),
          const SizedBox(height: 10), Text("${inv.supplierOrClientName} - N° ${inv.number}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 15),
          Row(children: [
            Expanded(child: ElevatedButton(onPressed: () => _validatePdpInvoice(inv), style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.black), child: const Text("ACCEPTER", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)))),
            const SizedBox(width: 10),
            Expanded(child: OutlinedButton(onPressed: () => _rejectPdpInvoice(inv), style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent)), child: const Text("REJETTER", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)))),
          ]),
        ]),
      )).toList(),
    );
  }


  Widget _buildPdpStatusBadge(Invoice inv) {
    switch (inv.pdpStatus) {
      case 'sent':
        return _badge("ENVOYÉ", Colors.orange);
      case 'confirmed':
        return _badge("ACCEPTÉ", Colors.green);
      case 'rejected':
        return _badge("REJETÉ", Colors.red);
      case 'received':
        return _badge("REÇU", Colors.blue);
      default:
        return const SizedBox();
    }
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }



  Future<void> _validatePdpInvoice(Invoice inv) async { await _apiService.updateInvoice(inv.id, {'pdpStatus': 'confirmed', 'status': 'validated'}); _showCelebration("Facture confirmée !"); _loadData(); }
  Future<void> _rejectPdpInvoice(Invoice inv) async { await _apiService.updateInvoice(inv.id, {'pdpStatus': 'rejected', 'status': 'rejected'}); _loadData(); }
}



class _AiTopAssistant extends StatefulWidget {
  final List<Invoice> invoices;
  final ApiService apiService;
  const _AiTopAssistant({required this.invoices, required this.apiService});

  @override
  State<_AiTopAssistant> createState() => _AiTopAssistantState();
}

class _AiTopAssistantState extends State<_AiTopAssistant> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isTyping = false;

  void _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;
    String userMsg = _controller.text;

    setState(() {
      _messages.add({"role": "user", "text": userMsg});
      _isTyping = true;
      _controller.clear();
    });

    _scrollToBottom();

    try {
      // 1. Préparer le contexte
      double totalRevenue = 0;
      double unpaid = 0;

      for (var inv in widget.invoices) {
        if (inv.type == InvoiceType.vente) {
          totalRevenue += inv.amountTTC;
        }
        if (!inv.isPaid) {
          unpaid += inv.amountTTC;
        }
      }

      String contextData = jsonEncode({
        "invoicesCount": widget.invoices.length,
        "totalRevenue": totalRevenue,
        "unpaidAmount": unpaid
      });


      // 2. APPEL CORRECT : On utilise askAI (qui va vers le port 3002)
      // On ne touche plus du tout à .aiProvider
      final response = await widget.apiService.askAI(userMsg, contextData);

      if (mounted) {
        setState(() {
          _messages.add({"role": "ai", "text": response});
          _isTyping = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({
            "role": "ai",
            "text": "Erreur : Impossible de contacter le serveur d'IA ($e)"
          });
          _isTyping = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Color(0xFF1A1B2E),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
          boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 20)],
        ),
        padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 10, 20, 20),
        child: Column(children: [
          Row(children: [
            const Icon(Icons.auto_awesome, color: Color(0xFF49F6C7), size: 20),
            const SizedBox(width: 12),
            const Text("alt. Intelligence", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(icon: const Icon(Icons.close, color: Colors.white70, size: 20), onPressed: () => Navigator.pop(context)),
          ]),
          const Divider(color: Colors.white12, height: 30),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (ctx, idx) {
                bool isAi = _messages[idx]["role"] == "ai";
                return Align(
                  alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isAi ? Colors.white.withOpacity(0.05) : const Color(0xFF49F6C7).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(15),
                      border: isAi ? Border.all(color: Colors.white10) : null,
                    ),
                    child: Text(_messages[idx]["text"]!, style: TextStyle(color: isAi ? Colors.white : const Color(0xFF49F6C7), fontSize: 13, height: 1.4)),
                  ),
                );
              },
            ),
          ),
          if (_isTyping) const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: LinearProgressIndicator(backgroundColor: Colors.transparent, color: Color(0xFF49F6C7), minHeight: 1)),
          const SizedBox(height: 10),
          TextField(
            controller: _controller,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            onSubmitted: (_) => _sendMessage(),
            decoration: InputDecoration(
              hintText: "Expliquez-moi comment créer une facture...",
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
              suffixIcon: IconButton(icon: const Icon(Icons.send_rounded, color: Color(0xFF49F6C7), size: 22), onPressed: _sendMessage),
              filled: true, fillColor: Colors.white.withOpacity(0.05),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
            ),
          ),
        ]),
      ),
    );
  }
}
