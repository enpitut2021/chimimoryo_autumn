import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:android_intent_plus/android_intent.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:workmanager/workmanager.dart';

/// Used for Background Updates using Workmanager Plugin
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) {
    final now = DateTime.now();
    return Future.wait<bool?>([
      HomeWidget.saveWidgetData(
        'title',
        'Updated from Background',
      ),
      HomeWidget.saveWidgetData(
        'message',
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      ),
      HomeWidget.updateWidget(
        name: 'HomeWidgetExampleProvider',
        iOSName: 'HomeWidgetExample',
      ),
    ]).then((value) {
      return !value.contains(false);
    });
  });
}

/// Called when Doing Background Work initiated from Widget
void backgroundCallback(Uri? data) async {
  print(data);

  if (data!.host == 'titleclicked') {
    final greetings = 'こんにちは';

    await HomeWidget.saveWidgetData<String>('title', greetings);
    await HomeWidget.updateWidget(
        name: 'HomeWidgetExampleProvider', iOSName: 'HomeWidgetExample');
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Workmanager().initialize(callbackDispatcher, isInDebugMode: kDebugMode);
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
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  // 将来ウィジェットにおける操作から何かを反映したい時用
  @override
  void initState() {
    super.initState();
    print('init');
    HomeWidget.setAppGroupId('YOUR_GROUP_ID');
    HomeWidget.registerBackgroundCallback(backgroundCallback);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkForWidgetLaunch();
    HomeWidget.widgetClicked.listen(_launchedFromWidget);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendData() async {
    try {
      Future.wait([
        HomeWidget.saveWidgetData<String>('title', _titleController.text),
        HomeWidget.saveWidgetData<String>('message', _messageController.text),
      ]);
    } on PlatformException catch (exception) {
      debugPrint('Error Sending Data. $exception');
    }
  }

  Future<void> _updateWidget() async {
    try {
      HomeWidget.updateWidget(
          name: 'HomeWidgetExampleProvider', iOSName: 'HomeWidgetExample');
    } on PlatformException catch (exception) {
      debugPrint('Error Updating Widget. $exception');
    }
  }

  // For load data in home widget
  Future<void> _loadData() async {
    try {
      Future.wait([
        HomeWidget.getWidgetData<String>('title', defaultValue: 'Default Title')
            .then((value) => _titleController.text = value!),
        HomeWidget.getWidgetData<String>('message',
                defaultValue: 'Default Message')
            .then((value) => _messageController.text = value!),
      ]);
    } on PlatformException catch (exception) {
      debugPrint('Error Getting Data. $exception');
    }
  }

  // For send information to Home Widget
  Future<void> _sendAndUpdate() async {
    await _sendData();
    await _updateWidget();
  }

  void _checkForWidgetLaunch() {
    HomeWidget.initiallyLaunchedFromHomeWidget().then(_launchedFromWidget);
  }

  /// For PBI「おまけ：ウィジェット起動時とアプリ起動時で異なる動きができるかを調査」 in PBI4
  void _launchedFromWidget(Uri? uri) {
    if (uri != null) {
      showDialog(
          context: context,
          builder: (buildContext) => AlertDialog(
                title: Text('App started from HomeScreenWidget'),
                content: Text('Here is the URI: $uri'),
              ));
    }
  }

  final valueRate = {
    "SevenEleven": {"Linepay": 2, "Paypay": 1},
    "Lawson": {"Linepay": 2, "Paypay": 1},
    "FamilyMart": {"Linepay": 2, "Paypay": 1},
  };

  Future<void> launchRandomPay(String storeName) async {
    const linepayPath = 'https://line.me/R/pay/generateQR';
    const paypayPath = 'https://www.paypay.ne.jp/app/cashier';
    var urls = [];
    var linepayRate = valueRate[storeName]!["Linepay"]!;
    var paypayRate = valueRate[storeName]!["Paypay"]!;
    if (linepayRate is! int) {
      print("valueRate must be an int type.");
      linepayRate = 1;
    }
    if (paypayRate is! int) {
      print("valueRate must be an int type.");
      paypayRate = 1;
    }
    for (var i = 0; i < linepayRate; i++) {
      urls.add(linepayPath);
    }
    for (var i = 0; i < paypayRate; i++) {
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
