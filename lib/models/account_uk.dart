import 'account_fr.dart'; // Importez le modèle de base correct (probablement account.dart)

class UKAccounts {
  static List<Account> get defaultAccounts =>
      [
        // --- BALANCE SHEET (Bilan) ---
        Account(id: 'uk_1200', number: '1200', name: 'Trade Debtors', type: 'asset', plan: 'UK (COA)'),
        Account(id: 'uk_1210', number: '1210', name: 'Other Debtors', type: 'asset', plan: 'UK (COA)'),
        Account(id: 'uk_2100', number: '2100', name: 'Trade Creditors', type: 'liability', plan: 'UK (COA)'),
        Account(id: 'uk_2200', number: '2200', name: 'Sales Tax Control (VAT)', type: 'liability', plan: 'UK (COA)'),
        Account(id: 'uk_1000', number: '1000', name: 'Bank Current Account', type: 'asset', plan: 'UK (COA)'),
        Account(id: 'uk_1010', number: '1010', name: 'Petty Cash', type: 'asset', plan: 'UK (COA)'),
        Account(id: 'uk_3000', number: '3000', name: 'Ordinary Shares', type: 'equity', plan: 'UK (COA)'),
        Account(id: 'uk_3100', number: '3100', name: 'Retained Earnings', type: 'equity', plan: 'UK (COA)'),

        Account(id: 'uk_4000', number: '4000', name: 'Sales', type: 'produit', plan: 'UK (COA)'),
        Account(id: 'uk_4900', number: '4900', name: 'Other Income', type: 'produit', plan: 'UK (COA)'),

        Account(id: 'uk_5000', number: '5000', name: 'Cost of Sales (Purchases)', type: 'charge', plan: 'UK (COA)'),
        Account(id: 'uk_7000', number: '7000', name: 'Gross Wages', type: 'charge', plan: 'UK (COA)'),
        Account(id: 'uk_7100', number: '7100', name: 'Rent and Rates', type: 'charge', plan: 'UK (COA)'),
        Account(id: 'uk_7200', number: '7200', name: 'Heat, Light and Power', type: 'charge', plan: 'UK (COA)'),
        Account(id: 'uk_7500', number: '7500', name: 'Office Costs', type: 'charge', plan: 'UK (COA)'),
        Account(id: 'uk_7506', number: '7506', name: 'Advertising and PR', type: 'charge', plan: 'UK (COA)'),
        Account(id: 'uk_7600', number: '7600', name: 'Legal and Professional Fees', type: 'charge', plan: 'UK (COA)'),
        Account(id: 'uk_7900', number: '7900', name: 'Bank Bank Interest Paid', type: 'charge', plan: 'UK (COA)'),
        Account(id: 'uk_8200', number: '8200', name: 'General Expenses', type: 'charge', plan: 'UK (COA)'),
      ];
}