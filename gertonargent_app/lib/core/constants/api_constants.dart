class ApiConstants {
  // Pour Android Emulator: 10.0.2.2 = localhost de l'ordinateur hôte
  // Pour iOS Simulator: localhost fonctionne directement
  // Pour appareil physique avec partage de connexion: IP WiFi de l'ordinateur
  static const String baseUrl = 'http://192.168.211.250:8000';
  
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String googleAuth = '/auth/google';
  static const String budgets = '/budgets/';
  static const String analyzeTransaction = '/ai/analyze';
}
