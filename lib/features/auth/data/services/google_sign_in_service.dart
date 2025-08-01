import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../shared/services/logger_service.dart';

/// Service class that manages Google Sign In using the singleton pattern.
///
/// This service wraps the GoogleSignIn instance and provides
/// a centralized way to manage authentication with Google.
///
/// Using google_sign_in 6.2.1:
/// - GoogleSignIn is created with configuration
/// - signIn() method for interactive sign-in
/// - signInSilently() for silent sign-in
/// - currentUser property for the current signed-in user
class GoogleSignInService {
  // Private constructor for singleton pattern
  GoogleSignInService._internal();

  // Static instance
  static final GoogleSignInService _instance = GoogleSignInService._internal();

  // Factory constructor to return the singleton instance
  factory GoogleSignInService() {
    return _instance;
  }

  // Track initialization status
  bool _isInitialized = false;

  // GoogleSignIn instance (using singleton pattern in v7.x)
  GoogleSignIn get _googleSignIn => GoogleSignIn.instance;

  // Stream subscription for authentication events
  StreamSubscription? _authSubscription;

  // Current user state (manually tracked in v7.x)
  GoogleSignInAccount? _currentUser;

  /// Whether the service has been initialized
  bool get isInitialized => _isInitialized;

  /// Check if the current platform supports google_sign_in
  bool get isPlatformSupported {
    if (kIsWeb) return true;
    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) return true;
    // Windows and Linux are not supported by google_sign_in
    return false;
  }

  /// Initialize the GoogleSignIn instance.
  ///
  /// This must be called once before using any other methods.
  /// Typically called from main() or during app initialization.
  Future<void> initialize() async {
    if (_isInitialized) {
      LoggerService.debug('GoogleSignInService already initialized', tag: 'GoogleSignInService');
      return;
    }

    // Check platform support
    if (!isPlatformSupported) {
      LoggerService.debug('Platform not supported for google_sign_in. Will use Firebase Auth OAuth flow.', tag: 'GoogleSignInService');
      _isInitialized = true; // Mark as initialized even on unsupported platforms
      return;
    }

    try {
      // Initialize GoogleSignIn instance (v7.x uses singleton pattern)
      await _googleSignIn.initialize();

      // Listen to authentication events (v7.x uses authenticationEvents)
        _authSubscription = _googleSignIn.authenticationEvents.listen((event) {
          switch (event) {
            case GoogleSignInAuthenticationEventSignIn():
              _currentUser = event.user;
              LoggerService.debug('Google Sign In auth event: ${event.user.email}', tag: 'GoogleSignInService');
              break;
            case GoogleSignInAuthenticationEventSignOut():
              _currentUser = null;
              LoggerService.debug('Google Sign In auth event: signed out', tag: 'GoogleSignInService');
              break;
          }
        });

      _isInitialized = true;

      LoggerService.debug('GoogleSignInService initialized', tag: 'GoogleSignInService');
    } catch (e) {
      LoggerService.error('GoogleSignInService initialization error', tag: 'GoogleSignInService', error: e);
      rethrow;
    }
  }

  /// Sign in with Google interactively.
  ///
  /// Triggers the Google sign-in flow and returns the signed-in account.
  /// Returns null if the user cancels the sign-in.
  Future<GoogleSignInAccount?> signIn() async {
    if (!_isInitialized) {
      throw StateError('GoogleSignInService not initialized. Call initialize() first.');
    }

    if (!isPlatformSupported) {
      LoggerService.debug('Google sign in not supported on this platform. Use Firebase Auth OAuth flow instead.', tag: 'GoogleSignInService');
      return null;
    }

    try {
      // In v7.x, use authenticate() instead of signIn()
      final account = await _googleSignIn.authenticate(
        scopeHint: ['email', 'profile'],
      );
      _currentUser = account;
      return account;
    } catch (e) {
      LoggerService.error('Google sign in error', tag: 'GoogleSignInService', error: e);
      rethrow;
    }
  }

  /// Sign out from Google.
  ///
  /// Signs out the current Google user.
  Future<void> signOut() async {
    if (!_isInitialized) {
      throw StateError('GoogleSignInService not initialized. Call initialize() first.');
    }

    if (!isPlatformSupported) {
      LoggerService.debug('Google sign out not needed on this platform (handled by Firebase Auth)', tag: 'GoogleSignInService');
      return;
    }

    try {
      await _googleSignIn.signOut();
      _currentUser = null;
    } catch (e) {
      LoggerService.error('Google sign out error', tag: 'GoogleSignInService', error: e);
      rethrow;
    }
  }

  /// Disconnect from Google.
  ///
  /// Signs out and disconnects the Google account, clearing cached authentication.
  Future<void> disconnect() async {
    if (!_isInitialized) {
      throw StateError('GoogleSignInService not initialized. Call initialize() first.');
    }

    if (!isPlatformSupported) {
      LoggerService.debug('Google disconnect not needed on this platform (handled by Firebase Auth)', tag: 'GoogleSignInService');
      return;
    }

    try {
      await _googleSignIn.signOut();
      _currentUser = null;
    } catch (e) {
      LoggerService.error('Google disconnect error', tag: 'GoogleSignInService', error: e);
      rethrow;
    }
  }

  /// Attempt silent sign in.
  ///
  /// Attempts to sign in a previously authenticated user without interaction.
  /// Returns null if no previously authenticated user is available.
  Future<GoogleSignInAccount?> signInSilently() async {
    if (!_isInitialized) {
      throw StateError('GoogleSignInService not initialized. Call initialize() first.');
    }

    if (!isPlatformSupported) {
      LoggerService.debug('Google silent sign in not supported on this platform', tag: 'GoogleSignInService');
      return null;
    }

    try {
      // In v7.x, use attemptLightweightAuthentication() for silent sign-in
      final result = _googleSignIn.attemptLightweightAuthentication();
      if (result is Future<GoogleSignInAccount?>) {
        final account = await result;
        _currentUser = account;
        return account;
      } else {
        _currentUser = result as GoogleSignInAccount?;
        return _currentUser;
      }
    } catch (e) {
      LoggerService.error('Google silent sign in error', tag: 'GoogleSignInService', error: e);
      rethrow;
    }
  }

  /// Get the current signed-in account.
  ///
  /// Returns null if no user is signed in.
  GoogleSignInAccount? get currentUser {
    if (!_isInitialized || !isPlatformSupported) {
      return null;
    }
    return _currentUser;
  }

  /// Check if a user is currently signed in.
  bool get isSignedIn {
    return _currentUser != null;
  }

  /// Request scopes from the user.
  ///
  /// This is needed for accessing Google APIs beyond basic profile.
  Future<bool> requestScopes(List<String> scopes) async {
    if (!_isInitialized) {
      throw StateError('GoogleSignInService not initialized. Call initialize() first.');
    }

    if (!isPlatformSupported) {
      LoggerService.debug('Google scope request not supported on this platform', tag: 'GoogleSignInService');
      return false;
    }

    try {
      // In v7.x, use authorizationClient for scope management
      final authClient = _googleSignIn.authorizationClient;
      final authorization = await authClient.authorizationForScopes(scopes);
      return authorization != null;
    } catch (e) {
      LoggerService.error('Request scopes error', tag: 'GoogleSignInService', error: e);
      rethrow;
    }
  }

  /// Clean up resources
  void dispose() {
    _authSubscription?.cancel();
    _authSubscription = null;
  }
}
