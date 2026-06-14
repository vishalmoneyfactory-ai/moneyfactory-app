import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/gold_button.dart';

class CourseDetailScreen extends StatelessWidget {
  const CourseDetailScreen({super.key, required this.courseId});

  final String courseId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Course')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: api.course(courseId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            );
          }
          final course = snapshot.data!['course'] as Map<String, dynamic>;
          final videos = (course['videos'] as List<dynamic>? ?? []);
          final owned = course['isOwned'] == true;
          final expired = course['access']?['isExpired'] == true;
          final isFree = course['isFree'] == true;
          final thumbnail = api.mediaUrl(course['thumbnail'] as String?);
          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                children: [
                  Container(
                    height: 190,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: AppColors.surface(context),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.line(context)),
                    ),
                    child: thumbnail.isEmpty
                        ? Center(
                            child: Icon(
                              Icons.candlestick_chart,
                              color: AppColors.gold,
                              size: 64,
                            ),
                          )
                        : CachedNetworkImage(
                            imageUrl: thumbnail,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorWidget: (context, url, error) => Center(
                              child: Icon(
                                Icons.candlestick_chart,
                                color: AppColors.gold,
                                size: 64,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    course['title'],
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _priceRow(context, course),
                  if (course['access'] != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _accessLabel(course['access']),
                      style: TextStyle(
                        color: expired
                            ? AppColors.error
                            : AppColors.mutedText(context),
                        fontWeight: expired ? FontWeight.w800 : FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    course['shortDescription'] ?? '',
                    style: TextStyle(
                      color: AppColors.mutedText(context),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ExpansionTile(
                    title: const Text("What you'll learn"),
                    initiallyExpanded: true,
                    children: (course['outcomes'] as List<dynamic>? ?? [])
                        .map(
                          (o) => ListTile(
                            leading: const Icon(
                              Icons.check,
                              color: AppColors.success,
                            ),
                            title: Text(o.toString()),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Videos',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  ...videos.map(
                    (v) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppColors.card(context),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.line(context)),
                      ),
                      child: ListTile(
                        leading: Icon(
                          v['isFreePreview'] == true || owned
                              ? Icons.play_circle
                              : Icons.lock,
                          color: v['isFreePreview'] == true || owned
                              ? AppColors.gold
                              : AppColors.mutedText(context),
                        ),
                        title: Text(v['title']),
                        subtitle: Text(durationLabel(v['duration'] ?? 0)),
                        onTap: v['isFreePreview'] == true || owned
                            ? () => context.push(
                                '/video/${v['_id']}?course=$courseId',
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    course['description'] ?? '',
                    style: TextStyle(
                      color: AppColors.mutedText(context),
                      height: 1.6,
                    ),
                  ),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card(context),
                    border: Border(
                      top: BorderSide(color: AppColors.line(context)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _priceRow(context, course, compact: true),
                      ),
                      Expanded(
                        child: GoldButton(
                          label: owned
                              ? 'Start Learning'
                              : expired
                              ? 'Repurchase Required'
                              : isFree
                              ? 'Unlock Free'
                              : 'Buy Now',
                          color: owned ? AppColors.success : null,
                          onPressed: () async {
                            if (owned) {
                              try {
                                final list = await api.courseVideos(courseId);
                                if (!context.mounted) return;
                                if (list.isNotEmpty) {
                                  context.push(
                                    '/video/${list.first['_id']}?course=$courseId',
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'No videos are added to this course yet',
                                      ),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(e.toString()),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              }
                            } else if (isFree) {
                              try {
                                await api.unlockFreeCourse(courseId);
                                if (context.mounted) {
                                  context.go('/learning');
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(e.toString()),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              }
                            } else {
                              context.push('/checkout/$courseId');
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _priceRow(
    BuildContext context,
    Map<String, dynamic> course, {
    bool compact = false,
  }) {
    if (course['isFree'] == true) {
      return Text(
        'FREE',
        style: TextStyle(
          color: AppColors.success,
          fontFamily: 'JetBrains Mono',
          fontSize: compact ? 20 : 25,
          fontWeight: FontWeight.w900,
        ),
      );
    }
    if (course['hasOffer'] != true) {
      return Text(
        money(course['price'] ?? 0),
        style: TextStyle(
          color: AppColors.gold,
          fontFamily: 'JetBrains Mono',
          fontSize: compact ? 20 : 25,
          fontWeight: FontWeight.w900,
        ),
      );
    }
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: [
        Text(
          money(course['originalPrice'] ?? course['price'] ?? 0),
          style: TextStyle(
            color: AppColors.mutedText(context),
            fontFamily: 'JetBrains Mono',
            decoration: TextDecoration.lineThrough,
            decorationColor: AppColors.mutedText(context),
            fontSize: compact ? 13 : 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          money(course['effectivePrice'] ?? course['price'] ?? 0),
          style: TextStyle(
            color: AppColors.gold,
            fontFamily: 'JetBrains Mono',
            fontSize: compact ? 20 : 26,
            fontWeight: FontWeight.w900,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: .15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${course['offerPercent'] ?? 0}% OFF',
            style: const TextStyle(
              color: AppColors.success,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  String _accessLabel(Map<String, dynamic> access) {
    if (access['isExpired'] == true)
      return 'Course Expired - Repurchase Required.';
    final days = access['daysRemaining'];
    if (days is num) return '$days Days Remaining';
    final expiry = access['expiryDate'];
    if (expiry != null)
      return 'Expiry Date: ${expiry.toString().split('T').first}';
    if (access['isOwned'] == true) return 'Lifetime Access';
    return '';
  }
}
