import 'package:flutter_test/flutter_test.dart';
import 'package:split_bill_app/models/participant_model.dart';
import 'package:split_bill_app/providers/split_bill_provider.dart';

void main() {
  group('SplitBillProvider Unit Testing (SB-27)', () {
    late SplitBillProvider provider;

    setUp(() {
      provider = SplitBillProvider();
    });

    test('calculateEqualSplit harus membagi subtotal secara merata', () {
      final participants = provider.calculateEqualSplit(
        subtotal: 100000,
        participantNames: ['Andi', 'Budi'],
      );

      expect(participants, isNotNull);
      expect(participants!.length, equals(2));
      expect(participants[0].nama, equals('Andi'));
      expect(participants[0].nominal, equals(50000));
      expect(participants[1].nama, equals('Budi'));
      expect(participants[1].nominal, equals(50000));
    });

    test('calculateEqualSplit harus membagikan PPN 10% & Service 5% secara proporsional', () {
      final participants = provider.calculateEqualSplit(
        subtotal: 100000,
        participantNames: ['Andi', 'Budi'],
        taxPercent: 10,
        servicePercent: 5,
      );

      expect(participants, isNotNull);
      expect(participants![0].nominal, equals(57500));
      expect(participants[1].nominal, equals(57500));
    });

    test('calculateCustomSplit harus memproses nominal kustom sesuai input', () {
      final customAmounts = {
        'Andi': 70000.0,
        'Budi': 30000.0,
      };

      final participants = provider.calculateCustomSplit(
        subtotal: 100000,
        customAmounts: customAmounts,
      );

      expect(participants, isNotNull);
      expect(participants![0].nominal, equals(70000));
      expect(participants[1].nominal, equals(30000));
    });

    test('calculateCustomSplit harus menolak jika total nominal custom != subtotal', () {
      final invalidCustom = {
        'Andi': 50000.0,
        'Budi': 30000.0,
      };

      final result = provider.calculateCustomSplit(
        subtotal: 100000,
        customAmounts: invalidCustom,
      );

      expect(result, isNull);
      expect(provider.errorMessage, isNotNull);
    });

    test('Perhitungan harus gagal jika subtotal <= 0', () {
      final result = provider.calculateEqualSplit(
        subtotal: 0,
        participantNames: ['Andi'],
      );

      expect(result, isNull);
      expect(
        provider.errorMessage,
        equals('Subtotal tagihan harus lebih besar dari Rp 0.'),
      );
    });

    test('toggleParticipantPaid harus mengubah status tagihan menjadi Lunas jika semua peserta sudah bayar', () async {
      final participants = [
        const ParticipantModel(
          id: 'p_1',
          nama: 'Andi',
          nominal: 50000,
          isPaid: false,
        ),
        const ParticipantModel(
          id: 'p_2',
          nama: 'Budi',
          nominal: 50000,
          isPaid: false,
        ),
      ];

      await provider.createBill(
        title: 'Makan Malam',
        subtotal: 100000,
        participants: participants,
      );

      final billId = provider.bills.first.id;
      expect(provider.activeBills.length, equals(1));
      expect(provider.settledBills.length, equals(0));

      await provider.toggleParticipantPaid(
        billId: billId,
        participantId: 'p_1',
      );
      expect(provider.bills.first.isLunas, isFalse);

      await provider.toggleParticipantPaid(
        billId: billId,
        participantId: 'p_2',
      );
      expect(provider.bills.first.isLunas, isTrue);
      expect(provider.activeBills.length, equals(0));
      expect(provider.settledBills.length, equals(1));
    });
  });
}