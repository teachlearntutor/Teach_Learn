import 'package:flutter_test/flutter_test.dart';
import 'package:teach_learn/core/utils/contact_utils.dart';

void main() {
  group('Contact & Phone Number Normalization Tests', () {
    test('normalizes Pakistani local 03xx numbers to +923xx format', () {
      expect(
        normalizePakistaniPhoneNumber('0301-555-0101'),
        equals('+923015550101'),
      );
      expect(
        normalizePakistaniPhoneNumber('0300 1234567'),
        equals('+923001234567'),
      );
      expect(
        normalizePakistaniPhoneNumber('03339876543'),
        equals('+923339876543'),
      );
    });

    test('preserves already formatted +923xx numbers', () {
      expect(
        normalizePakistaniPhoneNumber('+923015550101'),
        equals('+923015550101'),
      );
      expect(
        normalizePakistaniPhoneNumber('923015550101'),
        equals('+923015550101'),
      );
    });

    test('handles empty or blank phone inputs gracefully', () {
      expect(normalizePakistaniPhoneNumber(''), equals(''));
      expect(normalizePakistaniPhoneNumber('   '), equals(''));
    });
  });

  group('WhatsApp contact messages', () {
    test('tutor message is addressed from learner to tutor', () {
      expect(
        buildTutorContactWhatsAppMessage('  Ayesha Khan  '),
        'Hello Ayesha Khan, I saw that you accepted my tuition request on Teach Learn. Please let me know the next steps.',
      );
    });

    test('tutor message handles a missing tutor name', () {
      expect(
        buildTutorContactWhatsAppMessage(' '),
        'Hello, I saw that you accepted my tuition request on Teach Learn. Please let me know the next steps.',
      );
    });
  });
}
