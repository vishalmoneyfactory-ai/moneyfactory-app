import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/api_service.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/theme/app_colors.dart';

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
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
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
      appBar: AppBar(title: const Text('Profile')),
      body: RefreshIndicator(
        color: AppColors.gold,
        onRefresh: _refresh,
        child: FutureBuilder<List<dynamic>>(
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
                        const Text(
                          'Pull down to retry',
                          style: TextStyle(color: AppColors.gold, fontSize: 13),
                        ),
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
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.gold),
                  ),
                ),
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

            // Filter out refund policy and contact us from legal pages
            final filteredLegal = legal.where((p) {
              final title = (p['title'] ?? '').toString().toLowerCase();
              return !title.contains('refund') && !title.contains('contact');
            }).toList();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _hero(user),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _stat('Courses Owned', '${courses.length}'),
                    _stat(
                      'Videos Watched',
                      '${progress.where((p) => p['isCompleted'] == true).length}',
                    ),
                    _stat('Hours Learned', hours.toStringAsFixed(1)),
                  ],
                ),
                const SizedBox(height: 16),
                _referralCard(user, settings),
                const SizedBox(height: 16),
                _sectionTitle('Owned Courses'),
                if (courses.isEmpty)
                  _emptyCourses(context)
                else
                  ...courses.map((course) => _ownedCourse(context, course)),
                const SizedBox(height: 16),
                _tile(
                  context,
                  'Edit Account',
                  Icons.manage_accounts,
                  () => _editAccount(user),
                ),
                _tile(
                  context,
                  'Help & Support',
                  Icons.support_agent,
                  () => _showHelpSupport(context),
                ),
                _tile(
                  context,
                  'Join Telegram',
                  Icons.send,
                  () => _launchUrl('https://t.me/money_factory_indicator'),
                ),
                _tile(
                  context,
                  'About',
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
                    Icons.article_outlined,
                    () => _showText(context, p['title'], p['content']),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: AppColors.line(context)),
                  ),
                  tileColor: AppColors.card(context),
                  leading: const Icon(Icons.logout, color: AppColors.error),
                  title: const Text(
                    'Logout',
                    style: TextStyle(color: AppColors.error),
                  ),
                  onTap: () async {
                    await _auth.signOut();
                    if (context.mounted) context.go('/login');
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _hero(Map<String, dynamic> user) {
    final image = api.mediaUrl(user['profileImage'] as String?);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.goldGlow),
      ),
      child: Column(
        children: [
          // Avatar with camera button positioned outside/beside (bottom-right corner, not overlapping face)
          SizedBox(
            width: 108,
            height: 108,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 46,
                  backgroundColor: AppColors.surface(context),
                  backgroundImage: image.isEmpty
                      ? null
                      : CachedNetworkImageProvider(image),
                  child: image.isEmpty
                      ? Text(
                          _initials(user['name'] ?? user['email']),
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: -8,
                  child: Material(
                    color: AppColors.gold,
                    shape: const CircleBorder(),
                    elevation: 3,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _busy ? null : _pickProfileImage,
                      child: const Padding(
                        padding: EdgeInsets.all(7),
                        child: Icon(
                          Icons.camera_alt,
                          color: AppColors.primaryBg,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            user['name'] ?? '',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          Text(
            user['email'] ?? '',
            style: TextStyle(color: AppColors.mutedText(context)),
          ),
          if (user['phone'] != null && (user['phone'] as String).isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                user['phone'],
                style: TextStyle(
                  color: AppColors.mutedText(context),
                  fontSize: 13,
                ),
              ),
            ),
          if (image.isNotEmpty)
            TextButton.icon(
              onPressed: _busy ? null : _removeProfileImage,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Remove Photo'),
            ),
        ],
      ),
    );
  }

  Widget _ownedCourse(BuildContext context, dynamic course) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.card(context),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.line(context)),
    ),
    child: Row(
      children: [
        Container(
          width: 62,
          height: 62,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: BorderRadius.circular(8),
          ),
          child: (course['thumbnail'] ?? '').toString().isEmpty
              ? Icon(Icons.school, color: AppColors.gold)
              : CachedNetworkImage(
                  imageUrl: api.mediaUrl(course['thumbnail']),
                  fit: BoxFit.cover,
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                course['title'],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                '${course['totalVideos'] ?? 0} videos',
                style: TextStyle(
                  color: AppColors.mutedText(context),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _validityLabel(course),
                style: TextStyle(
                  color: course['isExpired'] == true
                      ? AppColors.error
                      : AppColors.mutedText(context),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: () => context.push('/course/${course['_id']}'),
          child: const Text('Open'),
        ),
      ],
    ),
  );

  Widget _referralCard(
    Map<String, dynamic> user,
    Map<String, dynamic> settings,
  ) {
    final history = user['referralHistory'] as List<dynamic>? ?? [];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Money Factory Wallet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _miniStat(
                'Referral Code',
                (user['referralCode'] ?? '-').toString(),
              ),
              _miniStat(
                'Wallet Balance',
                '\u20b9${user['walletBalance'] ?? 0}',
              ),
              _miniStat('Total Referrals', '${user['totalReferrals'] ?? 0}'),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.share),
              label: const Text('Share Referral Code'),
              onPressed: () => _shareReferral(user, settings),
            ),
          ),
          if (history.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Referral History',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            ...history
                .take(5)
                .map(
                  (row) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '${row['referredUserId']?['name'] ?? row['referredUserId']?['email'] ?? 'Referral'} - ${row['status']} - \u20b9${row['rewardAmount']}',
                      style: TextStyle(
                        color: AppColors.mutedText(context),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value) => Expanded(
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line(context)),
      ),
      child: Column(
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.gold,
              fontFamily: 'JetBrains Mono',
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.mutedText(context), fontSize: 11),
          ),
        ],
      ),
    ),
  );

  String _validityLabel(dynamic course) {
    if (course['isExpired'] == true) return 'Course Expired';
    final days = course['daysRemaining'];
    if (days is num) return '$days Days Remaining';
    final expiry = course['expiryDate'];
    if (expiry != null)
      return 'Expiry Date: ${expiry.toString().split('T').first}';
    return 'Lifetime Access';
  }

  Widget _emptyCourses(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.card(context),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.line(context)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            'No purchased courses yet',
            style: TextStyle(color: AppColors.mutedText(context)),
          ),
        ),
        TextButton(
          onPressed: () => context.go('/home'),
          child: const Text('Browse'),
        ),
      ],
    ),
  );

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
      backgroundColor: AppColors.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.manage_accounts, color: AppColors.gold),
                    const SizedBox(width: 10),
                    const Text(
                      'Edit Account',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.gold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Update your personal information below.',
                  style: TextStyle(
                    color: AppColors.mutedText(context),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),

                // Name
                TextField(
                  controller: name,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),

                // Phone
                TextField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone_outlined),
                    hintText: '+91 XXXXXXXXXX',
                  ),
                ),
                const SizedBox(height: 12),

                // Bio
                TextField(
                  controller: bio,
                  maxLines: 3,
                  maxLength: 160,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                    prefixIcon: Icon(Icons.info_outline),
                    hintText: 'Tell us a bit about yourself...',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),

                // City
                TextField(
                  controller: city,
                  decoration: const InputDecoration(
                    labelText: 'City',
                    prefixIcon: Icon(Icons.location_city_outlined),
                  ),
                ),
                const SizedBox(height: 12),

                // Country
                TextField(
                  controller: country,
                  decoration: const InputDecoration(
                    labelText: 'Country',
                    prefixIcon: Icon(Icons.flag_outlined),
                  ),
                ),
                const SizedBox(height: 12),

                // Date of Birth
                TextField(
                  controller: dob,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Date of Birth',
                    prefixIcon: Icon(Icons.cake_outlined),
                    hintText: 'YYYY-MM-DD',
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
                            primary: AppColors.gold,
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
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save Changes'),
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
    );
  }

  void _showHelpSupport(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Help & Support',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Reach us through any of the channels below.',
              style: TextStyle(
                color: AppColors.mutedText(context),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),

            // Email
            _contactTile(
              icon: Icons.email_outlined,
              color: const Color(0xFF4CAF50),
              label: 'Mail Us',
              subtitle: 'vishalmoneyfactory@gmail.com',
              onTap: () => _launchUrl('mailto:vishalmoneyfactory@gmail.com'),
            ),
            const SizedBox(height: 12),

            // WhatsApp
            _contactTile(
              icon: Icons.chat_outlined,
              color: const Color(0xFF25D366),
              label: 'Contact via WhatsApp',
              subtitle: '+91 8446519926',
              onTap: () => _launchUrl('https://wa.me/918446519926'),
            ),
            const SizedBox(height: 12),

            _contactTile(
              icon: Icons.camera_alt_outlined,
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
    );
  }

  Widget _contactTile({
    required IconData icon,
    required Color color,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.open_in_new,
              color: color.withValues(alpha: 0.7),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
    ),
  );

  Widget _stat(String label, String value) => Expanded(
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line(context)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.gold,
              fontFamily: 'JetBrains Mono',
              fontWeight: FontWeight.w900,
              fontSize: 19,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.mutedText(context), fontSize: 12),
          ),
        ],
      ),
    ),
  );

  Widget _tile(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: AppColors.line(context)),
      ),
      tileColor: AppColors.card(context),
      leading: Icon(icon, color: AppColors.gold),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
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
        backgroundColor: AppColors.card(context),
        builder: (_) => Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(body, style: const TextStyle(height: 1.5)),
              ],
            ),
          ),
        ),
      );
}
