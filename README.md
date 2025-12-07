# MS2109-mono-to-stereo-mac

[日本語版はこちら](https://github.com/kunichiko/MS2109-mono-to-stereo-mac/blob/main/README.ja.md)

## About

This program converts MS2109's 96kHz mono sound stream to 48kHz stereo sound stream in real time.

This is realized by a mechanism in which this program receives the input from one audio input interface (microphone, capture device, etc.), converts it, and outputs it to another audio output interface (line output, etc.).

Note that installing this program will not automatically convert monaural audio to stereo. You will need to use it in combination with other tools such as `Black Hole` to capture the converted stereo audio.

## How to Use

If you want to convert mono sound to stereo and capture it with QuickTime Player, you should use the 'Black Hole' virtual sound device.

Black Hole is software that functions as a virtual sound device with audio input and output. From the perspective of macOS and other programs, it appears as if new audio input/output interfaces named Black Hole have been added.

Please see here for details.
https://github.com/ExistentialAudio/BlackHole

A major feature of Black Hole is that when audio is output to the Black Hole output device, as shown below, the audio can then be captured from the Black Hole input device.

```
BlackHole(Out) <== audio out from some app
↓
BlackHole(In)  ==> audio in to some app
```

By using this behavior, you can capture stereo sound with QuickTime as follows:

```
MS2109Device(In) ==> mono2stereo
                       ↓ convert to stereo
BlackHole(Out)   <== Select BlackHole(Out) as output device
↓
BlackHole(In)    ==> Select BlackHole(In) as input device on QuickTime.
```

### Step 0-1. Install Homebrew

This mono2stereo and BlackHole can be installed using Homebrew, so please install Homebrew first.
If you already have a Homebrew environment, you can skip this step.

https://brew.sh/

Install it by executing the command listed on the above page on the macOS terminal.

### Step 0-2. Install Xcode

You need to install Xcode because building may not succeed when using only the Command Line Tools that Homebrew automatically installs. After installing Xcode, please execute the following command in the terminal (even if Xcode is already installed, please execute it to be sure).

```
> xcode-select -p
```

If the output is `/Library/Developer/CommandLineTools`, you should change the active developer directory to Xcode's path, as shown below:

```
> sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

**Note:** This example assumes Xcode was installed in `/Applications/Xcode.app`. If it was installed in a different path, please adjust the command accordingly.


### Step 1. Install mono2stereo

Install this program (mono2stereo) using Homebrew. To install from my personal repository (tap) instead of the official Homebrew repository, run the command below.

```
> brew install kunichiko/tap/mono2stereo
```

In order to install it, you need to compile it from the source code, so you need to install Xcode. We have confirmed the operation with the following combinations:

* macOS 11.6.4 (Big Sur) + Xcode 12.5.1
* macOS 12.2.1 (Monterey) + Xcode 13.2.1
* macOS 13.2.1 (Ventura) + Xcode 14.2

If you have successfully installed it, you should be able to use the `mono2stereo` command. If you run it from the terminal and see output similar to the following, the installation was successful.

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

If the name of the MS2109 device is not `FY HD Audio`, the automatic detection will fail. In this case, you can specify the device manually using the method described below.

### Step 2. Install BlackHole 2ch

Install BlackHole using Homebrew. There are several versions available (2ch, 16ch, etc.), but since we only need to handle stereo audio, we'll use `blackhole-2ch`.

```
> brew install blackhole-2ch
```

https://github.com/ExistentialAudio/BlackHole

### Step 3. Find input/output device ID 

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

### Step 4. Start the converter

Set the input and output device ID using the -i and -o options as shown below:

```
> mono2stereo -i 82 -o 69
```

You can also specify these devices by name instead of ID, as shown below. Using names may be more convenient since device IDs can change after a system restart.

```
> mono2stereo -i "FY HD Audio" -o "BlackHole 2ch"
```

### Step 5. Open QuickTime Player and start recording

* Select `File` -> `New Movie Recording`
* Click the triangle menu on the right side of the recording button
* Select `FY HD Video` as the Camera
* Select `BlackHole 2ch` as the Microphone
* Start recording

## Tips

### List all options

You can list all available options by passing the -h option as shown below:

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

### Invert L/R channels

You can invert the left and right channels by using the -I option.

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

### Partial device name matching

When specifying input/output devices by name, you can use partial matches, as shown below:

```
> mono2stereo -o "BlackHole 2ch"
> mono2stereo -o black
> mono2stereo -o hole
```

## Known Issues

### Buffer underrun / overrun

The input device's clock and the output device's clock are not perfectly synchronized. Below is an example from my environment:

```
I: 2781381689.0, 0.0 : Avg:95.9975kHz,  E:0
O: 2781477888.0, 0.0 : Avg:48.0005kHz,  E:0
D: 1792.0
```

The input device is the MS2109 and its theoretical sampling rate is 96kHz, but the measured value was 95.9975kHz. Similarly, the output device's theoretical sampling rate is 48kHz, but the measured value was 48.0005kHz.

This means the output speed is slightly faster than the input speed, which causes **buffer underrun**. If you use this program for an extended period, some noise may be produced.

These measured values depend on my environment, so your environment may produce different values. If the input speed is faster than the output speed in your environment, it causes **buffer overrun**. In this situation, the output sound will become progressively delayed and eventually produce noise.

For the time being, there should be no issues with running the program for 1-2 hours, but please be aware of this limitation if you need to record for extended periods.

I plan to fix these issues in a future version by inserting dummy signals and removing extra signals.
