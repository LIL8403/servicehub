import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// A service category available on the platform.
///
/// For the MVP, categories are hardcoded in [ServiceCategories.all].
/// Later, this will be replaced with a Laravel-backed catalog.
class ServiceCategory {
  const ServiceCategory({
    required this.id,
    required this.icon,
    required this.slug,
  });

  /// Stable identifier used for routing and backend references.
  final String id;

  /// Icon displayed in the category card.
  final IconData icon;

  /// Slug used for URLs and analytics.
  final String slug;
}

/// The list of service categories offered by ServiceHUB.
///
/// Names and descriptions are resolved from the localization layer
/// using the `slug` as the ARB key suffix.
class ServiceCategories {
  ServiceCategories._();

  static const List<ServiceCategory> all = [
    ServiceCategory(
      id: 'plumbing',
      slug: 'plumbing',
      icon: LucideIcons.droplet,
    ),
    ServiceCategory(
      id: 'electrical',
      slug: 'electrical',
      icon: LucideIcons.zap,
    ),
    ServiceCategory(
      id: 'carpentry',
      slug: 'carpentry',
      icon: LucideIcons.hammer,
    ),
    ServiceCategory(
      id: 'painting',
      slug: 'painting',
      icon: LucideIcons.paintbrush,
    ),
    ServiceCategory(
      id: 'masonry',
      slug: 'masonry',
      icon: LucideIcons.layoutGrid,
    ),
    ServiceCategory(
      id: 'mechanics',
      slug: 'mechanics',
      icon: LucideIcons.settings,
    ),
  ];
}