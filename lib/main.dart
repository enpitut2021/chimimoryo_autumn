import 'dart:io' show Platform;
import 'dart:math';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:quiver/iterables.dart';

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
  var valueRate = {
    "SevenEleven": {"Linepay": 2, "Paypay": 1},
    "Lawson": {"Linepay": 2, "Paypay": 1},
    "FamilyMart": {"Linepay": 2, "Paypay": 1},
  };

  Future<void> launchRandomPay(String storeName) async {
    const linepayPath = 'https://line.me/R/pay/generateQR';
    const paypayPath = 'https://www.paypay.ne.jp/app/cashier';
    var urls = [];
    for (final _ in range(valueRate[storeName]!["Linepay"]!)) {
      urls.add(linepayPath);
    }
    for (final _ in range(valueRate[storeName]!["Paypay"]!)) {
      urls.add(paypayPath);
    }
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
              onPressed: () {
                launchRandomPay('FamilyMart');
              },
            ),
            IconButton(
              icon: Image.asset("assets/images/lawson.png"),
              iconSize: 128.0,
              onPressed: () {
                launchRandomPay('SevenEleven');
              },
            ),
            IconButton(
              icon: Image.asset("assets/images/seveneleven.png"),
              iconSize: 128.0,
              onPressed: () {
                launchRandomPay('Lawson');
              },
            ),
          ],
        ),
      ),
    );
  }
}
