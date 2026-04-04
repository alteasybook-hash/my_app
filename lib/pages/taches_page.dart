import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../l10n/app_localizations.dart';
import '../models/task.dart';
import '../models/employee.dart';
import '../services/api_service.dart';

class TachesPage extends StatefulWidget {
  const TachesPage({super.key});

  @override
  State<TachesPage> createState() => _TachesPageState();
}

class _TachesPageState extends State<TachesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  final Color primaryColor = const Color(0xFF49F6C7);
  late Future<List<Task>> _tasksFuture;
  List<Employee> _employees = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadInitialData();
  }

  void _loadInitialData() async {
    _refreshTasks();
    final emps = await _apiService.fetchEmployees();
    setState(() => _employees = emps);
  }

  void _refreshTasks() {
    setState(() {
      _tasksFuture = _apiService.fetchTasks();
    });
  }

  void _showTaskSheet({Task? taskToEdit}) {
    final t = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleController = TextEditingController(text: taskToEdit?.title ?? '');
    DateTime selectedDate = taskToEdit != null
        ? (DateTime.tryParse(taskToEdit.deadline) ?? DateTime.now())
        : DateTime.now();
    Employee? selectedEmployee;

    if (taskToEdit?.assignedToId != null) {
      try {
        selectedEmployee = _employees.firstWhere((e) => e.id == taskToEdit!.assignedToId);
      } catch (_) {}
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2C) : Colors.white, 
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30))
          ),
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, top: 20, left: 20, right: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                taskToEdit == null ? t.addTask : 'Modifier tâche', 
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)
              ),
              const SizedBox(height: 20),
              TextField(
                controller: titleController, 
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: t.titleHint, 
                  labelStyle: const TextStyle(color: Colors.grey),
                  border: const OutlineInputBorder()
                )
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final d = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                  if (d != null) setS(() => selectedDate = d);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Date d\'échéance *', border: OutlineInputBorder()),
                  child: Text(DateFormat('dd/MM/yyyy').format(selectedDate), style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Employee>(
                value: selectedEmployee,
                dropdownColor: isDark ? const Color(0xFF232435) : Colors.white,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: const InputDecoration(labelText: 'Assigner à (Optionnel)', border: OutlineInputBorder()),
                items: [
                  DropdownMenuItem<Employee>(
                    value: null, 
                    child: Text("Non assigné", style: TextStyle(color: isDark ? Colors.white54 : Colors.grey))
                  ),
                  ..._employees.map((e) => DropdownMenuItem(
                    value: e, 
                    child: Row(
                      children: [
                        Text("${e.firstName} ${e.lastName}", style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        Text("(${e.post})", style: TextStyle(fontSize: 11, color: isDark ? primaryColor : Colors.blueGrey, fontStyle: FontStyle.italic)),
                      ],
                    )
                  )),
                ],
                onChanged: (v) => setS(() => selectedEmployee = v),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.isEmpty) return;
                    final newTask = Task(
                      id: taskToEdit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                      title: titleController.text,
                      deadline: selectedDate.toIso8601String(),
                      isDone: taskToEdit?.isDone ?? false,
                      userId: 'current_user',
                      assignedToId: selectedEmployee?.id,
                      assignedToName: selectedEmployee != null ? "${selectedEmployee!.firstName} ${selectedEmployee!.lastName}" : null,
                    );

                    if (taskToEdit == null) {
                      await _apiService.createTask(newTask);
                    } else {
                      await _apiService.updateTask(newTask.id, newTask.toJson());
                    }

                    Navigator.pop(context);
                    _refreshTasks();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                  child: Text(t.save, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
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
        title: Text(t.taches, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController, 
          labelColor: isDark ? primaryColor : Colors.black, 
          unselectedLabelColor: Colors.grey,
          indicatorColor: primaryColor, 
          tabs: [Tab(text: t.todo), Tab(text: t.done)]
        ),
      ),
      body: FutureBuilder<List<Task>>(
        future: _tasksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Erreur de chargement', style: TextStyle(color: Colors.red[300])));
          final tasks = snapshot.data ?? [];
          return TabBarView(
            controller: _tabController,
            children: [
              _buildTasksList(tasks.where((task) => !task.isDone).toList(), false),
              _buildTasksList(tasks.where((task) => task.isDone).toList(), true),
            ],
          );
        },
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(backgroundColor: primaryColor, child: const Icon(Icons.add, color: Colors.black), onPressed: () => _showTaskSheet())
          : null,
    );
  }

  Widget _buildTasksList(List<Task> tasks, bool isDone) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (tasks.isEmpty) return Center(child: Text('Aucune tâche', style: TextStyle(color: isDark ? Colors.grey : Colors.black54)));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        DateTime? d;
        try { d = DateTime.parse(task.deadline); } catch(_) {}

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          color: isDark ? const Color(0xFF232435) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: isDone ? primaryColor : (isDark ? Colors.white10 : Colors.grey.withOpacity(0.2)))),
          child: ListTile(
            leading: IconButton(
              icon: Icon(isDone ? Icons.check_circle : Icons.radio_button_unchecked, color: isDone ? primaryColor : (isDark ? Colors.white70 : Colors.black)),
              onPressed: () async {
                await _apiService.updateTask(task.id, {'isDone': !task.isDone});
                _refreshTasks();
              },
            ),
            title: Text(task.title, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black, decoration: isDone ? TextDecoration.lineThrough : null)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (d != null) Text("Échéance: ${DateFormat('dd/MM/yyyy').format(d)}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                if (task.assignedToName != null) Text("Assigné à: ${task.assignedToName}", style: TextStyle(fontSize: 11, color: isDark ? primaryColor : Colors.blue[700])),
              ],
            ),
            trailing: PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: isDark ? Colors.white70 : Colors.black),
              onSelected: (val) async {
                if (val == 'edit') _showTaskSheet(taskToEdit: task);
                if (val == 'share') {
                  String text = "Tâche : ${task.title}";
                  if (d != null) text += "\nÉchéance : ${DateFormat('dd/MM/yyyy').format(d)}";
                  if (task.assignedToName != null) text += "\nAssigné à : ${task.assignedToName}";
                  Share.share(text);
                }
                if (val == 'delete') {
                  await _apiService.deleteTask(task.id);
                  _refreshTasks();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Modifier')),
                const PopupMenuItem(value: 'share', child: Text('Partager')),
                const PopupMenuItem(value: 'delete', child: Text('Supprimer', style: TextStyle(color: Colors.red))),
              ],
            ),
          ),
        );
      },
    );
  }
}
