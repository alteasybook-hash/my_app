import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../models/account.dart';
import '../services/api_service.dart';
import '../app.dart';
import 'settings/chart_of_accounts_page.dart';

class SettingsPage extends StatefulWidget {
  final VoidCallback? onBack;
  const SettingsPage({super.key, this.onBack});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final ApiService _apiService = ApiService();
  final Color primaryColor = const Color(0xFF49F6C7);
  String? _adminPin;
  bool _notificationsEnabled = true;
  List<Account> _customAccounts = [];
  ThemeMode _currentThemeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final pin = await _apiService.getAdminPin();
    final accs = await _apiService.fetchAccounts();
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _adminPin = pin;
      _customAccounts = accs;
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    });
  }

  Future<void> _saveNotificationPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    setState(() => _notificationsEnabled = value);
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

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Choisir le thème"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.light_mode_outlined),
              title: const Text("Clair"),
              trailing: _currentThemeMode == ThemeMode.light ? Icon(Icons.check, color: primaryColor) : null,
              onTap: () {
                setState(() => _currentThemeMode = ThemeMode.light);
                MyApp.setTheme(context, ThemeMode.light);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode_outlined),
              title: const Text("Sombre"),
              trailing: _currentThemeMode == ThemeMode.dark ? Icon(Icons.check, color: primaryColor) : null,
              onTap: () {
                setState(() => _currentThemeMode = ThemeMode.dark);
                MyApp.setTheme(context, ThemeMode.dark);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_suggest_outlined),
              title: const Text("Système"),
              trailing: _currentThemeMode == ThemeMode.system ? Icon(Icons.check, color: primaryColor) : null,
              onTap: () {
                setState(() => _currentThemeMode = ThemeMode.system);
                MyApp.setTheme(context, ThemeMode.system);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

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

  void _showAccountsList(String planName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) =>
          StatefulBuilder(builder: (ctx, setS) => Container(
            height: MediaQuery.of(context).size.height * 0.8,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(planName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 28),
                      onSelected: (val) async {
                        if (val == 'add') {
                          await _showAddAccountForm(planName);
                          final updated = await _apiService.fetchAccounts();
                          setS(() { _customAccounts = updated; });
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(value: 'add', child: Row(children: [Icon(Icons.add_circle_outline, color: Colors.green), SizedBox(width: 10), Text("Ajouter un compte")])),
                      ],
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: _customAccounts.length,
                    itemBuilder: (context, index) {
                      final acc = _customAccounts[index];
                      bool isDefault = int.tryParse(acc.id) != null && acc.id.length < 5;

                      return ListTile(
                        title: Text(acc.name),
                        subtitle: Text(acc.number),
                        leading: CircleAvatar(
                          backgroundColor: acc.number.startsWith('512') ? const Color(0xFF49F6C7).withOpacity(0.2) : Colors.grey[100],
                          child: Text(acc.number.substring(0, 1), style: const TextStyle(fontSize: 12)),
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (val) async {
                            if (val == 'edit') {
                              await _showAddAccountForm(planName, accountToEdit: acc);
                              final updated = await _apiService.fetchAccounts();
                              setS(() { _customAccounts = updated; });
                            } else if (val == 'delete') {
                              _confirmDeleteAccount(acc, () async {
                                await _apiService.deleteAccount(acc.id);
                                final updated = await _apiService.fetchAccounts();
                                setS(() { _customAccounts = updated; });
                              });
                            }
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined), SizedBox(width: 10), Text("Modifier")])),
                            if (!isDefault) const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, color: Colors.red), SizedBox(width: 10), Text("Supprimer", style: TextStyle(color: Colors.red))])),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          )),
    );
  }

  void _confirmDeleteAccount(Account acc, VoidCallback onConfirmed) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Supprimer le compte"),
        content: Text("Voulez-vous vraiment supprimer le compte ${acc.number} - ${acc.name} ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("ANNULER")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirmed();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("SUPPRIMER", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Future<void> _showAddAccountForm(String planName, {Account? accountToEdit}) async {
    final numController = TextEditingController(text: accountToEdit?.number);
    final nameController = TextEditingController(text: accountToEdit?.name);
    String selectedCurrency = accountToEdit?.currency ?? 'EUR';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(accountToEdit == null ? "Ajouter un compte ($planName)" : "Modifier le compte", style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              TextField(
                controller: numController,
                decoration: const InputDecoration(labelText: "Numéro de compte (ex: 512001)", border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                onChanged: (val) => setModalState(() {}),
              ),
              if (numController.text.startsWith('512')) ...[
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: selectedCurrency,
                  decoration: const InputDecoration(labelText: "Devise principale du compte", border: OutlineInputBorder()),
                  items: ['EUR', 'USD', 'GBP', 'CHF'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) => setModalState(() => selectedCurrency = val!),
                ),
              ],
              const SizedBox(height: 15),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Libellé (ex: Banque Société Générale)", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                  onPressed: () async {
                    if (numController.text.isEmpty || nameController.text.isEmpty) return;

                    final newAcc = Account(
                      id: accountToEdit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                      number: numController.text,
                      name: nameController.text,
                      type: numController.text.startsWith('51') ? 'banque' : 'autre',
                      currency: selectedCurrency,
                    );

                    await _apiService.createAccount(newAcc);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(accountToEdit == null ? "Compte ajouté" : "Compte modifié"), backgroundColor: Colors.green),
                    );
                  },
                  child: const Text("Enregistrer", style: TextStyle(color: Colors.black)),
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
                  onPressed: () async {
                    final double? rate = double.tryParse(controller.text);
                    if (rate != null) {
                      await _apiService.addTaxRate(country, rate);
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

  void _showTaxesList(String country) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(builder: (ctx, setS) {
        final taxes = _apiService.getTaxesForCountry(country);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Taux de taxe : $country", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                  IconButton(
                    icon: Icon(Icons.add_circle_outline, color: primaryColor, size: 28),
                    onPressed: () => _addNewTaxRate(country),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: taxes.length,
                  itemBuilder: (ctx, idx) => ListTile(
                    title: Text("${taxes[idx]} %", style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black)),
                    leading: Icon(Icons.percent, size: 18, color: primaryColor),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  void _showTaxesSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: isDark ? const Color(0xFF232435) : Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(25))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Paramètres de Taxes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
              const SizedBox(height: 20),
              _buildTaxCountryTile("France (TVA FR)", "France"),
              _buildTaxCountryTile("UK (VAT UK)", "UK"),
              _buildTaxCountryTile("Germany (MwSt DE)", "Allemagne"),
              _buildTaxCountryTile("USA (Sales Tax US)", "USA"),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaxCountryTile(String label, String country) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: const Icon(Icons.public, color: Colors.blue),
      title: Text(label, style: TextStyle(color: isDark ? Colors.white : Colors.black)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.pop(context);
        _showTaxesList(country);
      },
    );
  }

  Widget _buildComingSoonPlan(String title) {
    return ListTile(
      leading: const Icon(Icons.public, color: Colors.grey),
      title: Text(title, style: const TextStyle(color: Colors.grey)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
        child: const Text("Coming soon", style: TextStyle(fontSize: 10, color: Colors.grey)),
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
            ListTile(title: const Text("Français"), onTap: () { MyApp.setLocale(context, const Locale('fr')); Navigator.pop(ctx); }),
            ListTile(title: const Text("English"), onTap: () { MyApp.setLocale(context, const Locale('en')); Navigator.pop(ctx); }),
            ListTile(title: const Text("Deutsch"), onTap: () { MyApp.setLocale(context, const Locale('de')); Navigator.pop(ctx); }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final currentLocale = Localizations.localeOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String languageName = "Français";
    if (currentLocale.languageCode == 'en') languageName = "English";
    if (currentLocale.languageCode == 'de') languageName = "Deutsch";

    String themeSubtitle = "Clair";
    if (_currentThemeMode == ThemeMode.dark) themeSubtitle = "Sombre";
    if (_currentThemeMode == ThemeMode.system) themeSubtitle = "Système";

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(t.settings, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: isDark ? primaryColor : Colors.black),
            onPressed: () {
              if (widget.onBack != null) {
                widget.onBack!();
              } else {
                Navigator.pop(context);
              }
            }
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader(t.appearance),
          _buildSettingTile(
              icon: Icons.palette_outlined,
              title: "Thème",
              subtitle: themeSubtitle,
              onTap: _showThemeDialog
          ),
          _buildSettingTile(icon: Icons.translate, title: t.language, subtitle: languageName, onTap: _showLanguageDialog),
          const SizedBox(height: 24),
          _buildSectionHeader(t.security),
          _buildSettingTile(icon: Icons.lock_outline, title: "Code PIN Administration", subtitle: _adminPin == null ? "Non configuré" : "****", onTap: _updatePin, trailing: Icon(Icons.edit_outlined, size: 18, color: primaryColor)),
          const SizedBox(height: 24),
          _buildSectionHeader("COMPTABILITÉ"),
          _buildSettingTile(icon: Icons.list_alt, title: t.chartOfAccounts, subtitle: "Gérer mes comptes", onTap: () => _showAccountingPlanSelector()),
          _buildSettingTile(icon: Icons.account_balance_wallet_outlined, title: "Devise par défaut", subtitle: "EUR (€)", onTap: () {}),
          _buildSettingTile(icon: Icons.calculate_outlined, title: "Paramètres Taxes", subtitle: "TVA FR, UK, DE, US", onTap: _showTaxesSelector),
          const SizedBox(height: 24),
          _buildSectionHeader(t.notifications),
          SwitchListTile(secondary: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle), child: const Icon(Icons.notifications_active_outlined, color: Colors.white, size: 20)), title: const Text("Notifications push", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)), subtitle: const Text("Alertes factures et rapprochements", style: TextStyle(fontSize: 12)), value: _notificationsEnabled, onChanged: (v) => _saveNotificationPreference(v), activeColor: primaryColor),
          const SizedBox(height: 40),
          Center(child: Text("Version 1.2.0", style: TextStyle(color: Colors.grey[500], fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) { return Padding(padding: const EdgeInsets.only(left: 8, bottom: 8), child: Text(title.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[600], letterSpacing: 1.1))); }
  Widget _buildSettingTile({required IconData icon, required String title, required String subtitle, required VoidCallback onTap, Widget? trailing}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 8),
        color: isDark ? const Color(0xFF232435) : Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade100)
        ),
        child: ListTile(
            onTap: onTap,
            leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: isDark ? primaryColor : Colors.black, size: 20)
            ),
            title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isDark ? Colors.white : Colors.black)),
            subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            trailing: trailing ?? const Icon(Icons.chevron_right, size: 20, color: Colors.grey)
        )
    );
  }
}
