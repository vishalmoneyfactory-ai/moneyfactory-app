import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

import '../../../core/api/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/gold_button.dart';
import '../../../shared/widgets/motion.dart';

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
    _future = Future.wait([
      api.courses(),
      api.bundle(),
      api.me(),
      api.progressAll(),
    ]);
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Course unlocked for 30 days'),
          backgroundColor: AppColors.success,
        ),
      );
      await _refresh();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(parseError(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _unlocking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  padding: const EdgeInsets.fromLTRB(20, 130, 20, 30),
                  child: Center(
                    child: Text(
                      parseError(snapshot.error!),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              if (!snapshot.hasData) {
                return CustomScrollView(
                  slivers: [
                    _floatingAppBar(),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(20, 28, 20, 30),
                      sliver: SliverList.list(
                        children: [
                          ShimmerLine(height: 120, radius: 24),
                          SizedBox(height: 22),
                          ShimmerLine(width: 220, height: 34),
                          SizedBox(height: 20),
                          ShimmerLine(height: 260, radius: 24),
                          SizedBox(height: 18),
                          ShimmerLine(height: 260, radius: 24),
                        ],
                      ),
                    ),
                  ],
                );
              }

              final courses = (snapshot.data![0] as List<dynamic>)
                  .where((c) => c['isBundle'] != true)
                  .toList();
              final bundleData = snapshot.data![1] as Map<String, dynamic>;
              final user = snapshot.data![2] as Map<String, dynamic>;
              final progress = snapshot.data![3] as List<dynamic>;
              final bundle = bundleData['bundle'];
              final visibleCourses = _showFavoritesOnly
                  ? courses
                        .where(
                          (course) =>
                              _favorites.contains(course['_id'].toString()),
                        )
                        .toList()
                  : courses;
              final unlocked =
                  (user['purchasedCourses'] as List<dynamic>? ?? []);
              final totalVideos = courses.fold<num>(
                0,
                (sum, course) => sum + _asNum(course['totalVideos']),
              );

              return CustomScrollView(
                slivers: [
                  _floatingAppBar(),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                    sliver: SliverList.list(
                      children: [
                        FadeSlideIn(
                          child: _pageHero(
                            courses.length + (bundle == null ? 0 : 1),
                            totalVideos,
                            unlocked
                                .where((c) => c['isExpired'] != true)
                                .length,
                          ),
                        ),
                        const SizedBox(height: 26),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 90),
                          child: _segmentedHeader(),
                        ),
                        const SizedBox(height: 26),
                        if (_sectionIndex == 0)
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 130),
                            child: _courseDiscovery(
                              context,
                              visibleCourses,
                              bundleData,
                            ),
                          )
                        else
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 130),
                            child: _learningList(context, unlocked, progress),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  SliverAppBar _floatingAppBar() {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: AppColors.isDark(context) 
          ? AppColors.bg(context).withValues(alpha: .86)
          : AppColors.card(context),
      surfaceTintColor: Colors.transparent,
      title: Text(
        'Courses',
        style: TextStyle(
          color: AppColors.text(context),
          fontWeight: FontWeight.w900,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => setState(() {
            _showFavoritesOnly = !_showFavoritesOnly;
            _sectionIndex = 0;
          }),
          icon: Icon(
            _showFavoritesOnly ? Icons.favorite : Icons.favorite_border,
          ),
          color: _showFavoritesOnly
              ? AppColors.error
              : AppColors.themeGold(context),
          tooltip: 'Favorite courses',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _pageHero(int courses, num videos, int unlocked) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _metric('Courses', courses),
            _metric('Videos', videos),
            _metric('Unlocked', unlocked),
          ],
        ),
      ],
    );
  }

  Widget _metric(String label, num value) => Expanded(
    child: Padding(
      padding: const EdgeInsets.only(right: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CountUpNumber(
            value: value,
            style: TextStyle(
              color: AppColors.themeGold(context),
              fontFamily: 'JetBrains Mono',
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: AppColors.mutedText(context),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _segmentedHeader() {
    return Container(
      height: 54,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface(context).withValues(alpha: .56),
        borderRadius: BorderRadius.circular(99),
        boxShadow: [
          BoxShadow(
            color: AppColors.neonBlue.withValues(alpha: .09),
            blurRadius: 20,
          ),
        ],
      ),
      child: Row(
        children: [
          _segmentButton(0, 'Courses', Icons.auto_stories_outlined),
          _segmentButton(1, 'My Learning', Icons.play_circle_outline),
        ],
      ),
    );
  }

  Widget _segmentButton(int index, String label, IconData icon) {
    final active = _sectionIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _sectionIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            gradient: active ? AppColors.accentGradient(context) : null,
            borderRadius: BorderRadius.circular(99),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.neonBlue.withValues(alpha: .22),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: active ? AppColors.white : AppColors.mutedText(context),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: active
                      ? AppColors.white
                      : AppColors.mutedText(context),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _courseDiscovery(
    BuildContext context,
    List<dynamic> courses,
    Map<String, dynamic> bundleData,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          _showFavoritesOnly ? 'Favorite sorted courses' : 'Courses',
          _showFavoritesOnly
              ? 'Your selected watchlist'
              : 'Programs and bundle',
        ),
        const SizedBox(height: 18),
        if (_showFavoritesOnly && courses.isEmpty)
          _emptyState('No favorite courses selected yet.')
        else ...[
          ...courses.indexed.map(
            (entry) => _courseBand(context, entry.$2, entry.$1),
          ),
          if (!_showFavoritesOnly) _bundleBand(context, bundleData),
        ],
      ],
    );
  }

  Widget _courseBand(BuildContext context, dynamic course, int index) {
    final id = course['_id'].toString();
    final isFree = course['isFree'] == true;
    final owned = course['isOwned'] == true;
    final expired = course['access']?['isExpired'] == true;
    final thumbnail = api.mediaUrl(course['thumbnail'] as String?);
    final label = owned
        ? 'Continue'
        : isFree
        ? 'Unlock'
        : expired
        ? 'Repurchase'
        : 'Buy Now';

    return Padding(
      padding: const EdgeInsets.only(bottom: 34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => context.push('/course/$id'),
            borderRadius: BorderRadius.circular(28),
            child: SizedBox(
              height: 220,
              child: Stack(
                children: [
                  Positioned.fill(child: _courseImage(thumbnail)),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: .72),
                            Colors.black.withValues(alpha: .18),
                            Colors.transparent,
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 18,
                    right: 18,
                    bottom: 18,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '0${index + 1}',
                          style: TextStyle(
                            color: AppColors.themeGold(context),
                            fontFamily: 'JetBrains Mono',
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          course['title'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 27,
                            height: 1.04,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            course['shortDescription'] ?? '',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppColors.mutedText(context), height: 1.45),
          ),
          const SizedBox(height: 14),
          _priceDisplay(course),
          const SizedBox(height: 14),
          Wrap(
            spacing: 18,
            runSpacing: 8,
            children: [
              _inlineMeta(
                '${course['totalVideos'] ?? 0} lessons',
                AppColors.neonBlue,
              ),
              _inlineMeta(
                durationLabel(course['totalDuration'] ?? 0),
                AppColors.violet,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  _validityLabel(course['access']),
                  style: TextStyle(
                    color: expired
                        ? AppColors.error
                        : AppColors.mutedText(context),
                    fontWeight: expired ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(
                height: 36,
                child: OutlinedButton.icon(
                  onPressed: () => setState(
                    () => _favorites.contains(id)
                        ? _favorites.remove(id)
                        : _favorites.add(id),
                  ),
                  icon: Icon(
                    _favorites.contains(id)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: _favorites.contains(id)
                        ? AppColors.error
                        : AppColors.themeGold(context),
                    size: 18,
                  ),
                  label: Text(
                    _favorites.contains(id) ? 'Saved' : 'Save',
                    style: TextStyle(
                      color: AppColors.text(context),
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.line(context)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GoldButton(
                  label: _unlocking && isFree && !owned
                      ? 'Unlocking...'
                      : label,
                  icon: owned
                      ? Icons.play_arrow
                      : isFree
                      ? Icons.lock_open
                      : Icons.shopping_bag_outlined,
                  color: owned ? AppColors.success : null,
                  onPressed: _unlocking
                      ? null
                      : () => owned
                            ? context.push('/course/$id')
                            : isFree
                            ? _unlock(context, id)
                            : context.push('/checkout/$id'),
                ),
              ),
              const SizedBox(width: 12),
              TextButton.icon(
                onPressed: () => context.push('/course/$id'),
                icon: const Icon(Icons.north_east),
                label: const Text('Explore'),
              ),
            ],
          ),
          _softDivider(),
        ],
      ),
    );
  }

  Widget _bundleBand(BuildContext context, Map<String, dynamic> data) {
    final bundle = data['bundle'];
    final courses = data['courses'] as List<dynamic>? ?? [];
    if (bundle == null) return const SizedBox.shrink();
    final thumbnail = api.mediaUrl(bundle['thumbnail'] as String?);
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            AppColors.themeGold(context).withValues(alpha: .15),
            AppColors.neonBlue.withValues(alpha: .05),
            AppColors.card(context),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.themeGold(context).withValues(alpha: .08),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
        border: Border.all(
          color: AppColors.themeGold(context).withValues(alpha: .3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.themeGold(context).withValues(alpha: .2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.stars_rounded,
                  color: AppColors.gold,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'BUNDLE DEAL',
                style: TextStyle(
                  color: AppColors.themeGold(context),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (thumbnail.isNotEmpty) ...[
            SizedBox(
              height: 190,
              width: double.infinity,
              child: _courseImage(thumbnail, radius: 24),
            ),
            const SizedBox(height: 20),
          ],
          Text(
            bundle['title'] ?? 'Complete Trading Mastery Bundle',
            style: TextStyle(
              color: AppColors.text(context),
              fontSize: 30,
              height: 1.1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'All ${courses.length} courses, one unlock, discounted for the full roadmap.',
            style: TextStyle(color: AppColors.mutedText(context), height: 1.5),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: courses
                .take(6)
                .map((course) => _chip(course['title'] ?? ''))
                .toList(),
          ),
          const SizedBox(height: 24),
          _priceDisplay(bundle, large: true),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: GoldButton(
              label: 'Get Bundle Deal',
              icon: Icons.workspace_premium,
              onPressed: () =>
                  context.push('/checkout/${bundle['_id']}?bundle=true'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _learningList(
    BuildContext context,
    List<dynamic> unlocked,
    List<dynamic> progress,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('My Learning', '30-day active windows'),
        const SizedBox(height: 18),
        if (unlocked.isEmpty)
          _emptyState('No unlocked courses yet.')
        else
          ...unlocked.indexed.map(
            (entry) => _learningRow(context, entry.$2, progress, entry.$1),
          ),
      ],
    );
  }

  Widget _learningRow(
    BuildContext context,
    dynamic course,
    List<dynamic> progress,
    int index,
  ) {
    final rows = progress
        .where((p) => p['course']?['_id'] == course['_id'])
        .toList();
    final completed = rows.where((p) => p['isCompleted'] == true).length;
    final total = course['totalVideos'] == 0
        ? rows.length
        : course['totalVideos'];
        
    double watchedSeconds = 0;
    for (var p in rows) {
      watchedSeconds += (p['watchedSeconds'] ?? 0);
    }
    final num totalSeconds = course['totalDuration'] ?? 0;
    
    double percent = 0.0;
    if (totalSeconds > 0) {
      percent = watchedSeconds / totalSeconds;
    } else {
      if (total > 0) percent = completed / total;
    }
    if (completed >= total && total > 0) percent = 1.0;
    final expired = course['isExpired'] == true;
    final thumbnail = api.mediaUrl(course['thumbnail'] as String?);
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () => context.push('/course/${course['_id']}'),
                borderRadius: BorderRadius.circular(22),
                child: SizedBox(
                  width: 112,
                  height: 112,
                  child: _courseImage(thumbnail, radius: 22),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '0${index + 1}',
                      style: TextStyle(
                        color: AppColors.themeGold(context),
                        fontFamily: 'JetBrains Mono',
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      course['title'],
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.text(context),
                        fontSize: 22,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _courseValidityLabel(course),
                      style: TextStyle(
                        color: expired
                            ? AppColors.error
                            : AppColors.mutedText(context),
                        fontWeight: expired ? FontWeight.w900 : FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LinearPercentIndicator(
            lineHeight: 7,
            padding: EdgeInsets.zero,
            barRadius: const Radius.circular(99),
            percent: percent.clamp(0, 1).toDouble(),
            progressColor: percent >= 1.0 ? AppColors.success : AppColors.themeGold(context),
            backgroundColor: AppColors.line(context).withValues(alpha: .55),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  '$completed of $total videos completed',
                  style: TextStyle(
                    color: AppColors.mutedText(context),
                    fontSize: 13,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.push('/course/${course['_id']}'),
                child: Text(expired ? 'Repurchase' : 'Continue'),
              ),
            ],
          ),
          _softDivider(),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, String subtitle) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        subtitle.toUpperCase(),
        style: TextStyle(
          color: AppColors.themeGold(context),
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.4,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        title,
        style: TextStyle(
          color: AppColors.text(context),
          fontSize: 32,
          height: 1.02,
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );

  Widget _emptyState(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 34),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.auto_awesome, color: AppColors.themeGold(context), size: 34),
        const SizedBox(height: 12),
        Text(
          text,
          style: TextStyle(color: AppColors.mutedText(context), fontSize: 16),
        ),
      ],
    ),
  );

  Widget _courseImage(String url, {double radius = 28}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: url.isEmpty
          ? ColoredBox(
              color: AppColors.surface(context),
              child: Center(
                child: Icon(
                  Icons.show_chart,
                  color: AppColors.themeGold(context),
                  size: 42,
                ),
              ),
            )
          : CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.contain,
              width: double.infinity,
              errorWidget: (_, _, _) => ColoredBox(
                color: AppColors.surface(context),
                child: Center(
                  child: Icon(
                    Icons.show_chart,
                    color: AppColors.themeGold(context),
                    size: 42,
                  ),
                ),
              ),
            ),
    );
  }

  Widget _inlineMeta(String label, Color color) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 7),
      Text(
        label,
        style: TextStyle(
          color: AppColors.text(context),
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );

  Widget _priceDisplay(dynamic course, {bool large = false}) {
    if (course['isFree'] == true) {
      return Text(
        'FREE',
        style: TextStyle(
          color: AppColors.success,
          fontFamily: 'JetBrains Mono',
          fontSize: large ? 34 : 24,
          fontWeight: FontWeight.w900,
        ),
      );
    }

    final original = _asNum(course['originalPrice'] ?? course['price']);
    final effective = _asNum(
      course['effectivePrice'] ??
          course['bundlePrice'] ??
          course['price'] ??
          original,
    );
    final discount = _asNum(course['offerDiscount'] ?? (original - effective));
    final percent = _asNum(
      course['offerPercent'] ?? _percentOff(discount, original),
    );
    final hasOffer = course['hasOffer'] == true && discount > 0;

    if (!hasOffer) {
      return Text(
        money(effective),
        style: TextStyle(
          color: AppColors.themeGold(context),
          fontFamily: 'JetBrains Mono',
          fontSize: large ? 34 : 24,
          fontWeight: FontWeight.w900,
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          money(effective),
          style: TextStyle(
            color: AppColors.themeGold(context),
            fontFamily: 'JetBrains Mono',
            fontSize: large ? 34 : 25,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          money(original),
          style: TextStyle(
            color: AppColors.mutedText(context),
            fontFamily: 'JetBrains Mono',
            decoration: TextDecoration.lineThrough,
            decorationColor: AppColors.mutedText(context),
            fontSize: large ? 16 : 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: .15),
            borderRadius: BorderRadius.circular(99),
            boxShadow: [
              BoxShadow(
                color: AppColors.success.withValues(alpha: .10),
                blurRadius: 18,
              ),
            ],
          ),
          child: Text(
            '${percent.round()}% OFF',
            style: const TextStyle(
              color: AppColors.success,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _chip(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: AppColors.surface(context).withValues(alpha: .58),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: AppColors.mutedText(context),
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
    ),
  );

  Widget _softDivider() => Padding(
    padding: const EdgeInsets.only(top: 22),
    child: Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            AppColors.line(context),
            Colors.transparent,
          ],
        ),
      ),
    ),
  );

  String _validityLabel(dynamic access) {
    if (access == null || access['isOwned'] != true) {
      return '30 days validity after purchase';
    }
    if (access['isExpired'] == true) {
      return 'Course Expired - Repurchase Required.';
    }
    final days = access['daysRemaining'];
    if (days is num) {
      return '$days days left';
    }
    return '30 days validity active';
  }

  String _courseValidityLabel(dynamic course) {
    if (course['isExpired'] == true) {
      return 'Course Expired - Repurchase Required.';
    }
    final days = course['daysRemaining'];
    if (days is num) {
      return '$days days left';
    }
    return '30 days validity active';
  }

  num _asNum(dynamic value) =>
      value is num ? value : num.tryParse(value?.toString() ?? '') ?? 0;

  int _percentOff(dynamic discount, dynamic original) {
    final base = _asNum(original);
    if (base <= 0) return 0;
    return ((_asNum(discount) / base) * 100).round().clamp(0, 99);
  }
}
