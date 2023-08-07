# MS2109-mono-to-stereo-mac

[日本語版はこちら](https://github.com/kunichiko/MS2109-mono-to-stereo-mac/blob/main/README.ja.md)

## About

This program converts MS2109's 96kHz mono sound stream to 48kHz stereo sound stream in real time.

This is realized by a mechanism in which this program receives the input of one voice input interface (microphone, capture device, etc.), returns it, and re-outputs it to another voice output interface (line output, etc.).

It does not mean that "installing this program will automatically turn monaural audio into stereo", so you will need to use it in combination with other tools such as `Black Hole` to capture the converted stereo audio.

## How to Use

If you want to convert a mono sound to stereo and capture by QuickTime Player, you should use 'Black Hole' virtual sound device.

Black Hole is software that functions as a virtual sound device with audio input and output, and from the perspective of macOS and other programs, it seems that new audio input / output interfaces named Black Hole has attached.

Please see here for details.
https://github.com/ExistentialAudio/BlackHole

A major feature of Black Hole is that when audio is output to the Black Hole output device as shown below, the audio can be captured from the Black Hole input device.

```
BlackHole(Out) <== audio out from some app
↓
BlackHole(In)  ==> audio in to some app
```

By using this behaviour, you can capture stereo sound with QuickTime etc. as follows.

```
MS2109Device(In) ==> mono2stereo
                       ↓ convert to stereo
BlackHole(Out)   <== Select BlackHole(Out) as output device
↓
BlackHole(In)    ==> Select BlackHole(In) as input device on QuickTime.
```

### Step 0-1. Install Homebrew

This mono2stereo and BlackHole can be installed using Homebrew, so please install Homebrew first.
If you already have a Homebre environment, you can skip it.

https://brew.sh/index_ja

Install it by executing the command listed on the above page on the macOS terminal.

### Step 0-2. Install Xcode

You need to install Xcode because building may not succeed when using the Command Line Tools that Homebrew automatically installs. After installing Xcode, please execute the following command in the terminal (even if it is already installed, please execute it just to be sure).

```
> xcode-select -p
```

If the output is /Library/Developer/CommandLineTools , you should change the active developer directory to Xcode's path, as shown below:

```
> sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

※ This example assumes Xcode was installed in `/Applications/Xcode.app` . If it was installed in a different path, please adjust the command accordingly.


### Step 1. Install mono2stereo

Install this program (mono2stereo) using Homebrew. To install from my personal repository (tap) instead of the official Homebrew repository, run the command below.

```
> brew install kunichiko/tap/mono2stereo
```

In order to install it, you need to compile it from the source code, so you need to install Xcode. We have confirmed the operation with the following combination t.

* macOS 11.6.4 (Big Sur) + Xcode 12.5.1
* macOS 12.2.1 (Monterey) + Xcode 13.2.1
* macOS 13.2.1 (Ventura) + Xcode 14.2

If you have successfully installed it, you should be able to use the command `mono2stereo`. If you run it from the terminal and get the following output, it's OK.

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

The program can be stopped with `Control + C`.

If the MS2109 device cannot be found, the following message may appear.

```
No MS2109 device was found. Please specify audio device id with -i option.
To find MS2109 device manually, please use -l option that lists all audio devices on your Mac.
```

If the name of the MS2109 device is not `FY HD Audio`, the automatic detection will fail, so specify the device manually using the method described below.

### Step 2. install BlackHole 2ch

```
> brew install blackhole-2ch
```

https://github.com/ExistentialAudio/BlackHole

### Step 3. Find input/output device id 

```
> mono2stereo -l
Found device:50 hasout=X "USB MICROPHONE", uid=AppleUSBAudioEngine:MICE MICROPHONE:USB MICROPHONE:201308:1
Found device:54 hasout=O "EX-LD4K271D", uid=25E4211B-0000-0000-1C1D-0103803C2278
Found device:69 hasout=O "BlackHole 2ch", uid=BlackHole2ch_UID
Found device:76 hasout=O "Mac mini's speaker", uid=BuiltInSpeakerDevice
Found device:82 hasout=X "FY HD Audio", uid=AppleUSBAudioEngine:MACROSILICON:FY HD Video:1114000:3
Found device:85 hasout=O "EpocCam Microphone", uid=VirtualMicInputOutput:01
```

Now you can find:

* input
    * FY HD Audio (MS2109 device) is 82
* output
    * BlackHole 2ch is 69

### Step 4. Start converter

Set the input and output device id by using -i and -o options like below:

```
> mono2stereo -i 82 -o 69
```

You can also specify these devices by name like below:

```
> mono2stereo -i "FY HD Audio" -o "BlackHole 2ch"
```

### Step 5. Open QuickTime Player and record

* Select `File` -> `New Movie Recording`
* Click the triangle menu put on right side of recording button
* Select Camera as `FY HD Video`
* Select Microphone as `BlackHole 2ch`
* Start recording

## Tips

### List all the options

You can list all the options by passing -h option like below:

```
> mono2stereo -h
USAGE: mono2stereo [--list-audio-units] [--debug] [--input-device <input-device>] [--output-device <output-device>] [--invert-lr] [--volume <volume>]

OPTIONS:
  -l, --list-audio-units  Show the list of AudioUnits.
  -d, --debug             Enable debug log.
  -i, --input-device <input-device>
                          AudioUnit ID or name for input.
  -o, --output-device <output-device>
                          AudioUnit ID or name for output.
  -I, --invert-lr         Invert L/R signal.
  -V, --volume <volume>   Volume adjust(+6 db 〜 -40 db). "p6" means +6 db, "m6"
                          means -6 db.
  -h, --help              Show help information.
```

### Invert L/R

You can invert L/R channels by using the -I option.

### Adjust volume

You can adjust the output volume by using the -V option, as shown below:

```
# -20 db
> mono2stereo -V m20
```

```
# -3 db
> mono2stereo -V p3
```

### Ambiguous device naming

When specifying input/output devices by name, you can use ambiguous device names, as shown below

```
> mono2stereo -o "BlackHole 2ch"
> mono2stereo -o black
> mono2stereo -o hole
```

## Problems

### Buffer underrun / overrun

The input device's clock and output device's clock is not perfectly synchronized. Below is an example of my environment.

```
I: 2781381689.0, 0.0 : Avg:95.9975kHz,  E:0
O: 2781477888.0, 0.0 : Avg:48.0005kHz,  E:0
D: 1792.0
```

The input device is MS2109 and the theoretical sampling rate is 96kHz, but measured value was 95.9975kHz.　Similarly, the output device's theoretical sampling rate is 48kHz, but measured value was 48.0005kHz.

It means output speed is a bit faster than input speed and it causes **buffer underrun**. So if you use this program for longer time, some noise will be produced.

This measured values are depend on my environment, so your environment may produces other values. If input speed is faster than output speed in your environment, it causes **buffer overrun**. In this situation, output sound will be getting delayed and finally it make some noise.

I will try to fix these problems in future version by inserting dummy signal and deleting extra signal.
