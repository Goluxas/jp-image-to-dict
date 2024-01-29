class Constants {
  static String lorenziJishoSearchPath = "https://jisho.hlorenzi.com/search/";

  // Defaults to true for safety
  static const bool isDevelopment =
      String.fromEnvironment("IS_DEVELOPMENT", defaultValue: "true") == "true";
}

class ApiConstants {
  // My PC
  static const String _localApi = "localhost:8221";
  // Backend hosted on Render
  static const String _remoteApi = "jp-image-to-dict.onrender.com";

  static String baseUrl = Constants.isDevelopment ? _localApi : _remoteApi;
  static String ocrEndpoint = "/ocr/png/";
}
