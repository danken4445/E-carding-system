import 'package:equatable/equatable.dart';

/// User roles with permission methods
enum UserRole {
  staff, // POS only
  manager, // POS + product management
  owner; // Full access

  /// Can access CMS (content management system)
  bool get canAccessCMS => this == manager || this == owner;

  /// Can manage products and categories
  bool get canManageProducts => this == manager || this == owner;

  /// Can manage users in the shop
  bool get canManageUsers => this == owner;

  /// Can manage shop settings
  bool get canManageShopSettings => this == owner;

  /// Can apply discounts
  bool get canApplyDiscounts => this != staff;

  /// Can void transactions
  bool get canVoidTransactions => this == manager || this == owner;

  /// Can view reports
  bool get canViewReports => this == manager || this == owner;

  /// Parse role from string
  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'staff':
        return UserRole.staff;
      case 'manager':
        return UserRole.manager;
      case 'owner':
        return UserRole.owner;
      default:
        return UserRole.staff; // Default to most restrictive
    }
  }
}

/// User entity representing a logged-in user
class UserEntity extends Equatable {
  final String id; // users table id
  final String authUserId; // auth.users.id from Supabase
  final String email;
  final String displayName;
  final String shopId;
  final UserRole role;
  final bool isActive;

  const UserEntity({
    required this.id,
    required this.authUserId,
    required this.email,
    required this.displayName,
    required this.shopId,
    required this.role,
    required this.isActive,
  });

  /// Create from JSON (Supabase response)
  factory UserEntity.fromJson(Map<String, dynamic> json) {
    return UserEntity(
      id: json['id'] as String,
      authUserId: json['auth_user_id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String,
      shopId: json['shop_id'] as String,
      role: UserRole.fromString(json['role'] as String),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'auth_user_id': authUserId,
      'email': email,
      'display_name': displayName,
      'shop_id': shopId,
      'role': role.name,
      'is_active': isActive,
    };
  }

  /// Copy with modifications
  UserEntity copyWith({
    String? id,
    String? authUserId,
    String? email,
    String? displayName,
    String? shopId,
    UserRole? role,
    bool? isActive,
  }) {
    return UserEntity(
      id: id ?? this.id,
      authUserId: authUserId ?? this.authUserId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      shopId: shopId ?? this.shopId,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
        id,
        authUserId,
        email,
        displayName,
        shopId,
        role,
        isActive,
      ];

  @override
  String toString() {
    return 'UserEntity(id: $id, email: $email, displayName: $displayName, role: ${role.name}, shopId: $shopId)';
  }
}
