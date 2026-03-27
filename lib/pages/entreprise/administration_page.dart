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
  List<Map<String, dynamic>> _documents = [];
  bool _isLoading = true;
  bool _isDocsUnlocked = false;

  File? _pickedLogo;
  String? _existingLogoPath;

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
    final docs = await _apiService.fetchCompanyDocuments();
    setState(() {
      _entities = entities;
      _documents = docs;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- LOGIQUE PIN ---
  Future<void> _unlockDocuments() async {
    final pinC = TextEditingController();
    final pin = await _apiService.getAdminPin();
    if (pin == null) return;

    showDialog(
      context: context,
      builder: (ctx) =>
          AlertDialog(
            title: const Text("Code PIN requis"),
            content: TextField(
              controller: pinC,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: "Entrez le code PIN"),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("ANNULER")),
              ElevatedButton(
                onPressed: () {
                  if (pinC.text == pin) {
                    setState(() => _isDocsUnlocked = true);
                    Navigator.pop(ctx);
                  }
                },
                child: const Text("VALIDER"),
              )
            ],
          ),
    );
  }

  Future<void> _pickDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      final file = result.files.first;
      await _apiService.addCompanyDocument({
        'id': DateTime
            .now()
            .millisecondsSinceEpoch
            .toString(),
        'name': file.name,
        'path': file.path,
        'date': DateTime.now().toIso8601String(),
      });
      _loadData();
    }
  }

  // --- FORMULAIRE ENTITÉ ---
  void _showEntityForm({Entity? entity, bool isReadOnly = false}) {
    final nameController = TextEditingController(text: entity?.name ?? '');
    final idController = TextEditingController(text: entity?.idNumber ?? '');
    final emailController = TextEditingController(text: entity?.email ?? '');
    final addressController =
    TextEditingController(text: entity?.address ?? '');
    final vatController = TextEditingController(text: entity?.vatNumber ?? '');

    String selectedCountry = entity?.country ?? 'France';
    String selectedCurrency = entity?.currency ?? 'EUR';
    String selectedAccountCurrency = 'EUR';
    String selectedAccountingPlan = entity?.accountingPlan ?? 'France (PCG)';




    bool isDefault = entity?.isDefault ?? false;
    _existingLogoPath = entity?.logoPath;
    _pickedLogo = null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          StatefulBuilder(
            builder: (context, setModalState) =>
                Container(
                  height: MediaQuery
                      .of(context)
                      .size
                      .height * 0.9,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                        top: Radius.circular(30)),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              _buildField(nameController, 'Raison Sociale *',
                                  enabled: !isReadOnly),

                              _buildDropdownField(
                                'Plan Comptable',
                                selectedAccountingPlan.contains("Coming soon")
                                    ? 'France (PCG)'
                                    : selectedAccountingPlan,
                                [
                                  'France (PCG)',
                                  'UK (COA) - Coming soon',
                                  'USA (GAAP) - Coming soon',
                                  'Germany (DATEV) - Coming soon'
                                ],
                                !isReadOnly,
                                    (val) {
                                  // On n'autorise le changement que si ce n'est pas un "Coming soon"
                                  if (val != null &&
                                      !val.contains("Coming soon")) {
                                    setModalState(() =>
                                    selectedAccountingPlan = val);
                                  }
                                },
                              ),
                              const SizedBox(height: 8),


                              _buildField(
                                idController,
                                'SIRET / ID Unique *',
                                enabled: !isReadOnly,
                                onChanged: (val) => setModalState(() {}),
                              ),
                              if (idController.text.startsWith('512'))
                                _buildDropdownField(
                                  'Devise du compte bancaire (512)',
                                  selectedAccountCurrency,
                                  ['EUR', 'USD', 'GBP', 'CHF', 'CAD'],
                                  !isReadOnly,
                                      (val) =>
                                      setModalState(() =>
                                      selectedAccountCurrency = val!),
                                ),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildDropdownField(
                                      'Pays *',
                                      selectedCountry,
                                      [
                                        'France',
                                        'Allemagne',
                                        'Belgique',
                                        'UK',
                                        'USA'
                                      ],
                                      !isReadOnly,
                                          (val) =>
                                          setModalState(() =>
                                          selectedCountry = val!),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildDropdownField(
                                      'Devise *',
                                      selectedCurrency,
                                      ['EUR', 'USD', 'GBP'],
                                      !isReadOnly,
                                          (val) =>
                                          setModalState(() =>
                                          selectedCurrency = val!),
                                    ),
                                  ),
                                ],
                              ),
                              _buildField(vatController, 'Numéro de TVA',
                                  enabled: !isReadOnly),
                              _buildField(emailController, 'Email *',
                                  enabled: !isReadOnly),
                              _buildField(addressController, 'Adresse *',
                                  enabled: !isReadOnly, maxLines: 2),

                              const SizedBox(height: 20),
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                    "Logo de l'entreprise", style: TextStyle(
                                    fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(height: 10),
                              GestureDetector(
                                onTap: isReadOnly ? null : () async {
                                  FilePickerResult? result = await FilePicker
                                      .platform.pickFiles(type: FileType.image);
                                  if (result != null) {
                                    setModalState(() {
                                      _pickedLogo =
                                          File(result.files.single.path!);
                                    });
                                  }
                                },

                                child: Container(
                                  height: 100,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                      border: Border.all(
                                          color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(12)),
                                  child: _pickedLogo != null
                                      ? Image.file(_pickedLogo!)
                                      : _existingLogoPath != null
                                      ? Image.file(File(_existingLogoPath!))
                                      : const Icon(Icons.add_a_photo),
                                ),
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
                              final entityData = {
                                'id': entity?.id ??
                                    DateTime
                                        .now()
                                        .millisecondsSinceEpoch
                                        .toString(),
                                'name': nameController.text,
                                'accountingPlan': selectedAccountingPlan,
                                'idNumber': idController.text,
                                'email': emailController.text,
                                'address': addressController.text,
                                'vatNumber': vatController.text,
                                'accountCurrency': selectedAccountCurrency,
                                'country': selectedCountry,
                                'currency': selectedCurrency,
                                'isDefault': isDefault,
                                'logoPath': _pickedLogo?.path ??
                                    _existingLogoPath,
                              };

                              if (entity == null) {
                                await _apiService.createEntity(Entity.fromJson(
                                    entityData));
                              } else {
                                await _apiService.updateEntity(entity.id,
                                    entityData);
                              }
                              Navigator.pop(context);
                              _loadData();
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor),
                            child: const Text("Enregistrer"),
                          ),
                        )
                    ],
                  ),
                ),
          ),
    );
  }

  Widget _buildField(TextEditingController controller, String label,
      {bool enabled = true, int maxLines = 1, Function(String)? onChanged}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        onChanged: onChanged,
        decoration: InputDecoration(
            labelText: label, border: const OutlineInputBorder()),
      ),
    );
  }

  Widget _buildDropdownField(String label, String value, List<String> items,
      bool enabled, Function(String?) onChanged) {
    return Padding(padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        // On s'assure que la valeur existe dans la liste, sinon on prend la première
        value: items.contains(value) ? value : items.first,
        items: items.map((e) {
          bool isComingSoon = e.contains("Coming soon");
          return DropdownMenuItem(
            value: e,
            child: Text(
              e,
              style: TextStyle(
                color: isComingSoon ? Colors.grey : Colors.black,
                fontStyle: isComingSoon ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          );
        }).toList(),
        onChanged: enabled ? onChanged : null,
        decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12))),
      ),
    );
  }
  Widget _buildEntityCard(Entity e) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: primaryColor.withOpacity(0.2),
          child: e.logoPath != null
              ? ClipOval(
              child: Image.file(File(e.logoPath!),
                  fit: BoxFit.cover, width: 40, height: 40))
              : const Icon(Icons.business, color: Colors.black),
        ),
        title: Text(
            e.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(e.idNumber),
        trailing: IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _showEntityForm(entity: e)),
        onTap: () => _showEntityForm(entity: e, isReadOnly: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () => Navigator.pop(context)),
        title: Text(t.admin,
            style: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          indicatorColor: primaryColor,
          tabs: const [Tab(text: 'Entités'), Tab(text: 'Documents')],
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
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
        onPressed: () => _showEntityForm(),
        label: const Text('Ajouter Entité'),
        icon: const Icon(Icons.add_business),
        backgroundColor: primaryColor,
      )
          : FloatingActionButton.extended(
        onPressed: _isDocsUnlocked ? _pickDocument : _unlockDocuments,
        label: Text(_isDocsUnlocked ? 'Ajouter Document' : 'Déverrouiller'),
        icon: Icon(_isDocsUnlocked ? Icons.upload_file : Icons.lock_open),
        backgroundColor: _isDocsUnlocked ? primaryColor : Colors.orange,
      ),
    );
  }

  Widget _buildDocumentsSection() {
    if (!_isDocsUnlocked) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
                Icons.lock_person_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text("Contenu sécurisé",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 8),
              child: Text(
                  "Veuillez entrer votre code PIN Administration pour accéder aux documents.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey)),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _unlockDocuments,
              icon: const Icon(Icons.lock_open),
              label: const Text("DÉVERROUILLER"),
              style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor, foregroundColor: Colors.black),
            )
          ],
        ),
      );
    }

    if (_documents.isEmpty) {
      return const Center(child: Text("Aucun document entreprise."));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _documents.length,
      itemBuilder: (ctx, idx) {
        final doc = _documents[idx];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.description, color: Colors.blue),
            title: Text(doc['name'] ?? 'Doc'),
            subtitle: Text(doc['date'] != null
                ? DateFormat('dd/MM/yyyy HH:mm')
                .format(DateTime.parse(doc['date']))
                : ''),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () async {
                await _apiService.deleteCompanyDocument(doc['id']);
                _loadData();
              },
            ),
          ),
        );
      },
    );
  }
}