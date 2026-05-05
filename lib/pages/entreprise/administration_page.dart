import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../l10n/app_localizations.dart';
import '../../models/entity.dart';
import '../../services/api_service.dart';
import 'package:intl/intl.dart';

class AdministrationPage extends StatefulWidget {
  const AdministrationPage({super.key});

  @override
  State<AdministrationPage> createState() => _AdministrationPageState();
}

class _AdministrationPageState extends State<AdministrationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  final Color primaryColor = const Color(0xFF49F6C7);

  List<Entity> _entities = [];
  List<InvoicingConfig> _invoicingConfigs = [];
  List<Map<String, dynamic>> _documents = [];
  bool _isLoading = true;
  bool _isDocsUnlocked = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final entities = await _apiService.fetchEntities();
    final configs = await _apiService.fetchInvoicingConfigs();
    final docs = await _apiService.fetchCompanyDocuments();
    setState(() {
      _entities = entities;
      _invoicingConfigs = configs;
      _documents = docs;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _unlockDocuments() async {
    final t = AppLocalizations.of(context);
    final pinC = TextEditingController();
    final pin = await _apiService.getAdminPin();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (pin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Veuillez d'abord configurer un code PIN dans les paramètres."))
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
        title: Text(t.pinRequired, style: TextStyle(color: isDark ? Colors.white : Colors.black)),
        content: TextField(
          controller: pinC,
          obscureText: true,
          keyboardType: TextInputType.number,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(labelText: t.validate, labelStyle: const TextStyle(color: Colors.grey)),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t.cancel, style: const TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              if (pinC.text == pin) {
                setState(() => _isDocsUnlocked = true);
                Navigator.pop(ctx);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.invalidPin)));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: Text(t.validate, style: const TextStyle(color: Colors.black)),
          )
        ],
      ),
    );
  }

  Future<void> _pickDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      final doc = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': result.files.single.name,
        'path': result.files.single.path,
        'date': DateTime.now().toIso8601String(),
        'size': result.files.single.size,
      };
      await _apiService.addCompanyDocument(doc);
      _loadData();
    }
  }

  void _showEntityForm({Entity? entity, bool isReadOnly = false}) {
    final nameController = TextEditingController(text: entity?.name ?? '');
    final idController = TextEditingController(text: entity?.idNumber ?? '');
    final vatController = TextEditingController(text: entity?.vatNumber ?? '');
    final emailController = TextEditingController(text: entity?.email ?? '');
    final addressController = TextEditingController(text: entity?.address ?? '');

    String selectedCountry = entity?.country ?? 'France';
    String selectedAccountingPlan = entity?.accountingPlan ?? 'France (PCG)';
    List<String> selectedCurrencies = List.from(entity?.currencies ?? ['EUR']);

    String selectedInvoicingType = entity?.invoicingType ?? (selectedCountry == 'France' ? 'pdp' : 'classic');
    String? selectedConfigId = entity?.invoicingConfigId;

    bool isDefault = entity?.isDefault ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          // 🔥 FILTER CONFIGS BY COUNTRY
          List<InvoicingConfig> countryConfigs = _invoicingConfigs
              .where((c) => c.country == selectedCountry)
              .toList();
          
          if (selectedConfigId != null && !countryConfigs.any((c) => c.id == selectedConfigId)) {
            selectedConfigId = null;
          }

          return Container(
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  entity == null ? "Nouvelle entité" : "Modifier entité",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildField(nameController, "Nom"),
                        _buildField(idController, "SIRET / ID"),
                        
                        _buildDropdownField(
                          "Pays",
                          selectedCountry,
                          ['France', 'UK', 'Germany', 'USA'],
                          !isReadOnly,
                          (val) {
                            setModalState(() {
                              selectedCountry = val!;
                              // Update related defaults
                              if (selectedCountry == 'France') {
                                selectedAccountingPlan = 'France (PCG)';
                                selectedInvoicingType = 'pdp';
                              } else if (selectedCountry == 'UK') {
                                selectedAccountingPlan = 'UK (COA)';
                                selectedInvoicingType = 'classic';
                              } else if (selectedCountry == 'Germany') {
                                selectedAccountingPlan = 'Germany (DATEV)';
                                selectedInvoicingType = 'classic';
                              } else {
                                selectedAccountingPlan = 'USA (GAAP)';
                                selectedInvoicingType = 'classic';
                              }
                            });
                          },
                        ),

                        _buildDropdownField(
                          "Plan Comptable",
                          selectedAccountingPlan,
                          ['France (PCG)', 'UK (COA)', 'Germany (DATEV)', 'USA (GAAP)'],
                          !isReadOnly,
                          (val) => setModalState(() => selectedAccountingPlan = val!),
                        ),

                        const SizedBox(height: 12),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text("Devises autorisées", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ),
                        Wrap(
                          spacing: 8,
                          children: ['EUR', 'USD', 'GBP', 'CHF'].map((c) {
                            final isSelected = selectedCurrencies.contains(c);
                            return FilterChip(
                              label: Text(c),
                              selected: isSelected,
                              onSelected: isReadOnly ? null : (selected) {
                                setModalState(() {
                                  if (selected) {
                                    selectedCurrencies.add(c);
                                  } else if (selectedCurrencies.length > 1) {
                                    selectedCurrencies.remove(c);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 12),
                        _buildDropdownField(
                          "Type de facturation",
                          selectedInvoicingType,
                          ['classic', 'pdp', 'chorus'],
                          !isReadOnly,
                          (val) => setModalState(() => selectedInvoicingType = val!),
                        ),

                        if (selectedInvoicingType != 'classic') ...[
                          const SizedBox(height: 12),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text("Configuration API / Provider", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ),
                          DropdownButton<String>(
                            value: selectedConfigId,
                            hint: const Text("Choisir une configuration"),
                            isExpanded: true,
                            dropdownColor: isDark ? const Color(0xFF232435) : Colors.white,
                            style: TextStyle(color: isDark ? Colors.white : Colors.black),
                            items: countryConfigs.map((c) => DropdownMenuItem(
                              value: c.id,
                              child: Text("${c.name} (${c.provider})"),
                            )).toList(),
                            onChanged: isReadOnly ? null : (val) => setModalState(() => selectedConfigId = val),
                          ),
                          if (countryConfigs.isEmpty)
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text(
                                "Aucune configuration API trouvée pour ce pays. Configurez-les dans les Paramètres.",
                                style: TextStyle(color: Colors.orange, fontSize: 11),
                              ),
                            ),
                        ],

                        const SizedBox(height: 12),
                        _buildField(vatController, "N° TVA"),
                        _buildField(emailController, "Email"),
                        _buildField(addressController, "Adresse"),

                        SwitchListTile(
                          title: const Text("Entité par défaut"),
                          value: isDefault,
                          onChanged: isReadOnly ? null : (v) => setModalState(() => isDefault = v),
                        ),
                      ],
                    ),
                  ),
                ),
                if (!isReadOnly)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final newEntity = Entity(
                          id: entity?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                          name: nameController.text,
                          idNumber: idController.text,
                          vatNumber: vatController.text,
                          email: emailController.text,
                          address: addressController.text,
                          country: selectedCountry,
                          accountingPlan: selectedAccountingPlan,
                          currencies: selectedCurrencies,
                          invoicingType: selectedInvoicingType,
                          invoicingConfigId: selectedConfigId,
                          isDefault: isDefault,
                        );

                        if (entity == null) {
                          await _apiService.createEntity(newEntity);
                        } else {
                          await _apiService.updateEntity(entity.id, newEntity.toJson());
                        }

                        Navigator.pop(context);
                        _loadData();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("SAUVEGARDER", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, {bool enabled = true, int maxLines = 1}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          filled: true,
          fillColor: isDark ? const Color(0xFF232435) : (enabled ? Colors.white : Colors.grey.shade100),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: isDark ? BorderSide.none : const BorderSide(color: Colors.grey)),
        ),
      ),
    );
  }

  Widget _buildDropdownField(String label, String value, List<String> items, bool enabled, Function(String?) onChanged) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          DropdownButton<String>(
            value: value,
            dropdownColor: isDark ? const Color(0xFF232435) : Colors.white,
            isExpanded: true,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: enabled ? onChanged : null,
          ),
        ],
      ),
    );
  }

  Widget _buildEntityCard(Entity e) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark ? const Color(0xFF232435) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: primaryColor.withOpacity(0.2),
          child: e.logoPath != null
              ? ClipOval(child: Image.file(File(e.logoPath!), fit: BoxFit.cover, width: 40, height: 40))
              : Icon(Icons.business, color: isDark ? primaryColor : Colors.black),
        ),
        title: Text(e.name, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
        subtitle: Text("${e.country} • ${e.idNumber}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
        trailing: IconButton(icon: Icon(Icons.edit_outlined, color: isDark ? Colors.white70 : Colors.black), onPressed: () => _showEntityForm(entity: e)),
        onTap: () => _showEntityForm(entity: e, isReadOnly: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1B2E) : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios, color: isDark ? primaryColor : Colors.black), onPressed: () => Navigator.pop(context)),
        title: Text(t.admin, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: isDark ? primaryColor : Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: primaryColor,
          tabs: [Tab(text: t.entities), Tab(text: t.documents)],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: _entities.map((e) => _buildEntityCard(e)).toList(),
          ),
          _buildDocumentsSection(),
        ],
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget? _buildFab() {
    final t = AppLocalizations.of(context);
    if (_tabController.index == 0) {
      return FloatingActionButton.extended(onPressed: () => _showEntityForm(), label: Text(t.newEntity, style: const TextStyle(color: Colors.black)), icon: const Icon(Icons.add_business, color: Colors.black), backgroundColor: primaryColor);
    }
    if (_tabController.index == 1 && _isDocsUnlocked) {
      return FloatingActionButton.extended(onPressed: _pickDocument, label: const Text('Ajouter Document', style: TextStyle(color: Colors.black)), icon: const Icon(Icons.upload_file, color: Colors.black), backgroundColor: primaryColor);
    }
    return null;
  }

  Widget _buildDocumentsSection() {
    final t = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!_isDocsUnlocked) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_person_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text("Contenu sécurisé", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 8),
              child: Text("Veuillez entrer votre code PIN Administration pour accéder aux documents.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _unlockDocuments,
              icon: const Icon(Icons.lock_open),
              label: Text(t.validate.toUpperCase()),
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.black),
            )
          ],
        ),
      );
    }

    if (_documents.isEmpty) {
      return Center(child: Text("Aucun document entreprise.", style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _documents.length,
      itemBuilder: (ctx, idx) {
        final doc = _documents[idx];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          color: isDark ? const Color(0xFF232435) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200)),
          child: ListTile(
            leading: const Icon(Icons.description, color: Colors.blue),
            title: Text(doc['name'] ?? 'Doc', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
            subtitle: Text(doc['date'] != null ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(doc['date'])) : ''),
            trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () async { await _apiService.deleteCompanyDocument(doc['id']); _loadData(); }),
          ),
        );
      },
    );
  }
}
