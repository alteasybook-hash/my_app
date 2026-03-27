import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/account.dart';
import '../services/api_service.dart';
import '../app.dart';
import 'settings/chart_of_accounts_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final ApiService _apiService = ApiService();
  final Color primaryColor = const Color(0xFF49F6C7);
  String? _adminPin;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final pin = await _apiService.getAdminPin();
    setState(() {
      _adminPin = pin;
    });
  }

  Future<void> _updatePin() async {
    final controller = TextEditingController(text: _adminPin);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Configurer le PIN Admin"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 4,
          decoration: const InputDecoration(
            labelText: "Nouveau Code PIN (4 chiffres)",
            hintText: "Ex: 1234",
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("ANNULER")),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.length == 4) {
                await _apiService.updateAdminPin(controller.text);
                Navigator.pop(ctx);
                _loadSettings();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Code PIN mis à jour"), backgroundColor: Colors.green),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Le code PIN doit faire 4 chiffres"), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text("ENREGISTRER"),
          )
        ],
      ),
    );
  }


  // 1. SELECTION DU PLAN (Drapeaux)
  void _showAccountingPlanSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) =>
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Choisir un Référentiel Comptable",
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.flag, color: Colors.blue),
                  title: const Text("France (PCG)"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);
                    // AU LIEU D'OUVRIR LE FORMULAIRE, ON OUVRE LA LISTE
                    _showAccountsList("France (PCG)");
                  },
                ),
                _buildComingSoonPlan("UK (COA)"),
                _buildComingSoonPlan("USA (GAAP)"),
                _buildComingSoonPlan("Germany (DATEV)"),
              ],
            ),
          ),
    );
  }

  // 2. NOUVELLE FONCTION : LA LISTE DES COMPTES
  void _showAccountsList(String planName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) =>
          Container(
            height: MediaQuery
                .of(context)
                .size
                .height * 0.8,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(planName, style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(
                          Icons.add_circle, color: Color(0xFF49F6C7), size: 30),
                      onPressed: () {
                        // On ferme la liste pour ouvrir le formulaire d'ajout
                        Navigator.pop(context);
                        _showAddAccountForm(planName);
                      },
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    // On utilise vos comptes par défaut définis dans votre modèle Account
                    itemCount: Account.defaultAccounts.length,
                    itemBuilder: (context, index) {
                      final acc = Account.defaultAccounts[index];
                      return ListTile(
                        title: Text(acc.name),
                        subtitle: Text(acc.number),
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey[100],
                          child: Text(acc.number.substring(0, 1),
                              style: const TextStyle(fontSize: 12)),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }

  // 3. FORMULAIRE D'AJOUT (Appelé par le bouton + de la liste)
  void _showAddAccountForm(String planName) {
    final numController = TextEditingController();
    final nameController = TextEditingController();
    String selectedCurrency = 'EUR';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) =>
          StatefulBuilder(
            builder: (context, setModalState) =>
                Padding(
                  padding: EdgeInsets.only(
                      bottom: MediaQuery
                          .of(context)
                          .viewInsets
                          .bottom,
                      left: 20, right: 20, top: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Ajouter un compte ($planName)",
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 15),
                      TextField(
                        controller: numController,
                        decoration: const InputDecoration(
                            labelText: "Numéro de compte (ex: 512001)",
                            border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        onChanged: (val) => setModalState(() {}),
                      ),
                      if (numController.text.startsWith('512')) ...[
                        const SizedBox(height: 15),
                        DropdownButtonFormField<String>(
                          value: selectedCurrency,
                          decoration: const InputDecoration(
                              labelText: "Devise principale du compte",
                              border: OutlineInputBorder()),
                          items: ['EUR', 'USD', 'GBP', 'CHF']
                              .map((c) =>
                              DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          onChanged: (val) =>
                              setModalState(() => selectedCurrency = val!),
                        ),
                      ],
                      const SizedBox(height: 15),
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                            labelText: "Libellé (ex: Banque Société Générale)",
                            border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor),
                          onPressed: () {
                            Navigator.pop(context);
                            // Après l'enregistrement, on peut réouvrir la liste
                            _showAccountsList(planName);
                          },
                          child: const Text("Enregistrer le compte",
                              style: TextStyle(color: Colors.black)),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
          ),
    );
  }

  void _addNewTaxRate(String country) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) =>
          AlertDialog(
            title: Text("Ajouter un taux pour $country"),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Nouveau taux (%)"),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx),
                  child: const Text("Annuler")),
              TextButton(
                  onPressed: () {
                    final double? rate = double.tryParse(controller.text);
                    if (rate != null) {
                      // Ici, vous devriez appeler une méthode apiService.saveCustomTax(country, rate)
                      setState(() {});
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text("Ajouter")
              ),
            ],
          ),
    );
  }



  // Petit widget pour les plans indisponibles
  Widget _buildComingSoonPlan(String title) {
    return ListTile(
      leading: const Icon(Icons.public, color: Colors.grey),
      title: Text(title, style: const TextStyle(color: Colors.grey)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
        child: const Text(
            "Coming soon", style: TextStyle(fontSize: 10, color: Colors.grey)),
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Choisir la langue"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text("Français"),
              onTap: () {
                MyApp.setLocale(context, const Locale('fr'));
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text("English"),
              onTap: () {
                MyApp.setLocale(context, const Locale('en'));
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text("Deutsch"),
              onTap: () {
                MyApp.setLocale(context, const Locale('de'));
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final currentLocale = Localizations.localeOf(context);
    String languageName = "Français";
    if (currentLocale.languageCode == 'en') languageName = "English";
    if (currentLocale.languageCode == 'de') languageName = "Deutsch";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(t.settings, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader(t.appearance),
          _buildSettingTile(
            icon: Icons.dark_mode_outlined,
            title: "Thème sombre",
            subtitle: "Désactivé (Bientôt disponible)",
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Le mode sombre sera disponible dans la prochaine mise à jour.")),
              );
            },
          ),
          _buildSettingTile(
            icon: Icons.translate,
            title: t.language,
            subtitle: languageName,
            onTap: _showLanguageDialog,
          ),

          const SizedBox(height: 24),
          _buildSectionHeader(t.security),
          _buildSettingTile(
            icon: Icons.lock_outline,
            title: "Code PIN Administration",
            subtitle: _adminPin == null ? "Non configuré" : "****",
            onTap: _updatePin,
            trailing: Icon(Icons.edit_outlined, size: 18, color: primaryColor),
          ),
          _buildSettingTile(
            icon: Icons.fingerprint,
            title: "Biométrie / FaceID",
            subtitle: "Désactivé",
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("La biométrie n'est pas disponible sur ce navigateur.")),
              );
            },
          ),

          const SizedBox(height: 24),
          _buildSectionHeader("COMPTABILITÉ"),
          _buildSettingTile(icon: Icons.list_alt,
            title: t.chartOfAccounts,
            subtitle: "Gérer mes comptes",
            onTap: () {
              // CORRECTION : On appelle la fonction de sélection au lieu de naviguer
              _showAccountingPlanSelector();
            },
          ),

          _buildSettingTile(
            icon: Icons.account_balance_wallet_outlined,
            title: "Devise par défaut",
            subtitle: "EUR (€)",
            onTap: () {},
          ),

          const SizedBox(height: 24),
          _buildSectionHeader(t.notifications),
          SwitchListTile(
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.notifications_active_outlined, color: Colors.blue, size: 20),
            ),
            title: const Text("Notifications push", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: const Text("Alertes factures et rapprochements", style: TextStyle(fontSize: 12)),
            value: _notificationsEnabled,
            onChanged: (v) {
              setState(() {
                _notificationsEnabled = v;
              });
            },
            activeColor: primaryColor,
          ),

          const SizedBox(height: 40),
          Center(
            child: Text(
              "Version 1.2.0 (Web/Desktop Build)",
              style: TextStyle(color: Colors.grey[500], fontSize: 11),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTVASettings() {
    return Scaffold(
      appBar: AppBar(title: const Text("Paramètres TVA par Pays")),
      body: ListView(
        children: [
          _buildCountryTile("France", "TVA FR", Icons.euro),
          _buildCountryTile("Allemagne", "MwSt", Icons.euro),
          _buildCountryTile("Royaume-Uni", "VAT", Icons.currency_pound),
          _buildCountryTile("USA", "Sales Tax", Icons.attach_money),
        ],
      ),
    );
  }

  Widget _buildCountryTile(String country, String taxName, IconData icon) {
    return ListTile(
      leading: Icon(icon),
      title: Text("$country ($taxName)"),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => _showTaxRatesDetail(country, taxName),
    );
  }

  void _showTaxRatesDetail(String country, String taxName) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) =>
          StatefulBuilder(builder: (context, setS) {
            final taxes = _apiService.getTaxesForCountry(country);
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text("Taux disponibles - $taxName",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: taxes.length,
                    itemBuilder: (c, i) =>
                        ListTile(
                          title: Text("${taxes[i]} %"),
                          trailing: IconButton(
                              icon: Icon(Icons.delete), onPressed: () {
                            // Logique de suppression
                          }),
                        ),
                  ),
                ),
                ElevatedButton(
                  child: const Text("Ajouter un taux personnalisé"),
                  onPressed: () => _addNewTaxRate(country),
                ),
              ],
            );
          }),
    );
  }


  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.black, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        trailing: trailing ?? const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
      ),
    );
  }
}
