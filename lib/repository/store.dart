import 'package:chimimoryo_autumn/models/pay.dart';
import 'package:chimimoryo_autumn/models/store.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StoreRepository {
  late FirebaseFirestore firestore;

  StoreRepository() {
    firestore = FirebaseFirestore.instance;
  }

  Future<List<Store>> getStores() async {
    /// __beta_1210/A94KOsRMgd5Sfk7JkI6u/Pays/0F7Jj4KRsnUB3oTTvLBe

    final qSnap = await firestore.collection("__beta_1210").get();
    print(qSnap.docs.length);
    final storeFutures = qSnap.docs.map((doc) async {
      final data = doc.data();
      final storeName = data["store_name"];

      final paysQSnap = await doc.reference.collection("Pays").get();
      final pays = paysQSnap.docs.map((payDoc) {
        final payData = payDoc.data();
        return Pay(name: payData["pay_name"], benefit: payData["benefits"]);
      });

      return Store(name: storeName, pays: pays.toList());
    });

    final stores = await Future.wait(storeFutures);

    return stores;
  }
}
