import 'dart:async';
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
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import 'package:jp_image_to_dict/constants.dart';
import 'package:super_clipboard/super_clipboard.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  void addPasteListener(AppState appState) {
    // When the user presses ctrl+v, intercept that and send the contents to the appState
    final events = ClipboardEvents.instance;

    if (events == null) {
      // ClipboardEvents only exist on web, so skip this setup
      return;
    }

    events.registerPasteEventListener((event) async {
      final reader = await event.getClipboardReader();

      if (reader.canProvide(Formats.png)) {
        reader.getFile(
          Formats.png,
          (file) {
            // This callback (onFile) is run every time another chunk of bytes comes through
            // But the file's stream will also emit all bytes, so we just send it off to
            // appState to handle stitching the file together.
            // appState also checks if the stream is new and rejects it if so, keeping us to
            // processing only the first stream, as we should.
            appState.processPaste(file.getStream());
          },
        );
      }
      // TODO: Handle other formats, if only to report to the user the paste was unusable
    });
  }

  @override
  Widget build(BuildContext context) {
    var appState = AppState();
    addPasteListener(appState);

    return ChangeNotifierProvider(
      create: (context) => appState,
      child: MaterialApp(
        home: Scaffold(
          body: ListView(
            shrinkWrap: true,
            children: <Widget>[
              ParseImageSection(),
              Divider(thickness: 3.0, color: Theme.of(context).dividerColor),
              EmbeddedJisho(),
            ],
          ),
        ),
      ),
    );
  }
}

class EmbeddedJisho extends StatelessWidget {
  const EmbeddedJisho({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Container(
      constraints:
          // By combining the container's constraints and the child SizedBox's height
          // we effectively create a box with a height of 800.0 or 80% of the viewport,
          // whichever is less.
          // NOTE: I picked 80% of viewport because the embed EATS ALL INPUTS for web users,
          // which would let them get trapped if they scrolled the ImageParseSection off screen
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
      child: SizedBox(
        height: 800.0,
        child: InAppWebView(
          initialUrlRequest: URLRequest(
              // Ugly. I should probably not include the trailing slash in the jishoPath
              // but later I do jishoSearchPath + encodedSearchQuery and it looks cleaner there
              url: WebUri("${Constants.jishoSearchPath}test"),
              method: "GET"),
          onWebViewCreated: (controller) {
            appState.webViewController = controller;
          },
        ),
      ),
    );
  }
}

class AppState extends ChangeNotifier {
  bool processing = false;

  Uint8List? _oldBytes;
  Uint8List? imagePngBytes;
  Image? imageWidget;

  String? capturedText;

  InAppWebViewController? webViewController;

  String? errorMessage;

  bool _receivingPaste = false;

  // These functions are used to turn on/off the progress spinner
  void _beginProcessing() {
    processing = true;
    notifyListeners();
  }

  void _endProcessing() {
    processing = false;
    notifyListeners();
  }

  Future<void> processPaste(Stream<Uint8List> pasteStream) async {
    if (_receivingPaste) {
      // Already received this stream and am still processing it.
      return;
    }

    _beginProcessing();
    _receivingPaste = true;
    final pasteBuilder = BytesBuilder();

    await for (final data in pasteStream) {
      pasteBuilder.add(data);
    }

    _receivingPaste = false;
    print("Updating with pasted file.");
    updateImageAndResults(pasteBuilder.toBytes());
  }

  void captureFromClipboard() async {
    // Firefox and Chrome cannot pull data from clipboard directly.
    // Keeping this method for posterity and for possible later native apps.

    /* Capture Text only
    ClipboardData? clipboard = await Clipboard.getData('text/plain');
    print(clipboard?.text);
    capturedText = clipboard?.text;
    */

    _beginProcessing();

    // BAD: Firefox and Chrome do not allow direct capture from keyboard. Fails silently.
    Uint8List? clipImage = await Pasteboard.image;

    if (clipImage != null && clipImage.isNotEmpty) {
      var decodedImage = await decodeImageFromList(clipImage);
      var pngBytes = await decodedImage.toByteData(format: ImageByteFormat.png);

      updateImageAndResults(pngBytes!.buffer.asUint8List());
    }
  }

  void updateImageAndResults(Uint8List newBytes) async {
    // First make sure this is a real update
    if (_oldBytes != null && listEquals(_oldBytes, newBytes)) {
      print("No change in bytes");
      _endProcessing();
      return;
    }

    _oldBytes = newBytes;
    final oldText = capturedText;

    await updateImage(newBytes);

    // TODO: Call a function to turn the Spinner state on
    try {
      print("Waiting for OCR Response...");
      capturedText = await _ocrImage(imagePngBytes!);
    } catch (error) {
      addError(error.toString(), StackTrace.current);
      return;
    } finally {
      // TODO: Call a function to turn the Spinner state off
      print("Done.");
    }

    if (capturedText != null && capturedText != oldText) {
      if (Constants.allowJishoEmbed) {
        //_navigateWebView(capturedText!);
        print(
            "Web view autonavigation temporarily disabled while the Long Text Problem is being fixed.");
      } else {
        print("Would have navigated to Jisho page.");
      }
    }

    _endProcessing();
    notifyListeners();
  }

