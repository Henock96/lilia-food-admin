import 'package:lilia_admin/models/role.dart';

class AppUser {
  final String id;
  final String email;
  final String? nom;
  final String? phone;
  final String? imageUrl;
  final Role role;
  final DateTime createdAt;
  final int loyaltyPoints;

  AppUser({
    required this.id,
    required this.email,
    this.nom,
    this.phone,
    this.imageUrl,
    required this.role,
    required this.createdAt,
    this.loyaltyPoints = 0,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      nom: json['nom'] as String?,
      phone: json['phone'] as String?,
      imageUrl: json['imageUrl'] as String?,
      role: roleFromString(json['role'] as String?),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      loyaltyPoints: json['loyaltyPoints'] as int? ?? 0,
    );
  }

  String get initials {
    if (nom == null || nom!.isEmpty) {
      if (email.isEmpty) return '??';
      return email.substring(0, email.length >= 2 ? 2 : email.length).toUpperCase();
    }
    final names = nom!.split(' ');
    if (names.length > 1 && names[0].isNotEmpty && names[1].isNotEmpty) {
      return names[0].substring(0, 1) + names[1].substring(0, 1);
    }
    return nom!.substring(0, nom!.length >= 2 ? 2 : nom!.length).toUpperCase();
  }
}
