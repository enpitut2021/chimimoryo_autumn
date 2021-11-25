# FirebaseのCloud Firestore構成
- 暫定的に決めているものなので変更する可能性は十分ある．
- NoSQLの設計が現在もあまりよくわかってないので改善点はたくさんある．
- 少し先を見越して，ここまででは必要のないデータも入っている．

# 構造
- users(collection)
    - user_name1(document)
        - advantages(割引率とか還元率といったお得度情報)(collection)
            - store1(document)
                - linepay(collection)
                    - random_id(document)
                        - coupons(field): user_name1のsevenのクーポン情報
                        - discounted_ratio: 割引率
                        - recommended_ratio: おすすめ度
                        - reduction_ratio: 還元率
                - paypay(collection)
                    - random_id(document)
                        - coupons(field): user_name1のsevenのクーポン情報
                        - discounted_ratio: 割引率
                        - recommended_ratio: おすすめ度
                        - reduction_ratio: 還元率
        - coupons(クーポン情報)
            - store1(document)
                - linepay(collection)
                    - random_id(document)
                        - descriptions: クーポン情報の文字列のarray
                - paypay(collection)
                    - random_id(document)
                        - descriptions: クーポン情報の文字列のarray

# 具体例

- users
    - bc
        - advantages
            - seven
                - linepay
                    - {random_id}
                        - coupons: users/bc/coupons/seven
                        - discounted_ratio: 0.01
                        - recommended_ratio: 4
                        - reduction_ratio: 0.06
                - paypay
                    - {random_id}
                        - discounted_ratio: 0.03
                        - recommended_ratio: 3
                        - reduction_ratio: 0.02
        - coupons
            - seven
                - linepay
                    - {random_id}
                        - descriptions: [三ツ矢サイダー30円引き]
                - paypay
                    - {random_id}
                        - descriptions: [コカコーラ20円引き, カップヌードル100円引き]
    - sudame