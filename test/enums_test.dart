import 'package:flutter_test/flutter_test.dart';
import 'package:qr_scan/qr_scan.dart';

void main() {
  group('ScanSoundResult', () {
    test('has exactly four values', () {
      expect(ScanSoundResult.values.length, 4);
    });

    test('contains expected values', () {
      expect(
          ScanSoundResult.values,
          containsAll([
            ScanSoundResult.success,
            ScanSoundResult.read,
            ScanSoundResult.fail,
            ScanSoundResult.none,
          ]));
    });

    test('values have correct index order', () {
      expect(ScanSoundResult.success.index, 0);
      expect(ScanSoundResult.read.index, 1);
      expect(ScanSoundResult.fail.index, 2);
      expect(ScanSoundResult.none.index, 3);
    });

    test('name returns correct string', () {
      expect(ScanSoundResult.success.name, 'success');
      expect(ScanSoundResult.read.name, 'read');
      expect(ScanSoundResult.fail.name, 'fail');
      expect(ScanSoundResult.none.name, 'none');
    });

    test('can be used as switch exhaustively', () {
      // Verify every value has a branch — compiler enforces exhaustiveness
      // but this test documents the contract
      for (final result in ScanSoundResult.values) {
        final label = switch (result) {
          ScanSoundResult.success => 'success',
          ScanSoundResult.read => 'read',
          ScanSoundResult.fail => 'fail',
          ScanSoundResult.none => 'none',
        };
        expect(label, isNotEmpty);
      }
    });

    test('nullable ScanSoundResult works for callback return type', () {
      // The useBarcode callback returns ScanSoundResult? — verify null is
      // a valid distinct value separate from ScanSoundResult.none
      ScanSoundResult? result;
      expect(result, isNull);
      expect(result != ScanSoundResult.none, isTrue);

      result = ScanSoundResult.none;
      expect(result, isNotNull);
    });
  });
}
