import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

import '../../../core/api/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/gold_button.dart';

class MyCoursesScreen extends StatefulWidget {
  const MyCoursesScreen({super.key});

  @override
  State<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends State<MyCoursesScreen> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = Future.wait([api.me(), api.progressAll()]);
  }

  Future<void> _refresh() async {
    setState(_load);
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Learning')),
      body: RefreshIndicator(
        color: AppColors.gold,
        onRefresh: _refresh,
        child: FutureBuilder(
          future: _future,
          builder: (context, snapshot) {
            // Error state — scrollable so pull-to-refresh still works
            if (snapshot.hasError) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wifi_off, color: AppColors.muted, size: 52),
                        const SizedBox(height: 16),
                        const Text('Could not load courses', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        const SizedBox(height: 6),
                        Text(
                          snapshot.error.toString().replaceAll('Exception: ', ''),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.muted, fontSize: 13),
                        ),
                        const SizedBox(height: 20),
                        const Text('Pull down to retry', style: TextStyle(color: AppColors.gold, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              );
            }
            // Loading state — scrollable so pull-to-refresh still works
            if (!snapshot.hasData) {
              return const SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: 400,
                  child: Center(child: CircularProgressIndicator(color: AppColors.gold)),
                ),
              );
            }
            final user = snapshot.data![0] as Map<String, dynamic>;
            final courses = user['purchasedCourses'] as List<dynamic>? ?? [];
            final progress = snapshot.data![1] as List<dynamic>;
            if (courses.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('No courses yet', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      GoldButton(label: 'Browse Courses', onPressed: () => context.go('/home')),
                    ],
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: courses.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final c = courses[i];
                final rows = progress.where((p) => p['course']?['_id'] == c['_id']).toList();
                final completed = rows.where((p) => p['isCompleted'] == true).length;
                final total = c['totalVideos'] == 0 ? rows.length : c['totalVideos'];
                final percent = total == 0 ? 0.0 : completed / total;
                final expired = c['isExpired'] == true;
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(children: [
                    Container(
                      width: 76, height: 76,
                      decoration: BoxDecoration(color: AppColors.secondaryBg, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.school, color: AppColors.gold),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(c['title'], style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      LinearPercentIndicator(
                        lineHeight: 6,
                        padding: EdgeInsets.zero,
                        percent: percent.clamp(0, 1),
                        progressColor: AppColors.gold,
                        backgroundColor: AppColors.border,
                      ),
                      const SizedBox(height: 6),
                      Text('$completed of $total videos', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(_validityLabel(c), style: TextStyle(color: expired ? AppColors.error : AppColors.muted, fontSize: 12, fontWeight: expired ? FontWeight.w800 : FontWeight.w500)),
                    ])),
                    TextButton(
                      onPressed: () => context.push('/course/${c['_id']}'),
                      child: Text(expired ? 'Repurchase' : 'Continue'),
                    ),
                  ]),
                );
              },
            );
          },
        ),
      ),
    );
  }

  String _validityLabel(dynamic course) {
    if (course['isExpired'] == true) return 'Course Expired';
    final days = course['daysRemaining'];
    if (days is num) return '$days Days Remaining';
    final expiry = course['expiryDate'];
    if (expiry != null) return 'Expiry Date: ${expiry.toString().split('T').first}';
    return 'Lifetime Access';
  }
}
