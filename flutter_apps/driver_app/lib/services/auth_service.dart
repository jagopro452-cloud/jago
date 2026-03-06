import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';
import 'fcm_service.dart';

class AuthService {
  static const _tokenKey = 'auth_token';
  static const _userKey = 'user_data';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> saveUser(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(userData));
  }

  static Future<Map<String, dynamic>?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_userKey);
    if (str == null) return null;
    return jsonDecode(str);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> sendOtp(String phone, [String userType = 'driver']) async {
    final res = await http.post(
      Uri.parse(ApiConfig.sendOtp),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'userType': userType}),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> verifyOtp(String phone, String otp, [String userType = 'driver']) async {
    final res = await http.post(
      Uri.parse(ApiConfig.verifyOtp),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'otp': otp, 'userType': userType}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['token'] != null) {
      await saveToken(data['token']);
      await saveUser(data['user'] ?? data);
      // Save FCM token to server after login
      FcmService().onLoginSuccess().catchError((_) {});
    }
    return data;
  }

  static Future<void> logout() async {
    try {
      final headers = await getHeaders();
      await http.post(Uri.parse(ApiConfig.logout), headers: headers);
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  static Future<UserModel?> getProfile() async {
    try {
      final headers = await getHeaders();
      final res = await http.get(Uri.parse(ApiConfig.driverProfile), headers: headers);
      if (res.statusCode == 200) {
        return UserModel.fromJson(jsonDecode(res.body));
      }
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>> loginWithPassword(String phone, String password) async {
    try {
      final res = await http.post(Uri.parse(ApiConfig.loginPassword),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone, 'password': password, 'userType': 'driver'}));
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['token'] != null) {
        await saveToken(data['token']);
        await saveUser(data['user'] ?? data);
        FcmService().onLoginSuccess().catchError((_) {});
      }
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Network error. Check connection.'};
    }
  }

  static Future<Map<String, dynamic>> registerWithPassword(String phone, String password, String fullName, {String? email, String? vehicleNumber, String? vehicleModel, String? vehicleCategoryId}) async {
    try {
      final body = <String, dynamic>{'phone': phone, 'password': password, 'fullName': fullName, 'userType': 'driver'};
      if (email != null && email.isNotEmpty) body['email'] = email;
      final res = await http.post(Uri.parse(ApiConfig.registerAccount),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body));
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['token'] != null) {
        await saveToken(data['token']);
        await saveUser(data['user'] ?? data);
        FcmService().onLoginSuccess().catchError((_) {});
      }
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Network error. Check connection.'};
    }
  }

  static Future<Map<String, dynamic>> forgotPassword(String phone) async {
    try {
      final res = await http.post(Uri.parse(ApiConfig.forgotPassword),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone, 'userType': 'driver'}));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error. Check connection.'};
    }
  }

  static Future<Map<String, dynamic>> resetPassword(String phone, String otp, String newPassword) async {
    try {
      final res = await http.post(Uri.parse(ApiConfig.resetPassword),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone, 'otp': otp, 'newPassword': newPassword, 'userType': 'driver'}));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error. Check connection.'};
    }
  }
}
