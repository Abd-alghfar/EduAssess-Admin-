import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerLoader extends StatelessWidget {
  final double width;
  final double height;
  final ShapeBorder shapeBorder;

  const ShimmerLoader.rectangular({
    super.key,
    this.width = double.infinity,
    required this.height,
  }) : shapeBorder = const RoundedRectangleBorder(
         borderRadius: BorderRadius.all(Radius.circular(16)),
       );

  const ShimmerLoader.circular({
    super.key,
    required this.width,
    required this.height,
    this.shapeBorder = const CircleBorder(),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[850]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      period: const Duration(milliseconds: 1500),
      child: Container(
        width: width,
        height: height,
        decoration: ShapeDecoration(
          color: Colors.grey[400]!,
          shape: shapeBorder,
        ),
      ),
    );
  }
}

class DashboardShimmer extends StatelessWidget {
  const DashboardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerLoader.rectangular(height: 140), // Header
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: const ShimmerLoader.rectangular(height: 110)),
              const SizedBox(width: 16),
              Expanded(child: const ShimmerLoader.rectangular(height: 110)),
            ],
          ),
          const SizedBox(height: 32),
          const ShimmerLoader.rectangular(
            height: 25,
            width: 140,
          ), // Section Title
          const SizedBox(height: 16),
          const ShimmerLoader.rectangular(height: 220), // Performance Chart
          const SizedBox(height: 32),
          const ShimmerLoader.rectangular(
            height: 25,
            width: 180,
          ), // Section Title
          const SizedBox(height: 16),
          ...List.generate(
            3,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: const ShimmerLoader.rectangular(height: 90),
            ),
          ),
        ],
      ),
    );
  }
}

class ListShimmer extends StatelessWidget {
  final int itemCount;
  const ListShimmer({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: itemCount,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            const ShimmerLoader.circular(width: 56, height: 56),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShimmerLoader.rectangular(height: 16, width: 150),
                  const SizedBox(height: 8),
                  const ShimmerLoader.rectangular(height: 12, width: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GridShimmer extends StatelessWidget {
  final int itemCount;
  const GridShimmer({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        mainAxisExtent: 220,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) =>
          const ShimmerLoader.rectangular(height: 220),
    );
  }
}
