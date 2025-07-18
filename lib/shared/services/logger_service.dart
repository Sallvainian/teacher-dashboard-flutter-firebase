/// Centralized logging service for the education platform.
/// 
/// This service provides structured logging with multiple severity levels,
/// console output in debug mode, and Firebase Crashlytics integration
/// for production error tracking.
library;

import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Enumeration of available log severity levels.
/// 
/// Levels are ordered from least to most severe:
/// - debug: Development-time debugging information
/// - info: General informational messages
/// - warning: Potentially problematic situations
/// - error: Error events requiring attention
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// Singleton service for centralized application logging.
/// 
/// This service provides:
/// - Structured logging with severity levels
/// - Console output with color coding in debug mode
/// - Firebase Crashlytics integration for production
/// - Contextual tagging for log categorization
/// - Extension methods for convenient logging
/// 
/// In debug mode, all log levels are printed to console.
/// In production, only warnings and errors are sent to Crashlytics.
class LoggerService {
  /// Singleton instance of the logger service.
  static final LoggerService _instance = LoggerService._internal();
  
  /// Factory constructor returning the singleton instance.
  factory LoggerService() => _instance;
  
  /// Private constructor for singleton pattern.
  LoggerService._internal();
  
  /// Minimum log level to display (can be configured via environment)
  static LogLevel minimumLogLevel = kDebugMode ? LogLevel.warning : LogLevel.warning;

  /// Logs a debug message (only in debug mode).
  /// 
  /// Debug messages are only printed in development builds
  /// and are completely ignored in production. Use for
  /// detailed debugging information during development.
  /// 
  /// @param message Debug message to log
  /// @param tag Optional tag for categorizing the log
  static void debug(String message, {String? tag}) {
    if (kDebugMode) {
      _log(LogLevel.debug, message, tag: tag);
    }
  }

  /// Logs an informational message.
  /// 
  /// Info messages are printed in debug mode and logged
  /// to analytics in production. Use for significant
  /// application events and state changes.
  /// 
  /// @param message Informational message to log
  /// @param tag Optional tag for categorizing the log
  static void info(String message, {String? tag}) {
    _log(LogLevel.info, message, tag: tag);
  }

  /// Logs a warning message.
  /// 
  /// Warnings indicate potentially problematic situations
  /// that don't prevent operation but should be addressed.
  /// Displayed in yellow in debug console and sent to
  /// Crashlytics in production.
  /// 
  /// @param message Warning message to log
  /// @param tag Optional tag for categorizing the log
  static void warning(String message, {String? tag}) {
    _log(LogLevel.warning, message, tag: tag);
  }
  
  /// Logs an error message with optional exception details.
  /// 
  /// Errors represent failure conditions requiring attention.
  /// Displayed in red in debug console and automatically
  /// sent to Firebase Crashlytics in production builds.
  /// 
  /// @param message Error description
  /// @param tag Optional tag for categorizing the error
  /// @param error Optional error object (Exception, Error, etc.)
  /// @param stackTrace Optional stack trace for debugging
  static void error(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    _log(LogLevel.error, message, tag: tag, error: error, stackTrace: stackTrace);
    
    // Send to Crashlytics in production
    if (!kDebugMode && error != null) {
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: message,
        information: tag != null ? ['Tag: $tag'] : [],
      );
    }
  }

  /// Internal logging method handling all log levels.
  /// 
  /// Formats log messages with timestamp, level, and optional tag.
  /// Routes output based on build mode:
  /// - Debug: Prints to console with color coding
  /// - Production: Sends warnings/errors to Crashlytics
  /// 
  /// @param level Severity level of the log
  /// @param message Log message content
  /// @param tag Optional categorization tag
  /// @param error Optional error object for error logs
  /// @param stackTrace Optional stack trace for error logs
  static void _log(
    LogLevel level,
    String message, {
    String? tag,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    // Skip logging if below minimum level
    final levelIndex = LogLevel.values.indexOf(level);
    final minLevelIndex = LogLevel.values.indexOf(minimumLogLevel);
    if (levelIndex < minLevelIndex) {
      return;
    }
    
    final timestamp = DateTime.now().toIso8601String();
    final levelStr = level.toString().split('.').last.toUpperCase();
    final tagStr = tag != null ? '[$tag] ' : '';
    
    final logMessage = '$timestamp [$levelStr] $tagStr$message';
    
    if (kDebugMode) {
      // In debug mode, print to console
      switch (level) {
        case LogLevel.debug:
        case LogLevel.info:
          debugPrint(logMessage);
          break;
        case LogLevel.warning:
          debugPrint('\x1B[33m$logMessage\x1B[0m'); // Yellow
          break;
        case LogLevel.error:
          debugPrint('\x1B[31m$logMessage\x1B[0m'); // Red
          if (error != null) {
            debugPrint('Error: $error');
          }
          if (stackTrace != null) {
            debugPrint('Stack trace:\n$stackTrace');
          }
          break;
      }
    } else {
      // In production, only log warnings and errors
      if (level == LogLevel.warning || level == LogLevel.error) {
        // You could send to Firebase Analytics or other logging service here
        FirebaseCrashlytics.instance.log(logMessage);
      }
    }
  }
}

/// Extension providing convenient logging methods for any object.
/// 
/// Automatically tags log messages with the object's runtime type,
/// making it easy to track which class generated each log entry.
/// 
/// Example usage:
/// ```dart
/// class MyService {
///   void doSomething() {
///     logInfo('Starting operation');
///     try {
///       // ... operation code
///     } catch (e, stack) {
///       logError('Operation failed', error: e, stackTrace: stack);
///     }
///   }
/// }
/// ```
extension LoggerExtension on Object {
  /// Gets the logger service instance.
  LoggerService get logger => LoggerService();
  
  /// Logs a debug message tagged with this object's type.
  /// 
  /// @param message Debug message to log
  void logDebug(String message) => LoggerService.debug(message, tag: runtimeType.toString());
  
  /// Logs an info message tagged with this object's type.
  /// 
  /// @param message Informational message to log
  void logInfo(String message) => LoggerService.info(message, tag: runtimeType.toString());
  
  /// Logs a warning message tagged with this object's type.
  /// 
  /// @param message Warning message to log
  void logWarning(String message) => LoggerService.warning(message, tag: runtimeType.toString());
  
  /// Logs an error message tagged with this object's type.
  /// 
  /// @param message Error description
  /// @param error Optional error object
  /// @param stackTrace Optional stack trace
  void logError(String message, {dynamic error, StackTrace? stackTrace}) => 
      LoggerService.error(message, tag: runtimeType.toString(), error: error, stackTrace: stackTrace);
}