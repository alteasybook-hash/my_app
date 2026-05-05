import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart';
import '../models/account_fr.dart';
import '../models/cost_center.dart';
import '../models/entity.dart';
import '../services/api_service.dart';
import '../app.dart';
import 'settings/faq_page.dart';

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
  List<CostCenter> _costCenters = [];
  List<InvoicingConfig> _invoicingConfigs = [];
  ThemeMode _currentThemeMode = ThemeMode.light;
  String _activePlan = "France (PCG)";
  String _defaultCurrency = 'EUR';
  final List<String> _commonCurrencies = ['USD', 'GBP', 'EUR'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final pin = await _apiService.getAdminPin();
    final plan = await _apiService.getActiveAccountingPlan();
    final accs = await _apiService.fetchAccounts();
    final ccs = await _apiService.fetchCostCenters();
    final configs = await _apiService.fetchInvoicingConfigs();
    final prefs = await SharedPreferences.getInstance();
    
    final String? themeStr = prefs.getString('theme_mode');
    ThemeMode loadedTheme = ThemeMode.light;
    if (themeStr != null) {
      loadedTheme = ThemeMode.values.firstWhere(
        (e) => e.toString() == themeStr,
        orElse: () => ThemeMode.light,
      );
    }

    setState(() {
      _adminPin = pin;
      _activePlan = plan;
      _customAccounts = accs;
      _costCenters = ccs;
      _invoicingConfigs = configs;
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _currentThemeMode = loadedTheme;
      _defaultCurrency = prefs.getString('default_currency') ?? 'EUR';
    });
  }

  Future<void> _saveNotificationPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    setState(() => _notificationsEnabled = value);
  }

  Future<void> _handleBackup() async {
    try {
      final jsonDb = await _apiService.exportFullDatabase();
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/alt_backup_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonDb);
      await Share.shareXFiles([XFile(file.path)], text: 'Sauvegarde Alt. Assistante');
    } catch (e) {
      _showError("Erreur lors de la sauvegarde : $e");
    }
  }

  Future<void> _handleImport() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        await _apiService.importFullDatabase(content);
        if (mounted) {
          _showSuccess("Données importées avec succès. Redémarrage recommandé.");
          _loadSettings();
        }
      }
    } catch (e) {
      _showError("Erreur lors de l'importation : $e");
    }
  }

  Future<void> _handleClearCache() async {
    final t = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.clearCache),
        content: const Text("Voulez-vous vraiment supprimer toutes les données locales ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t.cancel.toUpperCase())),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true), 
            child: Text(t.delete.toUpperCase(), style: const TextStyle(color: Colors.white))
          ),
        ],
      )
    );
    if (confirm == true) {
      await _apiService.clearAllCache();
      if (mounted) {
        _showSuccess("Cache vidé.");
        _loadSettings();
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }

  Future<void> _updatePin() async {
    final t = AppLocalizations.of(context);
    final controller = TextEditingController(text: _adminPin);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.adminPinConfig),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 4,
          decoration: InputDecoration(labelText: t.newPinLabel, hintText: "Ex: 1234"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t.cancel.toUpperCase())),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.length == 4) {
                await _apiService.updateAdminPin(controller.text);
                Navigator.pop(ctx);
                _loadSettings();
                _showSuccess(t.pinUpdated);
              } else {
                _showError(t.pinError);
              }
            },
            child: Text(t.save.toUpperCase()),
          )
        ],
      ),
    );
  }

  void _showThemeDialog() {
    final t = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.chooseTheme),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.light_mode_outlined),
              title: Text(t.themeLight),
              trailing: _currentThemeMode == ThemeMode.light ? Icon(Icons.check, color: primaryColor) : null,
              onTap: () { setState(() => _currentThemeMode = ThemeMode.light); MyApp.setTheme(context, ThemeMode.light); Navigator.pop(ctx); },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode_outlined),
              title: Text(t.themeDark),
              trailing: _currentThemeMode == ThemeMode.dark ? Icon(Icons.check, color: primaryColor) : null,
              onTap: () { setState(() => _currentThemeMode = ThemeMode.dark); MyApp.setTheme(context, ThemeMode.dark); Navigator.pop(ctx); },
            ),
            ListTile(
              leading: const Icon(Icons.settings_suggest_outlined),
              title: Text(t.themeSystem),
              trailing: _currentThemeMode == ThemeMode.system ? Icon(Icons.check, color: primaryColor) : null,
              onTap: () { setState(() => _currentThemeMode = ThemeMode.system); MyApp.setTheme(context, ThemeMode.system); Navigator.pop(ctx); },
            ),
          ],
        ),
      ),
    );
  }

  void _showAccountingPlanSelector() {
    final t = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.chartOfAccounts, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildAccountingPlanTile("France (PCG)", "France (PCG)"),
            _buildAccountingPlanTile("UK (COA)", "UK (COA)"),
            _buildAccountingPlanTile("USA (GAAP)", "USA (GAAP)"),
            _buildAccountingPlanTile("Germany (DATEV)", "Germany (DATEV)"),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountingPlanTile(String label, String planKey) {
    bool isActive = _activePlan == planKey;
    return ListTile(
      leading: Icon(Icons.flag, color: isActive ? primaryColor : Colors.grey),
      title: Text(label, style: TextStyle(fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
      trailing: isActive ? Icon(Icons.check_circle, color: primaryColor) : const Icon(Icons.chevron_right),
      onTap: () async {
        Navigator.pop(context);
        await _apiService.setActiveAccountingPlan(planKey);
        await _loadSettings();
        _showAccountsList(label);
      },
    );
  }

  void _showAccountsList(String planName) {
    final t = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(builder: (ctx, setS) => Container(
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
                    if (val == 'add') { await _showAddAccountForm(planName); final updated = await _apiService.fetchAccounts(); setS(() { _customAccounts = updated; }); }
                  },
                  itemBuilder: (ctx) => [PopupMenuItem(value: 'add', child: Row(children: [const Icon(Icons.add_circle_outline, color: Colors.green), const SizedBox(width: 10), Text(t.add + " " + t.bankAccount)]))],
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: _customAccounts.length,
                itemBuilder: (context, index) {
                  final acc = _customAccounts[index];
                  bool isDefault = acc.id.startsWith('uk_') || acc.id.startsWith('de_') || (int.tryParse(acc.id) != null && acc.id.length < 7);
                  return ListTile(
                    title: Text(acc.name),
                    subtitle: Text(acc.number),
                    leading: CircleAvatar(backgroundColor: acc.number.startsWith('512') ? const Color(0xFF49F6C7).withOpacity(0.2) : Colors.grey[100], child: Text(acc.number.isNotEmpty ? acc.number.substring(0, 1) : "?", style: const TextStyle(fontSize: 12))),
                    trailing: PopupMenuButton<String>(
                      onSelected: (val) async {
                        if (val == 'edit') { await _showAddAccountForm(planName, accountToEdit: acc); final updated = await _apiService.fetchAccounts(); setS(() { _customAccounts = updated; }); }
                        else if (val == 'delete') { _confirmDeleteAccount(acc, () async { await _apiService.deleteAccount(acc.id); final updated = await _apiService.fetchAccounts(); setS(() { _customAccounts = updated; }); }); }
                      },
                      itemBuilder: (ctx) => [
                        PopupMenuItem(value: 'edit', child: Row(children: [const Icon(Icons.edit_outlined), const SizedBox(width: 10), Text(t.edit)])),
                        if (!isDefault) PopupMenuItem(value: 'delete', child: Row(children: [const Icon(Icons.delete_outline, color: Colors.red), const SizedBox(width: 10), Text(t.delete, style: const TextStyle(color: Colors.red))])),
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

  Future<void> _showAddAccountForm(String planName, {Account? accountToEdit}) async {
    final t = AppLocalizations.of(context);
    final numberController = TextEditingController(text: accountToEdit?.number);
    final nameController = TextEditingController(text: accountToEdit?.name);
    String selectedType = accountToEdit?.type ?? 'charge';
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(accountToEdit == null ? t.add + " " + t.bankAccount : t.edit),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: numberController, decoration: InputDecoration(labelText: t.number)),
            TextField(controller: nameController, decoration: InputDecoration(labelText: t.name)),
            DropdownButtonFormField<String>(
              value: selectedType,
              items: ['charge', 'produit', 'asset', 'liability', 'equity', 'immobilisation', 'banque', 'tiers', 'dette', 'capitaux'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => selectedType = val!,
              decoration: const InputDecoration(labelText: "Type"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t.cancel.toUpperCase())),
          ElevatedButton(onPressed: () async {
            final newAcc = Account(id: accountToEdit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(), number: numberController.text, name: nameController.text, type: selectedType);
            await _apiService.createAccount(newAcc);
            Navigator.pop(ctx);
            _loadSettings();
          }, child: Text(t.save.toUpperCase())),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(Account acc, VoidCallback onDelete) {
    final t = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.delete),
        content: Text("${t.delete} ${acc.number} - ${acc.name} ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t.cancel.toUpperCase())),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () { onDelete(); Navigator.pop(ctx); }, child: Text(t.delete.toUpperCase(), style: const TextStyle(color: Colors.white))),
        ],
      ),
    );
  }

  void _showCurrencySelector() {
    final t = AppLocalizations.of(context);
    final customCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(builder: (ctx, setS) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.defaultCurrency, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Wrap(spacing: 12, children: _commonCurrencies.map((c) => ChoiceChip(label: Text(c), selected: _defaultCurrency == c, onSelected: (selected) async { if (selected) { final prefs = await SharedPreferences.getInstance(); await prefs.setString('default_currency', c); setState(() => _defaultCurrency = c); Navigator.pop(context); } }, selectedColor: primaryColor)).toList()),
              const SizedBox(height: 20),
              TextField(controller: customCtrl, decoration: InputDecoration(labelText: "Autre devise", suffixIcon: IconButton(icon: const Icon(Icons.check_circle, color: Colors.green), onPressed: () async { if (customCtrl.text.isNotEmpty) { final prefs = await SharedPreferences.getInstance(); await prefs.setString('default_currency', customCtrl.text); setState(() => _defaultCurrency = customCtrl.text); Navigator.pop(context); } }))),
              const SizedBox(height: 20),
            ],
          ),
        ),
      )),
    );
  }

  // 🔥 INVOICING CONFIGS MANAGEMENT
  void _showInvoicingConfigs() {
    final t = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(builder: (ctx, setS) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(t.apiBillingConfig, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Colors.green, size: 28),
                  onPressed: () async {
                    await _showInvoicingConfigForm();
                    final updated = await _apiService.fetchInvoicingConfigs();
                    setS(() => _invoicingConfigs = updated);
                    _loadSettings();
                  },
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: _invoicingConfigs.length,
                itemBuilder: (context, index) {
                  final config = _invoicingConfigs[index];
                  return ListTile(
                    title: Text(config.name),
                    subtitle: Text("${config.country} - ${config.provider}"),
                    leading: const Icon(Icons.api_outlined, color: Colors.blue),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () async {
                            await _showInvoicingConfigForm(config: config);
                            final updated = await _apiService.fetchInvoicingConfigs();
                            setS(() => _invoicingConfigs = updated);
                            _loadSettings();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () async {
                            await _apiService.deleteInvoicingConfig(config.id);
                            final updated = await _apiService.fetchInvoicingConfigs();
                            setS(() => _invoicingConfigs = updated);
                            _loadSettings();
                          },
                        ),
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

  Future<void> _showInvoicingConfigForm({InvoicingConfig? config}) async {
    final nameCtrl = TextEditingController(text: config?.name);
    final apiKeyCtrl = TextEditingController(text: config?.apiKey);
    final apiSecretCtrl = TextEditingController(text: config?.apiSecret);
    final endpointCtrl = TextEditingController(text: config?.endpoint);
    String selectedCountry = config?.country ?? 'France';
    String selectedProvider = config?.provider ?? 'sage';

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(config == null ? "Nouvelle Configuration" : "Modifier Configuration"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Nom de la config (ex: Sage FR)")),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedCountry,
                items: ['France', 'UK', 'Germany', 'USA'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => selectedCountry = val!,
                decoration: const InputDecoration(labelText: "Pays"),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedProvider,
                items: ['sage', 'pennylane', 'chorus', 'datev'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (val) => selectedProvider = val!,
                decoration: const InputDecoration(labelText: "Provider"),
              ),
              TextField(controller: apiKeyCtrl, decoration: const InputDecoration(labelText: "API Key")),
              TextField(controller: apiSecretCtrl, decoration: const InputDecoration(labelText: "API Secret / Token")),
              TextField(controller: endpointCtrl, decoration: const InputDecoration(labelText: "Endpoint (Optionnel)")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("ANNULER")),
          ElevatedButton(
            onPressed: () async {
              final newConfig = InvoicingConfig(
                id: config?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameCtrl.text,
                country: selectedCountry,
                provider: selectedProvider,
                apiKey: apiKeyCtrl.text,
                apiSecret: apiSecretCtrl.text,
                endpoint: endpointCtrl.text,
              );
              if (config == null) {
                await _apiService.createInvoicingConfig(newConfig);
              } else {
                await _apiService.updateInvoicingConfig(config.id, newConfig);
              }
              Navigator.pop(ctx);
            },
            child: const Text("ENREGISTRER"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1B2E) : Colors.grey[50],
      appBar: AppBar(title: Text(t.settings, style: const TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.transparent, elevation: 0, leading: widget.onBack != null ? IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: widget.onBack) : null),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(t.general, [
            _buildTile(t.language, Icons.language, Color(0xFF49F6C7), _showLanguageDialog),
            _buildTile(t.chooseTheme, Icons.palette_outlined, Colors.purple, _showThemeDialog),
            _buildTile(t.adminPinConfig, Icons.lock_outline, Color(0xFF49F6C7), _updatePin),
            _buildTile(t.defaultCurrency, Icons.monetization_on_outlined, Color(0xFF49F6C7), _showCurrencySelector),
            _buildTile(t.faqHelp, Icons.help_outline, Colors.indigo, () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const FaqPage()));
            }),
            SwitchListTile(title: Text(t.notifications), secondary: const Icon(Icons.notifications_none, color: Colors.teal), value: _notificationsEnabled, onChanged: _saveNotificationPreference),
          ]),
          const SizedBox(height: 24),
          _buildSection(t.accounting, [
            _buildTile(t.apiBillingConfig, Icons.api, Color(0xFF49F6C7), _showInvoicingConfigs),
            _buildTile(t.chartOfAccounts, Icons.account_balance_outlined, Color(0xFF49F6C7), _showAccountingPlanSelector),
            _buildTile(t.taxSettings, Icons.percent, Color(0xFF49F6C7), _showTaxesSelector),
            _buildTile(t.costCenters, Icons.hub_outlined, Color(0xFF49F6C7), _showCostCentersList),
          ]),
          const SizedBox(height: 24),
          _buildSection(t.data, [
            _buildTile(t.backupData, Icons.cloud_upload_outlined, Color(0xFF49F6C7), _handleBackup),
            _buildTile(t.importExport, Icons.import_export, Color(0xFF49F6C7), _handleImport),
            _buildTile(t.clearCache, Icons.delete_sweep_outlined, Color(0xFF49F6C7), _handleClearCache),
          ]),
          const SizedBox(height: 40),
          Center(child: Text("Version 1.0.0", style: TextStyle(color: Colors.grey[500], fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), child: Text(title.toUpperCase(), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey[600], letterSpacing: 1.2))),
      Card(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: isDark ? Colors.white10 : Colors.grey[200]!)), color: isDark ? const Color(0xFF232435) : Colors.white, child: Column(children: children)),
    ]);
  }

  Widget _buildTile(String title, IconData icon, Color color, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 22)),
      title: Text(title, style: TextStyle(fontSize: 15, color: isDark ? Colors.white : Colors.black87)),
      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
      onTap: onTap,
    );
  }

  void _showTaxesList(String country) {
    final taxes = _apiService.getTaxesForCountry(country);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(builder: (context, setS) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("${AppLocalizations.of(context).taxSettings} - $country", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: Icon(Icons.add_circle_outline, color: primaryColor, size: 28), onPressed: () => _addNewTaxRate(country))]),
            const Divider(),
            Expanded(child: ListView.builder(itemCount: taxes.length, itemBuilder: (ctx, idx) => ListTile(title: Text("${taxes[idx]} %", style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black)), leading: Icon(Icons.percent, size: 18, color: primaryColor)))),
          ],
        ),
      )),
    );
  }

  void _showTaxesSelector() {
    final t = AppLocalizations.of(context);
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
              Text(t.taxSettings, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
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
    return ListTile(leading: const Icon(Icons.public, color: Colors.blue), title: Text(label, style: TextStyle(color: isDark ? Colors.white : Colors.black)), trailing: const Icon(Icons.chevron_right), onTap: () { Navigator.pop(context); _showTaxesList(country); });
  }

  void _addNewTaxRate(String country) {
    final t = AppLocalizations.of(context);
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.taxSettings),
        content: TextField(controller: controller, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: "Taux (%)", hintText: "Ex: 20.0")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t.cancel.toUpperCase())),
          ElevatedButton(onPressed: () async {
            final rate = double.tryParse(controller.text.replaceAll(',', '.'));
            if (rate != null) { await _apiService.addTaxRate(country, rate); Navigator.pop(ctx); Navigator.pop(context); _showTaxesList(country); }
          }, child: Text(t.save.toUpperCase())),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    final t = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.language),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(title: const Text("Français"), onTap: () { MyApp.setLocale(context, const Locale('fr')); Navigator.pop(ctx); }),
          ListTile(title: const Text("English"), onTap: () { MyApp.setLocale(context, const Locale('en')); Navigator.pop(ctx); }),
          ListTile(title: const Text("Deutsch"), onTap: () { MyApp.setLocale(context, const Locale('de')); Navigator.pop(ctx); }),
        ]),
      ),
    );
  }

  void _showCostCentersList() {
    final t = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(builder: (context, setS) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(t.costCenters, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: Icon(Icons.add_circle_outline, color: primaryColor, size: 28), onPressed: () async { await _showAddCostCenterForm(); final updated = await _apiService.fetchCostCenters(); setS(() { _costCenters = updated; }); })]),
            const Divider(),
            Expanded(child: ListView.builder(itemCount: _costCenters.length, itemBuilder: (ctx, idx) {
              final cc = _costCenters[idx];
              return ListTile(title: Text(cc.serviceName, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text("Code: ${cc.code}"), trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () async { await _apiService.deleteCostCenter(cc.id); final updated = await _apiService.fetchCostCenters(); setS(() { _costCenters = updated; }); }));
            })),
          ],
        ),
      )),
    );
  }

  Future<void> _showAddCostCenterForm() async {
    final t = AppLocalizations.of(context);
    final codeCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final managerFnCtrl = TextEditingController();
    final managerLnCtrl = TextEditingController();
    final approverCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.add + " " + t.costCenters),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: "Code")),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Service")),
              TextField(controller: managerFnCtrl, decoration: const InputDecoration(labelText: "Prénom Manager")),
              TextField(controller: managerLnCtrl, decoration: const InputDecoration(labelText: "Nom Manager")),
              TextField(controller: approverCtrl, decoration: const InputDecoration(labelText: "Approbateur")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t.cancel.toUpperCase())),
          ElevatedButton(
            onPressed: () async {
              final newCc = CostCenter(id: DateTime.now().millisecondsSinceEpoch.toString(), code: codeCtrl.text, serviceName: nameCtrl.text, managerFirstName: managerFnCtrl.text, managerLastName: managerLnCtrl.text, approverName: approverCtrl.text);
              await _apiService.createCostCenter(newCc);
              Navigator.pop(ctx);
              _loadSettings();
            },
            child: Text(t.save.toUpperCase()),
          ),
        ],
      ),
    );
  }
}
