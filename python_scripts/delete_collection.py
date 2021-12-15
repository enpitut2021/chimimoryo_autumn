import argparse

import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore


def delete_collection(collection_name):
    cred = credentials.Certificate("chimimoryo-firebase-adminsdk-uwfpa-6cb6f788eb.json")
    firebase_admin.initialize_app(cred)
    db = firestore.client()
    print("connect data base")

    all_documents = db.collection(collection_name).get()

    for document in all_documents:
        print("delete document: ", document.reference)
        document.reference.delete()


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--delete_collection", type=str, help="削除するcollection名", default=None
    )
    args = parser.parse_args()

    if args.delete_collection is None:
        raise ValueError("delete_collectionが指定されていない")
    delete_collection(args.delete_collection)
