import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../../core/api/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/motion.dart';

class EarnScreen extends StatefulWidget {
  const EarnScreen({super.key});

  @override
  State<EarnScreen> createState() => _EarnScreenState();
}

class _EarnScreenState extends State<EarnScreen> {
  static const _assetVideoPath = 'assets/videos/earn_explainer.mp4';

  late Future<Map<String, dynamic>> _userFuture;
  VideoPlayerController? _controller;
  bool _loadingVideo = false;
  String? _videoError;
  bool _showControls = true;
  Timer? _hideTimer;

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    _hideTimer?.cancel();
    if (_showControls && _controller?.value.isPlaying == true) {
      _hideTimer = Timer(const Duration(seconds: 3), () {
        if (mounted && _controller?.value.isPlaying == true) {
          setState(() => _showControls = false);
        }
      });
    }
  }

  void _togglePlay() {
    final controller = _controller;
    if (controller == null) return;
    if (controller.value.isPlaying) {
      controller.pause();
      setState(() => _showControls = true);
      _hideTimer?.cancel();
    } else {
      controller.play();
      setState(() => _showControls = false);
      _hideTimer?.cancel();
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0 ? '${duration.inHours}:$minutes:$seconds' : '$minutes:$seconds';
  }

  void _seekBy(int seconds) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final targetMs = controller.value.position.inMilliseconds + (seconds * 1000);
    final maxMs = controller.value.duration.inMilliseconds;
    controller.seekTo(Duration(milliseconds: targetMs.clamp(0, maxMs).toInt()));
    setState(() => _showControls = true);
    _hideTimer?.cancel();
    if (controller.value.isPlaying) {
      _hideTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showControls = false);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _userFuture = api.me();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _userFuture = api.me());
    await _userFuture;
  }

  Future<void> _playEarnVideo() async {
    if (_controller != null) {
      if (_controller!.value.isPlaying) {
        await _controller!.pause();
      } else {
        await _controller!.play();
      }
      if (mounted) setState(() {});
      return;
    }

    setState(() {
      _loadingVideo = true;
      _videoError = null;
    });
    try {
      final data = await api.earnVideo();
      final url = data['sources']?['url720'] ?? data['sources']?['url480'];
      if (url == null) throw Exception('Earn video source is missing');
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      await _startController(controller);
    } catch (e) {
      final playedAsset = await _tryAssetVideo();
      if (mounted && !playedAsset) {
        setState(() => _videoError = _videoMessage(e));
      }
    } finally {
      if (mounted) setState(() => _loadingVideo = false);
    }
  }

  Future<void> _startController(VideoPlayerController controller) async {
    await controller.initialize();
    await controller.play();
    if (!mounted) {
      await controller.dispose();
      return;
    }
    setState(() {
      _controller = controller;
      _showControls = false;
    });
  }

  Future<bool> _tryAssetVideo() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      if (!manifest.listAssets().contains(_assetVideoPath)) return false;
      final controller = VideoPlayerController.asset(_assetVideoPath);
      await _startController(controller);
      return true;
    } catch (_) {
      return false;
    }
  }

  String _videoMessage(Object error) {
    if (error is DioException) {
      final message = error.response?.data is Map
          ? error.response?.data['message']?.toString()
          : null;
      if (error.response?.statusCode == 404) {
        return 'Earn video is not added yet. Add Bunny video IDs in Admin Settings or add assets/videos/earn_explainer.mp4.';
      }
      return message ?? 'Unable to load the earn video. Please try again.';
    }
    return error.toString().replaceAll('Exception: ', '');
  }

  Future<void> _copy(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Referral code copied'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _share(String code) async {
    final message =
        '''
Join Money Factory and learn professional trading.

Use my referral code: $code

Earn with Money Factory.
''';
    final url = 'https://wa.me/?text=${Uri.encodeComponent(message)}';
    if (!await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        ) &&
        mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open sharing'),
          backgroundColor: AppColors.error,
        ),
      );
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
          child: FutureBuilder<Map<String, dynamic>>(
            future: _userFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return CustomScrollView(
                  slivers: [
                    _floatingAppBar(),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                      sliver: SliverList.list(
                        children: const [
                          ShimmerLine(height: 220, radius: 28),
                          SizedBox(height: 28),
                          ShimmerLine(width: 240, height: 34),
                          SizedBox(height: 14),
                          ShimmerLine(height: 20),
                          SizedBox(height: 10),
                          ShimmerLine(height: 20),
                        ],
                      ),
                    ),
                  ],
                );
              }
              final user = snapshot.data!;
              final code = (user['referralCode'] ?? '').toString();
              final wallet = user['walletBalance'] as num? ?? 0;
              final referrals = user['totalReferrals'] as num? ?? 0;

              return CustomScrollView(
                slivers: [
                  _floatingAppBar(),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                    sliver: SliverList.list(
                      children: [
                        FadeSlideIn(child: _videoHero()),
                        const SizedBox(height: 32),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 90),
                          child: _programInfo(),
                        ),
                        const SizedBox(height: 30),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 150),
                          child: _wallet(wallet, referrals),
                        ),
                        const SizedBox(height: 26),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 210),
                          child: _referralTools(code),
                        ),
                        const SizedBox(height: 30),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 270),
                          child: _referralTable(),
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

  Widget _videoHero() {
    final controller = _controller;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AspectRatio(
          aspectRatio: controller?.value.isInitialized == true
              ? controller!.value.aspectRatio
              : 16 / 9,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: AppColors.surface(context)),
                if (controller?.value.isInitialized == true)
                  GestureDetector(
                    onTap: _toggleControls,
                    child: VideoPlayer(controller!),
                  )
                else
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.neonBlue.withValues(alpha: .25),
                          AppColors.violet.withValues(alpha: .20),
                          AppColors.themeGold(context).withValues(alpha: .12),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _videoError ?? 'Earn Explainer',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.text(context),
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                if (controller?.value.isInitialized == true)
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: !_showControls,
                      child: AnimatedOpacity(
                        opacity: _showControls ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: .4),
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      iconSize: 42,
                                      color: AppColors.themeGold(context),
                                      icon: const Icon(Icons.replay_10),
                                      onPressed: () => _seekBy(-10),
                                    ),
                                    const SizedBox(width: 24),
                                    InkWell(
                                      onTap: _togglePlay,
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 220),
                                        width: 74,
                                        height: 74,
                                        decoration: BoxDecoration(
                                          color: AppColors.themeGold(context).withValues(alpha: .92),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.themeGold(context).withValues(alpha: .35),
                                              blurRadius: 28,
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          controller!.value.isPlaying
                                              ? Icons.pause
                                              : Icons.play_arrow,
                                          color: AppColors.primaryBg,
                                          size: 42,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    IconButton(
                                      iconSize: 42,
                                      color: AppColors.themeGold(context),
                                      icon: const Icon(Icons.forward_10),
                                      onPressed: () => _seekBy(10),
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                left: 16,
                                right: 16,
                                bottom: 12,
                                child: ValueListenableBuilder<VideoPlayerValue>(
                                  valueListenable: controller,
                                  builder: (context, value, child) {
                                    return Row(
                                      children: [
                                        Text(
                                          _formatDuration(value.position),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: VideoProgressIndicator(
                                            controller,
                                            allowScrubbing: true,
                                            colors: VideoProgressColors(
                                              playedColor: AppColors.themeGold(context),
                                              bufferedColor: Colors.white24,
                                              backgroundColor: Colors.white12,
                                            ),
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          _formatDuration(value.duration),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                else if (_loadingVideo)
                  Positioned.fill(
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.themeGold(context)),
                    ),
                  )
                else
                  Positioned.fill(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _playEarnVideo,
                        child: Center(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            width: 74,
                            height: 74,
                            decoration: BoxDecoration(
                              color: AppColors.themeGold(context).withValues(alpha: .92),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.themeGold(context).withValues(alpha: .35),
                                  blurRadius: 28,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              color: AppColors.primaryBg,
                              size: 42,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _programInfo() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _kicker('Program Flow'),
      Text(
        'Promote & Earn Program',
        style: TextStyle(
          color: AppColors.text(context),
          fontSize: 32,
          height: 1,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 18),
      _step(
        'Create your referral code',
        'Your code is ready inside Money Factory.',
      ),
      _step('Suggest it to a friend', 'Help them choose a course or bundle.'),
      _step('Share the code', 'They enter your code while buying.'),
      _step(
        'Earn the reward',
        'Get Rs 300 on course sales and Rs 1000 on bundle sales.',
      ),
      _step(
        'Get Instant Cashback',
        'Receive your earnings instantly in your wallet after every successful referral.',
      ),
      const SizedBox(height: 14),
      Text(
        'Earn rewards on each qualifying sale.',
        style: TextStyle(
          color: AppColors.themeGold(context),
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );

  Widget _step(String title, String body) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 9,
          height: 9,
          margin: const EdgeInsets.only(top: 7),
          decoration: const BoxDecoration(
            color: AppColors.neonBlue,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 14),
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
              const SizedBox(height: 4),
              Text(
                body,
                style: TextStyle(
                  color: AppColors.mutedText(context),
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _wallet(num wallet, num referrals) => Row(
    children: [
      Expanded(child: _metric('Wallet Balance', wallet, prefix: 'Rs ')),
      Expanded(child: _metric('Referrals', referrals)),
    ],
  );

  Widget _metric(String label, num value, {String prefix = ''}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      CountUpNumber(
        value: value,
        prefix: prefix,
        style: TextStyle(
          color: AppColors.themeGold(context),
          fontFamily: 'JetBrains Mono',
          fontSize: 28,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        label,
        style: TextStyle(
          color: AppColors.mutedText(context),
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );

  Widget _referralTools(String code) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _kicker('Your Code'),
      Row(
        children: [
          Expanded(
            child: Text(
              code.isEmpty ? '-' : code,
              style: TextStyle(
                color: AppColors.text(context),
                fontSize: 34,
                fontFamily: 'JetBrains Mono',
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          IconButton.filledTonal(
            onPressed: code.isEmpty ? null : () => _copy(code),
            icon: const Icon(Icons.copy),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            onPressed: code.isEmpty ? null : () => _share(code),
            icon: const Icon(Icons.share),
          ),
        ],
      ),
      const SizedBox(height: 10),
      Text(
        'Share this code with your network. Rewards are credited to your digital wallet after successful payment confirmation.',
        style: TextStyle(color: AppColors.mutedText(context), height: 1.5),
      ),
    ],
  );

  Widget _referralTable() {
    const data = [
      {'course': 'Basics of forex', 'price': 'Free', 'referral': 'N/A'},
      {'course': 'Candlestick & chart', 'price': '1999', 'referral': '300'},
      {'course': 'Smart Money Concept', 'price': '1999', 'referral': '300'},
      {'course': 'Candle range theory', 'price': '1999', 'referral': '300'},
      {'course': 'Liquidity concept', 'price': '1999', 'referral': '300'},
      {'course': 'Money factory indicator', 'price': '4999', 'referral': '1000'},
      {'course': 'Bundle Course', 'price': '12999', 'referral': '2000'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _kicker('Reward Structure'),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.line(context)),
            borderRadius: BorderRadius.circular(12),
            color: AppColors.surface(context),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Table(
              border: TableBorder(
                horizontalInside: BorderSide(color: AppColors.line(context)),
                verticalInside: BorderSide(color: AppColors.line(context)),
              ),
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1.2),
                2: FlexColumnWidth(1.2),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: AppColors.card(context)),
                  children: [
                    _tableHeader('Course'),
                    _tableHeader('Price'),
                    _tableHeader('Reward'),
                  ],
                ),
                ...data.map((item) => TableRow(
                      children: [
                        _tableCell(item['course']!, isMain: true),
                        _tableCell(item['price'] == 'Free' ? 'Free' : 'Rs ${item['price']}'),
                        _tableCell(item['referral'] == 'N/A' ? '-' : 'Rs ${item['referral']}', isGold: item['referral'] != 'N/A'),
                      ],
                    )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _tableHeader(String text) => Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          text,
          style: TextStyle(
            color: AppColors.mutedText(context),
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      );

  Widget _tableCell(String text, {bool isMain = false, bool isGold = false}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Text(
          text,
          style: TextStyle(
            color: isGold ? AppColors.themeGold(context) : (isMain ? AppColors.text(context) : AppColors.mutedText(context)),
            fontWeight: isMain || isGold ? FontWeight.w700 : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      );

  Widget _kicker(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text.toUpperCase(),
      style: TextStyle(
        color: AppColors.themeGold(context),
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
      ),
    ),
  );

  SliverAppBar _floatingAppBar() {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: AppColors.isDark(context) 
          ? AppColors.bg(context).withValues(alpha: .86)
          : AppColors.card(context),
      surfaceTintColor: Colors.transparent,
      title: Text(
        'Promote & Earn',
        style: TextStyle(
          color: AppColors.text(context),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}