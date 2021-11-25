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
  void initState() {
    //アプリ起動時に一度だけ実行される
    super.initState();
    launchRandomPay();
  }

  var valueRate = {
    "SevenEleven": {"Paypay": 1, "Linepay": 1}
  };

  Future<void> launchRandomPay() async {
    final urls = [
      'https://line.me/R/pay/generateQR',
      "https://www.paypay.ne.jp/app/cashier",
    ];
    final select = Random().nextInt(urls.length);
    var selectedUrl = urls[select];
    if (Platform.isAndroid) {
      AndroidIntent intent = AndroidIntent(
        action: 'action_view',
        data: selectedUrl,
      );
      await intent.launch();
    } else if (Platform.isIOS) {
      if (selectedUrl == "https://www.paypay.ne.jp/app/cashier") {
        selectedUrl = 'paypay://';
      }
      await canLaunch(selectedUrl)
          ? await launch(selectedUrl)
          : throw 'Could not launch $selectedUrl';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Image.asset("assets/images/familymart.png"),
              iconSize: 128.0,
              onPressed: launchRandomPay,
            ),
            IconButton(
              icon: Image.asset("assets/images/lawson.png"),
              iconSize: 128.0,
              onPressed: launchRandomPay,
            ),
            IconButton(
              icon: Image.asset("assets/images/seveneleven.png"),
              iconSize: 128.0,
              onPressed: launchRandomPay,
            ),
          ],
        ),
      ),
    );
  }
}
