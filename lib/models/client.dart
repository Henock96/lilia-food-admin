class Client {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? imageUrl;

  Client({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.imageUrl,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] as String? ?? '',
      // Le backend utilise 'nom' pas 'name'
      name: json['nom'] as String? ?? json['name'] as String? ?? 'Inconnu',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': name,
      'email': email,
      'phone': phone,
      'imageUrl': imageUrl,
    };
  }
}
