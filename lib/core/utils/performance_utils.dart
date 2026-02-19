/// Performance optimization utilities
// ignore_for_file: use_super_parameters

library;

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Optimized image loading with proper error handling and memory management
class OptimizedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const OptimizedImage({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: width != null ? (width! * 2).toInt() : null,
      memCacheHeight: height != null ? (height! * 2).toInt() : null,
      maxWidthDiskCache: width != null ? (width! * 3).toInt() : 1000,
      maxHeightDiskCache: height != null ? (height! * 3).toInt() : 1000,
      placeholder: placeholder != null
          ? (context, url) => placeholder!
          : (context, url) => Container(
                color: Colors.grey[200],
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
      errorWidget: errorWidget != null
          ? (context, url, error) => errorWidget!
          : (context, url, error) => Container(
                color: Colors.grey[200],
                child: Icon(Icons.error_outline, color: Colors.grey[400]),
              ),
    );
  }
}

/// Optimized list view with automatic scroll physics
class OptimizedListView extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final ScrollPhysics? physics;
  final EdgeInsets? padding;
  final bool shrinkWrap;
  final ScrollController? controller;

  const OptimizedListView({
    Key? key,
    required this.itemCount,
    required this.itemBuilder,
    this.physics,
    this.padding,
    this.shrinkWrap = false,
    this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      physics: physics ?? const BouncingScrollPhysics(),
      padding: padding,
      shrinkWrap: shrinkWrap,
      cacheExtent: 500, // Cache items outside viewport
      addAutomaticKeepAlives: true,
      addRepaintBoundaries: true,
      addSemanticIndexes: false,
    );
  }
}

/// Optimized grid view
class OptimizedGridView extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final double childAspectRatio;
  final EdgeInsets? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  const OptimizedGridView({
    Key? key,
    required this.itemCount,
    required this.itemBuilder,
    this.crossAxisCount = 2,
    this.crossAxisSpacing = 10,
    this.mainAxisSpacing = 10,
    this.childAspectRatio = 1,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: itemCount,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemBuilder: itemBuilder,
      physics: physics ?? const BouncingScrollPhysics(),
      padding: padding,
      shrinkWrap: shrinkWrap,
      cacheExtent: 500,
      addAutomaticKeepAlives: true,
      addRepaintBoundaries: true,
    );
  }
}
