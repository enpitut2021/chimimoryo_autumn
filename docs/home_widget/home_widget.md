# home_widget
home widgetのための覚書。

## android

- `home_widget_helloworld.dart`は、ホームウィジェットを動かすためのexample code
- ベースとなっているコードは、公式の https://pub.dev/packages/home_widget のものです。
- ソースは https://github.com/ABausG/home_widget
- 公式のexampleに対してこの`home_widget_helloworld.dart`は、
chimimoryo内で動くように次の点が異なります
  - 関連ファイルへのパス（ウィジェットの動きやスタイルを決めてるkotlinファイルなど）
  - nullに対応するための`?`オペレータ等の追加
  - import文やpackage宣言の細かい変更
  - など

## iOS
TBA