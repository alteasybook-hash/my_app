import 'account_fr.dart';

class DEAccounts {
  static List<Account> get defaultAccounts => [
    // =========================================================
    // CLASSE 0 : IMMOBILISATIONS (ANLAGEVERMÖGEN)
    // =========================================================
    Account(id: 'de_0010', number: '0010', name: 'Konzessionen, gewerbliche Schutzrechte', type: 'asset'),
    Account(id: 'de_0027', number: '0027', name: 'EDV-Software', type: 'asset'),
    Account(id: 'de_0035', number: '0035', name: 'Geschäfts- oder Firmenwert', type: 'asset'),
    Account(id: 'de_0039', number: '0039', name: 'Geleistete Anzahlungen', type: 'asset'),
    Account(id: 'de_0050', number: '0050', name: 'Grundstücke und Bauten', type: 'asset'),
    Account(id: 'de_0090', number: '0090', name: 'Geschäftsbauten', type: 'asset'),
    Account(id: 'de_0140', number: '0140', name: 'Wohnbauten', type: 'asset'),
    Account(id: 'de_0200', number: '0200', name: 'Technische Anlagen und Maschinen', type: 'asset'),
    Account(id: 'de_0320', number: '0320', name: 'Pkw (Véhicules)', type: 'asset'),
    Account(id: 'de_0350', number: '0350', name: 'Lkw (Camions)', type: 'asset'),
    Account(id: 'de_0400', number: '0400', name: 'Betriebsausstattung', type: 'asset'),
    Account(id: 'de_0410', number: '0410', name: 'Geschäftsausstattung', type: 'asset'),
    Account(id: 'de_0420', number: '0420', name: 'Büroeinrichtung', type: 'asset'),
    Account(id: 'de_0480', number: '0480', name: 'Geringwertige Wirtschaftsgüter (GWG)', type: 'asset'),
    Account(id: 'de_0485', number: '0485', name: 'Wirtschaftsgüter (Sammelposten)', type: 'asset'),
    Account(id: 'de_0510', number: '0510', name: 'Beteiligungen', type: 'asset'),
    Account(id: 'de_0550', number: '0550', name: 'Darlehen', type: 'asset'),

    // =========================================================
    // CLASSE 06-07 : DETTES LONG TERME (VERBINDLICHKEITEN)
    // =========================================================
    Account(id: 'de_0630', number: '0630', name: 'Verbindlichkeiten gegenüber Kreditinstituten', type: 'liability'),
    Account(id: 'de_0660', number: '0660', name: 'Verbindlichkeiten aus Teilzahlungsverträgen', type: 'liability'),
    Account(id: 'de_0700', number: '0700', name: 'Verbindlichkeiten ggü. verbundenen Unternehmen', type: 'liability'),
    Account(id: 'de_0730', number: '0730', name: 'Verbindlichkeiten gegenüber Gesellschaftern', type: 'liability'),

    // =========================================================
    // CLASSE 08-09 : CAPITAUX & PROVISIONS (EIGENKAPITAL / RÜCKSTELLUNGEN)
    // =========================================================
    Account(id: 'de_0800', number: '0800', name: 'Gezeichnetes Kapital', type: 'equity'),
    Account(id: 'de_0840', number: '0840', name: 'Kapitalrücklage', type: 'equity'),
    Account(id: 'de_0860', number: '0860', name: 'Gewinnvortrag vor Verwendung', type: 'equity'),
    Account(id: 'de_0950', number: '0950', name: 'Rückstellungen für Pensionen', type: 'liability'),
    Account(id: 'de_0955', number: '0955', name: 'Steuerrückstellungen', type: 'liability'),
    Account(id: 'de_0965', number: '0965', name: 'Rückstellungen für Personalkosten', type: 'liability'),
    Account(id: 'de_0970', number: '0970', name: 'Sonstige Rückstellungen', type: 'liability'),
    Account(id: 'de_0980', number: '0980', name: 'Aktive Rechnungsabgrenzung', type: 'asset'),
    Account(id: 'de_0990', number: '0990', name: 'Passive Rechnungsabgrenzung', type: 'liability'),

    // =========================================================
    // CLASSE 1 : TRÉSORERIE & CRÉANCES (UMLAUFVERMÖGEN)
    // =========================================================
    Account(id: 'de_1000', number: '1000', name: 'Kasse', type: 'asset'),
    Account(id: 'de_1100', number: '1100', name: 'Bank (Postbank)', type: 'asset'),
    Account(id: 'de_1200', number: '1200', name: 'Bank', type: 'asset'),
    Account(id: 'de_1360', number: '1360', name: 'Geldtransit', type: 'asset'),
    Account(id: 'de_1400', number: '1400', name: 'Forderungen aus Lieferungen und Leistungen', type: 'asset'),
    Account(id: 'de_1460', number: '1460', name: 'Zweifelhafte Forderungen', type: 'asset'),

    // --- Taxes et acomptes ---
    Account(id: 'de_1510', number: '1510', name: 'Geleistete Anzahlungen auf Vorräte', type: 'asset'),
    Account(id: 'de_1530', number: '1530', name: 'Forderungen gegen Personal', type: 'asset'),
    Account(id: 'de_1545', number: '1545', name: 'Umsatzsteuervorauszahlungen', type: 'asset'),
    Account(id: 'de_1571', number: '1571', name: 'Abziehbare Vorsteuer 7 %', type: 'asset'),
    Account(id: 'de_1576', number: '1576', name: 'Abziehbare Vorsteuer 19 %', type: 'asset'),
    Account(id: 'de_1588', number: '1588', name: 'Einfuhrumsatzsteuer', type: 'asset'),
    Account(id: 'de_1590', number: '1590', name: 'Durchlaufende Posten', type: 'asset'),
    Account(id: 'de_1600', number: '1600', name: 'Verbindlichkeiten aus L.L.', type: 'liability'),
    Account(id: 'de_1610', number: '1610', name: 'Verbindlichkeiten sans CC', type: 'liability'),
    Account(id: 'de_1624', number: '1624', name: 'Verbindlichkeiten Investitionen', type: 'liability'),
    Account(id: 'de_1630', number: '1630', name: 'Verbindlichkeiten ggü. verb. Untern.', type: 'liability'),
    Account(id: 'de_1650', number: '1650', name: 'Verbindlichkeiten ggü. Gesellschaftern', type: 'liability'),
    Account(id: 'de_1665', number: '1665', name: 'Verbindlichkeiten ggü. GmbH-Gesellschaftern', type: 'liability'),
    Account(id: 'de_1625', number: '1625', name: 'Verbindlichkeiten Investitionen ≤ 1 J.', type: 'liability'),
    Account(id: 'de_1626', number: '1626', name: 'Verbindlichkeiten Investitionen 1–5 J.', type: 'liability'),
    Account(id: 'de_1628', number: '1628', name: 'Verbindlichkeiten Investitionen > 5 J.', type: 'liability'),

    // =========================================================
    // CLASSE 17 : AUTRES DETTES, SALAIRES ET TVA
    // =========================================================
    Account(id: 'de_1700', number: '1700', name: 'Sonstige Verbindlichkeiten', type: 'liability'),
    Account(id: 'de_1705', number: '1705', name: 'Darlehen (Emprunts)', type: 'liability'),
    Account(id: 'de_1710', number: '1710', name: 'Erhaltene Anzahlungen', type: 'liability'),
    Account(id: 'de_1718', number: '1718', name: 'Erhaltene Anzahlungen 19% USt', type: 'liability'),

    // --- Salaires ---
    Account(id: 'de_1740', number: '1740', name: 'Verbindlichkeiten aus Lohn und Gehalt', type: 'liability'),
    Account(id: 'de_1741', number: '1741', name: 'Verbindlichkeiten Lohn- und Kirchensteuer', type: 'liability'),
    Account(id: 'de_1742', number: '1742', name: 'Verbindlichkeiten sociale Sicherheit', type: 'liability'),
    Account(id: 'de_1755', number: '1755', name: 'Lohn- und Gehaltsverrechnung', type: 'liability'),

    // --- TVA ---
    Account(id: 'de_1770', number: '1770', name: 'Umsatzsteuer', type: 'liability'),
    Account(id: 'de_1771', number: '1771', name: 'Umsatzsteuer 7 %', type: 'liability'),
    Account(id: 'de_1776', number: '1776', name: 'Umsatzsteuer 19 %', type: 'liability'),
    Account(id: 'de_1780', number: '1780', name: 'Umsatzsteuer-Vorauszahlungen', type: 'asset'),
    Account(id: 'de_1787', number: '1787', name: 'Umsatzsteuer § 13b UStG 19 %', type: 'liability'),

    // =========================================================
    // CLASSE 18 : COMPTES PRIVÉS
    // =========================================================
    Account(id: 'de_1800', number: '1800', name: 'Privatentnahmen', type: 'equity'),
    Account(id: 'de_1810', number: '1810', name: 'Privatsteuern', type: 'equity'),
    Account(id: 'de_1840', number: '1840', name: 'Spenden', type: 'equity'),
    Account(id: 'de_1890', number: '1890', name: 'Privateinlagen', type: 'equity'),

    // =========================================================
    // CLASSE 20 : AUTRES CHARGES (SONSTIGE AUFWENDUNGEN)
    // =========================================================
    Account(id: 'de_2000', number: '2000', name: 'Sonstige betriebliche Aufwendungen', type: 'charge'),
    Account(id: 'de_2010', number: '2010', name: 'Betriebsfremde Aufwendungen', type: 'charge'),
    Account(id: 'de_2020', number: '2020', name: 'Periodenfremde Aufwendungen', type: 'charge'),
    Account(id: 'de_2100', number: '2100', name: 'Zinsen und ähnliche Aufwendungen', type: 'charge'),
    Account(id: 'de_2150', number: '2150', name: 'Währungsumrechnung', type: 'charge'),
    Account(id: 'de_2200', number: '2200', name: 'Körperschaftsteuer', type: 'charge'),
    Account(id: 'de_2310', number: '2310', name: 'Anlagenabgänge Sachanlagen Verlust', type: 'charge'),
    Account(id: 'de_2640', number: '2640', name: 'Zins- und Dividendenerträge', type: 'produit'),
    Account(id: 'de_2742', number: '2742', name: 'Versicherungsentschädigungen', type: 'produit'),

    // =========================================================
    // CLASSE 3 : ACHATS
    // =========================================================
    Account(id: 'de_3200', number: '3200', name: 'Wareneingang', type: 'charge'),
    Account(id: 'de_3400', number: '3400', name: 'Wareneingang 19 % USt', type: 'charge'),
    Account(id: 'de_3800', number: '3800', name: 'Bezugsnebenkosten', type: 'charge'),
    Account(id: 'de_3950', number: '3950', name: 'Bestandsveränderungen Waren', type: 'charge'),

    // =========================================================
    // CLASSE 4 : CHARGES D'EXPLOITATION
    // =========================================================
    Account(id: 'de_4100', number: '4100', name: 'Löhne und Gehälter', type: 'charge'),
    Account(id: 'de_4130', number: '4130', name: 'Soziale Abgaben', type: 'charge'),
    Account(id: 'de_4210', number: '4210', name: 'Miete', type: 'charge'),
    Account(id: 'de_4240', number: '4240', name: 'Energie', type: 'charge'),
    Account(id: 'de_4530', number: '4530', name: 'Kfz-Betriebskosten', type: 'charge'),
    Account(id: 'de_4600', number: '4600', name: 'Werbekosten', type: 'charge'),
    Account(id: 'de_4660', number: '4660', name: 'Reisekosten Arbeitnehmer', type: 'charge'),
    Account(id: 'de_4910', number: '4910', name: 'Porto', type: 'charge'),
    Account(id: 'de_4920', number: '4920', name: 'Telefon', type: 'charge'),
    Account(id: 'de_4930', number: '4930', name: 'Bürobedarf', type: 'charge'),
    Account(id: 'de_4950', number: '4950', name: 'Rechts- und Beratungskosten', type: 'charge'),

    // =========================================================
    // CLASSE 8 : CHIFFRE D'AFFAIRES
    // =========================================================
    Account(id: 'de_8000', number: '8000', name: 'Umsatzerlöse', type: 'produit'),
    Account(id: 'de_8191', number: '8191', name: 'Umsätze 19 % USt', type: 'produit'),
    Account(id: 'de_8730', number: '8730', name: 'Skonti', type: 'produit'),
    Account(id: 'de_8990', number: '8990', name: 'aktivierte Eigenleistungen', type: 'produit'),

    // =========================================================
    // CLASSE 9 : COMPTES TECHNIQUES & BILAN
    // =========================================================
    Account(id: 'de_9000', number: '9000', name: 'Saldenvorträge', type: 'equity'),
    Account(id: 'de_9800', number: '9800', name: 'Gewinn-/Verlustvortrag', type: 'equity'),
  ];
}
