import 'dart:typed_data';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;

import 'package:jp_image_to_dict/constants.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    var appState = AppState();

    return ChangeNotifierProvider(
      create: (context) => appState,
      child: MaterialApp(
        home: Scaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              ParseImageSection(),
              ImagePreviewButton(),
              Divider(thickness: 3.0, color: Theme.of(context).dividerColor),
              Expanded(
                child: InAppWebView(
                  initialUrlRequest: URLRequest(
                      url: WebUri("https://jisho.hlorenzi.com/search/test"),
                      method: "GET"),
                  onWebViewCreated: (controller) {
                    appState.webViewController = controller;
                  },
                ),
                /*child: Placeholder(
                  child: Text("Web View Here"),
                ),
                */
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppState extends ChangeNotifier {
  String? capturedText;
  Uint8List? clipImage;
  double? imageHeight;
  Image? image;
  Uint8List? imagePngBytes;

  InAppWebViewController? webViewController;

  void captureFromClipboard() async {
    /* Capture Text only
    ClipboardData? clipboard = await Clipboard.getData('text/plain');
    print(clipboard?.text);
    capturedText = clipboard?.text;
    */
    final oldText = capturedText;

    clipImage = await Pasteboard.image;

    if (clipImage?.isNotEmpty ?? false) {
      // The Image class returned from this function is not the same as the Image widget from flutter
      var decodedImage = await decodeImageFromList(clipImage!);
      imageHeight = decodedImage.height.toDouble();
      var pngBytes = await decodedImage.toByteData(format: ImageByteFormat.png);

      // If this doesn't work for invalid image, its likely a matter of Uint size
      imagePngBytes = pngBytes!.buffer.asUint8List();

      // TODO: Call a function to turn the Spinner state on
      try {
        capturedText = await _ocrImage(imagePngBytes!);
      } finally {
        // TODO: Call a function to turn the Spinner state off
      }

      if (capturedText != null && capturedText != oldText) {
        _navigateWebView(capturedText!);
      }

      image = Image.memory(clipImage!);
    }

    notifyListeners();
  }

  Future<String> _ocrImage(Uint8List pngBytes) async {
    var request = http.MultipartRequest(
        "POST", Uri.http(ApiConstants.baseUrl, ApiConstants.ocrEndpoint))
      ..files.add(http.MultipartFile.fromBytes("file", pngBytes,
          filename: "upload.png",
          contentType: http_parser.MediaType('image', 'png')));

    http.Response response;
    try {
      var streamResp = await request.send();
      response = await http.Response.fromStream(streamResp);
      // response = await http.get(Uri.http(ApiConstants.baseUrl, "/"));
    } on http.ClientException catch (e) {
      print("API Call Exception: $e");
      return "";
    }

    if (response.statusCode == 200) {
      // TODO: Replace this with a class that converts the JSON response to an object
      // Will want that when the response later includes analysis, bounding boxes, etc.
      final decoded =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final text = decoded["captured_text"];

      return text;
    } else {
      throw Exception("Error received from API");
    }
  }

  void _navigateWebView(String capturedText) {
    // sanitize capturedText
    final searchUri = WebUri(
        Constants.lorenziJishoSearchPath + Uri.encodeComponent(capturedText));

    print(searchUri);
    print(webViewController);

    webViewController?.loadUrl(
        urlRequest: URLRequest(url: searchUri, method: "GET"));
  }
}

class ParseImageSection extends StatelessWidget {
  const ParseImageSection({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          FilledButton.tonal(
            child: Text("Read Text From Clipboard Image"),
            onPressed: () async {
              //print("Button pressed");
              /* Only gets text
              ClipboardData? clipboard = await Clipboard.getData('text/plain');
              print(clipboard?.text);
              */

              appState.captureFromClipboard();

              //final imageBytes = await Pasteboard.image;
              //print(imageBytes?.length);
              //print(imageBytes?.toString());
            },
          ),
          Expanded(
            child: Card(
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outline,
                ),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 5.0, bottom: 5.0),
                child: SizedBox(
                  child: Center(
                      child: Text(
                          appState.capturedText ?? "Parsed Text Goes Here")),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ImagePreviewButton extends StatelessWidget {
  const ImagePreviewButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();

    final bool enabled = appState.clipImage?.isNotEmpty ?? false;
    final VoidCallback? onPressed = enabled
        ? () {
            _showImagePreview(context, appState.image!, appState.imageHeight!);
          }
        : null;

    return FilledButton.tonal(
      onPressed: onPressed,
      child: Text("Show Image"),
    );
  }

  void _showImagePreview(BuildContext context, Image image, double height) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return ImagePreviewDialog(
          image: image,
          height: height,
        );
      },
    );
  }
}

class ImagePreviewDialog extends StatelessWidget {
  final Image image;
  final double height;

  const ImagePreviewDialog({
    super.key,
    required this.image,
    required this.height,
  });

  // Okay I have to explain here.
  // The WebView eats clicks within its frame, even though the Dialog pops up over it.
  // This includes clicking on the close button.
  // So I make sure to use MainAxisSize.max here because it forces the close button up into the top
  // of the app, where the web view notably isn't.

  // TODO: When removing the WebView, this can be changed to more closely fit the image, if desired.

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: Icon(Icons.close_sharp),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
            SizedBox(height: height, child: image),
          ],
        ),
      ),
    );
  }
}
