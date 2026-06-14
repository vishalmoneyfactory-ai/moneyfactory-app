import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/api_service.dart';
import '../../../core/theme/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = Future.wait([api.me(), api.settings()]);
  }

  Future<void> _refresh() async {
    setState(() => _future = Future.wait([api.me(), api.settings()]));
    await _future;
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open $url'), backgroundColor: AppColors.error),
      );
    }
  }

  void _walletSheet(Map<String, dynamic> user) {
    final code = (user['referralCode'] ?? '').toString();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.account_balance_wallet, color: AppColors.themeGold(context)),
              const SizedBox(width: 10),
              Text('Digital Wallet', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.text(context))),
            ]),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.goldGlow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.themeGold(context).withValues(alpha: .45)),
                boxShadow: [BoxShadow(color: AppColors.themeGold(context).withValues(alpha: .12), blurRadius: 18)],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Current Balance', style: TextStyle(color: AppColors.mutedText(context), fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text('Rs ${user['walletBalance'] ?? 0}', style: TextStyle(color: AppColors.themeGold(context), fontSize: 30, fontFamily: 'JetBrains Mono', fontWeight: FontWeight.w900)),
              ]),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.surface(context), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.line(context))),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Referral Code', style: TextStyle(color: AppColors.mutedText(context), fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(code.isEmpty ? '-' : code, style: TextStyle(color: AppColors.text(context), fontSize: 20, fontFamily: 'JetBrains Mono', fontWeight: FontWeight.w900)),
                ])),
                IconButton.outlined(
                  onPressed: code.isEmpty ? null : () async {
                    await Clipboard.setData(ClipboardData(text: code));
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Referral code copied'), backgroundColor: AppColors.success));
                    }
                  },
                  icon: const Icon(Icons.copy),
                  tooltip: 'Copy referral code',
                ),
              ]),
            ),
            const SizedBox(height: 12),
            Text(
              'Share this referral code with your friends and family. If they use your code while buying any course, you get Rs 1000 in your digital wallet.',
              style: TextStyle(color: AppColors.mutedText(context), height: 1.45),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MONEY FACTORY', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          FutureBuilder<List<dynamic>>(
            future: _future,
            builder: (context, snapshot) {
              final user = snapshot.data?[0] as Map<String, dynamic>?;
              return IconButton(
                onPressed: user == null ? null : () => _walletSheet(user),
                icon: const Icon(Icons.account_balance_wallet_outlined),
                color: AppColors.themeGold(context),
                tooltip: 'Digital Wallet',
              );
            },
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
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator(color: AppColors.themeGold(context)));
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                children: [
                  _ownerFrame(),
                  const SizedBox(height: 18),
                  _description(),
                  const SizedBox(height: 18),
                  _socials(),
                  const SizedBox(height: 18),
                  _reviews(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _ownerFrame() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.card(context),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.themeGold(context).withValues(alpha: .55), width: 1.2),
      boxShadow: [BoxShadow(color: AppColors.themeGold(context).withValues(alpha: .10), blurRadius: 22, offset: const Offset(0, 10))],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 340,
        color: AppColors.surface(context),
        child: Image.asset('assets/images/owner-1.png', width: double.infinity, fit: BoxFit.contain),
      ),
    ),
  );

  Widget _description() => _panel([
    Text('The Money Factory indicator', style: TextStyle(color: AppColors.themeGold(context), fontSize: 24, fontWeight: FontWeight.w900)),
    const SizedBox(height: 12),
    Text(
      "Stop chasing lagging indicators. The Money Factory system reads the market's true DNA—Structure and Liquidity—making it an absolute weapon for trading Gold (XAU/USD).",
      style: TextStyle(color: AppColors.text(context), height: 1.5, fontSize: 15),
    ),
    const SizedBox(height: 14),
    Text('Two indicator', style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.w900, fontSize: 17)),
    const SizedBox(height: 10),
    _indicatorLine('1.money factory indicator (The Trigger)', 'Tracks market structure and behavior to strike with precise BUY/SELL signals right as the trend shifts.'),
    const SizedBox(height: 10),
    _indicatorLine('2. Money factory Liquidity Indicator (The Magnet)', 'Reveals "Liquidity Pools"—hidden institutional zones that pull the price toward them like a powerful magnet.'),
  ]);

  Widget _indicatorLine(String title, String body) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.surface(context).withValues(alpha: .72),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.neonBlue.withValues(alpha: .32)),
      boxShadow: [BoxShadow(color: AppColors.neonBlue.withValues(alpha: .06), blurRadius: 16)],
    ),
    child: RichText(
      text: TextSpan(
        style: TextStyle(color: AppColors.mutedText(context), height: 1.45),
        children: [
          TextSpan(text: '$title: ', style: TextStyle(color: AppColors.themeGold(context), fontWeight: FontWeight.w900)),
          TextSpan(text: body),
        ],
      ),
    ),
  );

  Widget _socials() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _sectionTitle('Direct Help/Social Media Handles'),
    const SizedBox(height: 10),
    _socialTile(Icons.camera_alt_outlined, 'Instagram', '@trader_vicky1', () => _launch('https://www.instagram.com/trader_vicky1?igsh=MWVlamdmbmRtcXZmaQ==')),
    _socialTile(Icons.chat_outlined, 'Whatsapp', '+91 8446519926', () => _launch('https://wa.me/918446519926')),
    _socialTile(Icons.send_outlined, 'Telegram', 'money_factory_indicator', () => _launch('https://t.me/money_factory_indicator')),
  ]);

  Widget _socialTile(IconData icon, String title, String subtitle, VoidCallback onTap) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(color: AppColors.card(context).withValues(alpha: .92), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.line(context)), boxShadow: [BoxShadow(color: AppColors.neonBlue.withValues(alpha: .06), blurRadius: 16, offset: const Offset(0, 8))]),
    child: ListTile(
      leading: CircleAvatar(backgroundColor: AppColors.neonBlue.withValues(alpha: .12), child: Icon(icon, color: AppColors.neonBlue)),
      title: Text(title, style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.w900)),
      subtitle: Text(subtitle, style: TextStyle(color: AppColors.mutedText(context))),
      trailing: Icon(Icons.open_in_new, color: AppColors.themeGold(context)),
      onTap: onTap,
    ),
  );

  Widget _reviews() {
    final rows = [
      ('Soumik Chaudhuri', 4.5, 'Clean signals and the liquidity view makes the chart much easier to understand.'),
      ('Aarav Mehta', 4.0, 'The course flow is simple and practical. I liked how quickly I could revise videos.'),
      ('Priya Sharma', 5.0, 'Premium feel, clear lessons, and the indicator logic is explained very well.'),
      ('Rohit Patil', 4.5, 'The app helped me stay disciplined instead of jumping between random strategies.'),
      ('Neha Verma', 5.0, 'Great learning experience for Gold trading with useful structure-based examples.'),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle('Feedbacks and reviews'),
      const SizedBox(height: 10),
      ...rows.map((row) => _reviewTile(row.$1, row.$2, row.$3)),
    ]);
  }

  Widget _reviewTile(String name, double rating, String comment) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppColors.card(context).withValues(alpha: .92), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.line(context)), boxShadow: [BoxShadow(color: AppColors.themeGold(context).withValues(alpha: .05), blurRadius: 14, offset: const Offset(0, 8))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(name, style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.w900))),
        Text('${rating.toStringAsFixed(1)}/5', style: TextStyle(color: AppColors.themeGold(context), fontFamily: 'JetBrains Mono', fontWeight: FontWeight.w900)),
      ]),
      const SizedBox(height: 6),
      Row(children: List.generate(5, (index) {
        final value = index + 1;
        if (rating >= value) return Icon(Icons.star, color: AppColors.themeGold(context), size: 18);
        if (rating > index) return Icon(Icons.star_half, color: AppColors.themeGold(context), size: 18);
        return Icon(Icons.star_border, color: AppColors.mutedText(context), size: 18);
      })),
      const SizedBox(height: 8),
      Text(comment, style: TextStyle(color: AppColors.mutedText(context), height: 1.4)),
    ]),
  );

  Widget _panel(List<Widget> children) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.card(context).withValues(alpha: .92),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.line(context)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );

  Widget _sectionTitle(String title) => Text(title, style: TextStyle(color: AppColors.text(context), fontSize: 20, fontWeight: FontWeight.w900));
}
