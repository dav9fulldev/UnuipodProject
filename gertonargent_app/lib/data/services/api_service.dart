import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';

class ApiService {
  late Dio _dio;
  String? _token;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        return handler.next(options);
      },
    ));
  }

  void setToken(String token) {
    _token = token;
  }

  // Auth
  Future<Map<String, dynamic>> register({
    required String email,
    required String username,
    required String phone,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.register,
        data: {
          'email': email,
          'username': username,
          'phone': phone,
          'password': password,
        },
      );
      return response.data;
    } catch (e) {
      rethrow;
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
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> googleAuth({
    required String idToken,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.googleAuth,
        data: {
          'id_token': idToken,
        },
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }


  // Budgets
  Future<List<dynamic>> getBudgets() async {
    try {
      final response = await _dio.get(ApiConstants.budgets);
      return response.data;
    } catch (e) {
      rethrow;
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
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // AI Analysis
  Future<Map<String, dynamic>> analyzeTransaction({
    required double amount,
    required String category,
    required int userId,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.analyzeTransaction,
        data: {
          'amount': amount,
          'category': category,
          'user_id': userId,
        },
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}
