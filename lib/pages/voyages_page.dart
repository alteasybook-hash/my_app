import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class VoyagesPage extends StatefulWidget {
  const VoyagesPage({super.key});

  @override
  State<VoyagesPage> createState() => _VoyagesPageState();
}

class _VoyagesPageState extends State<VoyagesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Color primaryColor = const Color(0xFF49F6C7);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          t.voyages,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: primaryColor,
          indicatorWeight: 3,
          tabs: [
            Tab(text: t.destinations),
            Tab(text: t.documents),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDestinationsView(t),
          _buildDocumentsView(t),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _buildDestinationsView(AppLocalizations t) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildTripCard('Tokyo, Japon', 'Octobre 2024', Icons.location_on_outlined),
        _buildTripCard('New York, USA', 'Décembre 2024', Icons.location_on_outlined),
      ],
    );
  }

  Widget _buildDocumentsView(AppLocalizations t) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildTripCard('Passeport', 'Expire en 2028', Icons.description_outlined),
        _buildTripCard('Visa Japon', 'Validé', Icons.verified_outlined),
      ],
    );
  }

  Widget _buildTripCard(String title, String subtitle, IconData icon) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.black),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }
}
