// for clipboard text: import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:pasteboard/pasteboard.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppState(),
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

  void captureFromClipboard() async {
    /* Capture Text only
    ClipboardData? clipboard = await Clipboard.getData('text/plain');
    print(clipboard?.text);
    capturedText = clipboard?.text;
    */

    clipImage = await Pasteboard.image;
    if (clipImage?.isNotEmpty ?? false) {
      // The Image class returned from this function is not the same as the Image widget from flutter
      var decodedImage = await decodeImageFromList(clipImage!);
      imageHeight = decodedImage.height.toDouble();
      var pngBytes = await decodedImage.toByteData(format: ImageByteFormat.png);

      // If this doesn't work for invalid image, its likely a matter of Uint size
      imagePngBytes = pngBytes!.buffer.asUint8List();

      image = Image.memory(clipImage!);
    }

    // TODO: Connect with Cloud Vision and send the image off to them
    capturedText = "<Not Yet Implemented>";

    notifyListeners();
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
