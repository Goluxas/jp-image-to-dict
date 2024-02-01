class Constants {
  static const String _lorenziJishoSearchPath =
      "https://jisho.hlorenzi.com/search/";
  static const String _jishoOrgSearchPath = "https://jisho.org/search/";

  static const String _useJisho =
      String.fromEnvironment("USING_JISHO", defaultValue: "lorenzi");

  static String jishoSearchPath = switch (_useJisho.toUpperCase()) {
    "LORENZI" => _lorenziJishoSearchPath,
    "JISHO.ORG" => _jishoOrgSearchPath,
    _ => _lorenziJishoSearchPath,
  };

  // Defaults to true for safety
  static const bool isDevelopment =
      bool.fromEnvironment("IS_DEVELOPMENT", defaultValue: true);

  // false will stop the app from sending capturedText to the embedded website
  // Useful to give the guy a break while I'm writing broken code
  static const bool allowJishoEmbed =
      bool.fromEnvironment("ALLOW_EMBED", defaultValue: !isDevelopment);
}

class ApiConstants {
  // Local Dev
  static const String _localApi = "http://localhost:8000";
  // Local Dev with Android Emulator
  static const String _androidApi = "http://10.0.2.2:8000";
  // Backend hosted on Render
  static const String _renderApi = "https://jp-image-to-dict.onrender.com";
  // Self-hosted backend
  static const String _selfHostedApi =
      "http://rattler-adequate-meerkat.ngrok-free.app";

  static const String _defaultApi = _localApi;
  static const String _useApi =
      String.fromEnvironment("USING_API", defaultValue: "LOCAL");

  static String baseUrl = switch (_useApi.toUpperCase()) {
    "LOCAL" => _localApi,
    "MOBILE_TEST" => _androidApi,
    "RENDER" => _renderApi,
    "SELFHOSTED" => _selfHostedApi,
    _ => _defaultApi,
  };

  static String ocrEndpoint = "/ocr/png/";
}
