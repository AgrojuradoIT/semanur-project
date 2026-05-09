import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Precachea una lista de URLs de imágenes
Future<void> precacheImages(List<String> imageUrls, BuildContext context) async {
  await Future.wait(
    imageUrls.map((url) => precacheImage(
      CachedNetworkImageProvider(url),
      context,
    )),
  );
}

/// Precachea imágenes de manera diferida (solo las primeras)
Future<void> precacheImagesDeferred(
  List<String> imageUrls,
  BuildContext context, {
  int initialCount = 10,
}) async {
  // Precachea solo las primeras imágenes
  final initialImages = imageUrls.take(initialCount);
  await Future.wait(
    initialImages.map((url) => precacheImage(
      CachedNetworkImageProvider(url),
      context,
    )),
  );
  
  // Precachea el resto en segundo plano
  final remainingImages = imageUrls.skip(initialCount);
  for (final url in remainingImages) {
    unawaited(
      precacheImage(
        CachedNetworkImageProvider(url),
        context,
      ),
    );
  }
}

/// Widget helper para precacheo automático
class AutoPrecacheImages extends StatefulWidget {
  final List<String> imageUrls;
  final Widget child;
  final int initialCount;

  const AutoPrecacheImages({
    super.key,
    required this.imageUrls,
    required this.child,
    this.initialCount = 10,
  });

  @override
  State<AutoPrecacheImages> createState() => _AutoPrecacheImagesState();
}

class _AutoPrecacheImagesState extends State<AutoPrecacheImages> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      precacheImagesDeferred(
        widget.imageUrls,
        context,
        initialCount: widget.initialCount,
      );
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
