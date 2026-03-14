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
    // Save commonly accessed fields separately for quick reads
    final name = userData['fullName'] ?? userData['full_name'] ?? userData['name'] ?? '';
    final phone = userData['phone'] ?? '';
    if (name.toString().isNotEmpty) await prefs.setString('user_name', name.toString());
    if (phone.toString().isNotEmpty) await prefs.setString('user_phone', phone.toString());
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

  static const Map<String, String> _base = {
    'Content-Type': 'application/json',
    'User-Agent': 'JAGO-Driver/1.0 (Android)',
    'Accept': 'application/json',
  };

  static Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {..._base, if (token != null) 'Authorization': 'Bearer $token'};
  }

  static Future<Map<String, dynamic>> sendOtp(String phone, [String userType = 'driver']) async {
    try {
      final res = await http.post(
        Uri.parse(ApiConfig.sendOtp),
        headers: _base,
        body: jsonEncode({'phone': phone, 'userType': userType}),
      );
      if (!(res.headers['content-type'] ?? '').contains('application/json')) {
        return {'success': false, 'message': 'Server error. Please try again.'};
      }
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'message': 'Network error. Check your connection.'};
    }
  }

  static Future<Map<String, dynamic>> verifyOtp(String phone, String otp, [String userType = 'driver']) async {
    try {
      final res = await http.post(
        Uri.parse(ApiConfig.verifyOtp),
        headers: _base,
        body: jsonEncode({'phone': phone, 'otp': otp, 'userType': userType}),
      );
      if (!(res.headers['content-type'] ?? '').contains('application/json')) {
        return {'success': false, 'message': 'Server error. Please try again.'};
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && data['token'] != null) {
        await saveToken(data['token']);
        await saveUser(data['user'] ?? data);
        // Save FCM token to server after login
        FcmService().onLoginSuccess().catchError((_) {});
      }
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Network error. Check your connection.'};
    }
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
        headers: _base,
        body: jsonEncode({'phone': phone, 'password': password, 'userType': 'driver'}));
      if (!(res.headers['content-type'] ?? '').contains('application/json')) {
        return {'success': false, 'message': 'Server error. Please try again.'};
      }
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

  /// Verify a Firebase Phone Auth ID token with our server.
  static Future<Map<String, dynamic>> verifyFirebaseToken(String idToken, String phone, [String userType = 'driver']) async {
    try {
      final res = await http.post(Uri.parse(ApiConfig.verifyFirebaseToken),
        headers: _base,
        body: jsonEncode({'firebaseIdToken': idToken, 'phone': phone, 'userType': userType}));
      if (!(res.headers['content-type'] ?? '').contains('application/json')) {
        return {'success': false, 'message': 'Server error. Please try again.'};
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && data['token'] != null) {
        await saveToken(data['token']);
        await saveUser(data['user'] ?? data);
        FcmService().onLoginSuccess().catchError((_) {});
      }
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Network error. Check your connection.'};
    }
  }

  static Future<Map<String, dynamic>> registerWithPassword(String phone, String password, String fullName, {String? email, String? vehicleNumber, String? vehicleModel, String? vehicleCategoryId}) async {    try {
      final body = <String, dynamic>{'phone': phone, 'password': password, 'fullName': fullName, 'userType': 'driver'};
      if (email != null && email.isNotEmpty) body['email'] = email;
      final res = await http.post(Uri.parse(ApiConfig.registerAccount),
        headers: _base,
        body: jsonEncode(body));
      if (!(res.headers['content-type'] ?? '').contains('application/json')) {
        return {'success': false, 'message': 'Server error. Please try again.'};
      }
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
        headers: _base,
        body: jsonEncode({'phone': phone, 'userType': 'driver'}));
      if (!(res.headers['content-type'] ?? '').contains('application/json')) {
        return {'success': false, 'message': 'Server error. Please try again.'};
      }
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error. Check connection.'};
    }
  }

  static Future<Map<String, dynamic>> resetPassword(String phone, String otp, String newPassword) async {
    try {
      final res = await http.post(Uri.parse(ApiConfig.resetPassword),
        headers: _base,
        body: jsonEncode({'phone': phone, 'otp': otp, 'newPassword': newPassword, 'userType': 'driver'}));
      if (!(res.headers['content-type'] ?? '').contains('application/json')) {
        return {'success': false, 'message': 'Server error. Please try again.'};
      }
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error. Check connection.'};
    }
  }

  static Future<Map<String, dynamic>> resetPasswordWithFirebase(String firebaseIdToken, String phone, String newPassword) async {
    try {
      final res = await http.post(Uri.parse(ApiConfig.resetPasswordFirebase),
        headers: _base,
        body: jsonEncode({'firebaseIdToken': firebaseIdToken, 'phone': phone, 'newPassword': newPassword, 'userType': 'driver'}));
      if (!(res.headers['content-type'] ?? '').contains('application/json')) {
        return {'success': false, 'message': 'Server error. Please try again.'};
      }
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error. Check connection.'};
    }
  }
}
