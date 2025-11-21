import 'package:google_sign_in/google_sign_in.dart';

/// Service pour gérer l'authentification Google
class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
    // IMPORTANT: Le serverClientId est le Web Client ID de Google Cloud Console
    // C'est nécessaire pour obtenir un idToken valide
    serverClientId: '1044256435944-spfhvk7hrq6e79a9m0uadcprobf2umhg.apps.googleusercontent.com',
  );

  /// Se connecter avec Google
  Future<GoogleSignInAccount?> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      return account;
    } catch (error) {
      throw Exception('Erreur lors de la connexion Google: $error');
    }
  }

  /// Obtenir le token ID Google
  Future<String?> getIdToken(GoogleSignInAccount account) async {
    try {
      final auth = await account.authentication;
      return auth.idToken;
    } catch (error) {
      throw Exception('Erreur lors de l\'obtention du token: $error');
    }
  }

  /// Se déconnecter
  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  /// Vérifier si l'utilisateur est déjà connecté
  Future<GoogleSignInAccount?> getCurrentUser() async {
    return _googleSignIn.currentUser;
  }

  /// Déconnexion silencieuse (sans dialogue)
  Future<void> disconnect() async {
    await _googleSignIn.disconnect();
  }
}
