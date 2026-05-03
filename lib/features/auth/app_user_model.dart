import 'package:firebase_auth/firebase_auth.dart';

import '../../models/adresse.dart';
import '../../models/role.dart';
import '../../models/restaurant.dart';

class AppUser {
  const AppUser({
    required this.uid, // Firebase UID
    this.id, // Database ID
    this.email,
    this.emailVerified = false,
    this.displayName,
    this.nom,
    this.phone,
    this.adresse,
    this.imageUrl,
    this.role,
    this.restaurant,
  });

  // Firebase data
  final String uid;
  final String? email;
  final bool emailVerified;
  final String? displayName;

  // Local database data
  final String? id;
  final String? nom;
  final String? phone;
  final String? imageUrl;
  final Adresse? adresse;
  final Role? role;
  final Restaurant? restaurant;

  // Mapper un User Firebase vers AppUser
  static AppUser? fromFirebaseUser(User? user) {
    if (user == null) {
      return null;
    }
    return AppUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      emailVerified: user.emailVerified,
    );
  }

  // Mapper un JSON de votre backend vers AppUser
  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String?,
      uid: json['firebaseUid'] as String? ?? '',
      email: json['email'] as String?,
      nom: json['nom'] as String?,
      phone: json['phone'] as String?,
      imageUrl: json['imageUrl'] as String?,
      role: json['role'] != null ? roleFromString(json['role'] as String?) : null,
      restaurant: json['restaurant'] != null
          ? Restaurant.fromJson(json['restaurant'] as Map<String, dynamic>)
          : null,
    );
  }

  // Copier l'objet avec de nouvelles valeurs
  AppUser copyWith({
    String? id,
    String? uid,
    String? email,
    bool? emailVerified,
    String? displayName,
    String? nom,
    String? imageUrl,
    String? phone,
    Adresse? adresse,
    Role? role,
    Restaurant? restaurant,
  }) {
    return AppUser(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      email: email ?? this.email,
      emailVerified: emailVerified ?? this.emailVerified,
      displayName: displayName ?? this.displayName,
      nom: nom ?? this.nom,
      phone: phone ?? this.phone,
      adresse: adresse ?? this.adresse,
      imageUrl: imageUrl ?? this.imageUrl,
      role: role ?? this.role,
      restaurant: restaurant ?? this.restaurant,
    );
  }

  // Verifier si l'utilisateur est un restaurateur ou admin
  bool get isRestaurateurOrAdmin =>
      role == Role.restaurateur || role == Role.admin;

  // Obtenir l'ID du restaurant (si l'utilisateur en a un)
  String? get restaurantId => restaurant?.id;

  // Obtenir les initiales de l'utilisateur
  String get initials {
    final name = nom ?? displayName ?? email ?? '';
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }
}
