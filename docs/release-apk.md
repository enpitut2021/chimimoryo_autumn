# APKファイルのリリース方法まとめ

## シンプルな方法
手元でapkファイルを作成して，アップロードする．

手順
1. `flutter build apk --release`でapkファイルを作成する．
2. 作成したapkファイルをGitHubの`/apks`ディレクトリかGoogle Driveにアップロードする．

## 少し複雑な方法(将来的にやりたい方法)
CIツールを使用してサーバー上でapkファイルの作成，releaseで公開する．

候補
1. Bitriseを使う．

    良い点
    - iosへの対応も割と簡単にできそう
    - 月200回まで無料

    悪い点
    - 使ったことがある人がいるか不明．
    - 手元でpushでもしかしたら十分？

    参考文献
    - https://qiita.com/yamatatsu10969/items/3590cc78c62e92718f28
    - https://zenn.dev/shuneihayakawa/articles/0847d18fb7372bbbdd28

2. Github Actionsを使う

   良い点
    - GitHubだけで完結できる
    - 月2000分まで無料

    悪い点
    - iosとAndroidでことなるyamlファイルを用意する必要がある？
    - 手元でpushでもしかしたら十分？

    参考文献
    - https://qiita.com/freddiefujiwara/items/76cfc05f5142d3b53da6
    - https://zenn.dev/pressedkonbu/articles/254ca2fc3cd1ab