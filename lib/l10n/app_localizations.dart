import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    )!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
  _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'fr': {
      'dashboard': 'Accueil',
      'budget': 'Mon budget',
      'rdv': 'Mes RDV',
      'entreprise': 'Mon entreprise',
      'voyages': 'Mes voyages',
      'famille': 'En famille',
      'taches': 'Mes tâches',
      'upcoming': 'À venir',
      'history': 'Historique',
      'new_rdv': 'Nouveau RDV',
      'save': 'Enregistrer',
      'title': 'Titre',
      'description': 'Description',
      'urgent': 'Marquer comme urgent 🚨',
      'gestion_admin': 'Gestion & Admin',
      'admin': 'Administration',
      'admin_sub': 'Infos légales, Contacts, Documents',
      'rh': 'Support RH',
      'rh_sub': 'Collaborateurs, Absences, Documents RH',
      'compta_docs': 'Comptabilité & Documents',
      'pre_compta': 'Pré-comptabilité',
      'pre_compta_sub': 'Achats, Ventes, OCR, Journal Entry, FNP',
      'rapprochement': 'Rapprochement Bancaire',
      'rapprochement_sub': 'Import relevé, Matching automatique',
      'analyses': 'Analyses',
      'reports': 'Rapports & Exports',
      'reports_sub': 'Résultat, Balance, Export expert-comptable',
      'legal_info': 'Informations Légales',
      'raison_sociale': 'Raison Sociale',
      'siret': 'Numéro SIRET',
      'address': 'Adresse',
      'entities': 'Entités Gérées',
      'default': 'Défaut',
      'add_entity': 'Ajouter une entité',
      'absences': 'Absences & Congés',
      'docs_rh': 'Documents RH',
      'collab_folders': 'Dossiers Collaborateurs',
      'add_collab': 'Ajouter un collaborateur',
      'achats': 'Achats (Fournisseurs)',
      'ventes': 'Ventes (Clients)',
      'journal': 'Journal Entry (OD)',
      'fnp': 'FNP',
      'scan_inv': 'Scanner Facture',
      'manual_inv': 'Saisie Manuelle',
      'create_inv': 'Créer Facture',
      'ocr_analysis': 'Analyse OCR...',
      'verify_data': 'Vérification des données extraites',
      'supplier': 'Fournisseur',
      'inv_number': 'N° Facture',
      'ht': 'HT',
      'tva': 'TVA',
      'ttc': 'TTC',
      'pending': 'En attente',
      'validated': 'Validée',
      'paid': 'Payée',
      'rest_to_live': 'Reste à vivre',
      'income': 'Revenus',
      'expenses': 'Dépenses',
      'goals': 'Objectifs',
      'add_income': 'Ajouter un revenu',
      'add_expense': 'Ajouter une dépense',
      'amount': 'Montant',
      'destinations': 'Destinations',
      'documents': 'Documents',
      'add_trip': 'Ajouter un voyage',
      'members': 'Membres',
      'events': 'Événements',
      'add_member': 'Ajouter un membre',
      'todo': 'À faire',
      'done': 'Terminé',
      'add_task': 'Ajouter une tâche',
      'import_statement': 'Importer relevé',
      'matching': 'Matching',
      'unmatched': 'Non rapprochés',
      'matched': 'Rapprochés',
      'auto_match': 'Auto-match',
      'manual_match': 'Ajustement manuel',
      'date': 'Date',
      'label': 'Libellé',
      'revenue_by_client': 'Revenus par client',
      'expenses_by_period': 'Dépenses par période',
      'simplified_result': 'Résultat simplifié',
      'export_data': 'Exporter les données',
      'monthly': 'Mensuel',
      'annual': 'Annuel',
      'settings': 'Paramètres',
      'language': 'Langue',
      'country': 'Pays',
      'chart_of_accounts': 'Plan comptable',
      'notifications': 'Notifications',
      'security': 'Sécurité',
      'user_roles': 'Rôles utilisateurs',
      'appearance': 'Apparence',
      'login': 'Se connecter',
      'email': 'Email',
      'password': 'Mot de passe',
      'login_welcome': 'Bienvenue sur alt.',
      'login_subtitle': 'Gérez votre vie pro et perso en un seul endroit',
      'dont_have_account': 'Pas encore de compte ?',
      'register': 'S\'inscrire',
    },
    'en': {
      'dashboard': 'Dashboard',
      'budget': 'My budget',
      'rdv': 'My meetings',
      'entreprise': 'My company',
      'voyages': 'My trips',
      'famille': 'Family',
      'taches': 'My tasks',
      'upcoming': 'Upcoming',
      'history': 'History',
      'new_rdv': 'New Meeting',
      'save': 'Save',
      'title': 'Title',
      'description': 'Description',
      'urgent': 'Mark as urgent 🚨',
      'gestion_admin': 'Management & Admin',
      'admin': 'Administration',
      'admin_sub': 'Legal info, Contacts, Documents',
      'rh': 'HR Support',
      'rh_sub': 'Employees, Absences, HR Documents',
      'compta_docs': 'Accounting & Documents',
      'pre_compta': 'Accounting',
      'pre_compta_sub': 'Purchases, Sales, OCR, Journal Entry, FNP',
      'rapprochement': 'Bank Reconciliation',
      'rapprochement_sub': 'Statement import, Auto-matching',
      'analyses': 'Analytics',
      'reports': 'Reports & Exports',
      'reports_sub': 'Results, Balance, Accounting Export',
      'legal_info': 'Legal Information',
      'raison_sociale': 'Company Name',
      'siret': 'Registration Number',
      'address': 'Address',
      'entities': 'Managed Entities',
      'default': 'Default',
      'add_entity': 'Add Entity',
      'absences': 'Absences & Leaves',
      'docs_rh': 'HR Documents',
      'collab_folders': 'Employee Folders',
      'add_collab': 'Add Employee',
      'achats': 'Purchases (Suppliers)',
      'ventes': 'Sales (Clients)',
      'journal': 'Journal Entry (Misc)',
      'fnp': 'Unreceived Invoices',
      'scan_inv': 'Scan Invoice',
      'manual_inv': 'Manual Entry',
      'create_inv': 'Create Invoice',
      'ocr_analysis': 'OCR Analysis...',
      'verify_data': 'Verify extracted data',
      'supplier': 'Supplier',
      'inv_number': 'Invoice No.',
      'ht': 'Excl. Tax',
      'tva': 'VAT',
      'ttc': 'Total Inc. Tax',
      'pending': 'Pending',
      'validated': 'Validated',
      'paid': 'Paid',
      'rest_to_live': 'Left to spend',
      'income': 'Income',
      'expenses': 'Expenses',
      'goals': 'Goals',
      'add_income': 'Add income',
      'add_expense': 'Add expense',
      'amount': 'Amount',
      'destinations': 'Destinations',
      'documents': 'Documents',
      'add_trip': 'Add trip',
      'members': 'Members',
      'events': 'Events',
      'add_member': 'Add member',
      'todo': 'To-do',
      'done': 'Done',
      'add_task': 'Add task',
      'import_statement': 'Import statement',
      'matching': 'Matching',
      'unmatched': 'Unmatched',
      'matched': 'Matched',
      'auto_match': 'Auto-match',
      'manual_match': 'Manual adjustment',
      'date': 'Date',
      'label': 'Label',
      'revenue_by_client': 'Revenue by client',
      'expenses_by_period': 'Expenses by period',
      'simplified_result': 'Simplified result',
      'export_data': 'Export data',
      'monthly': 'Monthly',
      'annual': 'Annual',
      'settings': 'Settings',
      'language': 'Language',
      'country': 'Country',
      'chart_of_accounts': 'Chart of Accounts',
      'notifications': 'Notifications',
      'security': 'Security',
      'user_roles': 'User Roles',
      'appearance': 'Appearance',
      'login': 'Login',
      'email': 'Email',
      'password': 'Password',
      'login_welcome': 'Welcome to alt.',
      'login_subtitle': 'Manage your pro and personal life in one place',
      'dont_have_account': 'Don\'t have an account?',
      'register': 'Register',
    },
    'de': {
      'dashboard': 'Startseite',
      'budget': 'Mein Budget',
      'rdv': 'Meine Termine',
      'entreprise': 'Mein Unternehmen',
      'voyages': 'Meine Reisen',
      'famille': 'Familie',
      'taches': 'Meine Aufgaben',
      'upcoming': 'Anstehend',
      'history': 'Verlauf',
      'new_rdv': 'Neuer Termin',
      'save': 'Speichern',
      'title': 'Titel',
      'description': 'Beschreibung',
      'urgent': 'Als dringend markieren 🚨',
      'gestion_admin': 'Management & Admin',
      'admin': 'Verwaltung',
      'admin_sub': 'Rechtliche Infos, Kontakte, Dokumente',
      'rh': 'HR-Support',
      'rh_sub': 'Mitarbeiter, Abwesenheiten, HR-Dokumente',
      'compta_docs': 'Buchhaltung & Dokumente',
      'pre_compta': 'Vorbuchhaltung',
      'pre_compta_sub': 'Einkauf, Verkauf, OCR, Journal, FNP',
      'rapprochement': 'Bankabstimmung',
      'rapprochement_sub': 'Kontoauszugsimport, Auto-Matching',
      'analyses': 'Analysen',
      'reports': 'Berichte & Exporte',
      'reports_sub': 'Ergebnis, Bilanz, Buchhaltungsexport',
      'legal_info': 'Rechtliche Informationen',
      'raison_sociale': 'Firmenname',
      'siret': 'Registernummer',
      'address': 'Adresse',
      'entities': 'Verwaltete Einheiten',
      'default': 'Standard',
      'add_entity': 'Einheit hinzufügen',
      'absences': 'Abwesenheit & Urlaub',
      'docs_rh': 'HR-Dokumente',
      'collab_folders': 'Mitarbeiterakten',
      'add_collab': 'Mitarbeiter hinzufügen',
      'achats': 'Einkauf (Lieferanten)',
      'ventes': 'Verkauf (Kunden)',
      'journal': 'Journalbuchung',
      'fnp': 'Nicht erhaltene Rechnungen',
      'scan_inv': 'Rechnung scannen',
      'manual_inv': 'Manuelle Eingabe',
      'create_inv': 'Rechnung erstellen',
      'ocr_analysis': 'OCR-Analyse...',
      'verify_data': 'Extrahierte Daten prüfen',
      'supplier': 'Lieferant',
      'inv_number': 'Rechnungsnr.',
      'ht': 'Netto',
      'tva': 'MwSt.',
      'ttc': 'Brutto',
      'pending': 'Ausstehend',
      'validated': 'Validiert',
      'paid': 'Bezahlt',
      'rest_to_live': 'Verbleibend',
      'income': 'Einnahmen',
      'expenses': 'Ausgaben',
      'goals': 'Ziele',
      'add_income': 'Einnahme hinzufügen',
      'add_expense': 'Ausgabe hinzufügen',
      'amount': 'Betrag',
      'destinations': 'Ziele',
      'documents': 'Dokumente',
      'add_trip': 'Reise hinzufügen',
      'members': 'Mitglieder',
      'events': 'Ereignisse',
      'add_member': 'Mitglied hinzufügen',
      'todo': 'Zu erledigen',
      'done': 'Erledigt',
      'add_task': 'Aufgabe hinzufügen',
      'import_statement': 'Kontoauszug importieren',
      'matching': 'Abgleich',
      'unmatched': 'Nicht abgeglichen',
      'matched': 'Abgeglichen',
      'auto_match': 'Auto-Abgleich',
      'manual_match': 'Manuelle Anpassung',
      'date': 'Datum',
      'label': 'Verwendungszweck',
      'revenue_by_client': 'Einnahmen nach Kunde',
      'expenses_by_period': 'Ausgaben nach Zeitraum',
      'simplified_result': 'Vereinfachtes Ergebnis',
      'export_data': 'Daten exportieren',
      'monthly': 'Monatlich',
      'annual': 'Jährlich',
      'settings': 'Einstellungen',
      'language': 'Sprache',
      'country': 'Land',
      'chart_of_accounts': 'Kontenrahmen',
      'notifications': 'Benachrichtigungen',
      'security': 'Sicherheit',
      'user_roles': 'Benutzerrollen',
      'appearance': 'Aussehen',
      'login': 'Anmelden',
      'email': 'E-Mail',
      'password': 'Passwort',
      'login_welcome': 'Willkommen bei alt.',
      'login_subtitle': 'Verwalten Sie Ihr Berufs- und Privatleben an einem Ort',
      'dont_have_account': 'Noch kein Konto?',
      'register': 'Registrieren',
    },
  };

  String get rdv => _localizedValues[locale.languageCode]!['rdv']!;
  String get entreprise => _localizedValues[locale.languageCode]!['entreprise']!;
  String get voyages => _localizedValues[locale.languageCode]!['voyages']!;
  String get famille => _localizedValues[locale.languageCode]!['famille']!;
  String get taches => _localizedValues[locale.languageCode]!['taches']!;
  String get budget => _localizedValues[locale.languageCode]!['budget']!;
  String get upcoming => _localizedValues[locale.languageCode]!['upcoming']!;
  String get history => _localizedValues[locale.languageCode]!['history']!;
  String get newRdv => _localizedValues[locale.languageCode]!['new_rdv']!;
  String get save => _localizedValues[locale.languageCode]!['save']!;
  String get titleHint => _localizedValues[locale.languageCode]!['title']!;
  String get descHint => _localizedValues[locale.languageCode]!['description']!;
  String get urgentLabel => _localizedValues[locale.languageCode]!['urgent']!;
  String get gestionAdmin => _localizedValues[locale.languageCode]!['gestion_admin']!;
  String get admin => _localizedValues[locale.languageCode]!['admin']!;
  String get adminSub => _localizedValues[locale.languageCode]!['admin_sub']!;
  String get rh => _localizedValues[locale.languageCode]!['rh']!;
  String get rhSub => _localizedValues[locale.languageCode]!['rh_sub']!;
  String get comptaDocs => _localizedValues[locale.languageCode]!['compta_docs']!;
  String get preCompta => _localizedValues[locale.languageCode]!['pre_compta']!;
  String get preComptaSub => _localizedValues[locale.languageCode]!['pre_compta_sub']!;
  String get rapprochement => _localizedValues[locale.languageCode]!['rapprochement']!;
  String get rapprochementSub => _localizedValues[locale.languageCode]!['rapprochement_sub']!;
  String get analyses => _localizedValues[locale.languageCode]!['analyses']!;
  String get reports => _localizedValues[locale.languageCode]!['reports']!;
  String get reportsSub => _localizedValues[locale.languageCode]!['reports_sub']!;
  String get legalInfo => _localizedValues[locale.languageCode]!['legal_info']!;
  String get raisonSociale => _localizedValues[locale.languageCode]!['raison_sociale']!;
  String get siret => _localizedValues[locale.languageCode]!['siret']!;
  String get address => _localizedValues[locale.languageCode]!['address']!;
  String get entities => _localizedValues[locale.languageCode]!['entities']!;
  String get defaultTag => _localizedValues[locale.languageCode]!['default']!;
  String get addEntity => _localizedValues[locale.languageCode]!['add_entity']!;
  String get absences => _localizedValues[locale.languageCode]!['absences']!;
  String get docsRh => _localizedValues[locale.languageCode]!['docs_rh']!;
  String get collabFolders => _localizedValues[locale.languageCode]!['collab_folders']!;
  String get addCollab => _localizedValues[locale.languageCode]!['add_collab']!;
  String get achats => _localizedValues[locale.languageCode]!['achats']!;
  String get ventes => _localizedValues[locale.languageCode]!['ventes']!;
  String get journal => _localizedValues[locale.languageCode]!['journal']!;
  String get fnp => _localizedValues[locale.languageCode]!['fnp']!;
  String get scanInv => _localizedValues[locale.languageCode]!['scan_inv']!;
  String get manualInv => _localizedValues[locale.languageCode]!['manual_inv']!;
  String get createInv => _localizedValues[locale.languageCode]!['create_inv']!;
  String get ocrAnalysis => _localizedValues[locale.languageCode]!['ocr_analysis']!;
  String get verifyData => _localizedValues[locale.languageCode]!['verify_data']!;
  String get supplier => _localizedValues[locale.languageCode]!['supplier']!;
  String get invNumber => _localizedValues[locale.languageCode]!['inv_number']!;
  String get ht => _localizedValues[locale.languageCode]!['ht']!;
  String get tva => _localizedValues[locale.languageCode]!['tva']!;
  String get ttc => _localizedValues[locale.languageCode]!['ttc']!;
  String get pending => _localizedValues[locale.languageCode]!['pending']!;
  String get validated => _localizedValues[locale.languageCode]!['validated']!;
  String get paid => _localizedValues[locale.languageCode]!['paid']!;
  String get restToLive => _localizedValues[locale.languageCode]!['rest_to_live']!;
  String get income => _localizedValues[locale.languageCode]!['income']!;
  String get expenses => _localizedValues[locale.languageCode]!['expenses']!;
  String get goals => _localizedValues[locale.languageCode]!['goals']!;
  String get addIncome => _localizedValues[locale.languageCode]!['add_income']!;
  String get addExpense => _localizedValues[locale.languageCode]!['add_expense']!;
  String get amountLabel => _localizedValues[locale.languageCode]!['amount']!;
  String get destinations => _localizedValues[locale.languageCode]!['destinations']!;
  String get documents => _localizedValues[locale.languageCode]!['documents']!;
  String get addTrip => _localizedValues[locale.languageCode]!['add_trip']!;
  String get members => _localizedValues[locale.languageCode]!['members']!;
  String get events => _localizedValues[locale.languageCode]!['events']!;
  String get addMember => _localizedValues[locale.languageCode]!['add_member']!;
  String get todo => _localizedValues[locale.languageCode]!['todo']!;
  String get done => _localizedValues[locale.languageCode]!['done']!;
  String get addTask => _localizedValues[locale.languageCode]!['add_task']!;
  String get importStatement => _localizedValues[locale.languageCode]!['import_statement']!;
  String get matching => _localizedValues[locale.languageCode]!['matching']!;
  String get unmatched => _localizedValues[locale.languageCode]!['unmatched']!;
  String get matched => _localizedValues[locale.languageCode]!['matched']!;
  String get autoMatch => _localizedValues[locale.languageCode]!['auto_match']!;
  String get manualMatch => _localizedValues[locale.languageCode]!['manual_match']!;
  String get dateLabel => _localizedValues[locale.languageCode]!['date']!;
  String get labelText => _localizedValues[locale.languageCode]!['label']!;
  String get revenueByClient => _localizedValues[locale.languageCode]!['revenue_by_client']!;
  String get expensesByPeriod => _localizedValues[locale.languageCode]!['expenses_by_period']!;
  String get simplifiedResult => _localizedValues[locale.languageCode]!['simplified_result']!;
  String get exportData => _localizedValues[locale.languageCode]!['export_data']!;
  String get monthly => _localizedValues[locale.languageCode]!['monthly']!;
  String get annual => _localizedValues[locale.languageCode]!['annual']!;
  String get settings => _localizedValues[locale.languageCode]!['settings']!;
  String get language => _localizedValues[locale.languageCode]!['language']!;
  String get country => _localizedValues[locale.languageCode]!['country']!;
  String get chartOfAccounts => _localizedValues[locale.languageCode]!['chart_of_accounts']!;
  String get notifications => _localizedValues[locale.languageCode]!['notifications']!;
  String get security => _localizedValues[locale.languageCode]!['security']!;
  String get userRoles => _localizedValues[locale.languageCode]!['user_roles']!;
  String get appearance => _localizedValues[locale.languageCode]!['appearance']!;
  String get login => _localizedValues[locale.languageCode]!['login']!;
  String get email => _localizedValues[locale.languageCode]!['email']!;
  String get password => _localizedValues[locale.languageCode]!['password']!;
  String get loginWelcome => _localizedValues[locale.languageCode]!['login_welcome']!;
  String get loginSubtitle => _localizedValues[locale.languageCode]!['login_subtitle']!;
  String get dontHaveAccount => _localizedValues[locale.languageCode]!['dont_have_account']!;
  String get register => _localizedValues[locale.languageCode]!['register']!;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['fr', 'en', 'de'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_) => false;
}
