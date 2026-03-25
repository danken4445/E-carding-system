import 'package:equatable/equatable.dart';

/// Shop entity representing a shop/business in the multi-tenant system
class ShopEntity extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String ownerId; // References auth.users.id
  final Map<String, dynamic> settings;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ShopEntity({
    required this.id,
    required this.name,
    required this.slug,
    required this.ownerId,
    required this.settings,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from JSON (Supabase response)
  factory ShopEntity.fromJson(Map<String, dynamic> json) {
    return ShopEntity(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      ownerId: json['owner_id'] as String,
      settings: json['settings'] as Map<String, dynamic>? ?? {},
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'owner_id': ownerId,
      'settings': settings,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Copy with modifications
  ShopEntity copyWith({
    String? id,
    String? name,
    String? slug,
    String? ownerId,
    Map<String, dynamic>? settings,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ShopEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      ownerId: ownerId ?? this.ownerId,
      settings: settings ?? this.settings,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        slug,
        ownerId,
        settings,
        isActive,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'ShopEntity(id: $id, name: $name, slug: $slug, isActive: $isActive)';
  }
}
