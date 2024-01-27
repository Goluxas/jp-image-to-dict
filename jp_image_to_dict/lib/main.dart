import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ParseImageSection(),
            Divider(thickness: 3.0, color: Theme.of(context).dividerColor),
            Expanded(
              child: Placeholder(
                child: Text("Embedded Web View goes Here"),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class ParseImageSection extends StatelessWidget {
  const ParseImageSection({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          FilledButton.tonal(
            child: Text("Read Text From Clipboard Image"),
            onPressed: () {
              print("Button pressed");
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
                  child: Center(child: Text("Parsed Text Goes Here")),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
