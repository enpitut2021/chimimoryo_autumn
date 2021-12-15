import 'dart:async';
import 'dart:io' show Platform;

import 'package:android_intent_plus/android_intent.dart';
import 'package:chimimoryo_autumn/models/store.dart';
import 'package:chimimoryo_autumn/repository/repository.dart';
import 'package:chimimoryo_autumn/repository/store.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:workmanager/workmanager.dart';

import 'models/pay.dart';

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
  if (data!.host == 'titleclicked') {
    const greetings = 'こんにちは';

    await HomeWidget.saveWidgetData<String>('title', greetings);
    await HomeWidget.updateWidget(
        name: 'HomeWidgetExampleProvider', iOSName: 'HomeWidgetExample');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Workmanager().initialize(callbackDispatcher, isInDebugMode: kDebugMode);
  await Firebase.initializeApp();
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
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title})
      : repo = Repository(),
        super(key: key);

  final String title;
  final Repository repo;

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
    // getLocationAndLaunchPay();
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

  void getLocationAndLaunchPay() async {
    final store = getLocation();
    final pay = await widget.repo.getRecommendedPay(store);
    launchPay(pay);
  }

  String getLocation() {
    // TODO: GPSを用いて店の情報を取得
    return 'seven_eleven';
  }

  Future<void> launchPay(String pay) async {
    const androidUrl = {
      "PAY_PAY": "https://www.paypay.ne.jp/app/cashier",
      "LINE_PAY": "https://line.me/R/pay/generateQR",
    };

    const iosUrl = {
      "PAY_PAY": "paypay://",
      "LINE_PAY": "https://line.me/R/pay/generateQR",
    };

    if (Platform.isAndroid) {
      final url = androidUrl[pay];
      if (url == null) {
        throw "不明なPayが指定されています";
      }
      AndroidIntent intent = AndroidIntent(
        action: 'action_view',
        data: url,
      );
      await intent.launch();
    } else if (Platform.isIOS) {
      final url = iosUrl[pay];
      if (url == null) {
        throw "不明なPayが指定されています";
      }
      await launch(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Builder(
          builder: (context) {
            final storeRepo = StoreRepository();
            return FutureBuilder<List<Store>>(
              future: storeRepo.getStores(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return Container();
                } else {
                  final stores = snap.data;
                  if (stores == null) {
                    return Container();
                  }
                  return ListView.builder(
                    itemBuilder: (context, index) {
                      final store = stores[index];
                      return ElevatedButton(
                        onPressed: () {
                          Pay maxBenefitPay = store.pays[0];
                          num maxBenefit = store.pays[0].benefit;
                          for (var pay in store.pays) {
                            if (pay.benefit > maxBenefit) {
                              maxBenefitPay = pay;
                            }
                          }
                          if (maxBenefitPay.name == "LINE Pay") {
                            launchPay("LINE_PAY");
                          } else {
                            launchPay("PAY_PAY");
                          }
                        },
                        child: Text(store.name),
                      );
                    },
                    itemCount: stores.length,
                  );
                }
              },
            );
          },
        ),
      ),
    );
  }
}
