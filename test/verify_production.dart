import 'package:black_ai/config/app_config.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

void main() async {
  print("🔍 Testing Connection to Production Server...");
  print("URL: ${AppConfig.rootUrl}");

  try {
    final response = await http.get(Uri.parse('${AppConfig.rootUrl}/health'));

    if (response.statusCode == 200) {
      print("✅ SUCCESS! Server is reachable.");
      print("Response: ${response.body}");
    } else {
      print("❌ FAILED. Status Code: ${response.statusCode}");
      print("Response: ${response.body}");
    }
  } catch (e) {
    print("❌ ERROR: Could not connect to server.");
    print("Details: $e");
    print("\nTroubleshooting:");
    print("1. Check if Render deployment is finished (Green Checkmark).");
    print("2. Check if you added MONGODB_URL in Render Environment Variables.");
    print("3. Check if your internet is working.");
  }
}
