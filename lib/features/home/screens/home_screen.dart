import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/gold_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<dynamic>> _future;
  final Set<String> _favorites = {};
  bool _unlocking = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<dynamic>> _load() =>
      Future.wait([api.courses(), api.bundle(), api.settings(), api.banners()]);

  Future<void> _refresh() async {
    setState(() => _future = _load());
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
          content: Text('Course unlocked'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/learning');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _unlocking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(context),
      body: RefreshIndicator(
        color: AppColors.gold,
        onRefresh: _refresh,
        child: FutureBuilder<List<dynamic>>(
          future: _future,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.gold),
              );
            }
            final courses = (snapshot.data![0] as List<dynamic>)
                .where((c) => c['isBundle'] != true)
                .toList();
            final bundle = snapshot.data![1] as Map<String, dynamic>;
            final settings = snapshot.data![2] as Map<String, dynamic>;
            final banners = snapshot.data![3] as List<dynamic>;
            final ownedCount = courses
                .where((c) => c['isOwned'] == true)
                .length;
            final freeCourse = courses
                .where((c) => c['isFree'] == true)
                .firstOrNull;
            final totalVideos = courses.fold<num>(
              0,
              (sum, c) => sum + _num(c['totalVideos']),
            );
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              children: [
                _hero(context, courses, ownedCount, totalVideos),
                const SizedBox(height: 14),
                _quickActions(context, freeCourse),
                const SizedBox(height: 22),
                _sectionHeader('Courses', '${courses.length} programs'),
                const SizedBox(height: 10),
                ...courses.map((course) => _courseCard(context, course)),
                const SizedBox(height: 12),
                _bundleCard(context, bundle),
                const SizedBox(height: 22),
                _featureGrid(),
                if (banners.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  _sectionHeader('Highlights', 'Admin updates'),
                  const SizedBox(height: 10),
                  ...banners
                      .take(3)
                      .map((banner) => _highlightTile(context, banner)),
                ],
                const SizedBox(height: 22),
                _about(settings),
              ],
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _appBar(BuildContext context) {
    return AppBar(
      toolbarHeight: 74,
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.candlestick_chart,
              color: AppColors.primaryBg,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MONEY FACTORY',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Trading command center',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: _openSearch,
          icon: const Icon(Icons.search, color: AppColors.white, size: 30),
          tooltip: 'Search courses',
        ),
        const SizedBox(width: 4),
        IconButton(
          onPressed: _openFavorites,
          icon: const Icon(Icons.favorite, color: AppColors.white, size: 29),
          tooltip: 'Favorites',
        ),
        const SizedBox(width: 10),
      ],
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.secondaryBg,
              AppColors.primaryBg,
              AppColors.goldGlow.withValues(alpha: .16),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: const Border(bottom: BorderSide(color: AppColors.border)),
        ),
      ),
    );
  }

  Widget _hero(
    BuildContext context,
    List<dynamic> courses,
    int ownedCount,
    num totalVideos,
  ) {
    final thumbnail = courses.isEmpty
        ? ''
        : api.mediaUrl(courses.first['thumbnail'] as String?);
    return SizedBox(
      height: 286,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.goldGlow),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (thumbnail.isNotEmpty)
              CachedNetworkImage(
                imageUrl: thumbnail,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => const SizedBox.shrink(),
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryBg.withValues(alpha: .92),
                    AppColors.secondaryBg.withValues(alpha: .76),
                    AppColors.primaryBg.withValues(alpha: .36),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.goldGlow,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.goldGlow),
                    ),
                    child: const Text(
                      'Structured Forex Education',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Learn the market like a complete system.',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Courses, progress, secure video access, and the full Money Factory roadmap in one place.',
                    style: TextStyle(color: AppColors.muted, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _heroStat('${courses.length}', 'Courses'),
                      _heroStat('$totalVideos', 'Videos'),
                      _heroStat('$ownedCount', 'Unlocked'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickActions(BuildContext context, dynamic freeCourse) {
    return Row(
      children: [
        Expanded(
          child: GoldButton(
            label: 'My Learning',
            icon: Icons.play_lesson,
            onPressed: () => context.go('/learning'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: freeCourse == null
                  ? null
                  : () => freeCourse['isOwned'] == true
                        ? context.push('/course/${freeCourse['_id']}')
                        : _unlock(context, freeCourse['_id']),
              icon: Icon(
                freeCourse?['isOwned'] == true ? Icons.school : Icons.lock_open,
              ),
              label: Text(
                freeCourse?['isOwned'] == true ? 'Open Free' : 'Unlock Free',
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _courseCard(BuildContext context, dynamic course) {
    final id = course['_id'].toString();
    final isFree = course['isFree'] == true;
    final owned = course['isOwned'] == true;
    final thumbnail = api.mediaUrl(course['thumbnail'] as String?);
    final primaryLabel = owned
        ? 'Continue'
        : isFree
        ? 'Unlock'
        : 'Buy Now';
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 158,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _courseImage(thumbnail),
                Positioned(
                  left: 12,
                  top: 12,
                  child: _pill(
                    isFree ? 'FREE' : _priceText(course),
                    isFree ? AppColors.success : AppColors.gold,
                  ),
                ),
                if (owned)
                  Positioned(
                    right: 12,
                    top: 12,
                    child: _pill('UNLOCKED', AppColors.success),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course['title'] ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  course['shortDescription'] ?? '',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, height: 1.35),
                ),
                const SizedBox(height: 10),
                _priceRow(course),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _miniMetric(
                      Icons.video_library_outlined,
                      '${course['totalVideos'] ?? 0} lessons',
                    ),
                    _miniMetric(
                      Icons.schedule,
                      durationLabel(course['totalDuration'] ?? 0),
                    ),
                    _miniMetric(
                      Icons.trending_up,
                      course['category'] ?? 'Trading',
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: GoldButton(
                        label: _unlocking && isFree && !owned
                            ? 'Unlocking...'
                            : primaryLabel,
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
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () => context.push('/course/$id'),
                        child: const Text('Explore'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 52,
                      height: 52,
                      child: IconButton.outlined(
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
                              : AppColors.gold,
                        ),
                        tooltip: 'Favorite',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bundleCard(BuildContext context, Map<String, dynamic> data) {
    final bundle = data['bundle'];
    final courses = data['courses'] as List<dynamic>? ?? [];
    if (bundle == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondaryBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gold, width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Complete Trading Mastery Bundle',
            style: TextStyle(
              color: AppColors.gold,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All ${courses.length} courses, one unlock, discounted for the full roadmap.',
            style: const TextStyle(color: AppColors.muted, height: 1.4),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: courses
                .take(6)
                .map((course) => _pill(course['title'] ?? '', AppColors.gold))
                .toList(),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  money(data['bundlePrice'] ?? bundle['price'] ?? 4999),
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontFamily: 'JetBrains Mono',
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _pill('Save ${money(data['savings'] ?? 0)}', AppColors.success),
            ],
          ),
          const SizedBox(height: 12),
          GoldButton(
            label: 'Get Bundle Deal',
            icon: Icons.workspace_premium,
            onPressed: () =>
                context.push('/checkout/${bundle['_id']}?bundle=true'),
          ),
        ],
      ),
    );
  }

  Widget _featureGrid() {
    final features = [
      (
        Icons.lock_outline,
        'Secure video',
        'Protected streams for enrolled students.',
      ),
      (
        Icons.timeline,
        'Progress tracking',
        'Resume learning from your watched lessons.',
      ),
      (
        Icons.local_offer_outlined,
        'Coupons',
        'Apply offers directly at checkout.',
      ),
      (
        Icons.support_agent,
        'Support',
        'Reach the team from your profile anytime.',
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Platform', 'Major features'),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.35,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: features
              .map(
                (feature) => _featureTile(feature.$1, feature.$2, feature.$3),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _highlightTile(BuildContext context, dynamic banner) {
    final image = api.mediaUrl(banner['imageUrl'] as String?);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 86,
            height: 64,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _courseImage(image),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  banner['title'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  banner['subtitle'] ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _about(Map<String, dynamic> settings) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About Money Factory',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            settings['company']?['description'] ?? '',
            style: const TextStyle(color: AppColors.muted, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _courseImage(String url) {
    if (url.isEmpty) {
      return const ColoredBox(
        color: AppColors.secondaryBg,
        child: Center(
          child: Icon(Icons.show_chart, color: AppColors.gold, size: 42),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      width: double.infinity,
      errorWidget: (_, _, _) => const ColoredBox(
        color: AppColors.secondaryBg,
        child: Center(
          child: Icon(Icons.show_chart, color: AppColors.gold, size: 42),
        ),
      ),
    );
  }

  Widget _heroStat(String value, String label) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primaryBg.withValues(alpha: .66),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: AppColors.gold,
                fontFamily: 'JetBrains Mono',
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: AppColors.muted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, String subtitle) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
      ),
      Text(
        subtitle,
        style: const TextStyle(
          color: AppColors.muted,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );

  Widget _miniMetric(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
    decoration: BoxDecoration(
      color: AppColors.secondaryBg,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.gold),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.muted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );

  Widget _featureTile(IconData icon, String title, String body) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.gold),
        const SizedBox(height: 10),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 5),
        Expanded(
          child: Text(
            body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              height: 1.3,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _pill(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .16),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: .4)),
    ),
    child: Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900),
    ),
  );

  String _priceText(dynamic course) =>
      money(course['effectivePrice'] ?? course['price'] ?? 0);

  Widget _priceRow(dynamic course) {
    if (course['isFree'] == true) {
      return const Text(
        'FREE',
        style: TextStyle(
          color: AppColors.success,
          fontFamily: 'JetBrains Mono',
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      );
    }
    final hasOffer = course['hasOffer'] == true;
    if (!hasOffer) {
      return Text(
        money(course['price'] ?? 0),
        style: const TextStyle(
          color: AppColors.gold,
          fontFamily: 'JetBrains Mono',
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      );
    }
    return Row(
      children: [
        Text(
          money(course['originalPrice'] ?? course['price'] ?? 0),
          style: const TextStyle(
            color: AppColors.muted,
            fontFamily: 'JetBrains Mono',
            decoration: TextDecoration.lineThrough,
            decorationColor: AppColors.muted,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 9),
        Text(
          money(course['effectivePrice'] ?? course['price'] ?? 0),
          style: const TextStyle(
            color: AppColors.gold,
            fontFamily: 'JetBrains Mono',
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 9),
        _pill('${course['offerPercent'] ?? 0}% OFF', AppColors.success),
      ],
    );
  }

  Future<void> _openSearch() async {
    final courses = await api.courses();
    if (!mounted) return;
    showSearch(
      context: context,
      delegate: _CourseSearchDelegate(
        courses.where((c) => c['isBundle'] != true).toList(),
      ),
    );
  }

  Future<void> _openFavorites() async {
    final courses = await api.courses();
    if (!mounted) return;
    final favorites = courses
        .where((course) => _favorites.contains(course['_id'].toString()))
        .toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Favorite Courses',
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              if (favorites.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Text(
                    'No favorite courses selected yet',
                    style: TextStyle(color: AppColors.muted),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: favorites.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final course = favorites[index];
                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: AppColors.border),
                        ),
                        leading: const Icon(
                          Icons.favorite,
                          color: AppColors.error,
                        ),
                        title: Text(course['title'] ?? ''),
                        subtitle: Text(
                          course['isFree'] == true
                              ? 'FREE'
                              : _priceText(course),
                          style: const TextStyle(color: AppColors.gold),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/course/${course['_id']}');
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  num _num(dynamic value) {
    if (value is num) {
      return value;
    }
    return num.tryParse(value?.toString() ?? '') ?? 0;
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _CourseSearchDelegate extends SearchDelegate<void> {
  _CourseSearchDelegate(this.courses);

  final List<dynamic> courses;

  @override
  ThemeData appBarTheme(BuildContext context) => Theme.of(context).copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.secondaryBg,
      foregroundColor: AppColors.white,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: InputBorder.none,
      hintStyle: TextStyle(color: AppColors.muted),
    ),
  );

  @override
  List<Widget>? buildActions(BuildContext context) => [
    if (query.isNotEmpty)
      IconButton(onPressed: () => query = '', icon: const Icon(Icons.close)),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    onPressed: () => close(context, null),
    icon: const Icon(Icons.arrow_back),
  );

  @override
  Widget buildResults(BuildContext context) => _results(context);

  @override
  Widget buildSuggestions(BuildContext context) => _results(context);

  Widget _results(BuildContext context) {
    final text = query.trim().toLowerCase();
    final results = text.isEmpty
        ? courses
        : courses.where((course) {
            final title = (course['title'] ?? '').toString().toLowerCase();
            final description =
                (course['shortDescription'] ?? course['description'] ?? '')
                    .toString()
                    .toLowerCase();
            final category = (course['category'] ?? '')
                .toString()
                .toLowerCase();
            return title.contains(text) ||
                description.contains(text) ||
                category.contains(text);
          }).toList();
    return Container(
      color: AppColors.primaryBg,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: results.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final course = results[index];
          final price = course['isFree'] == true
              ? 'FREE'
              : money(course['effectivePrice'] ?? course['price'] ?? 0);
          return ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: AppColors.border),
            ),
            tileColor: AppColors.cardBg,
            title: Text(
              course['title'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            subtitle: Text(
              price,
              style: TextStyle(
                color: course['isFree'] == true
                    ? AppColors.success
                    : AppColors.gold,
                fontWeight: FontWeight.w800,
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              close(context, null);
              context.push('/course/${course['_id']}');
            },
          );
        },
      ),
    );
  }
}
