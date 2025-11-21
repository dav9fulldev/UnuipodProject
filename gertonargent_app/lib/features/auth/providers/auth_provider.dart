import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/google_auth_service.dart';
import '../../../data/models/user_model.dart';

final apiServiceProvider = Provider((ref) => ApiService());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(apiServiceProvider));
});

class AuthState {
  final bool isAuthenticated;
  final UserModel? user;
  final String? token;
  final bool isLoading;
  final String? error;

  AuthState({
    this.isAuthenticated = false,
    this.user,
    this.token,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    UserModel? user,
    String? token,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      token: token ?? this.token,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService;

  AuthNotifier(this._apiService) : super(AuthState());

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiService.login(
        email: email,
        password: password,
      );

      final token = response['access_token'];
      _apiService.setToken(token);

      state = state.copyWith(
        isAuthenticated: true,
        token: token,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur de connexion: $e',
      );
    }
  }

  Future<void> register({
    required String email,
    required String username,
    required String phone,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiService.register(
        email: email,
        username: username,
        phone: phone,
        password: password,
      );

      final token = response['access_token'];
      _apiService.setToken(token);

      state = state.copyWith(
        isAuthenticated: true,
        token: token,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur d\'inscription: $e',
      );
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final googleAuthService = GoogleAuthService();
      
      // Étape 1: Connexion Google
      print('🔐 Tentative de connexion Google...');
      final account = await googleAuthService.signIn();
      
      if (account == null) {
        print('❌ Aucun compte sélectionné');
        state = state.copyWith(
          isLoading: false,
          error: 'Connexion Google annulée',
        );
        return;
      }
      
      print('✅ Compte Google connecté: ${account.email}');
      
      // Étape 2: Obtenir le token ID
      print('🔑 Récupération du token ID...');
      final idToken = await googleAuthService.getIdToken(account);
      
      if (idToken == null || idToken.isEmpty) {
        print('❌ Token ID vide ou null');
        state = state.copyWith(
          isLoading: false,
          error: 'Impossible d\'obtenir le token Google. Vérifiez la configuration du Client ID dans Google Cloud Console.',
        );
        return;
      }
      
      print('✅ Token ID obtenu (${idToken.length} caractères)');
      
      // Étape 3: Envoyer au backend
      print('📤 Envoi du token au backend...');
      final response = await _apiService.googleAuth(idToken: idToken);
      
      final token = response['access_token'];
      _apiService.setToken(token);
      
      print('✅ Authentification réussie!');

      state = state.copyWith(
        isAuthenticated: true,
        token: token,
        isLoading: false,
      );
    } catch (e) {
      print('❌ Erreur Google Sign-In: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void logout() {
    state = AuthState();
  }
}
