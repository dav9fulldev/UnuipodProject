class ApiConstants {
  // Base URL - Modifier selon votre configuration
  static const String baseUrl = 'http://192.168.84.130:8000';

  // Auth endpoints
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String me = '/auth/me';

  // Budgets endpoints
  static const String budgets = '/budgets/';
  static const String budgetsSummary = '/budgets/summary';
  static const String budgetsReset = '/budgets/reset';

  // Transactions endpoints
  static const String transactions = '/transactions/';
  static const String transactionsSummary = '/transactions/summary';

  // Goals endpoints
  static const String goals = '/goals/';
  static const String goalsSummary = '/goals/summary';

  // AI endpoints
  static const String aiAnalyze = '/ai/analyze';
  static const String aiRecommend = '/ai/recommend';
  static const String aiPredict = '/ai/predict';
  static const String aiVoice = '/ai/voice';

  // Sika Assistant endpoints
  static const String sikaChat = '/ai/sika';
  static const String sikaConfirm = '/ai/sika/confirm';
}