  Future<void> updateImage(Uint8List newBytes) async {
    // NOTE: The Image class returned from this function is not the same as the Image widget from flutter

    //final decodedImage = await decodeImageFromList(newBytes);
    final decodedImage = img.decodeImage(newBytes);
    if (decodedImage == null) {
      addError("Unable to decode bytes.", StackTrace.current);
      return;
    }

    // Encode newBytes as PNG
    // It may already be a PNG but I don't know how to verify that
    // in a way that doesn't require decoding the whole file anyway
    Uint8List encoded = Uint8List(0);
    try {
      //encoded = await decodedImage.toByteData(format: ImageByteFormat.png);
      encoded = img.encodePng(decodedImage);
    } catch (error) {
      addError(error.toString(), StackTrace.current);
    }

    //imagePngBytes = encoded?.buffer.asUint8List();
    imagePngBytes = encoded;

    if (imagePngBytes != null) {
      imageWidget = Image.memory(newBytes);

      notifyListeners();
    }
  }

  Future<String?> _ocrImage(Uint8List pngBytes) async {
    var request = http.MultipartRequest(
        "POST", Uri.parse(ApiConstants.baseUrl + ApiConstants.ocrEndpoint))
      ..files.add(http.MultipartFile.fromBytes("file", pngBytes,
          filename: "upload.png",
          contentType: http_parser.MediaType('image', 'png')));

    http.Response response;
    try {
      var streamResp = await request.send();
      response = await http.Response.fromStream(streamResp);
      // response = await http.get(Uri.http(ApiConstants.baseUrl, "/"));
    } on http.ClientException catch (e) {
      addError("API Call Exception: $e", StackTrace.current);
      return null;
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

  Future<void> _navigateWebView(String capturedText) async {
    // sanitize capturedText
    final urlsafeCapturedText = Uri.encodeComponent(capturedText);

    if (urlsafeCapturedText.length > 6000) {
      addError("Captured text too long to send to Jisho", StackTrace.current);
      return;
    }

    final searchUri = WebUri(Constants.jishoSearchPath + urlsafeCapturedText);

    print("Navigating to Jisho page.");
    try {
      await webViewController?.loadUrl(
          urlRequest: URLRequest(url: searchUri, method: "GET"));
    } catch (error) {
      addError(error.toString(), StackTrace.current);
    }
  }

  void addError(String error, StackTrace stackTrace) {
    // Awkward way to report error, repurposing the captured text box
    // TODO: Use a SnackBar or something
    capturedText = null;
    errorMessage = error;
    print(stackTrace);

    notifyListeners();
  }

  Future<void> handleUpload() async {
    _beginProcessing();

    final picker = ImagePicker();
    Uint8List? imageBytes;
    try {
      final pickedImage = await picker.pickImage(source: ImageSource.gallery);
      imageBytes = await pickedImage?.readAsBytes();
    } catch (error) {
      addError(error.toString(), StackTrace.current);
    }

    if (imageBytes != null) {
      updateImageAndResults(imageBytes);
    } else {
      addError("Error while receiving image: Image empty.", StackTrace.current);
      return;
    }
    // for testing api access easily
    // TODO: make an actual function that checks for the response body too, because this misses CORS issues
    // http.get(Uri.parse(ApiConstants.baseUrl));
  }
}

class ParseImageSection extends StatelessWidget {
  const ParseImageSection({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();

    /*
    /// Old method: Clicking button pulls from clipboard
    // Only use captureFromClipboard if not web
    // Should probably change it from a button to a text display that says Paste Your Image (CTRL+V)
    final VoidCallback? onPressed = kIsWeb
        ? null
        : () async {
            // Only gets text
            //ClipboardData? clipboard = await Clipboard.getData('text/plain');

            appState.captureFromClipboard();
          };
    */

    Future<void> uploadButtonOnPressed() async {
      appState.handleUpload();
    }

    void imagePreviewOnPressed() {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) {
          return ImagePreviewDialog(
            imageBytes: appState.imagePngBytes!,
          );
        },
      );
    }

    Widget cardContents() {
      if (appState.processing) {
        return CircularProgressIndicator(value: null);
      }

      if (appState.errorMessage != null && appState.capturedText == null) {
        return SelectableText(appState.errorMessage!);
      }

      return SelectableText(appState.capturedText ?? "Captured Text Goes Here");
    }

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LabeledIconButton(
                  label: Text("(or paste)"),
                  icon: Icon(Icons.add_photo_alternate),
                  onPressed: uploadButtonOnPressed),
              if (appState.imagePngBytes != null) SizedBox(width: 5.0),
              if (appState.imagePngBytes != null)
                LabeledIconButton(
                  label: Text("Show Image"),
                  icon: Icon(Icons.photo),
                  onPressed: imagePreviewOnPressed,
                ),
            ],
          ),
          SizedBox(height: 5.0),
          Card(
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: Theme.of(context).colorScheme.outline,
              ),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
              child: Center(
                child: cardContents(),
              ),
            ),
          ),
          if (appState.imagePngBytes != null)
            // TODO: Improve this feature and remove this prompt
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [Icon(Icons.arrow_upward), Text("Copy this")],
                ),
                Column(
                  children: [Text("Paste below"), Icon(Icons.arrow_downward)],
                ),
                SizedBox(width: 8.0),
                Text(
                    "Try to select a few sentences AT MOST. Too much text will break the site."),
              ],
            )
        ],
      ),
    );
  }
}

class LabeledIconButton extends StatelessWidget {
  final Text label;
  final Icon icon;
  final VoidCallback? onPressed;

  const LabeledIconButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
      onPressed: onPressed,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            icon,
            label,
          ],
        ),
      ),
    );
  }
}

class ImagePreviewDialog extends StatelessWidget {
  final Uint8List imageBytes;

  const ImagePreviewDialog({
    super.key,
    required this.imageBytes,
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
          //mainAxisSize: MainAxisSize.max,
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
            Flexible(
              child: Image.memory(
                imageBytes,
                fit: BoxFit.scaleDown,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
