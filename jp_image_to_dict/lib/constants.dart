class Constants {
  static String lorenziJishoSearchPath = "https://jisho.hlorenzi.com/search/";

  // Defaults to true for safety
  static const bool isDevelopment =
      bool.fromEnvironment("IS_DEVELOPMENT", defaultValue: true);

  // false will stop the app from sending capturedText to the embedded website
  // Useful to give the guy a break while I'm writing broken code
  static const bool allowJishoEmbed = !isDevelopment;
}

class ApiConstants {
  // My PC
  static const String _localApi = "http://localhost:8221";
  // Backend hosted on Render
  static const String _remoteApi = "https://jp-image-to-dict.onrender.com";

  static String baseUrl = Constants.isDevelopment ? _localApi : _remoteApi;
  static String ocrEndpoint = "/ocr/png/";
}
