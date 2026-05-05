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
      'budget': 'Budget',
      'rdv': 'RDV',
      'entreprise': 'Entreprise',
      'entity': 'Entité',
      'entities': 'Entités',
      'documents': 'Documents',
      'backup_data': 'Sauvegarde des données',
      'import_export': 'Import / Export',
      'clear_cache': 'Vider le cache',
      'clear_cache_msg': 'Voulez-vous vraiment supprimer toutes les données locales ?',
      'number': 'Numéro',
      'taches': 'Tâches',
      'save': 'Enregistrer',
      'cancel': 'Annuler',
      'validate': 'Valider',
      'edit': 'Modifier',
      'delete': 'Supprimer',
      'view': 'Voir',
      'admin': 'Administration',
      'admin_sub': 'Infos légales, Contacts, Documents',
      'rh': 'RH',
      'finance': 'Finance',
      'marketing': 'Marketing',
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
      'siret': 'SIRET / ID Unique',
      'vat_number': 'Numéro de TVA',
      'address': 'Adresse',
      'country': 'Pays',
      'currency': 'Devise',
      'email': 'Email',
      'phone': 'Téléphone',
      'is_default': 'Entité par défaut',
      'add_logo': 'Ajouter un logo',
      'new_entity': 'Nouvelle Entité',
      'entity_details': 'Détails Entité',
      'first_name': 'Prénom',
      'last_name': 'Nom',
      'post': 'Poste / Mission',
      'contract_type': 'Type de contrat',
      'arrival_date': 'Date d\'arrivée',
      'end_date': 'Date de fin',
      'hiring_date': 'Date d\'embauche',
      'marital_status': 'Situation familiale',
      'emergency_contact': 'Contact urgence (Nom & Tél)',
      'vacation_rights': 'Droits Congés / an',
      'rtt_rights': 'Droits RTT / an',
      'onboarding': 'Intégration (Onboarding)',
      'new_employee': 'Nouveau Salarié',
      'launch_onboarding': 'Lancer l\'onboarding',
      'preparation_onboarding': '🚀 PRÉPARATION ONBOARDING',
      'select_entity': 'Sélectionner une entité',
      'status': 'Statut',
      'active': 'ACTIF',
      'resigned': 'SORTI',
      'upcoming': 'À VENIR',
      'absences': 'Absences',
      'absences_msg': 'Aucune absence pour ce mois.',
      'absence_motif': 'Motif',
      'half_day': 'Demi-journée (0,5 j)',
      'save_absence': 'Enregistrer l\'absence',
      'tr_resto': 'Titres-Resto',
      'new_absence': 'Saisie d\'Absence',
      'correction_for': 'Correction pour ',
      'taken': 'pris',
      'remaining': 'restants',
      'total_prorated': 'Total proratisé',
      'tr_calculated': ' tickets calculés',
      'view_file': 'Voir la fiche',
      'resign': 'Marquer démissionnaire',
      'reanimate': 'Réactiver',
      'activate_settings': 'ACTIVER DANS LES PARAMÈTRES',
      'add_document': 'Ajouter Document',
      'add_task': 'Ajouter une tâche',
      'ai_intelligence': 'Intelligence de Gestion',
      'alerts_disabled': 'Alertes désactivées',
      'enable_alerts_msg': 'Activez-les pour surveiller les dérives budgétaires et les urgences.',
      'budget_alert_title': 'ALERTE DE DÉRIVE BUDGÉTAIRE',
      'budget_alert_msg': 'Dépassement détecté sur : ',
      'budget_alert_suffix': '. Une révision des arbitrages financiers est requise.',
      'customer_followup': 'Relance client requise',
      'customer_followup_msg': ' créance(s) en attente. Risque sur le BFR identifié.',
      'hr_optimization': 'Optimisation RH',
      'hr_onboarding_msg': 'Onboarding de ',
      'hr_onboarding_suffix': ' à finaliser.',
      'debt_followup': 'Suivi des Créances',
      'secured_payments': 'Encaissements à sécuriser :',
      'remind': 'RELANCER',
      'home': 'Accueil',
      'settings_tab': 'Paramètres',
      'appearance': 'Apparence',
      'chart_of_accounts': 'Plan comptable',
      'contact_incomplete': '⚠️ Informations de contact à compléter',
      'destinations': 'Destinations',
      'doc_type': 'Type',
      'done': 'Terminé',
      'dont_have_account': 'Pas encore de compte ?',
      'employees': 'Salariés',
      'events': 'Événements',
      'famille': 'Famille',
      'file_source': 'Fichier source *',
      'gestion_admin': 'Gestion & Admin',
      'history': 'Historique',
      'how_can_i_help': 'Comment puis-je vous aider ?',
      'hr_new_doc': 'Nouveau Document Salarié',
      'invalid_pin': 'Code erroné',
      'language': 'Langue',
      'login': 'Se connecter',
      'members': 'Membres',
      'new_rdv': 'Nouveau RDV',
      'no_employees': 'Aucun salarié enregistré.',
      'notifications': 'Notifications',
      'password': 'Mot de passe',
      'pick_file': 'Cliquer pour choisir un fichier',
      'pin_required': 'Code PIN requis',
      'register': 'S\'inscrire',
      'security': 'Sécurité',
      'settings': 'Paramètres',
      'title': 'Titre',
      'todo': 'À faire',
      'urgent': 'Marquer comme urgent 🚨',
      'voyages': 'Voyages',
      'global_history': 'Historique général',
      'global_history_sub': 'Suivi des modifications et suppressions',
      'scan_invoice_btn': 'SCANNER UNE FACTURE',
      'no_invoice_found': 'Aucune facture trouvée.',
      'partial_status': 'PARTIEL',
      'paid_status': 'PAYÉ',
      'to_pay_status': 'À RÉGLER',
      'unpaid_status': 'NON PAYÉ',
      'apply_payment_action': 'Appliquer règlement',
      'collect_action': 'Encaisser',
      'print_action': 'Imprimer',
      'statement_action': 'État de compte',
      'partners': 'Partenaires',
      'suppliers': 'Fournisseurs',
      'customers': 'Clients',
      'quotes': 'Devis',
      'invoices': 'Factures',
      'journal_entries': 'Journal',
      'fnp_label': 'FNP',
      'no_entry_month': 'Aucune écriture pour ce mois.',
      'no_fnp_month': 'Aucune provision (FNP) pour ce mois.',
      'search': 'Rechercher...',
      'achats': 'Achats',
      'ventes': 'Ventes',
      'account_statement': 'État de compte',
      'partner_not_found': 'Détails du partenaire introuvables.',
      'local_analysis': 'Analyse locale de la facture...',
      'unknown_supplier': 'Fournisseur Inconnu',
      'auto_scan_label': 'Scan automatique (Local)',
      'total_ht': 'TOTAL HT',
      'total_tva': 'TOTAL TVA',
      'total_ttc': 'TOTAL TTC',
      'provision_detail': 'PROVISION EN DÉTAIL',
      'charge_detail_title': 'Détail des charges (Provisions)',
      'pass_od_provision': 'PASSER OD PROVISION',
      'od_generated': 'OD de provision générée.',
      'fnp_state_title': 'ÉTAT DES PROVISIONS (FNP)',
      'rest': 'Reste',
      'date_label': 'Date',
      'supplier_label': 'Fournisseur',
      'desc_label': 'Description',
      'ht_label': 'HT',
      'tva_label': 'TVA',
      'ttc_label': 'TTC',
      'confirm_delete': 'Voulez-vous vraiment supprimer cet élément ?',
      'amount_label': 'Montant',
      'debit': 'Débit',
      'credit': 'Crédit',
      'add_line': 'Ajouter une ligne',
      'payment_terms': 'Conditions de paiement',
      'attached_account': 'Compte rattaché',
      'issuer': 'Émetteur (Entité)',
      'select_account': 'Sélectionner un compte',
      'due_date': 'Échéance',
      'invoice_no': 'N° facture',
      'cost_center': 'Centre de coût',
      'none': 'Aucun',
      'bank_account': 'Compte bancaire',
      'add': 'Ajouter',
      'label': 'Libellé',
      'supplier': 'Fournisseur',
      'description': 'Description',
      'ht': 'HT',
      'tva': 'TVA',
      'ttc': 'TTC',
      'invNumber': 'N° de facture',
      'descHint': 'Ex: Achat matériel informatique',
      'edit_rdv': 'Modifier RDV',
      'type': 'Type',
      'error_loading': 'Erreur de chargement',
      'no_rdv': 'Aucun rendez-vous',
      'complete': 'Terminer',
      'edit_task': 'Modifier tâche',
      'due_date_label': 'Date d\'échéance *',
      'assign_to_optional': 'Assigner à (Optionnel)',
      'unassigned': 'Non assigné',
      'no_tasks': 'Aucune tâche',
      'due_date_prefix': 'Échéance:',
      'assigned_to_prefix': 'Assigné à:',
      'share': 'Partager',
      'theme': 'Thème',
      'theme_light': 'Clair',
      'theme_dark': 'Sombre',
      'theme_system': 'Système',
      'choose_theme': 'Choisir le thème',
      'admin_pin_config': 'Configurer le PIN Admin',
      'new_pin_label': 'Nouveau Code PIN (4 chiffres)',
      'pin_updated': 'Code PIN mis à jour',
      'pin_error': 'Le code PIN doit faire 4 chiffres',
      'push_notifications': 'Notifications push',
      'push_notifications_sub': 'Alertes factures et rapprochements',
      'cost_centers': 'Centres de Coûts',
      'manage_cost_centers': 'Gérer les centres de coûts',
      'accounting': 'COMPTABILITÉ',
      'manage_accounts': 'Gérer mes comptes',
      'tax_settings': 'Paramètres Taxes',
      'version': 'Version',
      'to_match': 'À MATCHER',
      'reconciled': 'RAPPROCHÉ',
      'total_software_balance': 'SOLDE COMPTABLE TOTAL (512) :',
      'software': 'LOGICIEL',
      'bank': 'BANQUE',
      'diff': 'DIFF.',
      'match': 'MATCHER',
      'bank_statement': 'RELEVÉ BANCAIRE',
      'accounting_512': 'COMPTABILITÉ (512)',
      'no_items': 'Aucun élément',
      'reconciled_lines': 'COMPTABILITÉ - LIGNES RAPPROCHÉES',
      'no_pending_lines': 'Aucune ligne en attente.',
      'doc_prefix': 'Doc: ',
      'report_history': 'HISTORIQUE DES RAPPORTS',
      'total_selected': 'TOTAL SÉLECTIONNÉ',
      'validate_and_report': 'VALIDER L\'ÉTAT ET GÉNÉRER LE RAPPORT',
      'suggested_matches': 'correspondances suggérées',
      'immediate': 'Immédiat',
      'fifteen_days': '15 jours',
      'thirty_days': '30 jours',
      'forty_five_days_eom': '45 jours fin de mois',
      'sixty_days': '60 jours',
      'new_quote': 'Nouveau Devis',
      'signed': 'SIGNÉ',
      'invoiced': 'FACTURÉ',
      'taxes': 'Taxes',
      'default_currency': 'Devise par défaut',
      'kept': 'GARDÉ',
      'extourned': 'EXTOURNÉ',
      'keep': 'Garder',
      'reverse': 'Extourner',
      'export_fnp': 'Exporter FNP',
      'designation_details': 'Désignation / Détails',
      'received_purchase': "REÇU D'ACHAT",
      'addressed_to': "ADRESSÉ À :",
      'final_balance': "SOLDE FINAL :",
      'position_debit': "POSITION : DÉBITRICE",
      'position_credit': "POSITION : CRÉDITRICE",
      'printed_on': "Imprimé le",
      'generated_by_software': "Document généré par votre logiciel de gestion.",
      'validity_quote': "Validité du devis : 30 jours",
      'payment_terms_prefix': "Conditions de paiement :",
      'quote_delete_title': "Supprimer le devis",
      'quote_delete_msg': "Voulez-vous vraiment supprimer ce devis ?",
      'account_label': 'Compte',
      'balance': 'Solde',
      'availabilitiesByBank': 'Disponibilités par Banque',
      'flowAnalysis6Months': 'Analyse des flux (6 mois)',
      'accountingExports': 'Exports Comptables',
      'purchasesJournal': 'Journal des Achats',
      'salesJournal': 'Journal des Ventes',
      'exportExcelMonth': 'Export Excel (Mois)',
      'generalLedger': 'Grand Livre',
      'expertSummary': 'Récapitulatif Expert',
      'sendToExpert': 'Envoyer à l\'expert',
      'caHt': 'CA HT',
      'charges': 'Charges',
      'monthlyResult': 'Résultat Mensuel',
      'profit': 'Bénéfice',
      'deficit': 'Déficit',
      'noBankAccount': 'Aucun compte bancaire',
      'balanceAt': 'Solde au',
      'revenueChart': 'Revenus',
      'expensesChart': 'Dépenses',
      'evolution6Months': 'Évolution sur 6 mois',
      'sending_documents': 'Envoi des documents...',
      'documents_sent_success': 'Documents envoyés avec succès !',
      'general': 'Général',
      'name': 'Nom',
      'cash_flow': 'Trésorerie',
      'invoices_to_pay': 'Factures à payer',
      'collections': 'Encaissement',
      'vat_balance': 'TVA',
      'pdp_received': 'FACTURE PDP REÇUE',
      'pdp_no_pending': 'Aucune facture PDP en attente.',
      'accept': 'ACCEPTER',
      'reject': 'REJETER',
      'faq_help': 'FAQ & Aide',
      'api_billing_config': 'Configurations Facturation API',
      'export_pdf': 'Export PDF',
      'select_entity_to_view': 'Sélectionnez une entité pour voir le budget.',
      'allocations': 'Allocations',
      'actual_spent': 'Réel (Achats/OD)',
      'available': 'Disponible',
      'consumption_rate': 'Taux de consommation',
      'forecast_provision': 'PROVISION PRÉVUE',
      'analysis_by_service': 'ANALYSE PAR SERVICE',
      'actual_expenses': 'Dépenses Réelles',
      'expense_history_6_months': 'HISTORIQUE DES DÉPENSES (6 MOIS)',
      'budget_bilan_title': 'BILAN DE PROVISION & FORECASTING',
      'export_excel': 'EXPORT EXCEL',
      'entity_label': 'Entité',
      'budget_envelope': 'Enveloppe Budgétaire',
      'real_consumption': 'Consommation Réelle',
      'variation': 'Variation',
      'execution_rate': 'Taux d\'exécution',
      'service': 'Service',
      'gap': 'Écart',
      'forecast': 'Forecast',
      'edit_provision': 'Modifier Provision',
      'adjust_forecast_msg': 'Ajustez le montant prévisionnel manuellement.',
      'expected_provision_hint': 'Provision Prévue (€)',
      'system_calculation': 'Calcul système',
      'auto_btn': 'AUTO',
      'save_btn': 'ENREGISTRER',
      'global_provision': 'Provision Globale',
      'override_provision_msg': 'Surchargez le montant de provision total pour l\'entité.',
      'auto_system_calculation': 'Calcul automatique système',
      'envelope_control': 'Contrôle de l\'Enveloppe',
      'entity_global_budget': 'Budget Global de l\'entité',
      'print_action': 'Imprimer',
      'partial_status': 'PARTIEL',
      'paid_status': 'PAYÉ',
      'to_pay_status': 'À RÉGLER',
      'unpaid_status': 'NON PAYÉ',
      'apply_payment_action': 'Appliquer le paiement',
      'collect_action': 'Encaisser',
      'statement_action': 'État de compte',
      'partners': 'Partenaires',
      'suppliers': 'Fournisseurs',
      'customers': 'Clients',
      'quotes': 'Devis',
      'invoices': 'Factures',
      'journal_entries': 'Journal',
      'paid_leave': 'congés',
      'faq_q1': "1. Qu’est-ce que alt. ?",
      'faq_a1': "alt. est une plateforme de gestion financière intelligente (FinTech) conçue pour les freelances et les entreprises.\n\n• Assistance par IA : Analyse financière et réponses en temps réel.\n• Multilingue : Support du Français, Anglais et Allemand.\n• Plans comptables : Compatible France (PCG), Royaume-Uni (COA), USA (GAAP) et Allemagne (DATEV).\n• Centres de coûts : Analyse détaillée par service ou activité.",
      'faq_q2': "2. Inscription & Compte",
      'faq_a2': "Pour commencer :\n\n1. Cliquez sur 'Créer un compte'.\n2. Renseignez vos informations (Email, SIREN, Adresse, Nom d'entreprise).\n3. Confirmez votre email.\n4. Configurez votre entité dans la page Administration.",
      'faq_q3': "3. Le Dashboard (Accueil)",
      'faq_a3': "C'est votre centre de pilotage :\n\n• Modules : Accès rapide à Entreprise, Budget, Tâches et RDV.\n• Assistant IA : Posez des questions comme 'Quel est mon burn rate ?' ou 'Quels clients sont inactifs ?'.\n• Notifications PDP : Acceptez ou rejetez les factures fournisseurs reçues instantanément.\n• Relances : Un bouton 'Relancer' automatique pour les factures clients impayées.",
      'faq_q4': "4. Gestion & Administration",
      'faq_a4': "Page Entreprise > Administration :\n• Configurez les détails légaux de votre structure.\n• Onglet Documents : Stockez, supprimez ou partagez vos documents officiels.\n\nPage Entreprise > Support RH :\n• Suivi des absences et gestion des documents salariés.\n• Titres-restaurant : Génération de exports CSV/Excel compatibles Swile et autres plateformes.",
      'faq_q5': "5. Pré-Comptabilité & Facturation",
      'faq_a5': "Achats :\n• Réception automatique via PDP (France uniquement).\n• Saisie manuelle via le bouton (+).\n• Application des paiements pour mettre à jour la trésorerie.\n\nVentes :\n• Cycle de vie : Brouillon -> En attente -> Reçu -> Accepté.\n• Devis : Création facile et partage direct avec vos clients.\n\nJournal & FNP :\n• Écritures d'achat/vente automatiques.\n• FNP (Factures Non Parvenues) : Gérez vos provisions mensuelles. Utilisez 'Garder' pour reporter à M+1 ou 'Extourner' pour les factures payées.",
      'faq_q6': "6. Rapprochement Bancaire",
      'faq_a6': "Un outil de précision pour votre 512 :\n\n1. Importez vos relevés (CSV ou OFX).\n2. Rapprochement IA : Cliquez sur l'icône IA pour matcher automatiquement les montants et dates.\n3. Validation : Une fois l'écart à zéro, validez pour générer un rapport de rapprochement mensuel téléchargeable.",
      'faq_q7': "7. Rapports, Budget & Paramètres",
      'faq_a7': "Analyses :\n• Graphiques de trésorerie dynamiques.\n• Calcul automatique du Burn Rate, MRR et Churn Rate.\n\nConfiguration :\n• Pin Admin : Sécurisez l'accès à vos documents sensibles.\n• Centres de coûts : Définissez vos codes (ex: 111 - RH) pour ventiler vos dépenses.",
      'faq_footer': "alt. Assistante - Simplifier votre finance",
    },
    'en': {
      'dashboard': 'Dashboard',
      'budget': 'Budget',
      'rdv': 'Meetings',
      'entreprise': 'Company',
      'entity': 'Entity',
      'entities': 'Entities',
      'documents': 'Documents',
      'backup_data': 'Backup Data',
      'import_export': 'Import / Export',
      'clear_cache': 'Clear Cache',
      'clear_cache_msg': 'Do you really want to clear all local data?',
      'number': 'Number',
      'taches': 'Tasks',
      'save': 'Save',
      'cancel': 'Cancel',
      'validate': 'Validate',
      'edit': 'Edit',
      'delete': 'Delete',
      'view': 'View',
      'admin': 'Administration',
      'admin_sub': 'Legal info, Contacts, Documents',
      'rh': 'HR',
      'finance': 'Finance',
      'marketing': 'Marketing',
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
      'siret': 'Tax ID / Registration No.',
      'vat_number': 'VAT Number',
      'address': 'Address',
      'country': 'Country',
      'currency': 'Currency',
      'email': 'Email',
      'phone': 'Phone',
      'is_default': 'Default Entity',
      'add_logo': 'Add Logo',
      'new_entity': 'New Entity',
      'entity_details': 'Entity Details',
      'first_name': 'First Name',
      'last_name': 'Last Name',
      'post': 'Job Title / Mission',
      'contract_type': 'Contract Type',
      'arrival_date': 'Arrival Date',
      'end_date': 'End Date',
      'hiring_date': 'Hiring Date',
      'marital_status': 'Marital Status',
      'emergency_contact': 'Emergency Contact (Name & Tel)',
      'vacation_rights': 'Vacation days / year',
      'rtt_rights': 'RTT days / year',
      'onboarding': 'Onboarding',
      'new_employee': 'New Employee',
      'launch_onboarding': 'Start Onboarding',
      'preparation_onboarding': '🚀 ONBOARDING PREPARATION',
      'select_entity': 'Select an entity',
      'status': 'Status',
      'active': 'ACTIVE',
      'resigned': 'LEFT',
      'upcoming': 'UPCOMING',
      'absences': 'Absences',
      'absences_msg': 'No absence for this month.',
      'absence_motif': 'Reason',
      'half_day': 'Half-day (0.5 d)',
      'save_absence': 'Save absence',
      'tr_resto': 'Meal Vouchers',
      'new_absence': 'New Absence',
      'correction_for': 'Correction for ',
      'taken': 'taken',
      'remaining': 'remaining',
      'total_prorated': 'Total prorated',
      'tr_calculated': ' vouchers calculated',
      'view_file': 'View file',
      'resign': 'Mark as resigned',
      'reanimate': 'Reactivate',
      'activate_settings': 'ACTIVATE IN SETTINGS',
      'add_document': 'Add Document',
      'add_task': 'Add Task',
      'ai_intelligence': 'Management Intelligence',
      'alerts_disabled': 'Alerts disabled',
      'enable_alerts_msg': 'Enable them to monitor budget drifts and emergencies.',
      'budget_alert_title': 'BUDGET DRIFT ALERT',
      'budget_alert_msg': 'Overrun detected on: ',
      'budget_alert_suffix': '. A review of financial trade-offs is required.',
      'customer_followup': 'Customer follow-up required',
      'customer_followup_msg': ' pending claim(s). Risk on working capital identified.',
      'hr_optimization': 'HR Optimization',
      'hr_onboarding_msg': 'Onboarding of ',
      'hr_onboarding_suffix': ' to finalize.',
      'debt_followup': 'Debt Tracking',
      'secured_payments': 'Payments to secure:',
      'remind': 'REMIND',
      'home': 'Home',
      'settings_tab': 'Settings',
      'appearance': 'Appearance',
      'chart_of_accounts': 'Chart of Accounts',
      'contact_incomplete': '⚠️ Contact info to complete',
      'destinations': 'Destinations',
      'doc_type': 'Type',
      'done': 'Done',
      'dont_have_account': 'Don\'t have an account?',
      'employees': 'Employees',
      'events': 'Events',
      'famille': 'Family',
      'file_source': 'Source file *',
      'gestion_admin': 'Management & Admin',
      'history': 'History',
      'how_can_i_help': 'How can I help you?',
      'hr_new_doc': 'New Employee Document',
      'invalid_pin': 'Incorrect code',
      'language': 'Language',
      'login': 'Login',
      'members': 'Members',
      'new_rdv': 'New Meeting',
      'no_employees': 'No employee registered.',
      'notifications': 'Notifications',
      'password': 'Password',
      'pick_file': 'Click to pick a file',
      'pin_required': 'PIN Code Required',
      'register': 'Register',
      'security': 'Security',
      'settings': 'Settings',
      'title': 'Title',
      'todo': 'To do',
      'urgent': 'Mark as urgent 🚨',
      'voyages': 'Trips',
      'global_history': 'General History',
      'global_history_sub': 'Tracking changes and deletions',
      'scan_invoice_btn': 'SCAN INVOICE',
      'no_invoice_found': 'No invoice found.',
      'partial_status': 'PARTIAL',
      'paid_status': 'PAID',
      'to_pay_status': 'TO PAY',
      'unpaid_status': 'UNPAID',
      'apply_payment_action': 'Apply Payment',
      'collect_action': 'Collect',
      'print_action': 'Print',
      'statement_action': 'Statement',
      'partners': 'Partners',
      'suppliers': 'Suppliers',
      'customers': 'Customers',
      'quotes': 'Quotes',
      'invoices': 'Invoices',
      'journal_entries': 'Journal',
      'fnp_label': 'FNP',
      'no_entry_month': 'No entries for this month.',
      'no_fnp_month': 'No accruals (FNP) for this month.',
      'search': 'Search...',
      'achats': 'Purchases',
      'ventes': 'Sales',
      'account_statement': 'Account statement',
      'partner_not_found': 'Partner details not found.',
      'local_analysis': 'Local invoice analysis...',
      'unknown_supplier': 'Unknown Supplier',
      'auto_scan_label': 'Automatic scan (Local)',
      'total_ht': 'TOTAL EXCL. TAX',
      'total_tva': 'TOTAL VAT',
      'total_ttc': 'TOTAL INCL. TAX',
      'provision_detail': 'ACCRUAL DETAILS',
      'charge_detail_title': 'Charge details (Accruals)',
      'pass_od_provision': 'PASS ACCRUAL JOURNAL ENTRY',
      'od_generated': 'Accrual journal entry generated.',
      'fnp_state_title': 'ACCRUAL STATE (FNP)',
      'rest': 'Rest',
      'date_label': 'Date',
      'supplier_label': 'Supplier',
      'desc_label': 'Description',
      'ht_label': 'Excl. Tax',
      'tva_label': 'VAT',
      'ttc_label': 'Incl. Tax',
      'confirm_delete': 'Are you sure you want to delete this item?',
      'amount_label': 'Amount',
      'debit': 'Debit',
      'credit': 'Credit',
      'add_line': 'Add line',
      'payment_terms': 'Payment terms',
      'attached_account': 'Attached account',
      'issuer': 'Issuer (Entity)',
      'select_account': 'Select account',
      'due_date': 'Due date',
      'invoice_no': 'Invoice no.',
      'cost_center': 'Cost Center',
      'none': 'None',
      'bank_account': 'Bank account',
      'add': 'Add',
      'label': 'Label',
      'supplier': 'Supplier',
      'description': 'Description',
      'ht': 'Excl. Tax',
      'tva': 'VAT',
      'ttc': 'Incl. Tax',
      'invNumber': 'Invoice No.',
      'descHint': 'Ex: IT equipment purchase',
      'edit_rdv': 'Edit Meeting',
      'type': 'Type',
      'error_loading': 'Error loading',
      'no_rdv': 'No meetings',
      'complete': 'Complete',
      'edit_task': 'Edit task',
      'due_date_label': 'Due date *',
      'assign_to_optional': 'Assign to (Optional)',
      'unassigned': 'Unassigned',
      'no_tasks': 'No tasks',
      'due_date_prefix': 'Due date:',
      'assigned_to_prefix': 'Assigned to:',
      'share': 'Share',
      'theme': 'Theme',
      'theme_light': 'Light',
      'theme_dark': 'Dark',
      'theme_system': 'System',
      'choose_theme': 'Choose theme',
      'admin_pin_config': 'Configure Admin PIN',
      'new_pin_label': 'New PIN (4 digits)',
      'pin_updated': 'PIN updated',
      'pin_error': 'PIN must be 4 digits',
      'push_notifications': 'Push notifications',
      'push_notifications_sub': 'Invoices and reconciliation alerts',
      'cost_centers': 'Cost Centers',
      'manage_cost_centers': 'Manage cost centers',
      'accounting': 'ACCOUNTING',
      'manage_accounts': 'Manage accounts',
      'tax_settings': 'Tax Settings',
      'version': 'Version',
      'to_match': 'TO MATCH',
      'reconciled': 'RECONCILED',
      'total_software_balance': 'TOTAL SOFTWARE BALANCE (512):',
      'software': 'SOFTWARE',
      'bank': 'BANK',
      'diff': 'DIFF.',
      'match': 'MATCH',
      'bank_statement': 'BANK STATEMENT',
      'accounting_512': 'ACCOUNTING (512)',
      'no_items': 'No items',
      'reconciled_lines': 'ACCOUNTING - RECONCILED LINES',
      'no_pending_lines': 'No pending lines.',
      'doc_prefix': 'Doc: ',
      'report_history': 'REPORT HISTORY',
      'total_selected': 'TOTAL SELECTED',
      'validate_and_report': 'VALIDATE STATE AND GENERATE REPORT',
      'suggested_matches': 'suggested matches',
      'immediate': 'Immediate',
      'fifteen_days': '15 days',
      'thirty_days': '30 days',
      'forty_five_days_eom': '45 days end of month',
      'sixty_days': '60 days',
      'new_quote': 'New Quote',
      'signed': 'SIGNED',
      'invoiced': 'INVOICED',
      'taxes': 'Taxes',
      'default_currency': 'Default Currency',
      'kept': 'KEPT',
      'extourned': 'REVERSED',
      'keep': 'Keep',
      'reverse': 'Reverse',
      'export_fnp': 'Export FNP',
      'designation_details': 'Designation / Details',
      'received_purchase': "PURCHASE RECEIPT",
      'addressed_to': "ADDRESSED TO:",
      'final_balance': "FINAL BALANCE:",
      'position_debit': "POSITION: DEBIT",
      'position_credit': "POSITION: CREDIT",
      'printed_on': "Printed on",
      'generated_by_software': "Document generated by your management software.",
      'validity_quote': "Quote validity: 30 days",
      'payment_terms_prefix': "Payment terms:",
      'quote_delete_title': "Delete quote",
      'quote_delete_msg': "Are you sure you want to delete this quote?",
      'account_label': 'Account',
      'balance': 'Balance',
      'availabilitiesByBank': 'Availabilities by Bank',
      'flowAnalysis6Months': 'Flow Analysis (6 months)',
      'accountingExports': 'Accounting Exports',
      'purchasesJournal': 'Purchases Journal',
      'salesJournal': 'Sales Journal',
      'exportExcelMonth': 'Excel Export (Month)',
      'generalLedger': 'General Ledger',
      'expertSummary': 'Expert Summary',
      'sendToExpert': 'Send to Expert',
      'caHt': 'Revenue (excl. tax)',
      'charges': 'Expenses',
      'monthlyResult': 'Monthly Result',
      'profit': 'Profit',
      'deficit': 'Deficit',
      'noBankAccount': 'No bank account',
      'balanceAt': 'Balance at',
      'revenueChart': 'Revenue',
      'expensesChart': 'Expenses',
      'evolution6Months': '6-month Evolution',
      'sending_documents': 'Sending documents...',
      'documents_sent_success': 'Documents sent successfully!',
      'general': 'General',
      'name': 'Name',
      'cash_flow': 'Cash Flow',
      'invoices_to_pay': 'Invoices to pay',
      'collections': 'Collections',
      'vat_balance': 'VAT',
      'pdp_received': 'PDP INVOICE RECEIVED',
      'pdp_no_pending': 'No pending PDP invoices.',
      'accept': 'ACCEPT',
      'reject': 'REJECT',
      'faq_help': 'FAQ & Help',
      'api_billing_config': 'API Billing Configurations',
      'faq_q1': "1. What is alt.?",
      'faq_a1': "alt. is an intelligent financial management platform (FinTech) designed for freelancers and businesses.\n\n• AI Assistance: Financial analysis and real-time answers.\n• Multilingual: Support for French, English, and German.\n• Accounting Plans: Compatible with France (PCG), UK (COA), USA (GAAP), and Germany (DATEV).\n• Cost Centers: Detailed analysis by department or activity.",
      'faq_q2': "2. Registration & Account",
      'faq_a2': "To get started:\n\n1. Click 'Create an account'.\n2. Enter your information (Email, Tax ID, Address, Company Name).\n3. Confirm your email.\n4. Set up your entity in the Administration page.",
      'faq_q3': "3. The Dashboard (Home)",
      'faq_a3': "It's your control center:\n\n• Modules: Quick access to Company, Budget, Tasks, and Meetings.\n• AI Assistant: Ask questions like 'What is my burn rate?' or 'Which clients are inactive?'.\n• PDP Notifications: Instantly accept or reject supplier invoices received.\n• Reminders: An automatic 'Remind' button for unpaid customer invoices.",
      'faq_q4': "4. Management & Administration",
      'faq_a4': "Company Page > Administration:\n• Configure the legal details of your structure.\n• Documents Tab: Store, delete, or share your official documents.\n\nCompany Page > HR Support:\n• Absence tracking and employee document management.\n• Meal Vouchers: CSV/Excel export generation compatible with Swile and other platforms.",
      'faq_q5': "5. Pre-Accounting & Invoicing",
      'faq_a5': "Purchases:\n• Automatic reception via PDP (France only).\n• Manual entry via the (+) button.\n• Apply payments to update cash flow.\n\nSales:\n• Lifecycle: Draft -> Pending -> Received -> Accepted.\n• Quotes: Easy creation and direct sharing with your clients.\n\nJournal & FNP:\n• Automatic purchase/sale entries.\n• FNP (Invoices Not Received): Manage your monthly accruals. Use 'Keep' to roll over to M+1 or 'Reverse' for paid invoices.",
      'faq_q6': "6. Bank Reconciliation",
      'faq_a6': "A precision tool for your bank accounts:\n\n1. Import your statements (CSV or OFX).\n2. AI Reconciliation: Click the AI icon to automatically match amounts and dates.\n3. Validation: Once the gap is zero, validate to generate a downloadable monthly reconciliation report.",
      'faq_q7': "7. Reports, Budget & Settings",
      'faq_a7': "Analytics:\n• Dynamic cash flow charts.\n• Automatic calculation of Burn Rate, MRR, and Churn Rate.\n\nConfiguration:\n• Admin PIN: Secure access to your sensitive documents.\n• Cost Centers: Define your codes (e.g., 111 - HR) to break down your expenses.",
      'faq_footer': "alt. Assistant - Simplifying your finance",
    },
    'de': {
      'dashboard': 'Startseite',
      'budget': 'Budget',
      'rdv': 'Termine',
      'entreprise': 'Unternehmen',
      'entity': 'Einheit',
      'entities': 'Einheiten',
      'documents': 'Dokumente',
      'backup_data': 'Datensicherung',
      'import_export': 'Import / Export',
      'clear_cache': 'Cache löschen',
      'clear_cache_msg': 'Möchten Sie wirklich alle lokalen Daten löschen?',
      'number': 'Nummer',
      'taches': 'Aufgaben',
      'save': 'Speichern',
      'cancel': 'Abbrechen',
      'validate': 'Validieren',
      'edit': 'Bearbeiten',
      'delete': 'Löschen',
      'view': 'Ansehen',
      'admin': 'Verwaltung',
      'admin_sub': 'Rechtliche Infos, Kontakte, Dokumente',
      'rh': 'HR',
      'finance': 'Finanzen',
      'marketing': 'Marketing',
      'rh_sub': 'Mitarbeiter, Fehlzeiten, HR-Dokumente',
      'compta_docs': 'Buchhaltung & Dokumente',
      'pre_compta': 'Vorabrechnung',
      'pre_compta_sub': 'Einkauf, Verkauf, OCR, Journalbuchung, FNP',
      'rapprochement': 'Bankabstimmung',
      'rapprochement_sub': 'Kontoauszug-Import, Automatischer Abgleich',
      'analyses': 'Analysen',
      'reports': 'Berichte & Exporte',
      'reports_sub': 'Ergebnis, Bilanz, Buchhaltungsexport',
      'legal_info': 'Rechtliche Informationen',
      'raison_sociale': 'Firmenname',
      'siret': 'Handelsregisternummer',
      'vat_number': 'USt-IdNr.',
      'address': 'Adresse',
      'country': 'Land',
      'currency': 'Währung',
      'email': 'E-Mail',
      'phone': 'Telefon',
      'is_default': 'Standardeinheit',
      'add_logo': 'Logo hinzufügen',
      'new_entity': 'Neue Einheit',
      'entity_details': 'Einheitendetails',
      'first_name': 'Vorname',
      'last_name': 'Nachname',
      'post': 'Position / Aufgabe',
      'contract_type': 'Vertragsart',
      'arrival_date': 'Ankunftsdatum',
      'end_date': 'Enddatum',
      'hiring_date': 'Einstellungsdatum',
      'marital_status': 'Familienstand',
      'emergency_contact': 'Notfallkontakt',
      'vacation_rights': 'Urlaubstage / Jahr',
      'rtt_rights': 'RTT-Tage / Jahr',
      'onboarding': 'Onboarding',
      'new_employee': 'Neuer Mitarbeiter',
      'launch_onboarding': 'Onboarding starten',
      'preparation_onboarding': '🚀 ONBOARDING VORBEREITUNG',
      'select_entity': 'Einheit auswählen',
      'status': 'Status',
      'active': 'AKTIV',
      'resigned': 'AUSGESCHIEDEN',
      'upcoming': 'ZUKÜNFTIG',
      'absences': 'Fehlzeiten',
      'absences_msg': 'Keine Fehlzeiten in diesem Monat.',
      'absence_motif': 'Grund',
      'half_day': 'Halber Tag (0,5 T)',
      'save_absence': 'Fehlzeit speichern',
      'tr_resto': 'Essensgutscheine',
      'new_absence': 'Fehlzeit erfassen',
      'correction_for': 'Korrektur für ',
      'taken': 'genommen',
      'remaining': 'verbleibend',
      'total_prorated': 'Gesamt anteilig',
      'tr_calculated': ' Gutscheine berechnet',
      'view_file': 'Akte ansehen',
      'resign': 'Als gekündigt markieren',
      'reanimate': 'Reaktivieren',
      'activate_settings': 'IN DEN EINSTELLUNGEN AKTIVIEREN',
      'add_document': 'Dokument hinzufügen',
      'add_task': 'Aufgabe hinzufügen',
      'ai_intelligence': 'Management-Intelligenz',
      'alerts_disabled': 'Warnungen deaktiviert',
      'enable_alerts_msg': 'Aktivieren Sie sie, um Budgetabweichungen und Notfälle zu überraschen.',
      'budget_alert_title': 'BUDGETABWEICHUNGSWARNUNG',
      'budget_alert_msg': 'Überschreitung erkannt bei: ',
      'budget_alert_suffix': '. Eine Überprüfung der finanziellen Abwägungen ist erforderlich.',
      'customer_followup': 'Kunden-Follow-up erforderlich',
      'customer_followup_msg': ' ausstehende Forderung(en). Risiko für das Betriebskapital identifiziert.',
      'hr_optimization': 'HR-Optimierung',
      'hr_onboarding_msg': 'Onboarding von ',
      'hr_onboarding_suffix': ' abschließen.',
      'debt_followup': 'Forderungsverfolgung',
      'secured_payments': 'Zahlungen sichern:',
      'remind': 'ERINNERN',
      'home': 'Startseite',
      'settings_tab': 'Einstellungen',
      'appearance': 'Erscheinungsbild',
      'chart_of_accounts': 'Kontenrahmen',
      'contact_incomplete': '⚠️ Kontaktinfos vervollständigen',
      'destinations': 'Ziele',
      'doc_type': 'Typ',
      'done': 'Erledigt',
      'dont_have_account': 'Noch kein Konto?',
      'employees': 'Mitarbeiter',
      'events': 'Ereignisse',
      'famille': 'Familie',
      'file_source': 'Quelldatei *',
      'gestion_admin': 'Management & Admin',
      'history': 'Verlauf',
      'how_can_i_help': 'Wie kann ich Ihnen helfen?',
      'hr_new_doc': 'Neues Mitarbeiterdokument',
      'invalid_pin': 'Falscher Code',
      'language': 'Sprache',
      'login': 'Anmelden',
      'members': 'Mitglieder',
      'new_rdv': 'Neuer Termin',
      'no_employees': 'Keine Mitarbeiter registriert.',
      'notifications': 'Benachrichtigungen',
      'password': 'Passwort',
      'pick_file': 'Datei auswählen',
      'pin_required': 'PIN erforderlich',
      'register': 'Registrieren',
      'security': 'Sicherheit',
      'settings': 'Einstellungen',
      'title': 'Titel',
      'todo': 'Zu erledigen',
      'urgent': 'Als dringend markieren 🚨',
      'voyages': 'Reisen',
      'global_history': 'Gesamtverlauf',
      'global_history_sub': 'Änderungen und Löschungen verfolgen',
      'scan_invoice_btn': 'RECHNUNG SCANNEN',
      'no_invoice_found': 'Keine Rechnung gefunden.',
      'partial_status': 'TEILWEISE',
      'paid_status': 'BEZAHLT',
      'to_pay_status': 'ZU ZAHLEN',
      'unpaid_status': 'UNBEZAHLT',
      'apply_payment_action': 'Zahlung anwenden',
      'collect_action': 'Einkassieren',
      'print_action': 'Drucken',
      'statement_action': 'Kontoauszug',
      'partners': 'Partner',
      'suppliers': 'Lieferanten',
      'customers': 'Kunden',
      'quotes': 'Angebote',
      'invoices': 'Rechnungen',
      'journal_entries': 'Journal',
      'fnp_label': 'FNP',
      'no_entry_month': 'Keine Einträge for diesen Monat.',
      'no_fnp_month': 'Keine Abgrenzungen (FNP) for diesen Monat.',
      'search': 'Suchen...',
      'achats': 'Einkauf',
      'ventes': 'Verkauf',
      'account_statement': 'Kontoauszug',
      'partner_not_found': 'Partnerdetails nicht gefunden.',
      'local_analysis': 'Lokale Rechnungsanalyse...',
      'unknown_supplier': 'Unbekannter Lieferant',
      'auto_scan_label': 'Automatischer Scan (Lokal)',
      'total_ht': 'GESAMT NETTO',
      'total_tva': 'GESAMT MWST',
      'total_ttc': 'GESAMT BRUTTO',
      'provision_detail': 'DETAILS DER ABGRENZUNG',
      'charge_detail_title': 'Kostendetails (Abgrenzungen)',
      'pass_od_provision': 'JOURNALBUCHUNG FÜR ABGRENZUNG ERSTELLEN',
      'od_generated': 'Journalbuchung for Abgrenzung erstellt.',
      'fnp_state_title': 'ABGRENZUNGSSTATUS (FNP)',
      'rest': 'Rest',
      'date_label': 'Datum',
      'supplier_label': 'Lieferant',
      'desc_label': 'Beschreibung',
      'ht_label': 'Netto',
      'tva_label': 'MwSt.',
      'ttc_label': 'Brutto',
      'confirm_delete': 'Möchten Sie dieses Element vraiment löschen?',
      'amount_label': 'Betrag',
      'debit': 'Soll',
      'credit': 'Haben',
      'add_line': 'Zeile hinzufügen',
      'payment_terms': 'Zahlungsbedingungen',
      'attached_account': 'Zugeordnetes Konto',
      'issuer': 'Aussteller (Einheit)',
      'select_account': 'Konto auswählen',
      'due_date': 'Fälligkeitsdatum',
      'invoice_no': 'Rechnungsnr.',
      'cost_center': 'Kostenstelle',
      'none': 'Keine',
      'bank_account': 'Bankkonto',
      'add': 'Hinzufügen',
      'label': 'Beschriftung',
      'supplier': 'Lieferant',
      'description': 'Beschreibung',
      'ht': 'Netto',
      'tva': 'MwSt.',
      'ttc': 'Brutto',
      'invNumber': 'Rechnungsnr.',
      'descHint': 'Z.B. Kauf von IT-Geräten',
      'edit_rdv': 'Termin bearbeiten',
      'type': 'Typ',
      'error_loading': 'Ladefehler',
      'no_rdv': 'Keine Termine',
      'complete': 'Abschließen',
      'edit_task': 'Aufgabe bearbeiten',
      'due_date_label': 'Fälligkeitsdatum *',
      'assign_to_optional': 'Zuweisen an (Optional)',
      'unassigned': 'Nicht zugewiesen',
      'no_tasks': 'Keine Aufgaben',
      'due_date_prefix': 'Fälligkeit:',
      'assigned_to_prefix': 'Zugewiesen an:',
      'share': 'Teilen',
      'theme': 'Thema',
      'theme_light': 'Hell',
      'theme_dark': 'Dunkel',
      'theme_system': 'System',
      'choose_theme': 'Thema wählen',
      'admin_pin_config': 'Admin-PIN konfigurieren',
      'new_pin_label': 'Neue PIN (4-stellig)',
      'pin_updated': 'PIN aktualisiert',
      'pin_error': 'PIN muss 4-stellig sein',
      'push_notifications': 'Push-Benachrichtigungen',
      'push_notifications_sub': 'Warnungen zu Rechnungen und Abstimmungen',
      'cost_centers': 'Kostenstellen',
      'manage_cost_centers': 'Kostenstellen verwalten',
      'accounting': 'BUCHHALTUNG',
      'manage_accounts': 'Konten verwalten',
      'tax_settings': 'Steuereinstellungen',
      'version': 'Version',
      'to_match': 'ZU ABGLEICHEN',
      'reconciled': 'ABGEGLICHEN',
      'total_software_balance': 'GESAMT-SOFTWARE-SALDO (512):',
      'software': 'SOFTWARE',
      'bank': 'BANK',
      'diff': 'DIFF.',
      'match': 'ABGLEICHEN',
      'bank_statement': 'KONTOAUSZUG',
      'accounting_512': 'BUCHHALTUNG (512)',
      'no_items': 'Keine Elemente',
      'reconciled_lines': 'BUCHHALTUNG - ABGEGLICHENE ZEILEN',
      'no_pending_lines': 'Keine ausstehenden Zeilen.',
      'doc_prefix': 'Dok: ',
      'report_history': 'BERICHTSVERLAUF',
      'total_selected': 'GESAMT AUSGEWÄHLT',
      'validate_and_report': 'STATUS BESTÄTIGEN UND BERICHT ERSTELLEN',
      'suggested_matches': 'vorgeschlagene Treffer',
      'immediate': 'Sofort',
      'fifteen_days': '15 Tage',
      'thirty_days': '30 Tage',
      'forty_five_days_eom': '45 Tage Monatsende',
      'sixty_days': '60 Tage',
      'new_quote': 'Neues Angebot',
      'signed': 'SIGNIERT',
      'invoiced': 'ABGERECHNET',
      'taxes': 'Steuern',
      'default_currency': 'Standardwährung',
      'kept': 'BEIBEHALTEN',
      'extourned': 'STORNIERT',
      'keep': 'Behalten',
      'reverse': 'Stornieren',
      'export_fnp': 'Export FNP',
      'designation_details': 'Bezeichnung / Details',
      'received_purchase': "EINKAUFSBELEG",
      'addressed_to': "ADRESSIERT AN:",
      'final_balance': "ENDSALDO:",
      'position_debit': "POSITION: SOLL",
      'position_credit': "POSITION: HABEN",
      'printed_on': "Gedruckt am",
      'generated_by_software': "Dokument erstellt durch Ihre Management-Software.",
      'validity_quote': "Angebotsgültigkeit: 30 Tage",
      'payment_terms_prefix': "Zahlungsbedingungen:",
      'quote_delete_title': "Angebot löschen",
      'quote_delete_msg': "Möchten Sie dieses Angebot wirklich löschen?",
      'account_label': 'Konto',
      'balance': 'Saldo',
      'availabilitiesByBank': 'Verfügbarkeit nach Bank',
      'flowAnalysis6Months': 'Flussanalyse (6 Monate)',
      'accountingExports': 'Buchhaltungsexportiert',
      'purchasesJournal': 'Einkauf Journal',
      'salesJournal': 'Verkauf Journal',
      'exportExcelMonth': 'Excel Export (Monat)',
      'generalLedger': 'Allgemeinledger',
      'expertSummary': 'Expertenzusammenfassung',
      'sendToExpert': 'An Expert senden',
      'caHt': 'Umsatz (netto)',
      'charges': 'Ausgaben',
      'monthlyResult': 'Monatliche Ergebnis',
      'profit': 'Profit',
      'deficit': 'Deficit',
      'noBankAccount': 'No bank account',
      'balanceAt': 'Balance at',
      'revenueChart': 'Revenue',
      'expensesChart': 'Expenses',
      'evolution6Months': '6-month Evolution',
      'sending_documents': 'Sending documents...',
      'documents_sent_success': 'Documents sent successfully!',
      'general': 'Allgemein',
      'name': 'Name',
      'cash_flow': 'Cash Flow',
      'invoices_to_pay': 'Invoices to pay',
      'collections': 'Collections',
      'vat_balance': 'VAT',
      'pdp_received': 'PDP RECHNUNG ERHALTEN',
      'pdp_no_pending': 'Keine ausstehenden PDP-Rechnungen.',
      'accept': 'AKZEPTIEREN',
      'reject': 'ABLEHNEN',
      'faq_help': 'FAQ & Hilfe',
      'api_billing_config': 'API-Abrechnungskonfigurationen',
      'faq_q1': "1. Was ist alt. ?",
      'faq_a1': "alt. ist eine intelligente Plattform für Finanzmanagement (FinTech), die für Freiberufler und Unternehmen entwickelt wurde.\n\n• KI-Unterstützung: Finanzanalyse und Antworten in Echtzeit.\n• Mehrsprachig: Unterstützung für Französisch, Englisch und Deutsch.\n• Kontenrahmen: Kompatibel mit Frankreich (PCG), Großbritannien (COA), USA (GAAP) und Deutschland (DATEV).\n• Kostenstellen: Detaillierte Analyse nach Abteilung oder Tätigkeit.",
      'faq_q2': "2. Registrierung & Konto",
      'faq_a2': "Um zu beginnen:\n\n1. Klicken Sie auf 'Konto erstellen'.\n2. Geben Sie Ihre Informationen ein (E-Mail, Steuernummer, Adresse, Firmenname).\n3. Bestätigen Sie Ihre E-Mail.\n4. Richten Sie Ihre Einheit auf der Administrationsseite ein.",
      'faq_q3': "3. Das Dashboard (Startseite)",
      'faq_a3': "Es ist Ihr Kontrollzentrum:\n\n• Module: Schneller Zugriff auf Unternehmen, Budget, Aufgaben und Termine.\n• KI-Assistent: Stellen Sie Fragen wie 'Wie hoch ist meine Burn Rate?' oder 'Welche Kunden sind inaktiv?'.\n• PDP-Benachrichtigungen: Akzeptieren oder lehnen Sie erhaltene Lieferantenrechnungen sofort ab.\n• Mahnungen: Eine automatische Schaltfläche 'Mahnung senden' für unbezahlte Kundenrechnungen.",
      'faq_q4': "4. Management & Administration",
      'faq_a4': "Unternehmensseite > Administration:\n• Konfigurieren Sie die rechtlichen Details Ihrer Struktur.\n• Registerkarte Dokumente: Speichern, löschen oder teilen Sie Ihre offiziellen Dokumente.\n\nUnternehmensseite > HR-Support:\n• Fehlzeitenverfolgung und Verwaltung von Mitarbeiterdokumenten.\n• Essensgutscheine: Erstellung von CSV/Excel-Exporten, die mit Swile und anderen Plattformen kompatibel sind.",
      'faq_q5': "5. Vorabrechnung & Rechnungsstellung",
      'faq_a5': "Einkauf:\n• Automatischer Empfang über PDP (nur Frankreich).\n• Manuelle Eingabe über die Schaltfläche (+).\n• Zahlungen anwenden, um den Cashflow zu aktualisieren.\n\nVerkauf:\n• Lebenszyklus: Entwurf -> Ausstehend -> Erhalten -> Akzeptiert.\n• Angebote: Einfache Erstellung und direkter Austausch mit Ihren Kunden.\n\nJournal & FNP:\n• Automatische Einkaufs-/Verkaufsbuchungen.\n• FNP (Noch nicht erhaltene Rechnungen): Verwalten Sie Ihre monatlichen Abgrenzungen. Verwenden Sie 'Beibehalten', um auf M+1 zu übertragen, oder 'Stornieren' für bezahlte Rechnungen.",
      'faq_q6': "6. Bankabstimmung",
      'faq_a6': "Ein Präzisionswerkzeug für Ihre Bankkonten:\n\n1. Importieren Sie Ihre Kontoauszüge (CSV oder OFX).\n2. KI-Abgleich: Klicken Sie auf das KI-Symbol, um Beträge und Daten automatisch abzugleichen.\n3. Validierung: Sobald die Differenz Null ist, validieren Sie, um einen herunterladbaren monatlichen Abstimmungsbericht zu erstellen.",
      'faq_q7': "7. Berichte, Budget & Einstellungen",
      'faq_a7': "Analysen:\n• Dynamische Cashflow-Diagramme.\n• Automatische Berechnung von Burn Rate, MRR und Churn Rate.\n\nKonfiguration:\n• Admin-PIN: Sicherer Zugriff auf Ihre sensiblen Dokumente.\n• Kostenstellen: Definieren Sie Ihre Codes (z. B. 111 - HR), um Ihre Ausgaben aufzuschlüsseln.",
      'faq_footer': "alt. Assistent - Vereinfachen Sie Ihre Finanzen",
    }
  };

  String _getValue(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? _localizedValues['fr']?[key] ?? 'MISSING: $key';
  }

  String get dashboard => _getValue('dashboard');
  String get budget => _getValue('budget');
  String get rdv => _getValue('rdv');
  String get entreprise => _getValue('entreprise');
  String get entity => _getValue('entity');
  String get entities => _getValue('entities');
  String get documents => _getValue('documents');
  String get backupData => _getValue('backup_data');
  String get importExport => _getValue('import_export');
  String get clearCache => _getValue('clear_cache');
  String get clearCacheMsg => _getValue('clear_cache_msg');
  String get number => _getValue('number');
  String get taches => _getValue('taches');
  String get save => _getValue('save');
  String get cancel => _getValue('cancel');
  String get validate => _getValue('validate');
  String get edit => _getValue('edit');
  String get delete => _getValue('delete');
  String get view => _getValue('view');
  String get admin => _getValue('admin');
  String get adminSub => _getValue('admin_sub');
  String get rh => _getValue('rh');
  String get hr => _getValue('rh');
  String get finance => _getValue('finance');
  String get marketing => _getValue('marketing');
  String get rhSub => _getValue('rh_sub');
  String get comptaDocs => _getValue('compta_docs');
  String get preCompta => _getValue('pre_compta');
  String get preComptaSub => _getValue('pre_compta_sub');
  String get rapprochement => _getValue('rapprochement');
  String get rapprochementSub => _getValue('rapprochement_sub');
  String get analyses => _getValue('analyses');
  String get reports => _getValue('reports');
  String get reportsSub => _getValue('reports_sub');
  String get legalInfo => _getValue('legal_info');
  String get raisonSociale => _getValue('raison_sociale');
  String get siret => _getValue('siret');
  String get vatNumber => _getValue('vat_number');
  String get address => _getValue('address');
  String get country => _getValue('country');
  String get currency => _getValue('currency');
  String get email => _getValue('email');
  String get phone => _getValue('phone');
  String get is_default => _getValue('is_default');
  String get addLogo => _getValue('add_logo');
  String get newEntity => _getValue('new_entity');
  String get entityDetails => _getValue('entity_details');
  String get firstName => _getValue('first_name');
  String get lastName => _getValue('last_name');
  String get post => _getValue('post');
  String get contractType => _getValue('contract_type');
  String get arrivalDate => _getValue('arrival_date');
  String get endDate => _getValue('end_date');
  String get hiringDate => _getValue('hiring_date');
  String get maritalStatus => _getValue('marital_status');
  String get emergencyContact => _getValue('emergency_contact');
  String get vacationRights => _getValue('vacation_rights');
  String get rttRights => _getValue('rtt_rights');
  String get onboarding => _getValue('onboarding');
  String get newEmployee => _getValue('new_employee');
  String get launchOnboarding => _getValue('launch_onboarding');
  String get preparationOnboarding => _getValue('preparation_onboarding');
  String get selectEntity => _getValue('select_entity');
  String get status => _getValue('status');
  String get active => _getValue('active');
  String get resigned => _getValue('resigned');
  String get upcoming => _getValue('upcoming');
  String get absences => _getValue('absences');
  String get absencesMsg => _getValue('absences_msg');
  String get absenceMotif => _getValue('absence_motif');
  String get halfDay => _getValue('half_day');
  String get saveAbsence => _getValue('save_absence');
  String get trResto => _getValue('tr_resto');
  String get newAbsence => _getValue('new_absence');
  String get correctionFor => _getValue('correction_for');
  String get taken => _getValue('taken');
  String get remaining => _getValue('remaining');
  String get totalProrated => _getValue('total_prorated');
  String get trCalculated => _getValue('tr_calculated');
  String get viewFile => _getValue('view_file');
  String get resign => _getValue('resign');
  String get reanimate => _getValue('reanimate');
  String get activateSettings => _getValue('activate_settings');
  String get addDocument => _getValue('add_document');
  String get addTask => _getValue('add_task');
  String get aiIntelligence => _getValue('ai_intelligence');
  String get alertsDisabled => _getValue('alerts_disabled');
  String get enableAlertsMsg => _getValue('enable_alerts_msg');
  String get budgetAlertTitle => _getValue('budget_alert_title');
  String get budgetAlertMsg => _getValue('budget_alert_msg');
  String get budgetAlertSuffix => _getValue('budget_alert_suffix');
  String get customerFollowup => _getValue('customer_followup');
  String get customerFollowupMsg => _getValue('customer_followup_msg');
  String get hrOptimization => _getValue('hr_optimization');
  String get hrOnboardingMsg => _getValue('hr_onboarding_msg');
  String get hrOnboardingSuffix => _getValue('hr_onboarding_suffix');
  String get debtFollowup => _getValue('debt_followup');
  String get securedPayments => _getValue('secured_payments');
  String get remind => _getValue('remind');
  String get home => _getValue('home');
  String get settingsTab => _getValue('settings_tab');
  String get appearance => _getValue('appearance');
  String get chartOfAccounts => _getValue('chart_of_accounts');
  String get contactIncomplete => _getValue('contact_incomplete');
  String get destinations => _getValue('destinations');
  String get docType => _getValue('doc_type');
  String get done => _getValue('done');
  String get dontHaveAccount => _getValue('dont_have_account');
  String get employees => _getValue('employees');
  String get events => _getValue('events');
  String get famille => _getValue('famille');
  String get fileSource => _getValue('file_source');
  String get gestionAdmin => _getValue('gestion_admin');
  String get history => _getValue('history');
  String get howCanIHelp => _getValue('how_can_i_help');
  String get hrNewDoc => _getValue('hr_new_doc');
  String get invalidPin => _getValue('invalid_pin');
  String get language => _getValue('language');
  String get login => _getValue('login');
  String get members => _getValue('members');
  String get newRdv => _getValue('new_rdv');
  String get noEmployees => _getValue('no_employees');
  String get notifications => _getValue('notifications');
  String get password => _getValue('password');
  String get pickFile => _getValue('pick_file');
  String get pinRequired => _getValue('pin_required');
  String get register => _getValue('register');
  String get security => _getValue('security');
  String get settings => _getValue('settings');
  String get titleHint => _getValue('title');
  String get todo => _getValue('todo');
  String get urgentLabel => _getValue('urgent');
  String get voyages => _getValue('voyages');
  String get globalHistory => _getValue('global_history');
  String get globalHistorySub => _getValue('global_history_sub');
  String get scanInvoiceBtn => _getValue('scan_invoice_btn');
  String get noInvoiceFound => _getValue('no_invoice_found');
  String get partialStatus => _getValue('partial_status');
  String get paidStatus => _getValue('paid_status');
  String get toPayStatus => _getValue('to_pay_status');
  String get unpaidStatus => _getValue('unpaid_status');
  String get applyPaymentAction => _getValue('apply_payment_action');
  String get collectAction => _getValue('collect_action');
  String get printAction => _getValue('print_action');
  String get statementAction => _getValue('statement_action');
  String get partners => _getValue('partners');
  String get suppliers => _getValue('suppliers');
  String get customers => _getValue('customers');
  String get quotes => _getValue('quotes');
  String get invoices => _getValue('invoices');
  String get journalEntries => _getValue('journal_entries');
  String get fnpLabel => _getValue('fnp_label');
  String get noEntryMonth => _getValue('no_entry_month');
  String get noFnpMonth => _getValue('no_fnp_month');
  String get search => _getValue('search');
  String get achats => _getValue('achats');
  String get ventes => _getValue('ventes');
  String get accountStatement => _getValue('account_statement');
  String get partnerNotFound => _getValue('partner_not_found');
  String get localAnalysis => _getValue('local_analysis');
  String get unknownSupplier => _getValue('unknown_supplier');
  String get autoScanLabel => _getValue('auto_scan_label');
  String get totalHT => _getValue('total_ht');
  String get totalTVA => _getValue('total_tva');
  String get totalTTC => _getValue('total_ttc');
  String get provisionDetail => _getValue('provision_detail');
  String get chargeDetailTitle => _getValue('charge_detail_title');
  String get passOdProvision => _getValue('pass_od_provision');
  String get odGenerated => _getValue('od_generated');
  String get fnpStateTitle => _getValue('fnp_state_title');
  String get rest => _getValue('rest');
  String get dateLabel => _getValue('date_label');
  String get supplierLabel => _getValue('supplier_label');
  String get descLabel => _getValue('desc_label');
  String get htLabel => _getValue('ht_label');
  String get tvaLabel => _getValue('tva_label');
  String get ttcLabel => _getValue('ttc_label');
  String get confirmDelete => _getValue('confirm_delete');
  String get amountLabel => _getValue('amount_label');
  String get debit => _getValue('debit');
  String get credit => _getValue('credit');
  String get addLine => _getValue('add_line');
  String get paymentTerms => _getValue('payment_terms');
  String get attachedAccount => _getValue('attached_account');
  String get issuer => _getValue('issuer');
  String get selectAccount => _getValue('select_account');
  String get dueDate => _getValue('due_date');
  String get invoiceNo => _getValue('invoice_no');
  String get costCenter => _getValue('cost_center');
  String get none => _getValue('none');
  String get bankAccount => _getValue('bank_account');
  String get add => _getValue('add');
  String get label => _getValue('label');
  String get supplier => _getValue('supplier');
  String get description => _getValue('description');
  String get ht => _getValue('ht');
  String get tva => _getValue('tva');
  String get ttc => _getValue('ttc');
  String get invNumber => _getValue('invNumber');
  String get descHint => _getValue('descHint');
  String get editRdv => _getValue('edit_rdv');
  String get typeLabel => _getValue('type');
  String get errorLoading => _getValue('error_loading');
  String get noRdv => _getValue('no_rdv');
  String get complete => _getValue('complete');
  String get editTask => _getValue('edit_task');
  String get dueDateLabel => _getValue('due_date_label');
  String get assignToOptional => _getValue('assign_to_optional');
  String get unassigned => _getValue('unassigned');
  String get noTasks => _getValue('no_tasks');
  String get dueDatePrefix => _getValue('due_date_prefix');
  String get assignedToPrefix => _getValue('assigned_to_prefix');
  String get share => _getValue('share');
  String get theme => _getValue('theme');
  String get themeLight => _getValue('theme_light');
  String get themeDark => _getValue('theme_dark');
  String get themeSystem => _getValue('theme_system');
  String get chooseTheme => _getValue('choose_theme');
  String get adminPinConfig => _getValue('admin_pin_config');
  String get newPinLabel => _getValue('new_pin_label');
  String get pinUpdated => _getValue('pin_updated');
  String get pinError => _getValue('pin_error');
  String get pushNotifications => _getValue('push_notifications');
  String get pushNotificationsSub => _getValue('push_notifications_sub');
  String get costCenters => _getValue('cost_centers');
  String get manageCostCenters => _getValue('manage_cost_centers');
  String get accounting => _getValue('accounting');
  String get manageAccounts => _getValue('manage_accounts');
  String get taxSettings => _getValue('tax_settings');
  String get version => _getValue('version');
  String get toMatch => _getValue('to_match');
  String get reconciled => _getValue('reconciled');
  String get totalSoftwareBalance => _getValue('total_software_balance');
  String get software => _getValue('software');
  String get bank => _getValue('bank');
  String get diff => _getValue('diff');
  String get match => _getValue('match');
  String get bankStatement => _getValue('bank_statement');
  String get accounting512 => _getValue('accounting_512');
  String get noItems => _getValue('no_items');
  String get reconciledLines => _getValue('reconciled_lines');
  String get noPendingLines => _getValue('no_pending_lines');
  String get docPrefix => _getValue('doc_prefix');
  String get reportHistory => _getValue('report_history');
  String get totalSelected => _getValue('total_selected');
  String get validateAndReport => _getValue('validate_and_report');
  String get suggestedMatches => _getValue('suggested_matches');
  String get immediate => _getValue('immediate');
  String get fifteenDays => _getValue('15_days');
  String get thirtyDays => _getValue('30_days');
  String get fortyFiveDaysEOM => _getValue('45_days_eom');
  String get sixtyDays => _getValue('60_days');
  String get newQuote => _getValue('new_quote');
  String get signed => _getValue('signed');
  String get invoiced => _getValue('invoiced');
  String get taxes => _getValue('taxes');
  String get defaultCurrency => _getValue('default_currency');
  String get kept => _getValue('kept');
  String get extourned => _getValue('extourned');
  String get keep => _getValue('keep');
  String get reverse => _getValue('reverse');
  String get exportFnp => _getValue('export_fnp');
  String get designationDetails => _getValue('designation_details');
  String get receivedPurchase => _getValue('received_purchase');
  String get addressedTo => _getValue('addressed_to');
  String get finalBalance => _getValue('final_balance');
  String get positionDebit => _getValue('position_debit');
  String get positionCredit => _getValue('position_credit');
  String get printedOn => _getValue('printed_on');
  String get generatedBySoftware => _getValue('generated_by_software');
  String get validityQuote => _getValue('validity_quote');
  String get paymentTermsPrefix => _getValue('payment_terms_prefix');
  String get quoteDeleteTitle => _getValue('quote_delete_title');
  String get quoteDeleteMsg => _getValue('quote_delete_msg');
  String get accountLabel => _getValue('account_label');
  String get balance => _getValue('balance');
  String get availabilitiesByBank => _getValue('availabilitiesByBank');
  String get flowAnalysis6Months => _getValue('flowAnalysis6Months');
  String get accountingExports => _getValue('accountingExports');
  String get purchasesJournal => _getValue('purchasesJournal');
  String get salesJournal => _getValue('salesJournal');
  String get exportExcelMonth => _getValue('exportExcelMonth');
  String get generalLedger => _getValue('generalLedger');
  String get expertSummary => _getValue('expertSummary');
  String get sendToExpert => _getValue('sendToExpert');
  String get caHt => _getValue('caHt');
  String get charges => _getValue('charges');
  String get monthlyResult => _getValue('monthlyResult');
  String get profit => _getValue('profit');
  String get deficit => _getValue('deficit');
  String get noBankAccount => _getValue('no_bank_account');
  String get balanceAt => _getValue('balanceAt');
  String get revenueChart => _getValue('revenueChart');
  String get expensesChart => _getValue('expensesChart');
  String get evolution6Months => _getValue('evolution6Months');
  String get sending_documents => _getValue('sending_documents');
  String get documents_sent_success => _getValue('documents_sent_success');
  String get general => _getValue('general');
  String get name => _getValue('name');
  String get cash_flow => _getValue('cash_flow');
  String get invoices_to_pay => _getValue('invoices_to_pay');
  String get collections => _getValue('collections');
  String get vat_balance => _getValue('vat_balance');
  String get pdp_received => _getValue('pdp_received');
  String get pdp_no_pending => _getValue('pdp_no_pending');
  String get accept => _getValue('accept');
  String get reject => _getValue('reject');
  String get faqHelp => _getValue('faq_help');
  String get apiBillingConfig => _getValue('api_billing_config');
  String get export_pdf => _getValue('export_pdf');
  String get select_entity_to_view => _getValue('select_entity_to_view');
  String get allocations => _getValue('allocations');
  String get actual_spent => _getValue('actual_spent');
  String get available => _getValue('available');
  String get consumption_rate => _getValue('consumption_rate');
  String get forecast_provision => _getValue('forecast_provision');
  String get analysis_by_service => _getValue('analysis_by_service');
  String get actual_expenses => _getValue('actual_expenses');
  String get expense_history_6_months => _getValue('expense_history_6_months');
  String get budget_bilan_title => _getValue('budget_bilan_title');
  String get export_excel => _getValue('export_excel');
  String get entity_label => _getValue('entity_label');
  String get budget_envelope => _getValue('budget_envelope');
  String get real_consumption => _getValue('real_consumption');
  String get variation => _getValue('variation');
  String get execution_rate => _getValue('execution_rate');
  String get service => _getValue('service');
  String get gap => _getValue('gap');
  String get forecast => _getValue('forecast');
  String get edit_provision => _getValue('edit_provision');
  String get adjust_forecast_msg => _getValue('adjust_forecast_msg');
  String get expected_provision_hint => _getValue('expected_provision_hint');
  String get system_calculation => _getValue('system_calculation');
  String get auto_btn => _getValue('auto_btn');
  String get save_btn => _getValue('save_btn');
  String get global_provision => _getValue('global_provision');
  String get override_provision_msg => _getValue('override_provision_msg');
  String get auto_system_calculation => _getValue('auto_system_calculation');
  String get envelope_control => _getValue('envelope_control');
  String get entity_global_budget => _getValue('entity_global_budget');
  String get print_action => _getValue('print_action');
  String get partial_status => _getValue('partial_status');
  String get paid_status => _getValue('paid_status');
  String get to_pay_status => _getValue('to_pay_status');
  String get unpaid_status => _getValue('unpaid_status');
  String get apply_payment_action => _getValue('apply_payment_action');
  String get collect_action => _getValue('collect_action');
  String get statement_action => _getValue('statement_action');
  String get journal_entries => _getValue('journal_entries');
  String get no_entry_month => _getValue('no_entry_month');
  String get allocated_budget => _getValue('allocated_budget');
  String get allocated_budget_title => _getValue('allocated_budget_title');
  String get allocated_budget_msg => _getValue('allocated_budget_msg');
  String get allocated_budget_btn => _getValue('allocated_budget_btn');
  String get forecast_end_month => _getValue('forecast_end_month');
  String get forecast_end_month_msg => _getValue('forecast_end_month_msg');
  String get forecast_end_month_btn => _getValue('forecast_end_month_btn');
  String get forecast_end_month_title => _getValue('forecast_end_month_title');
  String get sendingDocuments => _getValue('sending_documents');
  String get documentsSentSuccess => _getValue('documents_sent_success');
  String get onboardingTask => _getValue('onboarding_task');
  String get data => _getValue('data');
  String get paidLeave => _getValue('paid_leave');
  String get paidLeaveMsg => _getValue('paid_leave_msg');


  String get faq_q1 => _getValue('faq_q1');
  String get faq_a1 => _getValue('faq_a1');
  String get faq_q2 => _getValue('faq_q2');
  String get faq_a2 => _getValue('faq_a2');
  String get faq_q3 => _getValue('faq_q3');
  String get faq_a3 => _getValue('faq_a3');
  String get faq_q4 => _getValue('faq_q4');
  String get faq_a4 => _getValue('faq_a4');
  String get faq_q5 => _getValue('faq_q5');
  String get faq_a5 => _getValue('faq_a5');
  String get faq_q6 => _getValue('faq_q6');
  String get faq_a6 => _getValue('faq_a6');
  String get faq_q7 => _getValue('faq_q7');
  String get faq_a7 => _getValue('faq_a7');
  String get faq_footer => _getValue('faq_footer');


  
  // Snake_case aliases to fix undefined_getter errors
  String get account_label => _getValue('account_label');
  String get export_fnp => _getValue('export_fnp');
  String get fnp_label => _getValue('fnp_label');
  String get charge_detail_title => _getValue('charge_detail_title');
  String get od_generated => _getValue('od_generated');
  String get fnp_state_title => _getValue('fnp_state_title');
  String get account_statement => _getValue('account_statement');
  String get received_purchase => _getValue('received_purchase');
  String get date_label => _getValue('date_label');
  String get due_date => _getValue('due_date');
  String get addressed_to => _getValue('addressed_to');
  String get designation_details => _getValue('designation_details');
  String get ht_label => _getValue('ht_label');
  String get tva_label => _getValue('tva_label');
  String get printed_on => _getValue('printed_on');
  String get generated_by_software => _getValue('generated_by_software');
  String get final_balance => _getValue('final_balance');
  String get position_debit => _getValue('position_debit');
  String get position_credit => _getValue('position_credit');
  String get quote_delete_title => _getValue('quote_delete_title');
  String get quote_delete_msg => _getValue('quote_delete_msg');
  String get amount_label => _getValue('amount_label');
  String get payment_terms_prefix => _getValue('payment_terms_prefix');
  String get validity_quote => _getValue('validity_quote');
  String get payment_terms => _getValue('payment_terms');
  String get attached_account => _getValue('attached_account');
  String get select_account => _getValue('select_account');
  String get supplier_label => _getValue('supplier_label');
  String get desc_label => _getValue('desc_label');
  String get edit_rdv => _getValue('edit_rdv');
  String get type => _getValue('type');
  String get error_loading => _getValue('error_loading');
  String get no_rdv => _getValue('no_rdv');
  String get edit_task => _getValue('edit_task');
  String get due_date_label => _getValue('due_date_label');
  String get assign_to_optional => _getValue('assign_to_optional');
  String get no_tasks => _getValue('no_tasks');


  String onboarding_task(int index) => _getValue('onboarding_task_$index');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) => ['fr', 'en', 'de'].contains(locale.languageCode);
  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);
  @override
  bool shouldReload(_) => false;
}
