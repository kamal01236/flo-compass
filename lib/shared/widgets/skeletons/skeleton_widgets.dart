import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class SessionSkeletonCard extends StatelessWidget {
  const SessionSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    final skeleton = AppChromeColors.of(context).skeleton;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 16, width: 220, color: skeleton),
            const SizedBox(height: 8),
            Container(height: 12, width: 300, color: skeleton),
            const SizedBox(height: 10),
            Container(height: 10, width: 120, color: skeleton),
          ],
        ),
      ),
    );
  }
}

class SessionDetailSkeleton extends StatelessWidget {
  const SessionDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkeletonLine(width: 240, height: 20),
          SizedBox(height: 10),
          _SkeletonLine(width: 160, height: 14),
          SizedBox(height: 16),
          _SkeletonLine(width: 320, height: 12),
          SizedBox(height: 8),
          _SkeletonLine(width: 300, height: 12),
          SizedBox(height: 8),
          _SkeletonLine(width: 280, height: 12),
        ],
      ),
    );
  }
}

class SpeakerDetailSkeleton extends StatelessWidget {
  const SpeakerDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          CircleAvatar(radius: 28, backgroundColor: AppChromeColors.of(context).skeleton),
          SizedBox(height: 12),
          _SkeletonLine(width: 200, height: 16),
          SizedBox(height: 8),
          _SkeletonLine(width: 260, height: 12),
        ],
      ),
    );
  }
}

class VenueMapSkeleton extends StatelessWidget {
  const VenueMapSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _SkeletonLine(width: 320, height: 14),
          SizedBox(height: 12),
          _SkeletonLine(width: 320, height: 58),
          SizedBox(height: 8),
          _SkeletonLine(width: 320, height: 58),
        ],
      ),
    );
  }
}

class RecapSkeleton extends StatelessWidget {
  const RecapSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: _SkeletonLine(width: 340, height: 180),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final skeleton = AppChromeColors.of(context).skeleton;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: skeleton,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
