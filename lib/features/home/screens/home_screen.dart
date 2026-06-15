import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/motion.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<dynamic>> _future;
  late final PageController _reviewController;
  Timer? _reviewTimer;
  int _reviewIndex = 0;
  bool _reviewsPaused = false;

  @override
  void initState() {
    super.initState();
    _future = Future.wait([api.me(), api.settings()]);
    _reviewController = PageController(viewportFraction: .82);
    _reviewTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_reviewsPaused || !_reviewController.hasClients) return;
      _reviewIndex = (_reviewIndex + 1) % 5;
      _reviewController.animateToPage(
        _reviewIndex,
        duration: const Duration(milliseconds: 760),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _reviewTimer?.cancel();
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _future = Future.wait([api.me(), api.settings()]));
    await _future;
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open $url'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _walletSheet(Map<String, dynamic> user) {
    final code = (user['referralCode'] ?? '').toString();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 32),
            decoration: BoxDecoration(
              gradient: AppColors.pageGradient(context),
              border: Border(
                top: BorderSide(color: AppColors.themeGold(context).withValues(alpha: .32)),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.mutedText(
                          context,
                        ).withValues(alpha: .35),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Icon(
                    Icons.account_balance_wallet,
                    color: AppColors.themeGold(context),
                    size: 34,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Digital Wallet',
                    style: TextStyle(
                      color: AppColors.text(context),
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Referral earnings are tracked here for manual payout.',
                    style: TextStyle(
                      color: AppColors.mutedText(context),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 26),
                  CountUpNumber(
                    value: (user['walletBalance'] as num?) ?? 0,
                    prefix: 'Rs ',
                    style: TextStyle(
                      color: AppColors.themeGold(context),
                      fontSize: 42,
                      fontFamily: 'JetBrains Mono',
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Referral code',
                              style: TextStyle(
                                color: AppColors.mutedText(context),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              code.isEmpty ? '-' : code,
                              style: TextStyle(
                                color: AppColors.text(context),
                                fontSize: 24,
                                fontFamily: 'JetBrains Mono',
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: code.isEmpty
                            ? null
                            : () async {
                                await Clipboard.setData(
                                  ClipboardData(text: code),
                                );
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Referral code copied'),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                }
                              },
                        icon: const Icon(Icons.copy),
                        tooltip: 'Copy referral code',
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Share this referral code with friends and family. If they use your code while buying any course, you get Rs 1000 in your digital wallet.',
                    style: TextStyle(
                      color: AppColors.mutedText(context),
                      height: 1.5,
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
              if (!snapshot.hasData) {
                return CustomScrollView(
                  slivers: [
                    _floatingAppBar(null),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(20, 28, 20, 28),
                      sliver: SliverList.list(
                        children: [
                          ShimmerLine(height: 360, radius: 26),
                          SizedBox(height: 26),
                          ShimmerLine(width: 260, height: 34),
                          SizedBox(height: 12),
                          ShimmerLine(height: 18),
                          SizedBox(height: 8),
                          ShimmerLine(height: 18),
                        ],
                      ),
                    ),
                  ],
                );
              }
              final user = snapshot.data![0] as Map<String, dynamic>;
              return CustomScrollView(
                slivers: [
                  _floatingAppBar(user),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 34),
                    sliver: SliverList.list(
                      children: [
                        FadeSlideIn(child: _hero(user)),
                        const SizedBox(height: 34),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 90),
                          child: _description(),
                        ),
                        const SizedBox(height: 34),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 150),
                          child: _socials(),
                        ),
                        const SizedBox(height: 34),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 210),
                          child: _reviews(),
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

  SliverAppBar _floatingAppBar(Map<String, dynamic>? user) {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: AppColors.bg(context).withValues(alpha: .86),
      surfaceTintColor: Colors.transparent,
      title: Text(
        'Money Factory',
        style: TextStyle(
          color: AppColors.text(context),
          fontWeight: FontWeight.w900,
        ),
      ),
      actions: [
        if (user != null)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(99),
              onTap: () => _walletSheet(user),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.themeGold(context).withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(99),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.themeGold(context).withValues(alpha: .12),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      color: AppColors.themeGold(context),
                      size: 17,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Rs ${user['walletBalance'] ?? 0}',
                      style: TextStyle(
                        color: AppColors.themeGold(context),
                        fontFamily: 'JetBrains Mono',
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _hero(Map<String, dynamic> user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Hero(
          tag: 'owner-photo',
          child: Container(
            height: 390,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: LinearGradient(
                colors: [
                  AppColors.themeGold(context).withValues(alpha: .58),
                  AppColors.neonBlue.withValues(alpha: .34),
                  Colors.transparent,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.themeGold(context).withValues(alpha: .16),
                  blurRadius: 38,
                  offset: const Offset(0, 24),
                ),
              ],
            ),
            padding: const EdgeInsets.all(1.6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(29),
              child: ColoredBox(
                color: AppColors.surface(context),
                child: Image.asset(
                  'assets/images/owner-1.png',
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _description() => _section(
    children: [
      _sectionKicker('Indicator System'),
      Text(
        'The Money Factory indicator',
        style: TextStyle(
          color: AppColors.text(context),
          fontSize: 34,
          height: 1.02,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 16),
      Text(
        "Stop chasing lagging indicators. The Money Factory system reads the market's true DNA—Structure and Liquidity—making it an absolute weapon for trading Gold (XAU/USD).",
        style: TextStyle(
          color: AppColors.mutedText(context),
          height: 1.6,
          fontSize: 16,
        ),
      ),
      const SizedBox(height: 24),
      _indicatorLine(
        'Money factory indicator',
        'The Trigger',
        'Tracks market structure and behavior to strike with precise BUY/SELL signals right as the trend shifts.',
      ),
      _softDivider(),
      _indicatorLine(
        'Money factory Liquidity Indicator',
        'The Magnet',
        'Reveals "Liquidity Pools"—hidden institutional zones that pull the price toward them like a powerful magnet.',
      ),
    ],
  );

  Widget _indicatorLine(String title, String tag, String body) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(top: 7),
          decoration: BoxDecoration(
            color: AppColors.themeGold(context),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tag.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.neonBlue,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  color: AppColors.text(context),
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                body,
                style: TextStyle(
                  color: AppColors.mutedText(context),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _socials() => _section(
    children: [
      _sectionKicker('Direct Help'),
      Text(
        'Social Media Handles',
        style: TextStyle(
          color: AppColors.text(context),
          fontSize: 31,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 18),
      _socialRow(
        Icons.camera_alt_outlined,
        'Instagram',
        '@trader_vicky1',
        () => _launch(
          'https://www.instagram.com/trader_vicky1?igsh=MWVlamdmbmRtcXZmaQ==',
        ),
      ),
      _socialRow(
        Icons.chat_outlined,
        'Whatsapp',
        '+91 8446519926',
        () => _launch('https://wa.me/918446519926'),
      ),
      _socialRow(
        Icons.send_outlined,
        'Telegram',
        'money_factory_indicator',
        () => _launch('https://t.me/money_factory_indicator'),
      ),
    ],
  );

  Widget _socialRow(
    IconData icon,
    String title,
    String subtitle,
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
            Icon(Icons.north_east, color: AppColors.themeGold(context), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _reviews() {
    final rows = [
      (
        'Soumik Chaudhuri',
        4.5,
        'Clean signals and the liquidity view makes the chart much easier to understand.',
      ),
      (
        'Aarav Mehta',
        4.0,
        'The course flow is simple and practical. I liked how quickly I could revise videos.',
      ),
      (
        'Priya Sharma',
        5.0,
        'Premium feel, clear lessons, and the indicator logic is explained very well.',
      ),
      (
        'Rohit Patil',
        4.5,
        'The app helped me stay disciplined instead of jumping between random strategies.',
      ),
      (
        'Neha Verma',
        5.0,
        'Great learning experience for Gold trading with useful structure-based examples.',
      ),
    ];
    return _section(
      children: [
        _sectionKicker('Community'),
        Text(
          'Feedbacks and reviews',
          style: TextStyle(
            color: AppColors.text(context),
            fontSize: 31,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 18),
        Listener(
          onPointerDown: (_) => setState(() => _reviewsPaused = true),
          onPointerUp: (_) => setState(() => _reviewsPaused = false),
          onPointerCancel: (_) => setState(() => _reviewsPaused = false),
          child: SizedBox(
            height: 250,
            child: PageView.builder(
              controller: _reviewController,
              onPageChanged: (value) => _reviewIndex = value % rows.length,
              itemBuilder: (context, index) {
                final row = rows[index % rows.length];
                return _reviewPreview(
                  row.$1,
                  row.$2,
                  row.$3,
                  index % rows.length,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _reviewPreview(
    String name,
    double rating,
    String comment,
    int index,
  ) => AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    margin: const EdgeInsets.only(right: 14),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      gradient: LinearGradient(
        colors: [
          AppColors.neonBlue.withValues(alpha: .22),
          AppColors.violet.withValues(alpha: .18),
          AppColors.themeGold(context).withValues(alpha: .10),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.neonBlue.withValues(alpha: .12),
          blurRadius: 24,
          offset: const Offset(0, 14),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              '0${index + 1}',
              style: TextStyle(
                color: AppColors.themeGold(context),
                fontFamily: 'JetBrains Mono',
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            Text(
              '${rating.toStringAsFixed(1)}/5',
              style: TextStyle(
                color: AppColors.themeGold(context),
                fontFamily: 'JetBrains Mono',
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        Text(
          comment,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.text(context),
            fontSize: 20,
            height: 1.25,
            fontWeight: FontWeight.w900,
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(5, (star) {
                final value = star + 1;
                if (rating >= value)
                  return Icon(
                    Icons.star,
                    color: AppColors.themeGold(context),
                    size: 18,
                  );
                if (rating > star)
                  return Icon(
                    Icons.star_half,
                    color: AppColors.themeGold(context),
                    size: 18,
                  );
                return Icon(
                  Icons.star_border,
                  color: AppColors.mutedText(context),
                  size: 18,
                );
              }),
            ),
            const SizedBox(height: 10),
            Text(
              name,
              style: TextStyle(
                color: AppColors.mutedText(context),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _section({required List<Widget> children}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);

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

  Widget _softDivider() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
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
}
