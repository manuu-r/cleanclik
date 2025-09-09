import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'token_service.g.dart';

/// Service for secure token management following Supabase security guidelines
/// Handles access tokens, refresh tokens, and automatic token refresh
class TokenService {
  static const String _accessTokenKey = 'supabase_access_token';
  static const String _refreshTokenKey = 'supabase_refresh_token';
  static const String _tokenExpiryKey = 'supabase_token_expiry';
  static const String _userIdKey = 'supabase_user_id';

  final FlutterSecureStorage _secureStorage;
  final SupabaseClient _supabase;

  Timer? _refreshTimer;
  final StreamController<bool> _tokenValidityController =
      StreamController<bool>.broadcast();

  TokenService(this._secureStorage, this._supabase) {
    _initializeTokenRefresh();
  }

  /// Stream of token validity changes
  Stream<bool> get tokenValidityStream => _tokenValidityController.stream;

  /// Check if we have valid tokens stored
  Future<bool> hasValidTokens() async {
    try {
      final accessToken = await _secureStorage.read(key: _accessTokenKey);
      final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
      final expiryString = await _secureStorage.read(key: _tokenExpiryKey);

      if (accessToken == null || refreshToken == null || expiryString == null) {
        return false;
      }

      final expiry = DateTime.parse(expiryString);
      final now = DateTime.now();

      // Consider token valid if it expires more than 5 minutes from now
      return expiry.isAfter(now.add(const Duration(minutes: 5)));
    } catch (e) {
      debugPrint('Error checking token validity: $e');
      return false;
    }
  }

  /// Store authentication tokens securely
  Future<void> storeTokens(Session session) async {
    try {
      await _secureStorage.write(
        key: _accessTokenKey,
        value: session.accessToken,
      );
      await _secureStorage.write(
        key: _refreshTokenKey,
        value: session.refreshToken,
      );
      await _secureStorage.write(key: _userIdKey, value: session.user.id);

      // Calculate and store expiry time
      final expiresAt = DateTime.now().add(
        Duration(seconds: session.expiresIn ?? 3600),
      );
      await _secureStorage.write(
        key: _tokenExpiryKey,
        value: expiresAt.toIso8601String(),
      );

      _scheduleTokenRefresh(expiresAt);
      _tokenValidityController.add(true);

      debugPrint('Tokens stored securely');
    } catch (e) {
      debugPrint('Error storing tokens: $e');
      rethrow;
    }
  }

  /// Retrieve stored access token
  Future<String?> getAccessToken() async {
    try {
      final token = await _secureStorage.read(key: _accessTokenKey);
      if (token == null) {
        debugPrint('No access token found in storage');
        return null;
      }

      // Validate token format
      if (token.isEmpty || !token.contains('.')) {
        debugPrint('Invalid access token format');
        await clearTokens();
        return null;
      }

      return token;
    } catch (e) {
      debugPrint('Error retrieving access token: $e');
      await clearTokens();
      return null;
    }
  }

  /// Retrieve stored refresh token
  Future<String?> getRefreshToken() async {
    try {
      final token = await _secureStorage.read(key: _refreshTokenKey);
      if (token == null) {
        debugPrint('No refresh token found in storage');
        return null;
      }

      // Validate token format
      if (token.isEmpty) {
        debugPrint('Invalid refresh token format');
        await clearTokens();
        return null;
      }

      return token;
    } catch (e) {
      debugPrint('Error retrieving refresh token: $e');
      await clearTokens();
      return null;
    }
  }

  /// Retrieve stored user ID
  Future<String?> getUserId() async {
    try {
      return await _secureStorage.read(key: _userIdKey);
    } catch (e) {
      debugPrint('Error retrieving user ID: $e');
      return null;
    }
  }

