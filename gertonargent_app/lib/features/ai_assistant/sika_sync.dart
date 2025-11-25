import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../../data/services/api_service.dart';

class SikaSync {
  static const MethodChannel _channel = MethodChannel('com.gertonargent/sika');
  static bool _isRunning = false;

  /// Reads pending transactions saved by the native overlay service and attempts to post them.
  /// On success clears the native pending list.
  static Future<int> syncPendingTransactions() async {
    if (_isRunning) return 0;
    _isRunning = true;
    try {
      final String jsonStr =
          await _channel.invokeMethod('getPendingTransactions');
      if (jsonStr.isEmpty || jsonStr == '[]') return 0;
      final List<dynamic> arr = jsonDecode(jsonStr) as List<dynamic>;
      if (arr.isEmpty) return 0;

      int successCount = 0;
      final api = ApiService();

      for (final item in arr) {
        try {
          final amount = (item['amount'] as num).toDouble();
          final description = item['description']?.toString() ?? '';
          await api.createTransaction(
              amount: amount, category: 'autre', description: description);
          // if no exception, consider success
          successCount++;
        } catch (e) {
          debugPrint('SikaSync: failed to send one item: $e');
        }
      }

      if (successCount == arr.length) {
        await _channel.invokeMethod('clearPendingTransactions');
      }

      return successCount;
    } catch (e) {
      debugPrint('SikaSync.sync error: $e');
      return 0;
    } finally {
      _isRunning = false;
    }
  }
}
