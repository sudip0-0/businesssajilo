import 'package:businesssajilo/core/utils/rupees_in_words.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('writes whole rupees in English', () {
    expect(rupeesInWords(0), 'Zero rupees.');
    expect(rupeesInWords(100), 'One rupee.');
    expect(rupeesInWords(690000), 'Six thousand nine hundred rupees.');
    expect(rupeesInWords(109500), 'One thousand ninety-five rupees.');
  });

  test('uses Indian grouping for lakh and crore', () {
    expect(
      rupeesInWords(12345600),
      'One lakh twenty-three thousand four hundred fifty-six rupees.',
    );
    expect(rupeesInWords(1000000000), 'One crore rupees.');
  });

  test('drops paisa so wording matches print amounts', () {
    expect(rupeesInWords(10050), 'One hundred rupees.');
  });

  test('prefixes negative amounts', () {
    expect(rupeesInWords(-50000), 'Minus five hundred rupees.');
  });
}
