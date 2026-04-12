import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

final authService = AuthService();

class AppUser {
  final String uid;
  final String? email;
  final String? displayName;
  AppUser({required this.uid, this.email, this.displayName});
}

class AuthService {
  static const String baseUrl = 'https://unipool-gateway.onrender.com/api/v1/auth';
  
  final _storage = const FlutterSecureStorage();
  
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';

  AppUser? currentUser;
  String? _accessToken;

  // Initialize service, load tokens and user data if exists
  Future<void> init() async {
    _accessToken = await _storage.read(key: _accessTokenKey);
    final userStr = await _storage.read(key: _userKey);
    if (userStr != null) {
      final map = jsonDecode(userStr);
      currentUser = AppUser(
        uid: map['id'],
        email: map['email'],
        displayName: map['email'],
      );
    }
  }

  bool get isAuthenticated => _accessToken != null;

  Future<void> _saveAuthData(Map<String, dynamic> responseData) async {
    final access = responseData['access_token'];
    final refresh = responseData['refresh_token'];
    final user = responseData['user'];

    if (access != null) {
      _accessToken = access;
      await _storage.write(key: _accessTokenKey, value: access);
    }
    if (refresh != null) {
      await _storage.write(key: _refreshTokenKey, value: refresh);
    }
    if (user != null) {
      currentUser = AppUser(
        uid: user['id'],
        email: user['email'],
        displayName: user['email'],
      );
      await _storage.write(key: _userKey, value: jsonEncode(user));
    }
  }

  Future<void> logout() async {
    _accessToken = null;
    currentUser = null;
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userKey);
  }

  // --- REGISTRATION ---

  /// Starts registration, sends an OTP to email.
  Future<void> startRegistration(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register/start'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'verify_phone': false}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final data = jsonDecode(response.body);
      throw Exception(data['error'] ?? 'Failed to start registration');
    }
  }

  /// Completes registration with OTP verification.
  Future<void> verifyRegistration({
    required String email,
    required String name,
    required String password,
    required String otp,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register/verify'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'name': name,
        'password': password,
        'otp': otp,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      await _saveAuthData(data);
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['error'] ?? 'Verification failed');
    }
  }

  // --- LOGIN ---

  Future<void> login(String identifier, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'identifier': identifier,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Ensure we treat a requires_setup or any other MFA as error since simple auth is chosen
      if (data['requires_totp'] == true || data['requires_otp'] == true) {
        throw Exception('MFA is not supported in simple login mode.');
      }
      if (data['access_token'] == null) {
        throw Exception('Login did not return an access token');
      }
      await _saveAuthData(data);
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['error'] ?? 'Login failed');
    }
  }

  // --- PASSWORD RESET ---

  Future<void> forgotPassword(String target) async {
    final response = await http.post(
      Uri.parse('$baseUrl/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'target': target}),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['error'] ?? 'Failed to send reset OTP');
    }
  }

  Future<void> resetPassword({
    required String target,
    required String otp,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'target': target,
        'otp': otp,
        'new_password': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['error'] ?? 'Failed to reset password');
    }
  }
}
