import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/api_constants.dart';

class ApiService {
  late Dio _dio;
  String? _token;
  int _userId = 1;

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        debugPrint('REQUEST[${options.method}] => PATH: ${options.path}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        debugPrint('RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        debugPrint('ERROR[${e.response?.statusCode}] => PATH: ${e.requestOptions.path}');
        debugPrint('ERROR MESSAGE: ${e.message}');
        return handler.next(e);
      },
    ));
  }

  void setToken(String token) {
    _token = token;
  }

  void setUserId(int userId) {
    _userId = userId;
  }

  int get userId => _userId;

  // ==================== AUTH ====================

  Future<Map<String, dynamic>> register({
    required String email,
    required String username,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    try {
      final data = <String, dynamic>{
        'email': email,
        'username': username,
        'password': password,
      };
      if (firstName != null) data['first_name'] = firstName;
      if (lastName != null) data['last_name'] = lastName;

      final response = await _dio.post(
        ApiConstants.register,
        data: data,
      );
      if (response.data['access_token'] != null) {
        setToken(response.data['access_token']);
      }
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: FormData.fromMap({
          'username': email,
          'password': password,
        }),
      );
      if (response.data['access_token'] != null) {
        setToken(response.data['access_token']);
      }
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getMe() async {
    try {
      final response = await _dio.get(ApiConstants.me);
      if (response.data['id'] != null) {
        setUserId(response.data['id']);
      }
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== BUDGETS ====================

  Future<List<dynamic>> getBudgets() async {
    try {
      final response = await _dio.get(
        ApiConstants.budgets,
        queryParameters: {'user_id': _userId},
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getBudgetsSummary() async {
    try {
      final response = await _dio.get(
        ApiConstants.budgetsSummary,
        queryParameters: {'user_id': _userId},
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> createBudget({
    required String category,
    required double monthlyLimit,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.budgets,
        data: {
          'category': category,
          'monthly_limit': monthlyLimit,
        },
        queryParameters: {'user_id': _userId},
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateBudget({
    required int budgetId,
    double? monthlyLimit,
    double? currentSpent,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (monthlyLimit != null) data['monthly_limit'] = monthlyLimit;
      if (currentSpent != null) data['current_spent'] = currentSpent;

      final response = await _dio.put(
        '${ApiConstants.budgets}$budgetId',
        data: data,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteBudget(int budgetId) async {
    try {
      await _dio.delete('${ApiConstants.budgets}$budgetId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== TRANSACTIONS ====================

  Future<List<dynamic>> getTransactions({
    String? category,
    String? transactionType,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'user_id': _userId,
        'limit': limit,
        'offset': offset,
      };
      if (category != null) queryParams['category'] = category;
      if (transactionType != null) queryParams['transaction_type'] = transactionType;

      final response = await _dio.get(
        ApiConstants.transactions,
        queryParameters: queryParams,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getTransactionsSummary() async {
    try {
      final response = await _dio.get(
        ApiConstants.transactionsSummary,
        queryParameters: {'user_id': _userId},
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> createTransaction({
    required double amount,
    required String category,
    String? description,
    String transactionType = 'expense',
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.transactions,
        data: {
          'amount': amount,
          'category': category,
          'description': description,
          'transaction_type': transactionType,
        },
        queryParameters: {'user_id': _userId},
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteTransaction(int transactionId) async {
    try {
      await _dio.delete('${ApiConstants.transactions}$transactionId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== GOALS ====================

  Future<List<dynamic>> getGoals({bool includeCompleted = true}) async {
    try {
      final response = await _dio.get(
        ApiConstants.goals,
        queryParameters: {
          'user_id': _userId,
          'include_completed': includeCompleted,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getGoalsSummary() async {
    try {
      final response = await _dio.get(
        ApiConstants.goalsSummary,
        queryParameters: {'user_id': _userId},
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> createGoal({
    required String name,
    String? description,
    required double targetAmount,
    DateTime? targetDate,
    String icon = 'flag',
    String color = '#00A86B',
  }) async {
    try {
      final data = <String, dynamic>{
        'name': name,
        'target_amount': targetAmount,
        'icon': icon,
        'color': color,
      };
      if (description != null) data['description'] = description;
      if (targetDate != null) data['target_date'] = targetDate.toIso8601String();

      final response = await _dio.post(
        ApiConstants.goals,
        data: data,
        queryParameters: {'user_id': _userId},
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateGoal({
    required int goalId,
    String? name,
    String? description,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    String? icon,
    String? color,
    bool? isCompleted,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (description != null) data['description'] = description;
      if (targetAmount != null) data['target_amount'] = targetAmount;
      if (currentAmount != null) data['current_amount'] = currentAmount;
      if (targetDate != null) data['target_date'] = targetDate.toIso8601String();
      if (icon != null) data['icon'] = icon;
      if (color != null) data['color'] = color;
      if (isCompleted != null) data['is_completed'] = isCompleted;

      final response = await _dio.put(
        '${ApiConstants.goals}$goalId',
        data: data,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> addToGoal({
    required int goalId,
    required double amount,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.goals}$goalId/add',
        data: {'amount': amount},
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteGoal(int goalId) async {
    try {
      await _dio.delete('${ApiConstants.goals}$goalId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== AI ====================

  Future<Map<String, dynamic>> analyzeTransaction({
    required double amount,
    required String category,
    String? description,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.aiAnalyze,
        data: {
          'amount': amount,
          'category': category,
          'description': description,
        },
        queryParameters: {'user_id': _userId},
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getRecommendations() async {
    try {
      final response = await _dio.post(
        ApiConstants.aiRecommend,
        queryParameters: {'user_id': _userId},
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getPredictions() async {
    try {
      final response = await _dio.post(
        ApiConstants.aiPredict,
        queryParameters: {'user_id': _userId},
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> sendVoiceQuery(String query) async {
    try {
      final response = await _dio.post(
        ApiConstants.aiVoice,
        data: {'query': query},
        queryParameters: {'user_id': _userId},
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== SIKA ASSISTANT ====================

  Future<Map<String, dynamic>> sikaChat(String query) async {
    try {
      final response = await _dio.post(
        ApiConstants.sikaChat,
        data: {'query': query},
        queryParameters: {'user_id': _userId},
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> sikaConfirmTransaction({
    required double amount,
    required String category,
    String? description,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.sikaConfirm,
        data: {
          'amount': amount,
          'category': category,
          'description': description ?? 'Dépense via Sika',
        },
        queryParameters: {'user_id': _userId},
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== ERROR HANDLING ====================

  String _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connexion au serveur expirée. Vérifiez votre connexion internet.';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final data = e.response?.data;
        if (statusCode == 400) {
          return data?['detail'] ?? 'Requête invalide';
        } else if (statusCode == 401) {
          return data?['detail'] ?? 'Non autorisé. Veuillez vous reconnecter.';
        } else if (statusCode == 404) {
          return data?['detail'] ?? 'Ressource non trouvée';
        } else if (statusCode == 500) {
          return 'Erreur serveur. Réessayez plus tard.';
        }
        return data?['detail'] ?? 'Erreur inconnue';
      case DioExceptionType.connectionError:
        return 'Impossible de se connecter au serveur. Vérifiez que le backend est lancé.';
      default:
        return 'Une erreur est survenue: ${e.message}';
    }
  }
}
