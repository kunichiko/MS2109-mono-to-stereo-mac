# MS2109-mono-to-stereo-mac

[English version](https://github.com/kunichiko/MS2109-mono-to-stereo-mac/blob/main/README.md)

## 概要

このプログラムは MS2109 キャプチャデバイスから取り込まれる 96kHzモノラル信号を、本来の 48kHzのステレオ信号にリアルタムに変換するプログラムです。

ある音声入力インターフェース(マイクやキャプチャデバイスなど)の入力をこのプルグラムが受け取って返還し、別の音声出力インターフェース(ライン出力など)に再出力する仕組みで実現しています。
「このプログラムをインストールすると自動的にモノラル音声がステレオになる」というものではないので、変換されたステレオ音声をキャプチャするためには `Black Hole` などの他のツールと組み合わせて使用する必要があります。

## 使い方

モノラル音声をステレオに変換して QuickTime Playerでキャプチャしたい場合は、 `Black Hole` という仮想サウンドデバイスを使う必要があります。
Black Hole は音声入力と音声出力を持った仮想のサウンドデバイスとして機能するソフトで、macOSや他のプログラムから見ると Black Holeという名前の音声入出力インターフェースが増えたように見えます。

詳しくはこちらこをご覧ください。
https://github.com/ExistentialAudio/BlackHole

Black Holeの大きな特徴は、以下のようにBlack Hole の出力デバイスに音声を出力すると、その音声が Black Hole の入力デバイスから取り込めるという点にあります。

```
BlackHole(Out) <== アプリからの音声出力
↓
BlackHole(In)  ==> アプリへの音声入力
```

この動きを利用すると以下のようにしてステレオ音声を QuickTimeなどでキャプチャできるようになります。

```
MS2109Device(In) ==> mono2stereo
                       ↓ ステレオに変換
BlackHole(Out)   <== 音声出力先として BlackHole(Out)を選択
↓
BlackHole(In)    ==> QuickTimeの音声入力としてBlackHole(In)を選択
```

### Step 0. Homebrewのインストール

この mono2stereo および BlackHoleは Homebrewを使用してインストールすることができますので、まず最初に Homebrewのインストールをしてください。
すでに Homebreの環境ができている方は飛ばして構いません。

https://brew.sh/index_ja

上記ページに掲載されているコマンドを macOSのターミナル上で実行することでインストールします。


### Step 1. mono2stereo をインストールする

このプログラム(mono2stereo)を Homebrew を使ってインストールします。Homebrewの公式リポジトリではなく、私の個人リポジトリ(tap)からインストールするため、以下のようにコマンドを実行してください。

```
> brew install kunichiko/tap/mono2stereo
```

インストールするためにはソースコードからのコンパイルが必要になりますので、Xcodeのインストールなどが必要になります。以下の組み合わせで動作を確認しています。

* macOS 11.6.4 (Big Sur) + Xcode 12.5.1
* macOS 12.2.1 (Monterey) + Xcode 13.2.1

うまくインストールできたら、 `mono2stereo` というコマンドが使えるようになっているはずです。ターミナルから実行して以下のような出力が出てきたらOKです。

```
> mono2stereo
Input Device : 49
Output Device: 85
I: 97792.0, 0.0 : Avg:104.1355kHz,  E:0
O: 64512.0, 0.0 : Avg:47.9934kHz,  E:0
D: 8448.0

I: 196096.0, 0.0 : Avg:99.8913kHz,  E:0
O: 195584.0, 0.0 : Avg:47.9993kHz,  E:0
D: 8448.0
```

プログラムは `Control + C` で停止できます。

### Step 2. BlackHole 2ch をインストールする

次に、Homebrew を使ってBlackHoleをインストールします。2ch版、16ch版などいくつか種類がありますが、今回はステレオ音声が扱えれば良いので、 `blackhole-2ch` を選択します。

```
> brew install blackhole-2ch
```

### Step 3. 入出力デバイス IDを調べます

`bin` フォルダに入っている実行バイナリ `mono2stereo` に `-l` オプションをつけて実行すると、あなたの Macに存在するサウンドデバイスとそのIDの一覧が表示されます。

```
> mono2stereo -l
Found device:50 hasout=X "USB MICROPHONE", uid=AppleUSBAudioEngine:MICE MICROPHONE:USB MICROPHONE:201308:1
Found device:54 hasout=O "EX-LD4K271D", uid=25E4211B-0000-0000-1C1D-0103803C2278
Found device:69 hasout=O "BlackHole 2ch", uid=BlackHole2ch_UID
Found device:76 hasout=O "Mac mini's speaker", uid=BuiltInSpeakerDevice
Found device:82 hasout=X "FY HD Audio", uid=AppleUSBAudioEngine:MACROSILICON:FY HD Video:1114000:3
Found device:85 hasout=O "EpocCam Microphone", uid=VirtualMicInputOutput:01
```

この結果から以下のことが読み取れます。

* 入力
    * FY HD Audio (MS2109 device) のIDは `82` である
* 出力
    * BlackHole 2ch のIDは `69` である

### Step 4. コンバーターの実行を開始する

入出力デバイスのIDは `-i` と `-o` オプションを使って以下のように指定します。

```
> mono2stereo -i 82 -o 69
```

IDでなく、以下のように名前で指定することも可能です。IDは再起動したりすると変わるので、名前で指定する方が便利かもしれません。

```
> mono2stereo -i "FY HD Audio" -o "BlackHole 2ch"
```

### Step 4. QuickTime Player を起動して録画する

* `ファイル` -> `新規ムービー収録` メニューを開きます
* 録画ボタンの右に出ている三角形のメニューをクリックします
* カメラとして `FY HD Video` (MS2109のデバイス名) を選択します
* マイクとして `BlackHole 2ch` を選択します
* 録画を開始します


## 問題

### バッファーアンダーラン / バッファーオーバーラン

入力デバイスのクロックと出力デバイスのクロックは完璧には同期していません。以下の値は私の環境で計測した数値です。

```
I: 2781381689.0, 0.0 : Avg:95.9975kHz,  E:0
O: 2781477888.0, 0.0 : Avg:48.0005kHz,  E:0
D: 1792.0
```

入力デバイスは MS2109 でサンプリングレートの理論値は 96kHzですが, 実測値は 95.9975kHz でした.　同様に、出力デバイスのサンプリングレートの理論値は 48kHzですが、実測値は 48.0005kHz でした.

これは、ほんのわずかですが入力速度よりも出力速度の方が早い (95.9975 は 48.0005 * 2 より小さい) ということを意味しており、 **バッファーアンダーラン** を引き起こします。そのため、長時間このプログラムを動かし続けるとプチノイズが発生する事になります。

この計測値は私の環境に依存しているため、皆さんの環境ではまた違った実測値が得られるはずです。もし逆に入力速度より出力速度の方が遅い場合、今度は **バッファーオーバーラン** を引き起こします。この状況だと、出力音声が徐々に遅れていく事になり、バッファが足りなくなるとやがてプチノイズを生成します.

ひとまず、1〜2時間ほど動かす分には問題はないと考えておりますが、長時間録画を継続したい場合などはご注意ください。

なお、この問題はダミーデータを挿入したり余計がデータを間引く対応を入れる事で対処できるため、将来のバージョンで対応したいと考えています。