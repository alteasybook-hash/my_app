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

  Future<void> _unlockDocuments() async {
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
        title: Text("Code PIN requis", style: TextStyle(color: isDark ? Colors.white : Colors.black)),
        content: TextField(
          controller: pinC,
          obscureText: true,
          keyboardType: TextInputType.number,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: const InputDecoration(labelText: "Entrez le code secret", labelStyle: TextStyle(color: Colors.grey)),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("ANNULER", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              if (pinC.text == pin) {
                setState(() => _isDocsUnlocked = true);
                Navigator.pop(ctx);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Code erroné")));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: const Text("VALIDER", style: TextStyle(color: Colors.black)),
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
    String selectedCurrency = entity?.currency ?? 'EUR';
    bool isDefault = entity?.isDefault ?? false;
    _existingLogoPath = entity?.logoPath;
    _pickedLogo = null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Container(
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
                Text(
                  isReadOnly ? 'Détails Entité' : (entity == null ? 'Nouvelle Entité' : 'Modifier Entité'),
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                ),
                const Divider(height: 32),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildField(nameController, 'Raison Sociale *', enabled: !isReadOnly),
                        _buildField(idController, 'SIRET / ID Unique *', enabled: !isReadOnly),
                        Row(
                          children: [
                            Expanded(child: _buildDropdownField('Pays *', selectedCountry, ['France', 'Allemagne', 'Belgique', 'Suisse', 'Luxembourg', 'Canada'], !isReadOnly, (val) => setModalState(() => selectedCountry = val!))),
                            const SizedBox(width: 12),
                            Expanded(child: _buildDropdownField('Devise *', selectedCurrency, ['EUR', 'GBP', 'USD', 'CHF', 'CAD'], !isReadOnly, (val) => setModalState(() => selectedCurrency = val!))),
                          ],
                        ),
                        _buildField(vatController, 'Numéro de TVA', enabled: !isReadOnly),
                        _buildField(emailController, 'Email *', enabled: !isReadOnly),
                        _buildField(addressController, 'Adresse *', enabled: !isReadOnly, maxLines: 2),

                        const SizedBox(height: 20),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text("Logo de l'entreprise", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: isReadOnly ? null : () async {
                            FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
                            if (result != null) {
                              setModalState(() { _pickedLogo = File(result.files.single.path!); });
                            }
                          },
                          child: Container(
                            height: 120,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                              color: isDark ? const Color(0xFF232435) : Colors.grey.shade50,
                            ),
                            child: _pickedLogo != null
                                ? Image.file(_pickedLogo!, fit: BoxFit.contain)
                                : (_existingLogoPath != null && _existingLogoPath!.isNotEmpty
                                ? Image.file(File(_existingLogoPath!), fit: BoxFit.contain)
                                : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined, color: Colors.grey, size: 40),
                                Text("Ajouter un logo", style: TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            )),
                          ),
                        ),
                        if (!isReadOnly)
                          SwitchListTile(
                            title: Text('Entité par défaut', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                            value: isDefault,
                            onChanged: (v) => setModalState(() => isDefault = v),
                            activeColor: primaryColor,
                          ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
                if (!isReadOnly)
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (nameController.text.isEmpty) return;
                        final newEntity = Entity(
                          id: entity?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                          name: nameController.text.trim(),
                          idNumber: idController.text.trim(),
                          vatNumber: vatController.text.trim(),
                          email: emailController.text.trim(),
                          address: addressController.text.trim(),
                          country: selectedCountry,
                          currency: selectedCurrency,
                          isDefault: isDefault,
                          logoPath: _pickedLogo?.path ?? _existingLogoPath,
                        );

                        if (entity == null) await _apiService.createEntity(newEntity);
                        else await _apiService.updateEntity(entity.id, newEntity.toJson());

                        if (context.mounted) {
                          Navigator.pop(context);
                          _loadData();
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                      child: const Text('Enregistrer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: isDark ? BorderSide.none : const BorderSide()),
        ),
      ),
    );
  }

  Widget _buildDropdownField(String label, String value, List<String> items, bool enabled, Function(String?) onChanged) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
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
        subtitle: Text(e.idNumber, style: const TextStyle(color: Colors.grey)),
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios, color: isDark ? primaryColor : Colors.black), onPressed: () => Navigator.pop(context)),
        title: Text(t.admin, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: isDark ? primaryColor : Colors.black,
          unselectedLabelColor: Colors.grey,
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
      floatingActionButton: _buildFab(),
    );
  }

  Widget? _buildFab() {
    if (_tabController.index == 0) {
      return FloatingActionButton.extended(onPressed: () => _showEntityForm(), label: const Text('Ajouter Entité', style: TextStyle(color: Colors.black)), icon: const Icon(Icons.add_business, color: Colors.black), backgroundColor: primaryColor);
    }
    
    // On n'affiche le FAB que si les documents sont déverrouillés
    if (_tabController.index == 1 && _isDocsUnlocked) {
      return FloatingActionButton.extended(onPressed: _pickDocument, label: const Text('Ajouter Document', style: TextStyle(color: Colors.black)), icon: const Icon(Icons.upload_file, color: Colors.black), backgroundColor: primaryColor);
    }
    
    return null;
  }

  Widget _buildDocumentsSection() {
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
              label: const Text("DÉVERROUILLER"),
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.black),
            )
          ],
        ),
      );
    }

    if (_documents.isEmpty) {
      return Center(child: Text("Aucun document entreprise.", style: TextStyle(color: isDark ? Colors.grey : Colors.grey)));
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
            subtitle: Text(doc['date'] != null ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(doc['date'])) : '', style: const TextStyle(color: Colors.grey)),
            trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () async { await _apiService.deleteCompanyDocument(doc['id']); _loadData(); }),
          ),
        );
      },
    );
  }
}
