# FirebaseのCloud Firestore構成
- 暫定的に決めているものなので変更する可能性は十分ある．
- NoSQLの設計が現在もあまりよくわかってないので改善点はたくさんある．
- 少し先を見越して，ここまででは必要のないデータも入っている．

# 構造
- users(collection)
    - random_userid(document)
        - name: (string) ユーザー名
        - stores(collection)
            - random_storeid(document)
                - name: (string) 店名
                - advantages(collection)
                    - random_payid_1(document)
                        - name: (string) payの名前
                        - coupons: (array) nameのpayのクーポンのパスのarray
                        - discounted_ratio: (number) 割引率
                        - recommended_ratio: (number) おすすめ度
                        - reduction_ratio: (number) 還元率
                - coupons(collection)
                    - random_couponid_1(document)
                        - name: (string) payの名前
                        - description: (string) クーポン情報


# 具体例
- users
    - {random_userid_1}
        - name: bc
        - stores
            - {random_storeid_1}
                - name: seven
                - advantages
                    - {random_payid_1}
                        - name: Linepay
                        - coupons: [
                            users/{random_userid_1}/stores/{random_storeid_1}/coupons/{random_couponid_2},
                            users/{random_userid_1}/stores/{random_storeid_1}/coupons/{random_couponid_3}
                            ]
                        - discounted_ratio: 0.01
                        - recommended_ratio: 4
                        - reduction_ratio: 0.06
                    - {random_payid_2}
                        - name: PayPay
                        - coupons: [
                            users/{random_userid_1}/stores/{random_storeid_1}/coupons/{random_couponid_1}
                            ]
                        - discounted_ratio: 0.03
                        - recommended_ratio: 3
                        - reduction_ratio: 0.02
                - coupons
                    - {random_couponid_1}
                        - name: PayPay
                        - description: コカコーラ20円引き
                    - {random_couponid_2}
                        - name: PayPay
                        - description: カップヌードル100円引き
                    - {random_couponid_3}
                        - name: LinePay
                        - description: 三ツ矢サイダー30円引き
    - {random_userid_2}
        - name: sudame
