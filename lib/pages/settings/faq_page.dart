import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

class FaqPage extends StatelessWidget {
  const FaqPage({super.key});

  final Color primaryColor = const Color(0xFF49F6C7);

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1B2E) : Colors.grey[50],
      appBar: AppBar(
        title: Text(t.faqHelp, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildFaqSection(
            t.faq_q1,
            t.faq_a1,
            Icons.info_outline,
            isDark
          ),
          _buildFaqSection(
            t.faq_q2,
            t.faq_a2,
            Icons.person_add_alt,
            isDark
          ),
          _buildFaqSection(
            t.faq_q3,
            t.faq_a3,
            Icons.dashboard_outlined,
            isDark
          ),
          _buildFaqSection(
            t.faq_q4,
            t.faq_a4,
            Icons.business_center_outlined,
            isDark
          ),
          _buildFaqSection(
            t.faq_q5,
            t.faq_a5,
            Icons.receipt_long_outlined,
            isDark
          ),
          _buildFaqSection(
            t.faq_q6,
            t.faq_a6,
            Icons.account_balance_outlined,
            isDark
          ),
          _buildFaqSection(
            t.faq_q7,
            t.faq_a7,
            Icons.analytics_outlined,
            isDark
          ),
          const SizedBox(height: 30),
          Center(
            child: Text(
              t.faq_footer,
              style: const TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildFaqSection(String title, String content, IconData icon, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF232435) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.withOpacity(0.1)),
      ),
      child: ExpansionTile(
        leading: Icon(icon, color: primaryColor),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 15,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedAlignment: Alignment.topLeft,
        children: [
          Text(
            content,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
