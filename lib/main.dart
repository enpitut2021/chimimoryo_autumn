import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:android_intent_plus/android_intent.dart';
import 'package:chimimoryo_autumn/models/store.dart';
import 'package:chimimoryo_autumn/repository/repository.dart';
import 'package:chimimoryo_autumn/repository/store.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:home_widget/home_widget.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:workmanager/workmanager.dart';

import './secret_const.dart';
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

  Future<List<Store>> filteredStores() async {
    Position position = await getLocation();
    Set<String> storeListByLocation = await getStoreListByLocation(position);
    final storeRepo = StoreRepository();
    final storeListByDB = await storeRepo.getStores();
    final filteredStoreList =
        intersectionStores(storeListByLocation, storeListByDB);
    return filteredStoreList.toList();
  }

  Future<Position> getLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again
        return Future.error('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    return position;
  }

  Future<Set<String>> getStoreListByLocation(Position position) async {
    final latitude = position.latitude.toString();
    final longitude = position.longitude.toString();
    const dist = 3;
    const outputType = "json";
    const sortType = "dist";

    final url = Uri.parse(
        "https://map.yahooapis.jp/search/local/V1/localSearch?appid=${yahooApiKey}&lat=${latitude}&lon=${longitude}&dist=${dist}&output=${outputType}&sort=${sortType}");
    final response = await http.get(url);

    final Map<String, dynamic> jsonData = jsonDecode(response.body);

    // 空の場合 Feature プロパティが存在しないので、空のSetを返す
    if (!jsonData.keys.contains("Feature")) {
      return {}; // Dartで {} は空のSetを表す
    }

    final features = jsonData["Feature"];
    Set<String> stores = Set.from(features.map((feature) => feature["Name"]));
    return stores;
  }

  Set<Store> intersectionStores(
      Set<String> storeListByLocation, List<Store> storeListByDB) {
    var filteredStores = [];
    storeListByLocation.forEach((storeName) {
      final store = includeDB(storeName, storeListByDB);
      if (store != null) {
        filteredStores.add(store);
      }
    });
    return Set.from(filteredStores);
  }

  Store? includeDB(String storeName, List<Store> storeListByDB) {
    for (var store in storeListByDB) {
      if (storeName.contains(store.name) || store.name.contains(storeName)) {
        return store;
      }
    }
    return null;
  }

  void showUseCouponPopup(String pay) {
    String pay_name = "";
    if (pay == "LINE Pay") {
      pay_name = "LINE Payクーポン";
    } else if (pay == "PayPay") {
      pay_name = "PayPayクーポン";
    } else {
      throw Exception();
    }
    Fluttertoast.showToast(
        msg: "お得になるクーポンを$pay_nameからゲットしましょう！🉐", //メッセージ
        timeInSecForIosWeb: 1, //ポップアップを出す時間
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0);
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
      appBar: AppBar(
        title: const Text("近くのお店"),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Builder(
              builder: (context) {
                final storeRepo = StoreRepository();
                return FutureBuilder<List<Store>>(
                  //future: storeRepo.getStores(),
                  future: filteredStores(),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Padding(
                          child: Center(child: CircularProgressIndicator()),
                          padding: EdgeInsets.all(15));
                    }
                    final stores = snap.data;
                    if (stores == null) {
                      return Container();
                    }
                    if (stores.isEmpty) {
                      return const Padding(
                          child: Text("見つかりませんでした...",
                              style: TextStyle(
                                fontSize: 20,
                              )),
                          padding: EdgeInsets.all(15));
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        final store = stores[index];
                        return ListTile(
                          onTap: () {
                            Pay maxBenefitPay = store.pays[0];
                            num maxBenefit = store.pays[0].benefit;
                            for (var pay in store.pays) {
                              if (pay.benefit > maxBenefit) {
                                maxBenefitPay = pay;
                              }
                            }
                            showUseCouponPopup(maxBenefitPay.name);
                            if (maxBenefitPay.name == "LINE Pay") {
                              launchPay("LINE_PAY");
                            } else {
                              launchPay("PAY_PAY");
                            }
                          },
                          title: Text(store.name),
                        );
                      },
                      itemCount: stores.length,
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
