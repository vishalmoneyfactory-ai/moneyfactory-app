import 'package:flutter_test/flutter_test.dart';
import 'package:money_factory/core/theme/app_colors.dart';

void main() {
  test('Money Factory gold color is configured', () {
    expect(AppColors.gold.toARGB32(), 0xFFFFD700);
  });
}
