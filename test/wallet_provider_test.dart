import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fisco_zen/data/wallet_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Audit Matematico e Stress Test - WalletProvider', () {
    late WalletProvider provider;
    late FakeFirebaseFirestore fakeDb;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      fakeDb = FakeFirebaseFirestore();
      provider = WalletProvider(firestore: fakeDb);
      await Future.delayed(const Duration(milliseconds: 10));
    });

    test('1. Calcolo Aliquota P.IVA e Riserva Tasse F24', () {
      provider.salvaProfiloFiscale(
        codiceAteco: '62.02.00',
        coeffRedditivitaVal: 67.0,
        aliquotaImpostaVal: 5.0,
        accontiVersati: 0.0,
        nettoTarget: 2500.0,
        fatturatoStimato: 50000.0,
        mesiAttivi: 11,
        annoAperturaPiva: 2026,
        meseAperturaPiva: 1,
      );

      provider.incassaFatturaPiva(
        cliente: 'Cliente Test Rossi',
        importoLordo: 10000.0,
        importoTasse: 2500.0,
        contoDestinazione: provider.accounts.first.title,
        dataIncasso: '15/03/2026',
      );

      expect(provider.fatturatoTotale, equals(10000.0));
      expect(provider.aliquotaFiscaleReale, greaterThan(0.0));

      final double tasseCalcolate = 10000.0 * provider.aliquotaFiscaleReale;
      final double nettoRimanente = 10000.0 - tasseCalcolate;

      expect(nettoRimanente + tasseCalcolate, closeTo(10000.0, 0.01));
    });

    test('2. Generazione e Controllo Ricorrenze', () {
      final double saldoIniziale = provider.patrimonioNetto;
      final DateTime ora = DateTime.now();

      provider.addTransaction(
        title: 'Abbonamento Palestra',
        amount: 100.0,
        isIncome: false,
        category: 'Divertimento',
        accountId: provider.accounts.first.id,
        date: ora,
        isRecurrent: true,
        frequenza: 'Ogni mese',
      );

      final previstiFuturo = provider.getMovimentiPrevisti(DateTime(ora.year + 1, 5, 1));
      expect(previstiFuturo.any((tx) => tx.title.contains('Palestra')), isTrue);
      expect(provider.patrimonioNetto, equals(saldoIniziale - 100.0));
    });

    test('3. Interruzione Ricorrenza (Stop da data)', () {
      final String idRule = 'test_rule_1';

      provider.addTransaction(
        customId: idRule,
        title: 'Affitto Ufficio',
        amount: 500.0,
        isIncome: false,
        category: 'Casa/Affitto',
        accountId: provider.accounts.first.id,
        date: DateTime(2026, 1, 1),
        isRecurrent: true,
        frequenza: 'Ogni mese',
      );

      provider.stopRecurrenceFromDate(idRule, DateTime(2026, 4, 30, 23, 59, 59));

      final previstiMaggio = provider.getMovimentiPrevisti(DateTime(2026, 5, 1));
      expect(previstiMaggio.any((tx) => tx.title.contains('Affitto Ufficio')), isFalse);
    });

    test('4. Ripartizione Bussola Budget (50/30/20)', () {
      provider.salvaRegolaBudget(50.0, 30.0, 20.0);

      final double entrateTotali = 3000.0;
      final double targetBisogni = entrateTotali * (provider.percentBisogni / 100);
      final double targetSvago = entrateTotali * (provider.percentSvago / 100);
      final double targetRisparmio = entrateTotali * (provider.percentRisparmio / 100);

      expect(targetBisogni, equals(1500.0));
      expect(targetSvago, equals(900.0));
      expect(targetRisparmio, equals(600.0));
      expect(targetBisogni + targetSvago + targetRisparmio, equals(entrateTotali));
    });
  });
}