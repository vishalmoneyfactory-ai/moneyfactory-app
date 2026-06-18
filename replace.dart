import 'dart:io';
void main() {
  var file = File('lib/features/earn/screens/earn_screen.dart');
  var content = file.readAsStringSync();
  content = content.replaceAll('AppColors.gold,', 'AppColors.themeGold(context),');
  content = content.replaceAll('AppColors.gold.', 'AppColors.themeGold(context).');
  content = content.replaceAll('AppColors.gold ?', 'AppColors.themeGold(context) ?');
  content = content.replaceAll('AppColors.gold :', 'AppColors.themeGold(context) :');
  content = content.replaceAll('AppColors.gold)', 'AppColors.themeGold(context))');
  content = content.replaceAllMapped(RegExp(r'const\s+TextStyle\([^)]*AppColors\.themeGold\(context\)[^)]*\)'), (m) => m.group(0)!.replaceAll('const ', ''));
  file.writeAsStringSync(content);
}
