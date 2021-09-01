# MS2109-mono-to-stereo-mac

[日本語版はこちら](https://github.com/kunichiko/MS2109-mono-to-stereo-mac/blob/main/README.ja.md)

## About

This program converts MS2109's 96kHz mono sound stream to 48kHz stereo sound stream in real time.

## How to Use

If you want to convert a mono sound to stereo and capture by QuickTime Player, you should use 'Black Hole' virtual sound device.

### Step 1. install BlackHole 2ch

```
> brew install blackhole-2ch
```

https://github.com/ExistentialAudio/BlackHole

### Step 2. Find input/output device id 

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

### Step 3. Start converter

Set the input and output device id by using -i and -o options like below:

```
> mono2stereo -i 82 -o 69
```

You can also specify these devices by name like below:

```
> mono2stereo -i "FY HD Audio" -o "BlackHole 2ch"
```

### Step 4. Open QuickTime Player and record

* Select `File` -> `New Movie Recording`
* Click the triangle menu put on right side of recording button
* Select Camera as `FY HD Video`
* Select Microphone as `BlackHole 2ch`
* Start recording


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