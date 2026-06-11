import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

import '../../../core/api/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/gold_button.dart';

class MyCoursesScreen extends StatelessWidget {
  const MyCoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Learning')),
      body: FutureBuilder(
        future: Future.wait([api.me(), api.progressAll()]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.gold));
          final user = snapshot.data![0] as Map<String, dynamic>;
          final courses = user['purchasedCourses'] as List<dynamic>? ?? [];
          final progress = snapshot.data![1] as List<dynamic>;
          if (courses.isEmpty) {
            return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Text('No courses yet', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)), const SizedBox(height: 12), GoldButton(label: 'Browse Courses', onPressed: () => context.go('/home'))])));
          }
          return ListView.separated(padding: const EdgeInsets.all(16), itemCount: courses.length, separatorBuilder: (context, index) => const SizedBox(height: 12), itemBuilder: (context, i) {
            final c = courses[i];
            final rows = progress.where((p) => p['course']?['_id'] == c['_id']).toList();
            final completed = rows.where((p) => p['isCompleted'] == true).length;
            final total = c['totalVideos'] == 0 ? rows.length : c['totalVideos'];
            final percent = total == 0 ? 0.0 : completed / total;
            return Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)), child: Row(children: [Container(width: 76, height: 76, decoration: BoxDecoration(color: AppColors.secondaryBg, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.school, color: AppColors.gold)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(c['title'], style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 8), LinearPercentIndicator(lineHeight: 6, padding: EdgeInsets.zero, percent: percent.clamp(0, 1), progressColor: AppColors.gold, backgroundColor: AppColors.border), const SizedBox(height: 6), Text('$completed of $total videos', style: const TextStyle(color: AppColors.muted, fontSize: 12))])), TextButton(onPressed: () => context.push('/course/${c['_id']}'), child: const Text('Continue'))]));
          });
        },
      ),
    );
  }
}
