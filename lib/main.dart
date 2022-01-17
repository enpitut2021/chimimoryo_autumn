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
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import './secret_const.dart';
import 'models/pay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

const locale = Locale("ja", "JP");

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
      locale: locale,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        locale,
      ],
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

  List<Store>? _storeList;

  // 将来ウィジェットにおける操作から何かを反映したい時用
  @override
  void initState() {
    super.initState();

    _refreshStoreList();
  }

  Future _refreshStoreList() async {
    setState(() {
      _storeList = null;
    });
    final storeList = await filteredStores();
    setState(() {
      _storeList = storeList;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  final valueRate = {
    "SevenEleven": {"Linepay": 2, "Paypay": 1},
    "Lawson": {"Linepay": 2, "Paypay": 1},
    "FamilyMart": {"Linepay": 2, "Paypay": 1},
  };

  Future<List<Store>> filteredStores() async {
    final storeRepo = StoreRepository();
    final futureResults = await Future.wait<dynamic>(
        [getLocationAndStoreList(), storeRepo.getStores()]);
    final Set<String> storeListByLocation = futureResults[0];
    final List<Store> storeListByDB = futureResults[1];
    final filteredStoreList =
        intersectionStores(storeListByLocation, storeListByDB);
    return filteredStoreList.toList();
  }

  Future<Set<String>> getLocationAndStoreList() async {
    Position position = await getLocation();
    Set<String> storeListByLocation = await getStoreListByLocation(position);
    return storeListByLocation;
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
        return Store(name: storeName, pays: store.pays);
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
        actions: [
          IconButton(
            onPressed: () {
              _refreshStoreList();
            },
            icon: const Icon(Icons.refresh, size: 30),
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Builder(builder: (context) {
              if (_storeList == null) {
                return const Padding(
                  child: Center(child: CircularProgressIndicator()),
                  padding: EdgeInsets.all(15),
                );
              }

              if (_storeList!.isEmpty) {
                return const Padding(
                  child: Text(
                    "見つかりませんでした...",
                    style: TextStyle(
                      fontSize: 20,
                    ),
                  ),
                  padding: EdgeInsets.all(15),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  final storeList = _storeList;
                  if (storeList == null) {
                    return Container();
                  }
                  final store = storeList[index];
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
                itemCount: _storeList?.length ?? 0,
              );
            }),
            Spacer(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info,
                          size: 30,
                          color: Colors.black54,
                        ),
                        const SizedBox(width: 6, height: 0),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              "今いるお店がみつかりませんか？",
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.black54,
                              ),
                            ),
                            Text(
                              "下のボタンから直接Payを開けます",
                              style: TextStyle(
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 24, width: 0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        LaunchPayButton(
                          onPressed: () {
                            launchPay("LINE_PAY");
                          },
                          payService: PayService.linepay,
                        ),
                        LaunchPayButton(
                          onPressed: () {
                            launchPay("PAY_PAY");
                          },
                          payService: PayService.paypay,
                        ),
                      ],
                    ),
                  ],
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(12),
              ),
            ),
            // Padding(
            //   padding: const EdgeInsets.only(bottom: 32.0),
            //   child:
            // ),
          ],
        ),
      ),
    );
  }
}

enum PayService {
  paypay,
  linepay,
}

class LaunchPayButton extends StatelessWidget {
  final void Function() onPressed;
  final PayService payService;

  String get payServiceText {
    if (payService == PayService.linepay) {
      return "LINE Pay";
    } else if (payService == PayService.paypay) {
      return "Pay Pay";
    } else {
      return "不明なPay";
    }
  }

  Color get payServiceColor {
    if (payService == PayService.linepay) {
      return const Color(0xff08bf5b);
    } else if (payService == PayService.paypay) {
      return const Color(0xfff24f4f);
    } else {
      return Colors.red;
    }
  }

  const LaunchPayButton({
    Key? key,
    required this.onPressed,
    required this.payService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      child: Text(
        payServiceText,
        style: TextStyle(
          color: payServiceColor,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: payServiceColor,
          width: 2,
        ),
        fixedSize: const Size(130, 48),
      ),
    );
  }
}
