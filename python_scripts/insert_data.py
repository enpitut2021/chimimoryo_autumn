import re
import argparse
import csv

import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore


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

        store_doc_ref = db.collection(collection_name).document()
        store_doc_ref.set({"store_name": store_name})
        print("insert store dic", store_doc_ref)

        coupon_doc_ref = store_doc_ref.collection("Pays").document()
        coupon_doc_ref.set({"pay_name": pay_name, "benefits": float(benefits[0])})
        print("insert coupon dic", coupon_doc_ref)


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
