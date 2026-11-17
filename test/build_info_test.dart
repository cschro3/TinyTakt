import 'package:flutter_test/flutter_test.dart';
import 'package:tinytakt/app/build_info.dart';

void main() {
  test('Ohne dart-define steht eine klare Entwicklungskennung da', () {
    expect(buildSha, 'dev');
    expect(buildLabel, 'dev · lokal');
  });
}
