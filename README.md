# MS2109-mono-to-stereo-mac

## How to Use

If you want to convert monoral sound to stereo and capture by QuickTime Player, you should use 'Black Hole' virtual sound device.

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

### Step 4. Open QuickTime Player and record

* Select `File` -> `New Movie Recording`
* Click the triangle menu put on right side of recording button
* Select Camera as `FY HD Video`
* Select Microphone as `BlackHole 2ch`
* Start recording