  /// Refresh access token using refresh token
  Future<bool> refreshAccessToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) {
        debugPrint('No refresh token available');
        return false;
      }

      final response = await _supabase.auth.refreshSession(refreshToken);

      if (response.session != null) {
        await storeTokens(response.session!);
        debugPrint('Access token refreshed successfully');
        return true;
      } else {
        debugPrint('Failed to refresh token');
        await clearTokens();
        return false;
      }
    } catch (e) {
      debugPrint('Error refreshing access token: $e');
      await clearTokens();
      return false;
    }
  }

  /// Clear all stored tokens
  Future<void> clearTokens() async {
    try {
      await Future.wait([
        _secureStorage.delete(key: _accessTokenKey),
        _secureStorage.delete(key: _refreshTokenKey),
        _secureStorage.delete(key: _tokenExpiryKey),
        _secureStorage.delete(key: _userIdKey),
      ]);

      _cancelTokenRefresh();
      _tokenValidityController.add(false);

      debugPrint('All tokens cleared successfully');
    } catch (e) {
      debugPrint('Error clearing tokens: $e');
      // Still cancel refresh timer and update validity even if clearing fails
      _cancelTokenRefresh();
      _tokenValidityController.add(false);
    }
  }

  /// Initialize automatic token refresh
  void _initializeTokenRefresh() {
    // Check if we need to refresh tokens on startup
    _checkAndRefreshTokens();
  }

  /// Check if tokens need refresh and refresh if necessary
  Future<void> _checkAndRefreshTokens() async {
    try {
      final expiryString = await _secureStorage.read(key: _tokenExpiryKey);
      if (expiryString == null) return;

      final expiry = DateTime.parse(expiryString);
      final now = DateTime.now();

      // If token expires within 10 minutes, refresh it
      if (expiry.isBefore(now.add(const Duration(minutes: 10)))) {
        await refreshAccessToken();
      } else {
        _scheduleTokenRefresh(expiry);
      }
    } catch (e) {
      debugPrint('Error checking token expiry: $e');
    }
  }

  /// Schedule automatic token refresh
  void _scheduleTokenRefresh(DateTime expiryTime) {
    _cancelTokenRefresh();

    final now = DateTime.now();
    final refreshTime = expiryTime.subtract(const Duration(minutes: 5));

    if (refreshTime.isAfter(now)) {
      final duration = refreshTime.difference(now);
      _refreshTimer = Timer(duration, () async {
        await refreshAccessToken();
      });

      debugPrint(
        'Token refresh scheduled for ${refreshTime.toIso8601String()}',
      );
    }
  }

  /// Cancel scheduled token refresh
  void _cancelTokenRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  /// Validate current session with Supabase
  Future<bool> validateSession() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) {
        await clearTokens();
        return false;
      }

      // Check if session is expired
      final now = DateTime.now().millisecondsSinceEpoch / 1000;
      if (session.expiresAt != null && session.expiresAt! <= now) {
        // Try to refresh
        return await refreshAccessToken();
      }

      return true;
    } catch (e) {
      debugPrint('Error validating session: $e');
      return false;
    }
  }

  /// Get token expiry time
  Future<DateTime?> getTokenExpiry() async {
    try {
      final expiryString = await _secureStorage.read(key: _tokenExpiryKey);
      if (expiryString == null) return null;
      return DateTime.parse(expiryString);
    } catch (e) {
      debugPrint('Error getting token expiry: $e');
      return null;
    }
  }

  /// Check if token is about to expire (within 5 minutes)
  Future<bool> isTokenAboutToExpire() async {
    final expiry = await getTokenExpiry();
    if (expiry == null) return true;

    final now = DateTime.now();
    return expiry.isBefore(now.add(const Duration(minutes: 5)));
  }

  /// Restore session from stored tokens
  /// This method attempts to restore a Supabase session using stored tokens
  Future<bool> restoreSession() async {
    try {
      debugPrint('Attempting to restore session from stored tokens...');

      final accessToken = await getAccessToken();
      final refreshToken = await getRefreshToken();

      if (accessToken == null || refreshToken == null) {
        debugPrint('Cannot restore session: Missing tokens');
        return false;
      }

      // Check if tokens are still valid
      final hasValidTokens = await this.hasValidTokens();
      if (!hasValidTokens) {
        debugPrint('Stored tokens are expired, attempting refresh...');
        return await refreshAccessToken();
      }

      // Validate the session with Supabase
      final sessionValid = await validateSession();
      if (sessionValid) {
        debugPrint('Session restored successfully');
        _tokenValidityController.add(true);
        return true;
      } else {
        debugPrint('Session validation failed, clearing tokens');
        await clearTokens();
        return false;
      }
    } catch (e) {
      debugPrint('Error restoring session: $e');
      await clearTokens();
      return false;
    }
  }

  /// Get comprehensive token status for debugging
  Future<Map<String, dynamic>> getTokenStatus() async {
    try {
      final accessToken = await _secureStorage.read(key: _accessTokenKey);
      final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
      final expiry = await getTokenExpiry();
      final userId = await getUserId();

      return {
        'hasAccessToken': accessToken != null && accessToken.isNotEmpty,
        'hasRefreshToken': refreshToken != null && refreshToken.isNotEmpty,
        'hasUserId': userId != null && userId.isNotEmpty,
        'tokenExpiry': expiry?.toIso8601String(),
        'isExpired': expiry?.isBefore(DateTime.now()) ?? true,
        'isAboutToExpire': await isTokenAboutToExpire(),
        'hasValidTokens': await hasValidTokens(),
        'currentTime': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {'error': e.toString(), 'hasValidTokens': false};
    }
  }

  /// Dispose resources
  void dispose() {
    _cancelTokenRefresh();
    _tokenValidityController.close();
  }
}

/// Provider for TokenService
@riverpod
TokenService tokenService(Ref ref) {
  const secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  final supabase = Supabase.instance.client;
  final service = TokenService(secureStorage, supabase);

  ref.onDispose(() {
    service.dispose();
  });

  return service;
}

/// Provider for token validity stream
@riverpod
Stream<bool> tokenValidity(Ref ref) {
  final tokenService = ref.watch(tokenServiceProvider);
  return tokenService.tokenValidityStream;
}
