# FlutterへのFirestoreの導入

基本的な導入はできているが、鍵情報をGitHubにアップロードするのはセキュリティ上懸念が大きいので、各自でやってほしい。

## Android

1. https://console.firebase.google.com/project/chimimoryo/settings/general/android:com.example.chimimoryo_autumn へアクセス
1. `google-services.json` をダウンロード
1. このプロジェクトの `android/app` に置く (`android/app/google-services.json` になる)
1. 完了