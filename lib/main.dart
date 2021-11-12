import 'dart:io' show Platform;
import 'dart:math';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chimimoryo Autumn',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          child: const Text("起動する"),
          onPressed: () async {
            final urls = [
              'https://line.me/R/pay/generateQR',
              "https://www.paypay.ne.jp/app/cashier",
            ];
            final select = Random().nextInt(urls.length);
            final selectedUrl = urls[select];
            if (Platform.isAndroid) {
              AndroidIntent intent = AndroidIntent(
                action: 'action_view',
                data: selectedUrl,
              );
              await intent.launch();
            } else if (Platform.isIOS) {
              await canLaunch(selectedUrl)
                  ? await launch(selectedUrl)
                  : throw 'Could not launch $selectedUrl';
            }
          },
        ),
      ),
    );
  }
}
