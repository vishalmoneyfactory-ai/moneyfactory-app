import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

import '../../../core/api/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/gold_button.dart';

class MyCoursesScreen extends StatefulWidget {
  const MyCoursesScreen({super.key});

  @override
  State<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends State<MyCoursesScreen> {
  late Future<List<dynamic>> _future;
  final Set<String> _favorites = {};
  bool _showFavoritesOnly = false;
  bool _unlocking = false;
  int _sectionIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = Future.wait([api.courses(), api.bundle(), api.me(), api.progressAll()]);
  }

  Future<void> _refresh() async {
    setState(_load);
    await _future;
  }

  Future<void> _unlock(BuildContext context, String courseId) async {
    if (_unlocking) return;
    setState(() => _unlocking = true);
    try {
      await api.unlockFreeCourse(courseId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Course unlocked for 30 days'), backgroundColor: AppColors.success));
      await _refresh();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _unlocking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Courses'),
        actions: [
          IconButton(
            onPressed: () => setState(() => _showFavoritesOnly = !_showFavoritesOnly),
            icon: Icon(_showFavoritesOnly ? Icons.favorite : Icons.favorite_border),
            color: _showFavoritesOnly ? AppColors.error : AppColors.themeGold(context),
            tooltip: 'Favorite courses',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.pageGradient(context)),
        child: RefreshIndicator(
          color: AppColors.themeGold(context),
          onRefresh: _refresh,
          child: FutureBuilder<List<dynamic>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Center(child: Text(snapshot.error.toString(), textAlign: TextAlign.center)),
                  ),
                );
              }
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator(color: AppColors.themeGold(context)));
              }

