import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/motion.dart';

class CourseDetailScreen extends StatelessWidget {
  const CourseDetailScreen({super.key, required this.courseId});

  final String courseId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.pageGradient(context)),
        child: FutureBuilder<Map<String, dynamic>>(
          future: api.course(courseId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return CustomScrollView(
                slivers: [
                  _floatingAppBar(context),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                    sliver: SliverList.list(
                      children: const [
                        ShimmerLine(height: 220, radius: 28),
                        SizedBox(height: 24),
                        ShimmerLine(height: 34, width: 200),
                        SizedBox(height: 12),
                        ShimmerLine(height: 24, width: 120),
                        SizedBox(height: 24),
                        ShimmerLine(height: 18),
                        SizedBox(height: 8),
                        ShimmerLine(height: 18),
                        SizedBox(height: 8),
                        ShimmerLine(height: 18),
                        SizedBox(height: 32),
                        ShimmerLine(height: 60, radius: 18),
                        SizedBox(height: 12),
                        ShimmerLine(height: 60, radius: 18),
                      ],
                    ),
                  ),
                ],
              );
            }

            final course = snapshot.data!['course'] as Map<String, dynamic>;
            final videos = (course['videos'] as List<dynamic>? ?? []);
            final owned = course['isOwned'] == true;
            final expired = course['access']?['isExpired'] == true;
            final isFree = course['isFree'] == true;
            final thumbnail = api.mediaUrl(course['thumbnail'] as String?);
            final outcomes = course['outcomes'] as List<dynamic>? ?? [];

            return Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    _floatingAppBar(context),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 140),
                      sliver: SliverList.list(
                        children: [
                          FadeSlideIn(
                            child: _heroThumbnail(context, thumbnail),
                          ),
                          const SizedBox(height: 24),
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 60),
                            child: Text(
                              course['title'],
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                height: 1.1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 100),
                            child: _priceRow(context, course),
                          ),
                          if (course['access'] != null) ...[
                            const SizedBox(height: 10),
                            FadeSlideIn(
                              delay: const Duration(milliseconds: 140),
                              child: _accessBadge(context, course['access']),
                            ),
                          ],
                          const SizedBox(height: 20),
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 180),
                            child: Text(
                              course['shortDescription'] ?? '',
                              style: TextStyle(
                                color: AppColors.mutedText(context),
                                height: 1.6,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (outcomes.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            FadeSlideIn(
                              delay: const Duration(milliseconds: 220),
                              child: _outcomesCard(context, outcomes),
                            ),
                          ],
                          const SizedBox(height: 32),
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 260),
                            child: _sectionKicker('Curriculum'),
                          ),
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 260),
                            child: const Text(
                              'Videos',
                              style: TextStyle(
                                fontSize: 31,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...videos.asMap().entries.map(
                            (entry) => FadeSlideIn(
                              delay: Duration(
                                milliseconds: 300 + (entry.key * 60),
                              ),
                              child: _videoTile(
                                context,
                                entry.value,
                                courseId,
                                owned: owned,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 600),
                            child: _sectionKicker('About'),
                          ),
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 600),
                            child: const Text(
                              'Detailed Description',
                              style: TextStyle(
                                fontSize: 31,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 640),
                            child: Text(
                              course['description'] ?? '',
                              style: TextStyle(
                                color: AppColors.mutedText(context),
                                height: 1.6,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Floating Frosted Bottom Bar
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: ClipRRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        padding: EdgeInsets.fromLTRB(
                          20,
                          16,
                          20,
                          MediaQuery.of(context).padding.bottom + 16,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.bg(context).withValues(alpha: .7),
                          border: Border(
                            top: BorderSide(
                              color: AppColors.gold.withValues(alpha: .2),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: _priceRow(context, course, compact: true),
                            ),
                            Expanded(
                              flex: 5,
                              child: _actionButton(
                                context,
                                course,
                                courseId,
                                owned,
                                isFree,
                                expired,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  SliverAppBar _floatingAppBar(BuildContext context) {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: AppColors.isDark(context) 
          ? AppColors.bg(context).withValues(alpha: .86)
          : AppColors.card(context),
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home');
          }
        },
      ),
      title: Text(
        'Course Details',
        style: TextStyle(
          color: AppColors.text(context),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _heroThumbnail(BuildContext context, String thumbnail) {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            AppColors.gold.withValues(alpha: .38),
            AppColors.neonBlue.withValues(alpha: .14),
            Colors.transparent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: .08),
            blurRadius: 38,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      padding: const EdgeInsets.all(1.6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(27),
        child: ColoredBox(
          color: AppColors.surface(context),
          child: thumbnail.isEmpty
              ? Center(
                  child: Icon(
                    Icons.school,
                    color: AppColors.gold.withValues(alpha: .4),
                    size: 80,
                  ),
                )
              : CachedNetworkImage(
                  imageUrl: thumbnail,
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                ),
        ),
      ),
    );
  }

  Widget _outcomesCard(BuildContext context, List<dynamic> outcomes) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface(context).withValues(alpha: .6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.line(context)),
        ),
        child: ExpansionTile(
          title: const Text(
            "What you'll learn",
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
          ),
          initiallyExpanded: true,
          iconColor: AppColors.gold,
          collapsedIconColor: AppColors.mutedText(context),
          childrenPadding: const EdgeInsets.only(bottom: 12),
          children: outcomes.map((o) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 3),
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: .15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 14,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      o.toString(),
                      style: TextStyle(
                        color: AppColors.text(context),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _videoTile(
    BuildContext context,
    dynamic v,
    String courseId, {
    required bool owned,
  }) {
    final canPlay = v['isFreePreview'] == true || owned;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line(context)),
        boxShadow: canPlay
            ? [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: .04),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ]
            : [],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: canPlay
                ? AppColors.gold.withValues(alpha: .15)
                : AppColors.surface(context),
            shape: BoxShape.circle,
          ),
          child: Icon(
            canPlay ? Icons.play_arrow_rounded : Icons.lock_outline_rounded,
            color: canPlay ? AppColors.gold : AppColors.mutedText(context),
            size: 26,
          ),
        ),
        title: Text(
          v['title'],
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: canPlay
                ? AppColors.text(context)
                : AppColors.mutedText(context),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            durationLabel(v['duration'] ?? 0),
            style: TextStyle(
              color: AppColors.mutedText(context),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        trailing: canPlay && v['isFreePreview'] == true && !owned
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'FREE',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              )
            : null,
        onTap: canPlay
            ? () => context.push('/video/${v['_id']}?course=$courseId')
            : null,
      ),
    );
  }

  Widget _actionButton(
    BuildContext context,
    Map<String, dynamic> course,
    String courseId,
    bool owned,
    bool isFree,
    bool expired,
  ) {
    return SizedBox(
      height: 54,
      child: FilledButton.icon(
        icon: Icon(
          owned
              ? Icons.play_arrow
              : isFree
              ? Icons.lock_open
              : Icons.shopping_cart,
          size: 20,
        ),
        label: Text(
          owned
              ? 'Start Learning'
              : expired
              ? 'Repurchase'
              : isFree
              ? 'Unlock Free'
              : 'Buy Now',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: owned ? AppColors.success : AppColors.gold,
          foregroundColor: AppColors.primaryBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: () async {
          if (owned) {
            try {
              final list = await api.courseVideos(courseId);
              if (!context.mounted) return;
              if (list.isNotEmpty) {
                context.push('/video/${list.first['_id']}?course=$courseId');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No videos are added to this course yet'),
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
          fontSize: compact ? 22 : 28,
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
          fontSize: compact ? 22 : 28,
          fontWeight: FontWeight.w900,
        ),
      );
    }
    final original = _asNum(course['originalPrice'] ?? course['price']);
    final effective = _asNum(course['effectivePrice'] ?? course['price']);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: [
        Text(
          money(effective),
          style: TextStyle(
            color: AppColors.gold,
            fontFamily: 'JetBrains Mono',
            fontSize: compact ? 22 : 28,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        Text(
          money(original),
          style: TextStyle(
            color: AppColors.mutedText(context),
            fontFamily: 'JetBrains Mono',
            decoration: TextDecoration.lineThrough,
            decorationColor: AppColors.mutedText(context).withValues(alpha: .5),
            fontSize: compact ? 13 : 16,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
        if (!compact)
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

  Widget _accessBadge(BuildContext context, Map<String, dynamic> access) {
    String text;
    bool isError = false;

    if (access['isExpired'] == true) {
      text = 'COURSE EXPIRED';
      isError = true;
    } else {
      final days = access['daysRemaining'];
      if (days is num) {
        text = '$days DAYS REMAINING';
      } else {
        final expiry = access['expiryDate'];
        if (expiry != null) {
          text = 'EXP: ${expiry.toString().split('T').first}';
        } else if (access['isOwned'] == true) {
          text = 'LIFETIME ACCESS';
        } else {
          return const SizedBox.shrink();
        }
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isError
            ? AppColors.error.withValues(alpha: .1)
            : AppColors.surface(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isError
              ? AppColors.error.withValues(alpha: .3)
              : AppColors.line(context),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isError ? AppColors.error : AppColors.mutedText(context),
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _sectionKicker(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: AppColors.gold,
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.8,
      ),
    ),
  );

  num _asNum(dynamic value) =>
      value is num ? value : num.tryParse(value?.toString() ?? '') ?? 0;
}
