class Constants {
  static String lorenziJishoSearchPath = "https://jisho.hlorenzi.com/search/";

  // Defaults to true for safety
  static const bool isDevelopment =
      bool.fromEnvironment("IS_DEVELOPMENT", defaultValue: true);

  // Used when testing web access from an Android emulator's browser
  static const bool isMobileTest =
      bool.fromEnvironment("IS_MOBILE_TEST", defaultValue: false);

  // false will stop the app from sending capturedText to the embedded website
  // Useful to give the guy a break while I'm writing broken code
  static const bool allowJishoEmbed = !isDevelopment;
}

class ApiConstants {
  // My PC
  static const String _localApi = "http://localhost:8000";
  // Local Dev with Android Emulator
  static const String _androidApi = "http://10.0.2.2:8000";
  // Backend hosted on Render
  static const String _remoteApi = "https://jp-image-to-dict.onrender.com";

  static String _chooseApi() {
    if (Constants.isMobileTest) {
      return _androidApi;
    }

    return Constants.isDevelopment ? _localApi : _remoteApi;
  }

  static String baseUrl = _chooseApi();
  static String ocrEndpoint = "/ocr/png/";
}
