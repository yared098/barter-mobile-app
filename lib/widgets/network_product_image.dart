import 'package:flutter/material.dart';

import '../theme.dart';

class NetworkProductImage extends StatelessWidget {
  final String? url;
  final double width;
  final double height;
  final double radius;
  final BoxFit fit;
  final IconData emptyIcon;
  final VoidCallback? onTap;

  const NetworkProductImage({
    super.key,
    required this.url,
    this.width = 88,
    this.height = 88,
    this.radius = 12,
    this.fit = BoxFit.cover,
    this.emptyIcon = Icons.inventory_2_outlined,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final safeUrl = url?.trim();
    final hasUrl = safeUrl != null && safeUrl.isNotEmpty;

    Widget image = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: width,
        height: height,
        color: AppColors.primaryLight,
        child: !hasUrl
            ? _placeholder()
            : Image.network(
                safeUrl,
                fit: fit,
                width: width,
                height: height,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary.withValues(alpha: 0.5),
                        value: progress.expectedTotalBytes != null
                            ? progress.cumulativeBytesLoaded /
                                  progress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => _error(),
                frameBuilder: (context, child, frame, wasSyncLoaded) {
                  if (wasSyncLoaded || frame != null) {
                    return AnimatedOpacity(
                      opacity: 1,
                      duration: const Duration(milliseconds: 200),
                      child: child,
                    );
                  }
                  return child;
                },
              ),
      ),
    );

    if (onTap != null && hasUrl) {
      return GestureDetector(onTap: onTap, child: image);
    }
    return image;
  }

  Widget _placeholder() {
    return Icon(emptyIcon, color: AppColors.primary, size: 32);
  }

  Widget _error() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.broken_image_outlined, color: AppColors.textMuted, size: 22),
      ],
    );
  }
}
