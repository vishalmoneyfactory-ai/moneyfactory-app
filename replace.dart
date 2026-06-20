import 'dart:io';

void main() {
  final libDir = Directory('lib');
  for (var file in libDir.listSync(recursive: true)) {
    if (file is File && file.path.endsWith('.dart') && !file.path.endsWith('app_colors.dart') && !file.path.endsWith('app_theme.dart')) {
      var content = file.readAsStringSync();
      var replaced = content.replaceAll('AppColors.gold', 'AppColors.themeGold(context)');
      if (content != replaced) {
        file.writeAsStringSync(replaced);
        print('Updated \${file.path}');
      }
    }
  }
}
