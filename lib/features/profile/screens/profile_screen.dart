import 'dart:async';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/api_service.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/motion.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = AuthService(dioProvider);
  final _picker = ImagePicker();
  late Future<List<dynamic>> _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = Future.wait([
      api.me(),
      api.progressAll(),
      api.legal(),
      api.settings(),
    ]);
  }

  Future<void> _refresh() async {
    setState(_reload);
    await _future;
  }

  Future<void> _pickProfileImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 900,
    );
    if (picked == null) return;
    await _run(
      () => api.uploadProfileImage(picked.path),
      success: 'Profile photo updated',
    );
  }

  Future<void> _removeProfileImage() async {
    await _run(api.removeProfileImage, success: 'Profile photo removed');
  }

  Future<void> _run(
    Future<dynamic> Function() action, {
    required String success,
  }) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success), backgroundColor: AppColors.success),
      );
      await _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(parseError(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open: $url'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _shareReferral(
    Map<String, dynamic> user,
    Map<String, dynamic> settings,
  ) async {
    final downloads = settings['appDownloads'] as Map<String, dynamic>? ?? {};
    final downloadLink =
        (downloads['android'] ?? downloads['ios'] ?? downloads['website'] ?? '')
            .toString();
    final fallbackLink =
        (downloads['website'] ?? downloads['android'] ?? downloads['ios'] ?? '')
            .toString();
    final link = downloadLink.isNotEmpty ? downloadLink : fallbackLink;
    final message =
        '''
Join Money Factory and learn professional trading.

Use my referral code:

${user['referralCode'] ?? ''}

Download the app:

$link
''';
    final url = kIsWeb
        ? 'https://wa.me/?text=${Uri.encodeComponent(message)}'
        : 'whatsapp://send?text=${Uri.encodeComponent(message)}';
    if (!await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    )) {
      await _launchUrl('https://wa.me/?text=${Uri.encodeComponent(message)}');
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
                return CustomScrollView(
                  slivers: [
                    _floatingAppBar(),
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.wifi_off,
                              color: AppColors.muted,
                              size: 52,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Could not load profile',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              snapshot.error.toString().replaceAll(
                                'Exception: ',
                                '',
                              ),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Pull down to retry',
                              style: TextStyle(
                                color: AppColors.themeGold(context),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }

              if (!snapshot.hasData) {
                return CustomScrollView(
                  slivers: [
                    _floatingAppBar(),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                      sliver: SliverList.list(
                        children: const [
                          ShimmerLine(height: 240, radius: 28),
                          SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(child: ShimmerLine(height: 90, radius: 18)),
                              SizedBox(width: 12),
                              Expanded(child: ShimmerLine(height: 90, radius: 18)),
                              SizedBox(width: 12),
                              Expanded(child: ShimmerLine(height: 90, radius: 18)),
                            ],
                          ),
                          SizedBox(height: 24),
                          ShimmerLine(height: 140, radius: 24),
                          SizedBox(height: 24),
                          ShimmerLine(height: 24, width: 120),
                          SizedBox(height: 16),
                          ShimmerLine(height: 80, radius: 18),
                        ],
                      ),
                    ),
                  ],
                );
              }

              final user = snapshot.data![0] as Map<String, dynamic>;
              final progress = snapshot.data![1] as List<dynamic>;
              final legal = snapshot.data![2] as List<dynamic>;
              final settings = snapshot.data![3] as Map<String, dynamic>;
              final courses = user['purchasedCourses'] as List<dynamic>? ?? [];
              final hours =
                  progress.fold<num>(
                    0,
                    (sum, p) => sum + ((p['watchedSeconds'] ?? 0) as num),
                  ) /
                  3600;

              final filteredLegal = legal.where((p) {
                final title = (p['title'] ?? '').toString().toLowerCase();
                return !title.contains('refund') && !title.contains('contact');
              }).toList();

              return CustomScrollView(
                slivers: [
                  _floatingAppBar(),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                    sliver: SliverList.list(
                      children: [
                        FadeSlideIn(child: _hero(user)),
                        const SizedBox(height: 24),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 60),
                          child: Row(
                            children: [
                              _stat('Courses', courses.length),
                              _stat(
                                'Watched',
                                progress.where((p) => p['isCompleted'] == true).length,
                              ),
                              _stat('Hours', hours, isDouble: true),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 120),
                          child: _referralCard(user, settings),
                        ),
                        const SizedBox(height: 32),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 180),
                          child: _sectionKicker('Learning'),
                        ),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 180),
                          child: const Text(
                            'Owned Courses',
                            style: TextStyle(
                              fontSize: 31,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 240),
                          child: courses.isEmpty
                              ? _emptyCourses(context)
                              : Column(
                                  children: courses
                                      .map((c) => _ownedCourse(context, c))
                                      .toList(),
                                ),
                        ),
                        const SizedBox(height: 32),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 300),
                          child: _sectionKicker('Settings & More'),
                        ),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 300),
                          child: const Text(
                            'General',
                            style: TextStyle(
                              fontSize: 31,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 360),
                          child: Column(
                            children: [
                              _tile(
                                context,
                                'Edit Account',
                                'Update your personal information',
                                Icons.manage_accounts,
                                () => _editAccount(user),
                              ),
                              _tile(
                                context,
                                'Help & Support',
                                'Contact us for any issues',
                                Icons.support_agent,
                                () => _showHelpSupport(context),
                              ),
                              _tile(
                                context,
                                'Join Telegram',
                                'Connect with the community',
                                Icons.send,
                                () => _launchUrl('https://t.me/money_factory_indicator'),
                              ),
                              _tile(
                                context,
                                'About',
                                'Learn more about us',
                                Icons.info,
                                () => _showText(
                                  context,
                                  'About Money Factory',
                                  settings['company']?['description'] ?? 'Money Factory',
                                ),
                              ),
                              ...filteredLegal.map(
                                (p) => _tile(
                                  context,
                                  p['title'],
                                  'Legal documentation',
                                  Icons.article_outlined,
                                  () => _showText(context, p['title'], p['content']),
                                ),
                              ),
                              const SizedBox(height: 12),
                              InkWell(
                                onTap: () async {
                                  await _auth.signOut();
                                  if (context.mounted) context.go('/login');
                                },
                                borderRadius: BorderRadius.circular(18),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: AppColors.error.withValues(alpha: .12),
                                          borderRadius: BorderRadius.circular(18),
                                        ),
                                        child: const Icon(Icons.logout, color: AppColors.error),
                                      ),
                                      const SizedBox(width: 15),
                                      const Expanded(
                                        child: Text(
                                          'Logout',
                                          style: TextStyle(
                                            color: AppColors.error,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
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
        'Profile',
        style: TextStyle(
          color: AppColors.text(context),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _hero(Map<String, dynamic> user) {
    final image = api.mediaUrl(user['profileImage'] as String?);
    return Container(
      width: double.infinity,
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
      ),
      child: Column(
        children: [
          SizedBox(
            width: 116,
            height: 116,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 116,
                  height: 116,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.themeGold(context).withValues(alpha: .4),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.themeGold(context).withValues(alpha: .18),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    backgroundColor: AppColors.surface(context),
                    backgroundImage: image.isEmpty
                        ? null
                        : CachedNetworkImageProvider(image),
                    child: image.isEmpty
                        ? Text(
                            _initials(user['name'] ?? user['email']),
                            style: TextStyle(
                              color: AppColors.themeGold(context),
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                            ),
                          )
                        : null,
                  ),
                ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Material(
                    color: AppColors.themeButtonColor(context),
                    shape: const CircleBorder(),
                    elevation: 6,
                    shadowColor: AppColors.themeButtonColor(context).withValues(alpha: .4),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _busy ? null : _pickProfileImage,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Icon(
                          Icons.camera_alt,
                          color: AppColors.themeButtonText(context),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            user['name'] ?? 'Trader',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, height: 1.1),
          ),
          const SizedBox(height: 4),
          Text(
            user['email'] ?? '',
            style: TextStyle(color: AppColors.mutedText(context), fontSize: 15),
          ),
          if (user['phone'] != null && (user['phone'] as String).isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                user['phone'],
                style: TextStyle(
                  color: AppColors.mutedText(context),
                  fontSize: 14,
                ),
              ),
            ),
          if (image.isNotEmpty) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _busy ? null : _removeProfileImage,
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              label: const Text('Remove Photo', style: TextStyle(color: AppColors.error)),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.error.withValues(alpha: .1),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _stat(String label, num value, {bool isDouble = false}) => Expanded(
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface(context).withValues(alpha: .6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.themeGold(context).withValues(alpha: .15)),
      ),
      child: Column(
        children: [
          CountUpNumber(
            value: value,
            style: TextStyle(
              color: AppColors.themeGold(context),
              fontFamily: 'JetBrains Mono',
              fontWeight: FontWeight.w900,
              fontSize: 26,
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.mutedText(context),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _referralCard(
    Map<String, dynamic> user,
    Map<String, dynamic> settings,
  ) {
    final history = user['referralHistory'] as List<dynamic>? ?? [];
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            AppColors.violet.withValues(alpha: .22),
            AppColors.neonBlue.withValues(alpha: .1),
            AppColors.card(context),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.violet.withValues(alpha: .12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.themeGold(context).withValues(alpha: .15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.stars_rounded, color: AppColors.themeGold(context), size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Money Factory Wallet',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.themeGold(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              _miniStat('Referral Code', (user['referralCode'] ?? '-').toString()),
              _miniStat('Wallet Balance', '\u20b9${user['walletBalance'] ?? 0}'),
              _miniStat('Total Referrals', '${user['totalReferrals'] ?? 0}'),
            ],
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              icon: Icon(Icons.share, size: 18),
              label: Text('Share Referral Code', style: TextStyle(fontWeight: FontWeight.w800)),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.themeButtonColor(context),
                foregroundColor: AppColors.themeButtonText(context),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => _shareReferral(user, settings),
            ),
          ),
          if (history.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'REFERRAL HISTORY',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 1.5,
                color: AppColors.mutedText(context),
              ),
            ),
            const SizedBox(height: 12),
            ...history
                .take(5)
                .map(
                  (row) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: AppColors.success, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${row['referredUserId']?['name'] ?? row['referredUserId']?['email'] ?? 'Referral'}',
                            style: TextStyle(
                              color: AppColors.text(context),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          '\u20b9${row['rewardAmount']}',
                          style: const TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'JetBrains Mono',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.text(context),
            fontFamily: 'JetBrains Mono',
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.mutedText(context), fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );

  Widget _ownedCourse(BuildContext context, dynamic course) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface(context).withValues(alpha: .7),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.line(context)),
      boxShadow: [
        BoxShadow(
          color: AppColors.themeGold(context).withValues(alpha: .03),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 72,
          height: 72,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(16),
          ),
          child: (course['thumbnail'] ?? '').toString().isEmpty
              ? Icon(Icons.school, color: AppColors.themeGold(context), size: 32)
              : CachedNetworkImage(
                  imageUrl: api.mediaUrl(course['thumbnail']),
                  fit: BoxFit.cover,
                ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                course['title'],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.play_circle_outline, size: 14, color: AppColors.themeGold(context)),
                  const SizedBox(width: 4),
                  Text(
                    '${course['totalVideos'] ?? 0} videos',
                    style: TextStyle(
                      color: AppColors.mutedText(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _validityLabel(course),
                style: TextStyle(
                  color: course['isExpired'] == true
                      ? AppColors.error
                      : AppColors.success,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.themeGold(context).withValues(alpha: .15),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(Icons.play_arrow, color: AppColors.themeGold(context), size: 22),
            onPressed: () => context.push('/course/${course['_id']}'),
          ),
        ),
      ],
    ),
  );

  String _validityLabel(dynamic course) {
    if (course['isExpired'] == true) return 'EXPIRED';
    final days = course['daysRemaining'];
    if (days is num) return '$days DAYS REMAINING';
    final expiry = course['expiryDate'];
    if (expiry != null) {
      return 'EXP: ${expiry.toString().split('T').first}';
    }
    return 'LIFETIME ACCESS';
  }

  Widget _emptyCourses(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: AppColors.surface(context).withValues(alpha: .6),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.line(context), width: 1.5, style: BorderStyle.solid),
    ),
    child: Column(
      children: [
        Icon(Icons.school_outlined, size: 48, color: AppColors.mutedText(context)),
        const SizedBox(height: 16),
        Text(
          'No courses yet',
          style: TextStyle(
            color: AppColors.text(context),
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Start your trading journey today.',
          style: TextStyle(color: AppColors.mutedText(context)),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: () => context.go('/home'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.themeButtonColor(context),
            foregroundColor: AppColors.themeButtonText(context),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const Text('Browse Courses', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
      ],
    ),
  );

  Widget _tile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppColors.accentGradient(context),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.neonBlue.withValues(alpha: .18),
                    blurRadius: 18,
                  ),
                ],
              ),
              child: Icon(icon, color: AppColors.white),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.text(context),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: AppColors.mutedText(context)),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.themeGold(context), size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _editAccount(Map<String, dynamic> user) async {
    final name = TextEditingController(text: user['name'] ?? '');
    final phone = TextEditingController(text: user['phone'] ?? '');
    final bio = TextEditingController(text: user['bio'] ?? '');
    final city = TextEditingController(text: user['city'] ?? '');
    final country = TextEditingController(text: user['country'] ?? '');
    final dob = TextEditingController(text: user['dateOfBirth'] ?? '');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: EdgeInsets.fromLTRB(
              20,
              24,
              20,
              MediaQuery.of(context).viewInsets.bottom + 120,
            ),
            decoration: BoxDecoration(
              gradient: AppColors.pageGradient(context),
              border: Border(top: BorderSide(color: AppColors.themeGold(context).withValues(alpha: .32))),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.mutedText(context).withValues(alpha: .35),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Icon(Icons.manage_accounts, color: AppColors.themeGold(context), size: 34),
                  const SizedBox(height: 12),
                  Text(
                    'Edit Account',
                    style: TextStyle(
                      color: AppColors.text(context),
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Update your personal information below.',
                    style: TextStyle(
                      color: AppColors.mutedText(context),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 26),

                  // Name
                  TextField(
                    controller: name,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: const Icon(Icons.person_outline),
                      filled: true,
                      fillColor: AppColors.surface(context),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Phone
                  TextField(
                    controller: phone,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      hintText: '+91 XXXXXXXXXX',
                      filled: true,
                      fillColor: AppColors.surface(context),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Bio
                  TextField(
                    controller: bio,
                    maxLines: 3,
                    maxLength: 160,
                    decoration: InputDecoration(
                      labelText: 'Bio',
                      prefixIcon: const Icon(Icons.info_outline),
                      hintText: 'Tell us a bit about yourself...',
                      alignLabelWithHint: true,
                      filled: true,
                      fillColor: AppColors.surface(context),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // City
                  TextField(
                    controller: city,
                    decoration: InputDecoration(
                      labelText: 'City',
                      prefixIcon: const Icon(Icons.location_city_outlined),
                      filled: true,
                      fillColor: AppColors.surface(context),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Country
                  TextField(
                    controller: country,
                    decoration: InputDecoration(
                      labelText: 'Country',
                      prefixIcon: const Icon(Icons.flag_outlined),
                      filled: true,
                      fillColor: AppColors.surface(context),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Date of Birth
                  TextField(
                    controller: dob,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Date of Birth',
                      prefixIcon: const Icon(Icons.cake_outlined),
                      hintText: 'YYYY-MM-DD',
                      filled: true,
                      fillColor: AppColors.surface(context),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate:
                            DateTime.tryParse(dob.text) ?? DateTime(2000),
                        firstDate: DateTime(1940),
                        lastDate: DateTime.now(),
                        builder: (context, child) => Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.dark(
                              primary: AppColors.themeGold(context),
                              onPrimary: AppColors.primaryBg,
                              surface: AppColors.card(context),
                            ),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        dob.text =
                            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                      }
                    },
                  ),
                  const SizedBox(height: 26),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton.icon(
                      icon: Icon(Icons.save_outlined),
                      label: Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w800)),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.themeButtonColor(context),
                        foregroundColor: AppColors.themeButtonText(context),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        await _run(
                          () => api.updateMe({
                            'name': name.text.trim(),
                            'phone': phone.text.trim(),
                            'bio': bio.text.trim(),
                            'city': city.text.trim(),
                            'country': country.text.trim(),
                            'dateOfBirth': dob.text.trim(),
                          }),
                          success: 'Profile updated',
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showHelpSupport(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 122),
            decoration: BoxDecoration(
              gradient: AppColors.pageGradient(context),
              border: Border(top: BorderSide(color: AppColors.themeGold(context).withValues(alpha: .32))),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.mutedText(context).withValues(alpha: .35),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Icon(Icons.support_agent, color: AppColors.themeGold(context), size: 34),
                const SizedBox(height: 12),
                Text(
                  'Help & Support',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text(context),
                    height: 1,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Reach us through any of the channels below.',
                  style: TextStyle(
                    color: AppColors.mutedText(context),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 26),

                _contactTile(
                  iconWidget: const Icon(Icons.email_outlined, color: Color(0xFF4CAF50), size: 24),
                  color: const Color(0xFF4CAF50),
                  label: 'Mail Us',
                  subtitle: 'vishalmoneyfactory@gmail.com',
                  onTap: () => _launchUrl('mailto:vishalmoneyfactory@gmail.com'),
                ),
                const SizedBox(height: 12),
                _contactTile(
                  iconWidget: const FaIcon(FontAwesomeIcons.whatsapp, color: Color(0xFF25D366), size: 24),
                  color: const Color(0xFF25D366),
                  label: 'Contact via WhatsApp',
                  subtitle: '+91 7522929338',
                  onTap: () => _launchUrl('https://wa.me/917522929338'),
                ),
                const SizedBox(height: 12),
                _contactTile(
                  iconWidget: const FaIcon(FontAwesomeIcons.instagram, color: Color(0xFFE1306C), size: 24),
                  color: const Color(0xFFE1306C),
                  label: 'Instagram',
                  subtitle: '@trader_vicky1',
                  onTap: () => _launchUrl(
                    'https://www.instagram.com/trader_vicky1?igsh=MWVlamdmbmRtcXZmaQ==',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _contactTile({
    required Widget iconWidget,
    required Color color,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(child: iconWidget),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.north_east,
              color: color.withValues(alpha: 0.8),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionKicker(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text.toUpperCase(),
      style: TextStyle(
        color: AppColors.themeGold(context),
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.8,
      ),
    ),
  );

  String _initials(String text) => text
      .trim()
      .split(RegExp(r'\s+'))
      .take(2)
      .map((p) => p.isEmpty ? '' : p[0].toUpperCase())
      .join();

  void _showText(BuildContext context, String title, String body) =>
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 122),
            decoration: BoxDecoration(
              gradient: AppColors.pageGradient(context),
              border: Border(top: BorderSide(color: AppColors.themeGold(context).withValues(alpha: .32))),
            ),
            child: SafeArea(
              top: false,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.mutedText(context).withValues(alpha: .35),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: AppColors.text(context),
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Text(
                          body,
                          style: TextStyle(
                            color: AppColors.mutedText(context),
                            height: 1.6,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
}
