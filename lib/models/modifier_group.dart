/// F3-09 — options & suppléments, vus par le vendeur (bibliothèque).
///
/// Un groupe (« Accompagnement », obligatoire, 1 choix) porte des options
/// (« Alloco +500 »), et s'attache à un ou plusieurs produits. Le serveur est
/// l'autorité : propriété, plafonds, cardinalités, prix.
library;

int _int(Object? v, [int fallback = 0]) => v is num ? v.toInt() : fallback;
String _str(Object? v, [String fallback = '']) => v is String ? v : fallback;

class ModifierOption {
  final String? id;
  final String name;
  final int priceDeltaXaf;
  final int maxQuantity;
  final bool isAvailable;

  const ModifierOption({
    this.id,
    required this.name,
    this.priceDeltaXaf = 0,
    this.maxQuantity = 1,
    this.isAvailable = true,
  });

  factory ModifierOption.fromJson(Map<String, dynamic> json) => ModifierOption(
    id: json['id'] as String?,
    name: _str(json['name'], 'Option'),
    priceDeltaXaf: _int(json['priceDeltaXaf']),
    maxQuantity: _int(json['maxQuantity'], 1),
    isAvailable: json['isAvailable'] != false,
  );

  /// Corps attendu par le backend. `id` absent = création.
  Map<String, dynamic> toJson() => {
    'id': ?id,
    'name': name.trim(),
    'priceDeltaXaf': priceDeltaXaf,
    'maxQuantity': maxQuantity,
    'isAvailable': isAvailable,
  };

  ModifierOption copyWith({
    String? name,
    int? priceDeltaXaf,
    int? maxQuantity,
    bool? isAvailable,
  }) => ModifierOption(
    id: id,
    name: name ?? this.name,
    priceDeltaXaf: priceDeltaXaf ?? this.priceDeltaXaf,
    maxQuantity: maxQuantity ?? this.maxQuantity,
    isAvailable: isAvailable ?? this.isAvailable,
  );
}

class ModifierProductRef {
  final String id;
  final String name;

  const ModifierProductRef({required this.id, required this.name});

  factory ModifierProductRef.fromJson(Map<String, dynamic> json) =>
      ModifierProductRef(id: _str(json['id']), name: _str(json['nom'], 'Produit'));
}

class ModifierGroup {
  final String id;
  final String name;
  final int minSelect;
  final int maxSelect;
  final List<ModifierOption> options;
  final List<ModifierProductRef> products;

  const ModifierGroup({
    required this.id,
    required this.name,
    this.minSelect = 0,
    this.maxSelect = 1,
    this.options = const [],
    this.products = const [],
  });

  bool get isRequired => minSelect >= 1;

  /// « Obligatoire · 1 choix », « Facultatif · jusqu'à 2 ».
  String get ruleLabel {
    if (isRequired) {
      return minSelect == maxSelect
          ? 'Obligatoire · $minSelect choix'
          : 'Obligatoire · $minSelect à $maxSelect choix';
    }
    return maxSelect == 1 ? 'Facultatif · 1 choix' : 'Facultatif · jusqu\'à $maxSelect';
  }

  factory ModifierGroup.fromJson(Map<String, dynamic> json) => ModifierGroup(
    id: _str(json['id']),
    name: _str(json['name'], 'Options'),
    minSelect: _int(json['minSelect']),
    maxSelect: _int(json['maxSelect'], 1),
    options: ((json['options'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(ModifierOption.fromJson)
        .toList(),
    products: ((json['products'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(ModifierProductRef.fromJson)
        .toList(),
  );
}

/// Bibliothèque + interrupteurs de déploiement (`meta`).
class ModifierLibrary {
  final List<ModifierGroup> groups;

  /// La plateforme propose-t-elle des options aux clients ?
  final bool modifiersEnabled;

  /// L'éditeur est-il ouvert aux vendeurs ? (Un ADMIN écrit toujours.)
  final bool managementEnabled;

  const ModifierLibrary({
    this.groups = const [],
    this.modifiersEnabled = false,
    this.managementEnabled = false,
  });
}
