enum Role {
  admin,
  restaurateur,
  livreur,
  client,
  unknown,
}

Role roleFromString(String? role) {
  if (role == null) return Role.unknown;
  switch (role.toUpperCase()) {
    case 'ADMIN':
      return Role.admin;
    case 'RESTAURATEUR':
      return Role.restaurateur;
    case 'LIVREUR':
      return Role.livreur;
    case 'CLIENT':
      return Role.client;
    default:
      return Role.unknown;
  }
}
