import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_config.dart'; // Correct import path based on file structure

class NodeAuthService {
  // ---------- COMMON HEADERS ----------
  static Map<String, String> _headers({String? token}) {
    final headers = {
      "Content-Type": "application/json",
      "ngrok-skip-browser-warning": "true",
    };

    if (token != null) {
      headers["Authorization"] = "Bearer $token";
    }
    return headers;
  }

  // ---------- SIGNUP ----------
  static Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("${AppConfig.baseUrl}/auth/signup"),
        headers: _headers(),
        body: jsonEncode({"name": name, "email": email, "password": password}),
      );

      if (response.headers['content-type']?.contains('application/json') ??
          false) {
        try {
          return jsonDecode(response.body);
        } catch (e) {
          return {
            "success": false,
            "message": "Invalid JSON response from server",
          };
        }
      }
    } catch (e) {
      return {"success": false, "message": "Connection error: ${e.toString()}"};
    }
    return {
      "success": false,
      "message": "Server is offline or returned an error",
    };
  }

  // ---------- LOGIN ----------
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("${AppConfig.baseUrl}/auth/login"),
        headers: _headers(),
        body: jsonEncode({"email": email, "password": password}),
      );

      Map<String, dynamic> data;
      if (response.headers['content-type']?.contains('application/json') ??
          false) {
        try {
          data = jsonDecode(response.body);
        } catch (e) {
          return {
            "success": false,
            "message": "Invalid JSON response from server",
          };
        }
      } else {
        return {
          "success": false,
          "message": "Server is offline or returned an error",
        };
      }

      final token = data["token"] ?? data["access_token"];

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("token", token);

        // Also save user info if available to keep app working
        if (data["user"] != null) {
          final user = data["user"];
          await prefs.setString("user_email", user["email"] ?? email);
          if (user["name"] != null) {
            await prefs.setString("user_name", user["name"]);
          }
          if (user["avatar"] != null) {
            await prefs.setString("user_avatar", user["avatar"]);
          }
          if (user["role"] != null) {
            await prefs.setString("user_role", user["role"]);
          }
          if (user["settings"] != null) {
            await prefs.setString(
              "user_settings",
              jsonEncode(user["settings"]),
            );
          }
        }
      }
      return data;
    } catch (e) {
      return {"success": false, "message": "Connection error: ${e.toString()}"};
    }
  }

  // ---------- GET PROFILE ----------
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final response = await http.get(
        Uri.parse("${AppConfig.baseUrl}/user/profile"),
        headers: _headers(token: token),
      );

      if (response.headers['content-type']?.contains('application/json') ??
          false) {
        try {
          return jsonDecode(response.body);
        } catch (e) {
          return {
            "success": false,
            "message": "Invalid JSON response from server",
          };
        }
      }
    } catch (e) {
      return {"success": false, "message": "Connection error: ${e.toString()}"};
    }
    return {
      "success": false,
      "message": "Server is offline or returned an error",
    };
  }

  // ---------- FORGOT PASSWORD ----------
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse("${AppConfig.fullUrl}/auth/forgot-password"),
        headers: _headers(),
        body: jsonEncode({"email": email}),
      );

      if (response.headers['content-type']?.contains('application/json') ??
          false) {
        try {
          return jsonDecode(response.body);
        } catch (e) {
          return {
            "success": false,
            "message": "Invalid JSON response from server",
          };
        }
      }
    } catch (e) {
      return {"success": false, "message": "Connection error: ${e.toString()}"};
    }
    return {
      "success": false,
      "message": "Server is offline or returned an error",
    };
  }

  // ---------- VERIFY OTP ----------
  static Future<Map<String, dynamic>> verifyOtp(
    String email,
    String otp,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("${AppConfig.fullUrl}/auth/verify-otp"),
        headers: _headers(),
        body: jsonEncode({"email": email, "otp": otp}),
      );

      if (response.headers['content-type']?.contains('application/json') ??
          false) {
        try {
          return jsonDecode(response.body);
        } catch (e) {
          return {
            "success": false,
            "message": "Invalid JSON response from server",
          };
        }
      }
    } catch (e) {
      return {"success": false, "message": "Connection error: ${e.toString()}"};
    }
    return {
      "success": false,
      "message": "Server is offline or returned an error",
    };
  }

  // ---------- RESET PASSWORD ----------
  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String password,
  }) async {
    try {
      final response = await http.put(
        Uri.parse("${AppConfig.fullUrl}/auth/reset-password"),
        headers: _headers(),
        body: jsonEncode({"email": email, "otp": otp, "password": password}),
      );

      if (response.headers['content-type']?.contains('application/json') ??
          false) {
        try {
          return jsonDecode(response.body);
        } catch (e) {
          return {
            "success": false,
            "message": "Invalid JSON response from server",
          };
        }
      }
    } catch (e) {
      return {"success": false, "message": "Connection error: ${e.toString()}"};
    }
    return {
      "success": false,
      "message": "Server is offline or returned an error",
    };
  }

  // ---------- UPDATE PROFILE ----------
  static Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? avatar,
    Map<String, dynamic>? settings,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final response = await http.put(
        Uri.parse("${AppConfig.fullUrl}/auth/updatedetails"),
        headers: _headers(token: token),
        body: jsonEncode({
          if (name != null) "name": name,
          if (avatar != null) "avatar": avatar,
          if (settings != null) "settings": settings,
        }),
      );

      if (response.headers['content-type']?.contains('application/json') ??
          false) {
        try {
          return jsonDecode(response.body);
        } catch (e) {
          return {
            "success": false,
            "message": "Invalid JSON response from server",
          };
        }
      }
    } catch (e) {
      return {"success": false, "message": "Connection error: ${e.toString()}"};
    }
    return {
      "success": false,
      "message": "Server is offline or returned an error",
    };
  }

  // ---------- DELETE ACCOUNT ----------
  static Future<Map<String, dynamic>> deleteAccount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final response = await http.delete(
        Uri.parse("${AppConfig.fullUrl}/auth/deleteme"),
        headers: _headers(token: token),
      );

      if (response.headers['content-type']?.contains('application/json') ??
          false) {
        try {
          return jsonDecode(response.body);
        } catch (e) {
          return {
            "success": false,
            "message": "Invalid JSON response from server",
          };
        }
      }
    } catch (e) {
      return {"success": false, "message": "Connection error: ${e.toString()}"};
    }
    return {
      "success": false,
      "message": "Server is offline or returned an error",
    };
  }

  // ---------- LOGOUT ----------
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");
    await prefs.remove("user_email");
    await prefs.remove("user_name");
    await prefs.remove("user_settings");
  }
}