              final courses = (snapshot.data![0] as List<dynamic>).where((c) => c['isBundle'] != true).toList();
              final bundleData = snapshot.data![1] as Map<String, dynamic>;
              final user = snapshot.data![2] as Map<String, dynamic>;
              final progress = snapshot.data![3] as List<dynamic>;
              final bundle = bundleData['bundle'];
              final visibleCourses = _showFavoritesOnly
                  ? courses.where((course) => _favorites.contains(course['_id'].toString())).toList()
                  : courses;
              final unlocked = (user['purchasedCourses'] as List<dynamic>? ?? []);
              final totalVideos = courses.fold<num>(0, (sum, course) => sum + _asNum(course['totalVideos']));

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                children: [
                  _counterRow(courses.length + (bundle == null ? 0 : 1), totalVideos, unlocked.where((c) => c['isExpired'] != true).length),
                  const SizedBox(height: 16),
                  _segmentedHeader(),
                  const SizedBox(height: 16),
                  if (_sectionIndex == 0) ...[
                    _sectionHeader('Courses', _showFavoritesOnly ? 'Favorite sorted courses' : 'All programs and bundle'),
                    const SizedBox(height: 10),
                    if (_showFavoritesOnly && visibleCourses.isEmpty)
                      _emptyBox('No favorite courses selected yet')
                    else ...[
                      ...visibleCourses.map((course) => _courseCard(context, course)),
                      if (!_showFavoritesOnly) _bundleCard(context, bundleData),
                    ],
                  ] else ...[
                    _sectionHeader('My learning', 'Unlocked courses with validity'),
                    const SizedBox(height: 10),
                    if (unlocked.isEmpty)
                      _emptyBox('No unlocked courses yet')
                    else
                      ...unlocked.map((course) => _learningCard(context, course, progress)),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _segmentedHeader() => Container(
    padding: const EdgeInsets.all(5),
    decoration: BoxDecoration(
      color: AppColors.card(context).withValues(alpha: .82),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.line(context)),
      boxShadow: [BoxShadow(color: AppColors.neonBlue.withValues(alpha: .08), blurRadius: 18, offset: const Offset(0, 8))],
    ),
    child: Row(children: [
      _segmentButton(0, 'Courses', Icons.auto_stories_outlined),
      _segmentButton(1, 'My Learning', Icons.play_circle_outline),
    ]),
  );

  Widget _segmentButton(int index, String label, IconData icon) {
    final active = _sectionIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _sectionIndex = index),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 46,
          decoration: BoxDecoration(
            gradient: active ? AppColors.accentGradient(context) : null,
            color: active ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: active ? [BoxShadow(color: AppColors.neonBlue.withValues(alpha: .20), blurRadius: 14)] : null,
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 18, color: active ? AppColors.white : AppColors.mutedText(context)),
            const SizedBox(width: 7),
            Text(label, style: TextStyle(color: active ? AppColors.white : AppColors.mutedText(context), fontWeight: FontWeight.w900)),
          ]),
        ),
      ),
    );
  }

  Widget _counterRow(int courses, num videos, int unlocked) => Row(children: [
    _counter('Courses', '$courses'),
    _counter('Videos', '$videos'),
    _counter('Unlocked', '$unlocked'),
  ]);

  Widget _counter(String label, String value) => Expanded(
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.card(context).withValues(alpha: .92),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line(context)),
        boxShadow: [BoxShadow(color: AppColors.themeGold(context).withValues(alpha: .06), blurRadius: 14, offset: const Offset(0, 8))],
      ),
      child: Column(children: [
        Text(value, style: TextStyle(color: AppColors.themeGold(context), fontFamily: 'JetBrains Mono', fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 3),
        Text(label, style: TextStyle(color: AppColors.mutedText(context), fontSize: 12)),
      ]),
    ),
  );

  Widget _courseCard(BuildContext context, dynamic course) {
    final id = course['_id'].toString();
    final isFree = course['isFree'] == true;
    final owned = course['isOwned'] == true;
    final expired = course['access']?['isExpired'] == true;
    final thumbnail = api.mediaUrl(course['thumbnail'] as String?);
    final label = owned ? 'Continue' : isFree ? 'Unlock' : expired ? 'Repurchase' : 'Buy Now';
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(color: AppColors.card(context).withValues(alpha: .94), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.line(context)), boxShadow: [BoxShadow(color: AppColors.neonBlue.withValues(alpha: .07), blurRadius: 18, offset: const Offset(0, 8))]),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          height: 158,
          width: double.infinity,
          child: Stack(fit: StackFit.expand, children: [
            _courseImage(thumbnail),
            Positioned(left: 12, top: 12, child: _pill(isFree ? 'FREE' : _priceText(course), isFree ? AppColors.success : AppColors.themeGold(context))),
            Positioned(right: 12, top: 12, child: IconButton.filledTonal(
              onPressed: () => setState(() => _favorites.contains(id) ? _favorites.remove(id) : _favorites.add(id)),
              icon: Icon(_favorites.contains(id) ? Icons.favorite : Icons.favorite_border, color: _favorites.contains(id) ? AppColors.error : AppColors.themeGold(context)),
            )),
            if (owned) Positioned(left: 12, bottom: 12, child: _pill('UNLOCKED', AppColors.success)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(course['title'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.text(context), fontSize: 19, fontWeight: FontWeight.w900)),
            const SizedBox(height: 7),
            Text(course['shortDescription'] ?? '', maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.mutedText(context), height: 1.35)),
            const SizedBox(height: 10),
            _priceRow(course),
            const SizedBox(height: 10),
            Text(_validityLabel(course['access']), style: TextStyle(color: expired ? AppColors.error : AppColors.mutedText(context), fontSize: 12, fontWeight: expired ? FontWeight.w800 : FontWeight.w500)),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _miniMetric(Icons.video_library_outlined, '${course['totalVideos'] ?? 0} lessons'),
              _miniMetric(Icons.schedule, durationLabel(course['totalDuration'] ?? 0)),
              _miniMetric(Icons.trending_up, course['category'] ?? 'Trading'),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: GoldButton(
                  label: _unlocking && isFree && !owned ? 'Unlocking...' : label,
                  icon: owned ? Icons.play_arrow : isFree ? Icons.lock_open : Icons.shopping_bag_outlined,
                  color: owned ? AppColors.success : null,
                  onPressed: _unlocking ? null : () => owned ? context.push('/course/$id') : isFree ? _unlock(context, id) : context.push('/checkout/$id'),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(height: 52, child: OutlinedButton(onPressed: () => context.push('/course/$id'), child: const Text('Explore'))),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _bundleCard(BuildContext context, Map<String, dynamic> data) {
    final bundle = data['bundle'];
    final courses = data['courses'] as List<dynamic>? ?? [];
    if (bundle == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.themeGold(context), width: 1.4),
        boxShadow: [BoxShadow(color: AppColors.themeGold(context).withValues(alpha: .08), blurRadius: 18)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Complete Trading Mastery Bundle', style: TextStyle(color: AppColors.themeGold(context), fontSize: 21, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text('All ${courses.length} courses, one unlock, discounted for the full roadmap.', style: TextStyle(color: AppColors.mutedText(context), height: 1.4)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: courses.take(6).map((course) => _pill(course['title'] ?? '', AppColors.themeGold(context))).toList()),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: Text(money(data['bundlePrice'] ?? bundle['price'] ?? 4999), style: TextStyle(color: AppColors.themeGold(context), fontFamily: 'JetBrains Mono', fontSize: 28, fontWeight: FontWeight.w900))),
          _pill('Save ${money(data['savings'] ?? 0)}', AppColors.success),
        ]),
        const SizedBox(height: 12),
        GoldButton(label: 'Get Bundle Deal', icon: Icons.workspace_premium, onPressed: () => context.push('/checkout/${bundle['_id']}?bundle=true')),
      ]),
    );
  }

  Widget _learningCard(BuildContext context, dynamic course, List<dynamic> progress) {
    final rows = progress.where((p) => p['course']?['_id'] == course['_id']).toList();
    final completed = rows.where((p) => p['isCompleted'] == true).length;
    final total = course['totalVideos'] == 0 ? rows.length : course['totalVideos'];
    final percent = total == 0 ? 0.0 : completed / total;
    final expired = course['isExpired'] == true;
    final thumbnail = api.mediaUrl(course['thumbnail'] as String?);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.card(context).withValues(alpha: .94), borderRadius: BorderRadius.circular(8), border: Border.all(color: expired ? AppColors.error.withValues(alpha: .45) : AppColors.line(context)), boxShadow: [BoxShadow(color: expired ? AppColors.error.withValues(alpha: .08) : AppColors.themeGold(context).withValues(alpha: .05), blurRadius: 14, offset: const Offset(0, 8))]),
      child: Row(children: [
        Container(
          width: 76,
          height: 76,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(color: AppColors.surface(context), borderRadius: BorderRadius.circular(8)),
          child: _courseImage(thumbnail),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(course['title'], maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          LinearPercentIndicator(lineHeight: 6, padding: EdgeInsets.zero, percent: percent.clamp(0, 1).toDouble(), progressColor: AppColors.themeGold(context), backgroundColor: AppColors.line(context)),
          const SizedBox(height: 6),
          Text('$completed of $total videos', style: TextStyle(color: AppColors.mutedText(context), fontSize: 12)),
          const SizedBox(height: 4),
          Text(_courseValidityLabel(course), style: TextStyle(color: expired ? AppColors.error : AppColors.mutedText(context), fontSize: 12, fontWeight: expired ? FontWeight.w800 : FontWeight.w500)),
        ])),
        TextButton(onPressed: () => context.push('/course/${course['_id']}'), child: Text(expired ? 'Repurchase' : 'Continue')),
      ]),
    );
  }

  Widget _sectionHeader(String title, String subtitle) => Row(children: [
    Expanded(child: Text(title, style: TextStyle(color: AppColors.text(context), fontSize: 22, fontWeight: FontWeight.w900))),
    Text(subtitle, style: TextStyle(color: AppColors.mutedText(context), fontSize: 12, fontWeight: FontWeight.w700)),
  ]);

  Widget _emptyBox(String text) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: AppColors.card(context), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.line(context))),
    child: Text(text, style: TextStyle(color: AppColors.mutedText(context))),
  );

  Widget _courseImage(String url) {
    if (url.isEmpty) {
      return ColoredBox(color: AppColors.surface(context), child: Center(child: Icon(Icons.show_chart, color: AppColors.themeGold(context), size: 42)));
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      width: double.infinity,
      errorWidget: (_, _, _) => ColoredBox(color: AppColors.surface(context), child: Center(child: Icon(Icons.show_chart, color: AppColors.themeGold(context), size: 42))),
    );
  }

  Widget _miniMetric(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
    decoration: BoxDecoration(color: AppColors.surface(context), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.line(context))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 15, color: AppColors.themeGold(context)),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(fontSize: 12, color: AppColors.mutedText(context), fontWeight: FontWeight.w700)),
    ]),
  );

  Widget _pill(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(color: color.withValues(alpha: .16), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withValues(alpha: .4))),
    child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900)),
  );

  Widget _priceRow(dynamic course) {
    if (course['isFree'] == true) return const Text('FREE', style: TextStyle(color: AppColors.success, fontFamily: 'JetBrains Mono', fontSize: 20, fontWeight: FontWeight.w900));
    if (course['hasOffer'] != true) return Text(money(course['price'] ?? 0), style: TextStyle(color: AppColors.themeGold(context), fontFamily: 'JetBrains Mono', fontSize: 20, fontWeight: FontWeight.w900));
    return Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 4, children: [
      Text(money(course['originalPrice'] ?? course['price'] ?? 0), style: TextStyle(color: AppColors.mutedText(context), fontFamily: 'JetBrains Mono', decoration: TextDecoration.lineThrough, fontSize: 14, fontWeight: FontWeight.w700)),
      Text(money(course['effectivePrice'] ?? course['price'] ?? 0), style: TextStyle(color: AppColors.themeGold(context), fontFamily: 'JetBrains Mono', fontSize: 22, fontWeight: FontWeight.w900)),
      _pill('${course['offerPercent'] ?? 0}% OFF', AppColors.success),
    ]);
  }

  String _priceText(dynamic course) => money(course['effectivePrice'] ?? course['price'] ?? 0);

  String _validityLabel(dynamic access) {
    if (access == null || access['isOwned'] != true) return '30 days validity after purchase';
    if (access['isExpired'] == true) return 'Course Expired - Repurchase Required.';
    final days = access['daysRemaining'];
    if (days is num) return '$days days left';
    return '30 days validity active';
  }

  String _courseValidityLabel(dynamic course) {
    if (course['isExpired'] == true) return 'Course Expired - Repurchase Required.';
    final days = course['daysRemaining'];
    if (days is num) return '$days days left';
    return '30 days validity active';
  }

  num _asNum(dynamic value) => value is num ? value : num.tryParse(value?.toString() ?? '') ?? 0;
}
