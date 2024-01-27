import 'dart:typed_data';

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
              ImagePreview(),
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

  void captureFromClipboard() async {
    /* Capture Text only
    ClipboardData? clipboard = await Clipboard.getData('text/plain');
    print(clipboard?.text);
    capturedText = clipboard?.text;
    */

    clipImage = await Pasteboard.image;
    if (clipImage?.isNotEmpty ?? false) {
      var decodedImage = await decodeImageFromList(clipImage!);
      imageHeight = decodedImage.height.toDouble();
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

class ImagePreview extends StatelessWidget {
  const ImagePreview({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();

    Widget output;
    double height = 20.0;

    if (appState.clipImage?.isNotEmpty ?? false) {
      // ! promotes the value to non-nullable since we just checked in the if
      print("image found and ready to convert from bytes");

      output = Image.memory(appState.clipImage!);
      height = appState.imageHeight!;
    } else {
      output = Placeholder();
    }

    return SizedBox(height: height, child: output);
  }
}
