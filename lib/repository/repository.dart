import 'package:cloud_firestore/cloud_firestore.dart';

class Repository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 店舗IDを渡すと推薦された支払い方法が返ってくる
  Future<String> getRecommendedPay(String store) async {
    final docSnap = await _firestore.collection("__beta").doc("__beta").get();
    final data = docSnap.data();
    if (data == null) {
      throw "データがnullで返ってきました";
    }
    return data[store];
  }
}
