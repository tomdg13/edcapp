class AppConfig {
  static const String baseUrl = 'http://10.0.28.109:3030';

  static Uri api(String endpoint) {
    return Uri.parse('$baseUrl$endpoint');
  }

  static String photoUrl(String photoName) {
    return '$baseUrl/photos/$photoName';
  }
}
