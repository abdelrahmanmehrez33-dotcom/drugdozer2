import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Custom exception types for the app
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'AppException: $message (code: $code)';
}

class NetworkException extends AppException {
  NetworkException([String message = 'Network error occurred']) 
      : super(message, code: 'NETWORK_ERROR');
}

class LocationException extends AppException {
  LocationException([String message = 'Location error occurred']) 
      : super(message, code: 'LOCATION_ERROR');
}

class StorageException extends AppException {
  StorageException([String message = 'Storage error occurred']) 
      : super(message, code: 'STORAGE_ERROR');
}

class NotificationException extends AppException {
  NotificationException([String message = 'Notification error occurred']) 
      : super(message, code: 'NOTIFICATION_ERROR');
}

/// Global error handler
class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  /// Initialize error handling
  void init() {
    // Handle Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      _logError(details.exception, details.stack);
    };

    // Handle async errors
    PlatformDispatcher.instance.onError = (error, stack) {
      _logError(error, stack);
      return true;
    };
  }

  /// Log error for debugging
  void _logError(dynamic error, StackTrace? stack) {
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('ERROR: $error');
    if (stack != null) {
      debugPrint('STACK TRACE:');
      debugPrint(stack.toString());
    }
    debugPrint('═══════════════════════════════════════════════════════════');
  }

  /// Handle error and return user-friendly message
  String getErrorMessage(dynamic error, {bool isEnglish = true}) {
    if (error is AppException) {
      return error.message;
    }
    
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('socket') || 
        errorString.contains('network') ||
        errorString.contains('connection')) {
      return isEnglish 
          ? 'No internet connection. Please check your network.'
          : 'لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة.';
    }
    
    if (errorString.contains('location') || 
        errorString.contains('permission')) {
      return isEnglish 
          ? 'Location permission required. Please enable in settings.'
          : 'يلزم إذن الموقع. يرجى التفعيل من الإعدادات.';
    }
    
    if (errorString.contains('timeout')) {
      return isEnglish 
          ? 'Request timed out. Please try again.'
          : 'انتهت مهلة الطلب. يرجى المحاولة مرة أخرى.';
    }
    
    return isEnglish 
        ? 'Something went wrong. Please try again.'
        : 'حدث خطأ ما. يرجى المحاولة مرة أخرى.';
  }

  /// Show error snackbar
  void showErrorSnackbar(BuildContext context, dynamic error, {bool isEnglish = true}) {
    final message = getErrorMessage(error, isEnglish: isEnglish);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: isEnglish ? 'Dismiss' : 'إغلاق',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Show success snackbar
  void showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show info snackbar
  void showInfoSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.blue.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

/// Result wrapper for operations that can fail
class Result<T> {
  final T? data;
  final AppException? error;
  final bool isSuccess;

  Result.success(this.data) : error = null, isSuccess = true;
  Result.failure(this.error) : data = null, isSuccess = false;

  R fold<R>(R Function(T data) onSuccess, R Function(AppException error) onFailure) {
    if (isSuccess && data != null) {
      return onSuccess(data as T);
    } else {
      return onFailure(error ?? AppException('Unknown error'));
    }
  }
}

/// Extension for running async operations with error handling
extension FutureExtension<T> on Future<T> {
  Future<Result<T>> toResult() async {
    try {
      final data = await this;
      return Result.success(data);
    } catch (e) {
      if (e is AppException) {
        return Result.failure(e);
      }
      return Result.failure(AppException(e.toString(), originalError: e));
    }
  }
}
