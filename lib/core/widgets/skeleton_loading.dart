import 'package:flutter/material.dart';

/// Skeleton shimmer animation widget for loading states
class SkeletonShimmer extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;

  const SkeletonShimmer({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFFE8E8E8),
    this.highlightColor = const Color(0xFFF5F5F5),
  });

  @override
  State<SkeletonShimmer> createState() => _SkeletonShimmerState();
}

class _SkeletonShimmerState extends State<SkeletonShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: [0.0, 0.5 + (_animation.value * 0.25), 1.0],
              transform: _SlidingGradientTransform(_animation.value),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;

  const _SlidingGradientTransform(this.slidePercent);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0, 0);
  }
}

/// Skeleton box placeholder
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE8E8E8),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Skeleton circle placeholder
class SkeletonCircle extends StatelessWidget {
  final double size;

  const SkeletonCircle({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFFE8E8E8),
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Skeleton for activity card
class SkeletonActivityCard extends StatelessWidget {
  const SkeletonActivityCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Icon skeleton
              const SkeletonBox(width: 46, height: 46, borderRadius: 12),
              const SizedBox(width: 12),
              // Content skeleton
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(
                      width: MediaQuery.of(context).size.width * 0.4,
                      height: 14,
                    ),
                    const SizedBox(height: 8),
                    const SkeletonBox(width: 80, height: 12),
                  ],
                ),
              ),
              // Points skeleton
              const SkeletonBox(width: 50, height: 28, borderRadius: 10),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton for family member avatar
class SkeletonFamilyMember extends StatelessWidget {
  const SkeletonFamilyMember({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: Column(
        children: [
          const SkeletonCircle(size: 60),
          const SizedBox(height: 8),
          const SkeletonBox(width: 50, height: 12),
        ],
      ),
    );
  }
}

/// Skeleton for the entire recent activities section
class SkeletonRecentActivities extends StatelessWidget {
  final int itemCount;

  const SkeletonRecentActivities({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        itemCount,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: index < itemCount - 1 ? 10 : 0),
          child: const SkeletonActivityCard(),
        ),
      ),
    );
  }
}

/// Skeleton for family members row
class SkeletonFamilyMembersRow extends StatelessWidget {
  final int itemCount;

  const SkeletonFamilyMembersRow({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: List.generate(
            itemCount,
            (index) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Column(
                children: [
                  const SkeletonCircle(size: 60),
                  const SizedBox(height: 8),
                  const SkeletonBox(width: 50, height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Skeleton for all activities screen
class SkeletonAllActivities extends StatelessWidget {
  const SkeletonAllActivities({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header skeleton
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 12),
              child: SkeletonBox(width: 100, height: 13),
            ),
            // Activity cards
            ...List.generate(
              4,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildActivityCardSkeleton(context),
              ),
            ),
            const SizedBox(height: 20),
            // Another date header
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 12),
              child: SkeletonBox(width: 120, height: 13),
            ),
            // More activity cards
            ...List.generate(
              3,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildActivityCardSkeleton(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCardSkeleton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon skeleton
            const SkeletonBox(width: 52, height: 52, borderRadius: 14),
            const SizedBox(width: 14),
            // Content skeleton
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(
                    width: MediaQuery.of(context).size.width * 0.45,
                    height: 15,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: const [
                      SkeletonBox(width: 60, height: 20, borderRadius: 6),
                      SizedBox(width: 8),
                      SkeletonBox(width: 50, height: 12),
                    ],
                  ),
                ],
              ),
            ),
            // Points skeleton
            const SkeletonBox(width: 60, height: 32, borderRadius: 12),
          ],
        ),
      ),
    );
  }
}
