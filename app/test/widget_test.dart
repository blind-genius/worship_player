import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/utils/formatters.dart';

void main() {
  test('AppFormatters formatDuration test', () {
    expect(AppFormatters.formatDuration(const Duration(seconds: 75), toPersian: false), '01:15');
    expect(AppFormatters.toPersianDigits('01:15'), '۰۱:۱۵');
  });
}
