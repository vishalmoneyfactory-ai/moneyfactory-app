import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

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
    _future = Future.wait([api.me(), api.progressAll(), api.legal(), api.settings()]);
  }

  Future<void> _refresh() async {
    setState(_reload);
    await _future;
  }

  Future<void> _pickProfileImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 82, maxWidth: 900);
    if (picked == null) return;
    await _run(() => api.uploadProfileImage(picked.path), success: 'Profile photo updated');
  }

  Future<void> _removeProfileImage() async {
    await _run(api.removeProfileImage, success: 'Profile photo removed');
  }

  Future<void> _run(Future<dynamic> Function() action, {required String success}) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success), backgroundColor: AppColors.success));
      await _refresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _busy = false);
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
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.gold));
            final user = snapshot.data![0] as Map<String, dynamic>;
            final progress = snapshot.data![1] as List<dynamic>;
            final legal = snapshot.data![2] as List<dynamic>;
            final settings = snapshot.data![3] as Map<String, dynamic>;
            final courses = user['purchasedCourses'] as List<dynamic>? ?? [];
            final hours = progress.fold<num>(0, (sum, p) => sum + ((p['watchedSeconds'] ?? 0) as num)) / 3600;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _hero(user),
                const SizedBox(height: 16),
                Row(children: [_stat('Courses Owned', '${courses.length}'), _stat('Videos Watched', '${progress.where((p) => p['isCompleted'] == true).length}'), _stat('Hours Learned', hours.toStringAsFixed(1))]),
                const SizedBox(height: 16),
                _sectionTitle('Owned Courses'),
                if (courses.isEmpty)
                  _emptyCourses(context)
                else
                  ...courses.map((course) => _ownedCourse(context, course)),
                const SizedBox(height: 16),
                _tile(context, 'Edit Account', Icons.manage_accounts, () => _editAccount(user)),
                _tile(context, 'Notification Settings', Icons.notifications, () => _showText(context, 'Notifications', 'Push notifications are enabled from your device settings.')),
                _tile(context, 'Help & Support', Icons.support_agent, () => _showText(context, 'Support', 'Email: ${settings['company']?['supportEmail'] ?? 'support@moneyfactory.com'}\nPhone: ${settings['company']?['supportPhone'] ?? ''}')),
                _tile(context, 'About', Icons.info, () => _showText(context, 'About Money Factory', settings['company']?['description'] ?? 'Money Factory')),
                ...legal.map((p) => _tile(context, p['title'], Icons.article_outlined, () => _showText(context, p['title'], p['content']))),
                const SizedBox(height: 12),
                ListTile(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: AppColors.border)), tileColor: AppColors.cardBg, leading: const Icon(Icons.logout, color: AppColors.error), title: const Text('Logout', style: TextStyle(color: AppColors.error)), onTap: () async { await _auth.signOut(); if (context.mounted) context.go('/login'); }),
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
      decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.goldGlow)),
      child: Column(children: [
        Stack(alignment: Alignment.bottomRight, children: [
          CircleAvatar(radius: 46, backgroundColor: AppColors.secondaryBg, backgroundImage: image.isEmpty ? null : CachedNetworkImageProvider(image), child: image.isEmpty ? Text(_initials(user['name'] ?? user['email']), style: const TextStyle(color: AppColors.gold, fontSize: 24, fontWeight: FontWeight.w900)) : null),
          Material(color: AppColors.gold, shape: const CircleBorder(), child: IconButton(onPressed: _busy ? null : _pickProfileImage, icon: const Icon(Icons.camera_alt, color: AppColors.primaryBg), tooltip: 'Update photo')),
        ]),
        const SizedBox(height: 12),
        Text(user['name'] ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        Text(user['email'] ?? '', style: const TextStyle(color: AppColors.muted)),
        if (image.isNotEmpty) TextButton.icon(onPressed: _busy ? null : _removeProfileImage, icon: const Icon(Icons.delete_outline), label: const Text('Remove Photo')),
      ]),
    );
  }

  Widget _ownedCourse(BuildContext context, dynamic course) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
    child: Row(children: [
      Container(width: 62, height: 62, clipBehavior: Clip.antiAlias, decoration: BoxDecoration(color: AppColors.secondaryBg, borderRadius: BorderRadius.circular(8)), child: (course['thumbnail'] ?? '').toString().isEmpty ? const Icon(Icons.school, color: AppColors.gold) : CachedNetworkImage(imageUrl: api.mediaUrl(course['thumbnail']), fit: BoxFit.cover)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(course['title'], maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text('${course['totalVideos'] ?? 0} videos', style: const TextStyle(color: AppColors.muted, fontSize: 12))])),
      TextButton(onPressed: () => context.push('/course/${course['_id']}'), child: const Text('Open')),
    ]),
  );

  Widget _emptyCourses(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
    child: Row(children: [const Expanded(child: Text('No purchased courses yet', style: TextStyle(color: AppColors.muted))), TextButton(onPressed: () => context.go('/home'), child: const Text('Browse'))]),
  );

  Future<void> _editAccount(Map<String, dynamic> user) async {
    final name = TextEditingController(text: user['name'] ?? '');
    final phone = TextEditingController(text: user['phone'] ?? '');
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg,
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Edit Account', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.gold)),
          const SizedBox(height: 14),
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
          const SizedBox(height: 12),
          TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone')),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: () async { Navigator.pop(context); await _run(() => api.updateMe({'name': name.text.trim(), 'phone': phone.text.trim()}), success: 'Profile updated'); }, child: const Text('Save Changes'))),
        ]),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)));
  Widget _stat(String label, String value) => Expanded(child: Container(margin: const EdgeInsets.symmetric(horizontal: 4), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)), child: Column(children: [Text(value, style: const TextStyle(color: AppColors.gold, fontFamily: 'JetBrains Mono', fontWeight: FontWeight.w900, fontSize: 19)), const SizedBox(height: 4), Text(label, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, fontSize: 12))])));
  Widget _tile(BuildContext context, String title, IconData icon, VoidCallback onTap) => Padding(padding: const EdgeInsets.only(bottom: 8), child: ListTile(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: AppColors.border)), tileColor: AppColors.cardBg, leading: Icon(icon, color: AppColors.gold), title: Text(title), trailing: const Icon(Icons.chevron_right), onTap: onTap));
  String _initials(String text) => text.trim().split(RegExp(r'\s+')).take(2).map((p) => p.isEmpty ? '' : p[0].toUpperCase()).join();
  void _showText(BuildContext context, String title, String body) => showModalBottomSheet(context: context, backgroundColor: AppColors.cardBg, builder: (_) => Padding(padding: const EdgeInsets.all(20), child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.gold)), const SizedBox(height: 12), Text(body, style: const TextStyle(height: 1.5))]))));
}
