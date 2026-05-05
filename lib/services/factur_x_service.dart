import 'dart:io';
import 'package:xml/xml.dart';
import '../models/invoice.dart';
import '../models/supplier.dart';

class FacturXService {
  /// Génère le XML Factur-X (profil BASIC-WL ou EN 16931)
  String generateFacturXXml(Invoice invoice, Supplier supplier) {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    
    builder.element('rsm:CrossIndustryInvoice', namespaces: {
      'http://www.unece.org/cefact/namespaces/StandardBusinessDocumentHeader': 'sbd',
      'urn:un:unece:uncefact:data:standard:CrossIndustryInvoice:100': 'rsm',
      'urn:un:unece:uncefact:data:standard:ReusableAggregateBusinessInformationEntity:100': 'ram',
      'urn:un:unece:uncefact:data:standard:QualifiedDataType:100': 'udt',
    }, nest: () {
      // 1. En-tête du document
      builder.element('rsm:ExchangedDocumentContext', nest: () {
        builder.element('ram:GuidelineSpecifiedDocumentContextParameter', nest: () {
          builder.element('ram:ID', nest: 'urn:factur-x.eu:1p0:basicwl'); // Profil Basic-WL
        });
      });

      builder.element('rsm:ExchangedDocument', nest: () {
        builder.element('ram:ID', nest: invoice.number);
        builder.element('ram:TypeCode', nest: '380'); // 380 = Commercial Invoice
        builder.element('ram:IssueDateTime', nest: () {
          builder.element('udt:DateTimeString', attributes: {'format': '102'}, nest: invoice.date.toIso8601String().split('T')[0].replaceAll('-', ''));
        });
      });

      // 2. Transaction (Vendeur, Acheteur, Montants)
      builder.element('rsm:SupplyChainTradeTransaction', nest: () {
        
        // Vendeur (Fournisseur)
        builder.element('ram:ApplicableHeaderTradeAgreement', nest: () {
          builder.element('ram:SellerTradeParty', nest: () {
            builder.element('ram:Name', nest: supplier.name);
            if (supplier.siret != null) {
              builder.element('ram:SpecifiedLegalOrganization', nest: () {
                builder.element('ram:ID', attributes: {'schemeID': '0002'}, nest: supplier.siret); // 0002 = SIRET
              });
            }
            builder.element('ram:PostalTradeAddress', nest: () {
              builder.element('ram:LineOne', nest: supplier.address);
              builder.element('ram:CountryID', nest: 'FR');
            });
            if (supplier.vatin != null) {
              builder.element('ram:SpecifiedTaxRegistration', nest: () {
                builder.element('ram:ID', attributes: {'schemeID': 'VA'}, nest: supplier.vatin);
              });
            }
          });
          
          // Acheteur (Client) - Ici on simule l'entité de l'app
          builder.element('ram:BuyerTradeParty', nest: () {
            builder.element('ram:Name', nest: invoice.supplierOrClientName);
          });
        });

        // Livraison
        builder.element('ram:ApplicableHeaderTradeDelivery', nest: () {
          builder.element('ram:ActualDeliverySupplyChainEvent', nest: () {
            builder.element('ram:OccurrenceDateTime', nest: () {
              builder.element('udt:DateTimeString', attributes: {'format': '102'}, nest: invoice.date.toIso8601String().split('T')[0].replaceAll('-', ''));
            });
          });
        });

        // RÈGLEMENTS ET MONTANTS
        builder.element('ram:ApplicableHeaderTradeSettlement', nest: () {
          builder.element('ram:InvoiceCurrencyCode', nest: invoice.currency);
          
          // Totaux
          builder.element('ram:SpecifiedTradeSettlementHeaderMonetarySummation', nest: () {
            builder.element('ram:LineTotalAmount', nest: invoice.amountHT.toStringAsFixed(2));
            builder.element('ram:TaxBasisTotalAmount', nest: invoice.amountHT.toStringAsFixed(2));
            builder.element('ram:TaxTotalAmount', attributes: {'currencyID': invoice.currency}, nest: (invoice.amountTTC - invoice.amountHT).toStringAsFixed(2));
            builder.element('ram:GrandTotalAmount', nest: invoice.amountTTC.toStringAsFixed(2));
            builder.element('ram:DuePayableAmount', nest: invoice.amountTTC.toStringAsFixed(2));
          });
        });
      });
    });

    return builder.buildDocument().toXmlString(pretty: true);
  }
}
