import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:video_player/video_player.dart';

import '../../../core/api/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key, required this.videoId, required this.courseId});

  final String videoId;
  final String courseId;

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _controller;
  Map<String, dynamic>? _stream;
  List<dynamic> _videos = [];
  List<dynamic> _progress = [];
  Timer? _localTimer;
  Timer? _remoteTimer;
  Timer? _hideTimer;
  String _quality = '720p';
  double _speed = 1.0;
  bool _playing = true;
  bool _showControls = true;
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _localTimer?.cancel();
    _remoteTimer?.cancel();
    _hideTimer?.cancel();
    _controller?.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _load() async {
    final stream = await api.streamUrl(widget.videoId);
    final videos = widget.courseId.isEmpty ? <dynamic>[] : await api.courseVideos(widget.courseId);
    final progress = widget.courseId.isEmpty ? <dynamic>[] : await api.progressCourse(widget.courseId);
    if (mounted) {
      setState(() {
        _stream = stream;
        _videos = videos;
        _progress = progress;
      });
    }
    await _buildPlayer(stream['sources']['url720'] ?? stream['sources']['url480'] ?? '');
  }

  Future<void> _buildPlayer(String url) async {
    if (url.isEmpty) return;
    _localTimer?.cancel();
    _remoteTimer?.cancel();
    await _controller?.dispose();
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(url),
      httpHeaders: {'Referer': 'https://moneyfactory.app/'},
    );
    await controller.initialize();
    await controller.setPlaybackSpeed(_speed);
    await controller.play();
    controller.addListener(() {
      if (mounted) setState(() {});
    });
    if (mounted) {
      setState(() {
        _controller = controller;
        _playing = true;
      });
    }
    _localTimer = Timer.periodic(const Duration(seconds: 10), (_) => _saveProgress(localOnly: true));
    _remoteTimer = Timer.periodic(const Duration(seconds: 30), (_) => _saveProgress());
    _startHideTimer();
  }

  Future<void> _saveProgress({bool localOnly = false}) async {
    final value = _controller?.value;
    if (value == null || !value.isInitialized) return;
    final watched = value.position.inSeconds;
    final total = value.duration.inSeconds;
    await Hive.box('progress').put(widget.videoId, {'watchedSeconds': watched, 'totalSeconds': total, 'savedAt': DateTime.now().toIso8601String()});
    if (!localOnly) await api.updateProgress({'videoId': widget.videoId, 'watchedSeconds': watched, 'totalSeconds': total});
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    if (mounted) {
      setState(() => _showControls = true);
      _hideTimer = Timer(const Duration(seconds: 3), () {
        if (mounted && _playing) setState(() => _showControls = false);
      });
    }
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _startHideTimer();
  }

  Future<void> _togglePlay() async {
    final controller = _controller;
    if (controller == null) return;
    if (controller.value.isPlaying) {
      await controller.pause();
      setState(() => _playing = false);
      _hideTimer?.cancel();
      setState(() => _showControls = true);
    } else {
      await controller.play();
      setState(() => _playing = true);
      _startHideTimer();
    }
  }

  Future<void> _seekBy(int seconds) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final targetMs = controller.value.position.inMilliseconds + (seconds * 1000);
    final maxMs = controller.value.duration.inMilliseconds;
    await controller.seekTo(Duration(milliseconds: targetMs.clamp(0, maxMs).toInt()));
    _startHideTimer();
  }

  Future<void> _setSpeed(double speed) async {
    final controller = _controller;
    if (controller == null) return;
    await controller.setPlaybackSpeed(speed);
    setState(() => _speed = speed);
    if (mounted) Navigator.pop(context);
    _startHideTimer();
  }

  Future<void> _switchQuality(String quality) async {
    if (_stream == null) return;
    final previousPosition = _controller?.value.position ?? Duration.zero;
    final wasPlaying = _controller?.value.isPlaying ?? true;
    setState(() => _quality = quality);
    final source = quality == '480p' ? _stream!['sources']['url480'] : _stream!['sources']['url720'];
    if (mounted) Navigator.pop(context);
    await _buildPlayer(source);
    await _controller?.seekTo(previousPosition);
    if (!wasPlaying) await _controller?.pause();
    if (mounted) setState(() => _playing = _controller?.value.isPlaying ?? false);
  }

  void _toggleFullscreen() {
    setState(() => _isFullscreen = !_isFullscreen);
    if (_isFullscreen) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    _startHideTimer();
  }

  void _showSettings() {
    _hideTimer?.cancel();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _settingsSheet(),
    ).then((_) => _startHideTimer());
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

  double _completion(String videoId) {
    final saved = Hive.box('progress').get(videoId);
    final remote = _progress.where((p) => p['videoId'] == videoId).firstOrNull;
    final target = saved ?? remote;
    if (target == null) return 0;
    final watched = (target['watchedSeconds'] ?? 0) as num;
    final total = (target['totalSeconds'] ?? 1) as num;
    return total == 0 ? 0 : (watched / total).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    if (_isFullscreen) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: _player(isFullScreen: true)),
      );
    }

    final current = _videos.cast<dynamic>().where((v) => v['_id'] == widget.videoId).firstOrNull;
    return Scaffold(
      appBar: AppBar(
        title: Text(current?['title'] ?? 'Video', style: const TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: AppColors.isDark(context) ? AppColors.bg(context) : AppColors.card(context),
        surfaceTintColor: Colors.transparent,
      ),
      body: _controller == null || !_controller!.value.isInitialized
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _player(isFullScreen: false),
                const SizedBox(height: 16),
                Text(
                  current?['title'] ?? _stream?['video']?['title'] ?? '',
                  style: TextStyle(color: AppColors.text(context), fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(value: _completion(widget.videoId), backgroundColor: AppColors.line(context), color: AppColors.gold),
                const SizedBox(height: 24),
                Text('Course Content', style: TextStyle(color: AppColors.text(context), fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                ..._videos.map((v) {
                  final active = v['_id'] == widget.videoId;
                  final done = _completion(v['_id']) >= .9;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppColors.card(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: active ? AppColors.gold : AppColors.line(context)),
                    ),
                    child: ListTile(
                      leading: Icon(done ? Icons.check_circle : Icons.play_circle_outline, color: done ? AppColors.success : AppColors.gold),
                      title: Text(v['title'], style: TextStyle(color: AppColors.text(context), fontWeight: active ? FontWeight.w800 : FontWeight.w600)),
                      subtitle: Text(durationLabel(v['duration'] ?? 0), style: TextStyle(color: AppColors.mutedText(context))),
                    ),
                  );
                }),
                const SizedBox(height: 40),
              ],
            ),
    );
  }

  Widget _player({required bool isFullScreen}) {
    final controller = _controller!;
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: isFullScreen ? BorderRadius.zero : BorderRadius.circular(16),
        border: isFullScreen ? null : Border.all(color: AppColors.line(context)),
      ),
      clipBehavior: Clip.hardEdge,
      width: double.infinity,
      child: AspectRatio(
        aspectRatio: isFullScreen ? MediaQuery.of(context).size.aspectRatio : controller.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: _toggleControls,
              child: isFullScreen ? Center(child: AspectRatio(aspectRatio: controller.value.aspectRatio, child: VideoPlayer(controller))) : VideoPlayer(controller),
            ),
            if (_showControls) ...[
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black87, Colors.black26, Colors.transparent, Colors.black45, Colors.black87],
                        stops: [0.0, 0.2, 0.5, 0.8, 1.0],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white, size: 28),
                  onPressed: _showSettings,
                ),
              ),
              Positioned(
                left: 16,
                top: 16,
                child: isFullScreen ? IconButton(
                  icon: const Icon(Icons.fullscreen_exit, color: Colors.white, size: 28),
                  onPressed: _toggleFullscreen,
                ) : const SizedBox.shrink(),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _control(Icons.replay_10, () => _seekBy(-10)),
                  const SizedBox(width: 32),
                  _control(_playing ? Icons.pause : Icons.play_arrow, _togglePlay, large: true),
                  const SizedBox(width: 32),
                  _control(Icons.forward_10, () => _seekBy(10)),
                ],
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 12,
                child: Row(
                  children: [
                    Text(_formatDuration(controller.value.position), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: VideoProgressIndicator(
                        controller,
                        allowScrubbing: true,
                        colors: VideoProgressColors(playedColor: AppColors.gold, bufferedColor: Colors.white30, backgroundColor: Colors.white12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(_formatDuration(controller.value.duration), style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(width: 8),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen, color: Colors.white, size: 24),
                      onPressed: _toggleFullscreen,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _control(IconData icon, VoidCallback onTap, {bool large = false}) => Material(
    color: Colors.black45,
    shape: const CircleBorder(),
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(large ? 16.0 : 12.0),
        child: Icon(icon, color: Colors.white, size: large ? 36 : 24),
      ),
    ),
  );

  Widget _settingsSheet() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 24, 20, MediaQuery.of(context).padding.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Text('Playback Settings', style: TextStyle(color: AppColors.text(context), fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 24),
          Text('Quality', style: TextStyle(color: AppColors.mutedText(context), fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(
            children: ['480p', '720p'].map((q) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ChoiceChip(
                label: Text(q, style: TextStyle(fontWeight: FontWeight.w600, color: _quality == q ? AppColors.primaryBg : AppColors.text(context))),
                selected: _quality == q,
                selectedColor: AppColors.gold,
                backgroundColor: AppColors.card(context),
                onSelected: (_) => _switchQuality(q),
              ),
            )).toList(),
          ),
          const SizedBox(height: 24),
          Text('Playback Speed', style: TextStyle(color: AppColors.mutedText(context), fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            children: [0.5, 1.0, 1.5, 2.0].map((s) {
              final label = s == 1.0 ? '1x (Normal)' : '${s}x';
              return ChoiceChip(
                label: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: _speed == s ? AppColors.primaryBg : AppColors.text(context))),
                selected: _speed == s,
                selectedColor: AppColors.gold,
                backgroundColor: AppColors.card(context),
                onSelected: (_) => _setSpeed(s),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    ),
    );
  }
}
