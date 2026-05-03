class Adresse {
  final String id;
  final String rue;
  final String ville;
  final String? etat;
  final String country;
  final String userId;

  Adresse({
    required this.id,
    required this.rue,
    required this.ville,
    this.etat,
    required this.country,
    required this.userId,
  });

  factory Adresse.fromJson(Map<String, dynamic> json) {
    return Adresse(
      id: json['id'] as String? ?? '',
      rue: json['rue'] as String? ?? '',
      ville: json['ville'] as String? ?? '',
      etat: json['etat'] as String?,
      country: json['country'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
    );
  }

  // Pour l'affichage
  @override
  String toString() {
    return rue;
  }
}
