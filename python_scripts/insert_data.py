import re
import argparse
import csv

import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore


def set_coupon(document, pay_name, benefits):
    coupon_doc_ref = document.collection("Payes").document()
    coupon_doc_ref.set({"pay_name": pay_name, "benefits": float(benefits[0])})
    print("insert coupon doc", coupon_doc_ref)


def insert_data(datas, collection_name):
    # datas: List[data, data,...,data]
    # data: [pay_name, genre, store_name, benefits, upper_bounds, lower_bounds, target_or_other]

    cred = credentials.Certificate("chimimoryo-firebase-adminsdk-uwfpa-6cb6f788eb.json")
    firebase_admin.initialize_app(cred)
    db = firestore.client()
    print("connect data base")

    for data in datas:
        pay_name = data[0]
        store_name = data[2]
        benefits = re.findall(r"\d+", data[3])

        print(f"pay_name:{pay_name}, store_name:{store_name}, benefits:{benefits}")
        if len(benefits) != 1:
            print("benefits infomation is unexpected")
            print(data)
            continue

        current_doc = (
            db.collection(collection_name).where("store_name", "==", store_name).get()
        )
        if (
            len(current_doc) == 1
        ):  # `collection_name`コレクション内のドキュメントに新たに追加する`store_name`が既に存在する
            print("insert store doc", current_doc[0])
            set_coupon(current_doc[0].reference, pay_name, benefits)
        elif len(current_doc) == 0:

            store_doc = db.collection(collection_name).document()
            store_doc.set({"store_name": store_name})
            print("insert store doc", store_doc)

            set_coupon(store_doc, pay_name, benefits)

        else:
            raise RuntimeError("collection内に同じstore_nameのドキュメントが複数存在している")


def get_data(csv_file_path):
    datas = []
    f = csv.reader(open(csv_file_path, "r"))

    for row in f:
        datas.append(row)
    return datas


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--path",
        type=str,
        help="importしたいcsvファイルのパス",
        default="python_scripts/data/coupons_info.csv",
    )
    parser.add_argument(
        "--collection", type=str, help="import先のcollection", default="__beta_1210"
    )
    args = parser.parse_args()
    datas = get_data(args.path)

    insert_data(datas, args.collection)
