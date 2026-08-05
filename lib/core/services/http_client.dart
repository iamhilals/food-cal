import 'package:http/http.dart' as http;

class CustomHttpClient {
  static final http.Client _client = http.Client();

  static Map<String, String> get headers => {
        'User-Agent': 'SmartIngredientsApp/1.0.0 (Windows; Flutter; https://github.com/example/food-cal)',
        'Content-Type': 'application/json',
      };

  static Future<http.Response> get(Uri url) async {
    return await _client.get(url, headers: headers);
  }

  static Future<http.Response> post(Uri url, {Object? body}) async {
    return await _client.post(
      url,
      headers: headers,
      body: body,
    );
  }
}
