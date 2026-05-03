import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../app_user_model.dart';

part 'firebase_auth_repository.g.dart';

class FirebaseAuthenticationRepository {
  final FirebaseAuth _firebaseAuth;

  FirebaseAuthenticationRepository(this._firebaseAuth);

  AppUser? get currentUser => _convertUser(_firebaseAuth.currentUser);

  // convertit le FirebaseUser nullable en notre AppUser
  AppUser? _convertUser(User? user) =>
      user == null ? null : AppUser.fromFirebaseUser(user);

  Stream<AppUser?> authStateChanges() {
    return _firebaseAuth.authStateChanges().map(_convertUser);
  }

  // Récupère le jeton ID Firebase de l'utilisateur actuellement connecté.
  Future<String?> getIdToken() async {
    return await _firebaseAuth.currentUser?.getIdToken();
  }

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<bool> signOut() async {
    try {
      await _firebaseAuth.signOut();
      return true;
    } on Exception {
      return false;
    }
  }

  Future<void> updatePassword(String newPassword) async {
    try {
      await _firebaseAuth.currentUser?.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      // Gérer les erreurs, par exemple si l'utilisateur doit se reconnecter
      if (e.code == 'requires-recent-login') {
        throw Exception(
          'Cette opération est sensible et nécessite une authentification récente. Veuillez vous déconnecter et vous reconnecter avant de réessayer.',
        );
      }
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmailWithEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null && user.email != null) {
        await _firebaseAuth.sendPasswordResetEmail(email: user.email!);
      } else {
        throw Exception(
          "Aucun utilisateur connecté ou l'email n'est pas disponible.",
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}

@Riverpod(keepAlive: true)
FirebaseAuthenticationRepository authRepository(Ref ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return FirebaseAuthenticationRepository(auth);
}

@Riverpod(keepAlive: true)
FirebaseAuth firebaseAuth(Ref ref) {
  return FirebaseAuth.instance;
}

@Riverpod(keepAlive: true)
Stream<AppUser?> authStateChange(Ref ref) {
  final auth = ref.watch(authRepositoryProvider);
  return auth.authStateChanges();
}

@Riverpod(keepAlive: true)
Stream<String?> firebaseIdToken(Ref ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return auth.idTokenChanges().asyncMap((user) async {
    // Si l'utilisateur est null, le jeton est null
    if (user == null) {
      return null;
    }
    // Sinon, obtenez le jeton ID
    return await user.getIdToken();
  });
}
