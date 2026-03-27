import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service.dart';

enum RdvStatus { pending, completed }

class RdvEvent {
  final String id;
  String title;
  DateTime date;
  String description;
  String type; // perso, pro, voyage
  RdvStatus status;
  bool isUrgent;

  RdvEvent({
    required this.id,
    required this.title,
    required this.date,
    this.description = '',
    this.type = 'perso',
    this.status = RdvStatus.pending,
    this.isUrgent = false,
  });

  factory RdvEvent.fromJson(Map<String, dynamic> json) {
    return RdvEvent(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      date: DateTime.parse(json['date']),
      description: json['description'] ?? '',
      type: json['type'] ?? 'perso',
      isUrgent: json['isUrgent'] ?? false,
      status: json['status'] == 'completed' ? RdvStatus.completed : RdvStatus.pending,
    );
  }
}

class RdvPage extends StatefulWidget {
  const RdvPage({super.key});

  @override
  State<RdvPage> createState() => _RdvPageState();
}

class _RdvPageState extends State<RdvPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  final Color primaryColor = const Color(0xFF49F6C7);

  late Future<List<RdvEvent>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _refreshEvents();
  }

  void _refreshEvents() {
    setState(() {
      _eventsFuture = _apiService.fetchEvents().then((list) =>
          list.map((item) => RdvEvent.fromJson(item)).toList()
      );
    });
  }

  Future<void> _handleDelete(String id) async {
    try {
      await _apiService.deleteEvent(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Rendez-vous supprimé'), backgroundColor: Colors.green),
        );
        _refreshEvents();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Erreur de suppression : $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _handleStatusChange(RdvEvent event) async {
    try {
      await _apiService.updateEvent(event.id, {'status': 'completed'});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ RDV terminé et déplacé dans l\'historique'), backgroundColor: Colors.blue),
        );
        _refreshEvents();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Erreur : $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _showAddRdvSheet({RdvEvent? eventToEdit}) {
    final t = AppLocalizations.of(context);
    final titleController = TextEditingController(text: eventToEdit?.title ?? '');
    final descController = TextEditingController(text: eventToEdit?.description ?? '');
    DateTime selectedDate = eventToEdit?.date ?? DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(selectedDate);
    String selectedType = eventToEdit?.type ?? 'perso';
    bool isUrgent = eventToEdit?.isUrgent ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, top: 20, left: 20, right: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Text(eventToEdit == null ? t.newRdv : 'Modifier RDV', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextField(controller: titleController, decoration: InputDecoration(labelText: t.titleHint, border: const OutlineInputBorder())),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Type'),
                  items: ['perso', 'pro', 'voyage'].map((type) => DropdownMenuItem(value: type, child: Text(type.toUpperCase()))).toList(),
                  onChanged: (v) => setModalState(() => selectedType = v!),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: OutlinedButton.icon(
                        onPressed: () async {
                          final d = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                          if (d != null) setModalState(() => selectedDate = d);
                        },
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'))),
                    const SizedBox(width: 10),
                    Expanded(child: OutlinedButton.icon(
                        onPressed: () async {
                          final tm = await showTimePicker(context: context, initialTime: selectedTime);
                          if (tm != null) setModalState(() => selectedTime = tm);
                        },
                        icon: const Icon(Icons.access_time, size: 16),
                        label: Text(selectedTime.format(context)))),
                  ],
                ),
                SwitchListTile(title: Text(t.urgentLabel), value: isUrgent, activeThumbColor: Colors.red, onChanged: (v) => setModalState(() => isUrgent = v)),
                const SizedBox(height: 20),
                SizedBox(width: double.infinity, height: 55, child: ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.isEmpty) return;

                    final finalDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, selectedTime.hour, selectedTime.minute);
                    final data = {
                      'title': titleController.text,
                      'description': descController.text,
                      'date': finalDate.toIso8601String(),
                      'isUrgent': isUrgent,
                      'type': selectedType,
                    };

                    try {
                      if (eventToEdit == null) {
                        await _apiService.createEvent(data);
                      } else {
                        await _apiService.updateEvent(eventToEdit.id, data);
                      }
                      if (mounted) {
                        Navigator.pop(context);
                        _refreshEvents();
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Erreur : $e')));
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.black),
                  child: Text(t.save, style: const TextStyle(fontWeight: FontWeight.bold)),
                )),
              ],
            ),
          ),
        ),
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
        title: Text(t.rdv, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        bottom: TabBar(controller: _tabController, labelColor: Colors.black, indicatorColor: primaryColor, tabs: [Tab(text: t.upcoming), Tab(text: t.history)]),
      ),
      body: FutureBuilder<List<RdvEvent>>(
        future: _eventsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Erreur : vérifiez que NestJS tourne', style: TextStyle(color: Colors.red[300])));

          final events = snapshot.data ?? [];
          return TabBarView(
            controller: _tabController,
            children: [
              _buildEventList(events.where((e) => e.status == RdvStatus.pending).toList()),
              _buildEventList(events.where((e) => e.status == RdvStatus.completed).toList()),
            ],
          );
        },
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(backgroundColor: primaryColor, child: const Icon(Icons.add, color: Colors.black), onPressed: () => _showAddRdvSheet())
          : null,
    );
  }

  Widget _buildEventList(List<RdvEvent> events) {
    if (events.isEmpty) return const Center(child: Text('Aucun rendez-vous'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
          child: ListTile(
            leading: Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                    color: event.isUrgent ? Colors.red : (event.type == 'voyage' ? Colors.blue : primaryColor),
                    borderRadius: BorderRadius.circular(2)
                )
            ),
            title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${event.date.day}/${event.date.month} à ${event.date.hour}:${event.date.minute}'),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (val) {
                if (val == 'edit') _showAddRdvSheet(eventToEdit: event);
                if (val == 'delete') _handleDelete(event.id);
                if (val == 'complete') _handleStatusChange(event);
              },
              itemBuilder: (ctx) => [
                if (event.status == RdvStatus.pending) const PopupMenuItem(value: 'complete', child: Text('Terminer')),
                const PopupMenuItem(value: 'edit', child: Text('Modifier')),
                const PopupMenuItem(value: 'delete', child: Text('Supprimer', style: TextStyle(color: Colors.red))),
              ],
            ),
          ),
        );
      },
    );
  }
}
