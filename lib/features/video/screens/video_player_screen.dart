import 'dart:async';

import 'package:flutter/material.dart';
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
  String _quality = '720p';
  double _speed = 1;
  bool _playing = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _localTimer?.cancel();
    _remoteTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final stream = await api.streamUrl(widget.videoId);
    final videos = widget.courseId.isEmpty ? <dynamic>[] : await api.courseVideos(widget.courseId);
    final progress = widget.courseId.isEmpty ? <dynamic>[] : await api.progressCourse(widget.courseId);
    setState(() {
      _stream = stream;
      _videos = videos;
      _progress = progress;
    });
    await _buildPlayer(stream['sources']['url720']);
  }

  Future<void> _buildPlayer(String url) async {
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
    setState(() {
      _controller = controller;
      _playing = true;
    });
    _localTimer = Timer.periodic(const Duration(seconds: 10), (_) => _saveProgress(localOnly: true));
    _remoteTimer = Timer.periodic(const Duration(seconds: 30), (_) => _saveProgress());
  }

  Future<void> _saveProgress({bool localOnly = false}) async {
    final value = _controller?.value;
    if (value == null || !value.isInitialized) return;
    final watched = value.position.inSeconds;
    final total = value.duration.inSeconds;
    await Hive.box('progress').put(widget.videoId, {'watchedSeconds': watched, 'totalSeconds': total, 'savedAt': DateTime.now().toIso8601String()});
    if (!localOnly) await api.updateProgress({'videoId': widget.videoId, 'watchedSeconds': watched, 'totalSeconds': total});
  }

  Future<void> _switchQuality(String quality) async {
    if (_stream == null) return;
    final previousPosition = _controller?.value.position ?? Duration.zero;
    final wasPlaying = _controller?.value.isPlaying ?? true;
    setState(() => _quality = quality);
    final source = quality == '480p' ? _stream!['sources']['url480'] : _stream!['sources']['url720'];
    await _buildPlayer(source);
    await _controller?.seekTo(previousPosition);
    if (!wasPlaying) await _controller?.pause();
    if (mounted) setState(() => _playing = _controller?.value.isPlaying ?? false);
  }

  Future<void> _togglePlay() async {
    final controller = _controller;
    if (controller == null) return;
    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }
    setState(() => _playing = controller.value.isPlaying);
  }

  Future<void> _seekBy(int seconds) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final targetMs = controller.value.position.inMilliseconds + (seconds * 1000);
    final maxMs = controller.value.duration.inMilliseconds;
    await controller.seekTo(Duration(milliseconds: targetMs.clamp(0, maxMs).toInt()));
  }

  Future<void> _setSpeed(double speed) async {
    final controller = _controller;
    if (controller == null) return;
    await controller.setPlaybackSpeed(speed);
    setState(() => _speed = speed);
  }

  @override
  Widget build(BuildContext context) {
    final current = _videos.cast<dynamic>().where((v) => v['_id'] == widget.videoId).firstOrNull;
    return Scaffold(
      appBar: AppBar(title: Text(current?['title'] ?? 'Video')),
      body: _controller == null || !_controller!.value.isInitialized
          ? Center(child: CircularProgressIndicator(color: AppColors.gold))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _player(),
                const SizedBox(height: 16),
                Text(current?['title'] ?? _stream?['video']?['title'] ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                LinearProgressIndicator(value: _completion(widget.videoId), backgroundColor: AppColors.border, color: AppColors.gold),
                const SizedBox(height: 18),
                const Text('Course Videos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                ..._videos.map((v) {
                  final active = v['_id'] == widget.videoId;
                  final done = _completion(v['_id']) >= .9;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: active ? AppColors.gold : AppColors.border)),
                    child: ListTile(
                      leading: Icon(done ? Icons.check_circle : Icons.play_circle_outline, color: done ? AppColors.success : AppColors.gold),
                      title: Text(v['title']),
                      subtitle: Text(durationLabel(v['duration'] ?? 0)),
                    ),
                  );
                }),
              ],
            ),
    );
  }

  Widget _player() {
    final controller = _controller!;
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border), color: AppColors.primaryBg),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(aspectRatio: controller.value.aspectRatio, child: VideoPlayer(controller)),
          Positioned.fill(child: InkWell(onTap: _togglePlay, child: Center(child: AnimatedOpacity(opacity: _playing ? 0 : 1, duration: Duration(milliseconds: 200), child: Icon(Icons.play_circle_fill, color: AppColors.gold, size: 72))))),
          Positioned(right: 8, top: 8, child: DecoratedBox(decoration: BoxDecoration(color: AppColors.primaryBg.withValues(alpha: .72), borderRadius: BorderRadius.circular(8)), child: Row(children: ['480p', '720p'].map((q) => Padding(padding: EdgeInsets.only(left: 6), child: ChoiceChip(label: Text(q), selected: _quality == q, selectedColor: AppColors.gold, onSelected: (_) => _switchQuality(q)))).toList()))),
          Positioned(left: 12, right: 12, bottom: 20, child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _control(Icons.replay_10, () => _seekBy(-10)),
              const SizedBox(width: 14),
              _control(_playing ? Icons.pause_circle_filled : Icons.play_circle_fill, _togglePlay, large: true),
              const SizedBox(width: 14),
              _control(Icons.forward_10, () => _seekBy(10)),
            ]),
            const SizedBox(height: 8),
            Wrap(spacing: 6, alignment: WrapAlignment.center, children: [0.5, 1.0, 1.5, 2.0].map((s) {
              final label = s == 1.0 ? '1x' : '${s}x';
              return ChoiceChip(label: Text(label), selected: _speed == s, selectedColor: AppColors.gold, onSelected: (_) => _setSpeed(s));
            }).toList()),
          ])),
          const Positioned(left: 12, top: 12, child: Opacity(opacity: .28, child: Text('student@moneyfactory', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700)))),
          Positioned(left: 0, right: 0, bottom: 0, child: VideoProgressIndicator(controller, allowScrubbing: true, colors: VideoProgressColors(playedColor: AppColors.gold, bufferedColor: AppColors.muted, backgroundColor: AppColors.border))),
        ],
      ),
    );
  }

  Widget _control(IconData icon, VoidCallback onTap, {bool large = false}) => Material(
    color: AppColors.primaryBg.withValues(alpha: .72),
    shape: const CircleBorder(),
    child: IconButton(
      iconSize: large ? 44 : 30,
      color: AppColors.gold,
      onPressed: onTap,
      icon: Icon(icon),
    ),
  );

  double _completion(String videoId) {
    final p = _progress.cast<dynamic>().where((row) => row['video']?['_id'] == videoId || row['video'] == videoId).firstOrNull;
    final watched = (p?['watchedSeconds'] ?? 0) as num;
    final total = (p?['totalSeconds'] ?? p?['video']?['duration'] ?? 0) as num;
    if (total <= 0) return 0;
    return (watched / total).clamp(0, 1).toDouble();
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
