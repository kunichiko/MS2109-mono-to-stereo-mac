# MS2109-mono-to-stereo-mac

[English version](https://github.com/kunichiko/MS2109-mono-to-stereo-mac/blob/main/README.md)

## 概要

このプログラムは MS2109 キャプチャデバイスから取り込まれる 96kHzモノラル信号を、本来の 48kHzのステレオ信号にリアルタムに変換するプログラムです。

## 使い方

モノラル音声をステレオに変換して QuickTime Playerでキャプチャしたい場合は、 `Black Hole` という仮想サウンドデバイスを使う必要があります。

### Step 1. BlackHole 2ch をインストールする

Homebrew を使ってインストールできます。

```
> brew install blackhole-2ch
```

https://github.com/ExistentialAudio/BlackHole

### Step 2. 入出力デバイス IDを調べます

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

この結果からいかが読み取れます。

* 入力
    * FY HD Audio (MS2109 device) のIDは `82` である
* 出力
    * BlackHole 2ch のIDは `69` である

### Step 3. コンバーターの実行を開始する

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