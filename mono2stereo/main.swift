//
//  main.swift
//  mono2stereo
//
//  Created by Kunihiko Ohnaka on 2021/08/14.
//

import Foundation
import Cocoa
import AVFoundation
import AudioToolbox
import AudioUnit


AudioDeviceFinder.findDevices()

let mono2stereo = Mono2Stereo()
mono2stereo.createInputUnit()
mono2stereo.createAndConnectOutputUnit()
mono2stereo.start()
// Sleep until the file is finished
usleep(UInt32(100 * 1000.0 * 1000.0))


//mainHALSample()
//signWaveMain()
exit(0)

struct MyAUGraphPlayer {
    var inputFormat :AudioStreamBasicDescription = AudioStreamBasicDescription()
    var inputFile: AudioFileID!
    var graph: AUGraph!
    var fileAU: AudioUnit!
}


/*
var input = AudioStreamBasicDescription(mSampleRate: 96000, mFormatID: kAudioFormatLinearPCM, mFormatFlags: kLinearPCMFormatFlagIsPacked | kLinearPCMFormatFlagIsSignedInteger, mBytesPerPacket: 4, mFramesPerPacket: 1, mBytesPerFrame: 4, mChannelsPerFrame: 1, mBitsPerChannel: 32, mReserved: 0)
var output = AudioStreamBasicDescription(mSampleRate: 48000, mFormatID: kAudioFormatLinearPCM, mFormatFlags: kLinearPCMFormatFlagIsPacked | kLinearPCMFormatFlagIsSignedInteger, mBytesPerPacket: 8, mFramesPerPacket: 1, mBytesPerFrame: 4*2, mChannelsPerFrame: 2, mBitsPerChannel: 32, mReserved: 0)


var audioConverter : AudioConverterRef?

let result = AudioConverterNew(&input, &output, &audioConverter)

guard result == errSecSuccess else {
    print("\(result)")
    exit(1)
}

let kRequestPackets = 8192
var outputBuffer = UnsafeMutableRawPointer.allocate(byteCount: 8192, alignment: 8)

while(true) {
    var bufferList = AudioBufferList(mNumberBuffers: 1, mBuffers: (AudioBuffer(mNumberChannels: 1, mDataByteSize: 1024, mData: outputBuffer)))
    var outPacketDescription = AudioStreamPacketDescription(mStartOffset: 0, mVariableFramesInPacket: 2, mDataByteSize: 8192)
    var ioOutputDataPacketSize: UInt32 = 128
    let error = AudioConverterFillComplexBuffer(audioConverter!, DataProc, nil, &ioOutputDataPacketSize, &bufferList, &outPacketDescription)
    guard error == errSecSuccess else {
        switch error {
        case kAudioConverterErr_InvalidOutputSize:
            print("AudioConverterFillComplexBuffer Error: InvalidOutputSize\n")
        case kAudioConverterErr_InvalidInputSize:
            print("AudioConverterFillComplexBuffer Error: InvalidInputSize\n")
        case kAudioConverterErr_FormatNotSupported:
            print("AudioConverterFillComplexBuffer Error: FormatNotSupported\n")
        default:
            print("AudioConverterFillComplexBuffer Error: \(error) \n")
        }
        exit(1)
    }

//    AudioConverterFillComplexBuffer(inAudioConverter: audioConverter, inInputDataProc: DataProc, inInputDataProcUserData: nil, ioOutputDataPacketSize: &ioOutputDataPacketSize, outOutputData: nil, outPacketDescription: packetDescription)
}


/**
 データ処理部
 */
func DataProc(_ inAudioConverter: AudioConverterRef, ioNumberDataPackets: UnsafeMutablePointer<UInt32>, ioData: UnsafeMutablePointer<AudioBufferList>, outDataPacketDescription: UnsafeMutablePointer<UnsafeMutablePointer<AudioStreamPacketDescription>?>?, inUserData: UnsafeMutableRawPointer?) -> OSStatus {
    
    let maxPackets: UInt32 = 10
    if ioNumberDataPackets.pointee > maxPackets {
        ioNumberDataPackets.pointee = maxPackets
    }

    
    return errSecSuccess
}

 */

let kInputFileLocation = "/Users/ohnaka/Desktop/Inori Minase Starry Wishes 1.m4a" as CFString


let inputFileURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, kInputFileLocation, CFURLPathStyle.cfurlposixPathStyle, false)!


// Open the input audio file
var player = MyAUGraphPlayer()
CheckError(AudioFileOpenURL(inputFileURL, AudioFilePermissions.readPermission, 0, &player.inputFile), "AudioFileOpenURL Failed")

// Get the audio data format from the file
var propSize = UInt32(MemoryLayout<AudioStreamBasicDescription>.size)
CheckError(AudioFileGetProperty(player.inputFile, kAudioFilePropertyDataFormat, &propSize, &player.inputFormat), "Couldn't get file's data format")

// Build a basic fileplayer->speakers graph
CreateMyAUGraph(&player)

// Configure the file player
let fileDuration = PrepareFileAU(&player)

// Start playing
CheckError(AUGraphStart(player.graph), "AUGraphStart failed");

// Sleep until the file is finished
usleep(UInt32(fileDuration * 1000.0 * 1000.0))

AUGraphStop(player.graph)
AUGraphUninitialize(player.graph)
AUGraphClose(player.graph)
AudioFileClose(player.inputFile)

//var player = MyAUGraphPlayer(inputFormat:, inputFile: <#T##AudioFileID#>, graph: <#T##AUGraph#>, fileAU: <#T##AudioUnit#>)
//var input = AudioStreamBasicDescription(mSampleRate: 96000, mFormatID: kAudioFormatLinearPCM, mFormatFlags: kLinearPCMFormatFlagIsPacked | kLinearPCMFormatFlagIsSignedInteger, mBytesPerPacket: 4, mFramesPerPacket: 1, mBytesPerFrame: 4, mChannelsPerFrame: 1, mBitsPerChannel: 32, mReserved: 0)

func CreateMyAUGraph(_ player: UnsafeMutablePointer<MyAUGraphPlayer>) {
    CheckError(NewAUGraph(&player.pointee.graph), "NewAUGraph failed")
    
    // Generate description that matches output device (speakers)
    var outputcd = AudioComponentDescription()
    outputcd.componentType = kAudioUnitType_Output
    outputcd.componentSubType = kAudioUnitSubType_DefaultOutput
    outputcd.componentManufacturer = kAudioUnitManufacturer_Apple

    // Adds a node with above description to the graph
    var outputNode = AUNode(bitPattern: 0)
    CheckError(AUGraphAddNode(player.pointee.graph, &outputcd, &outputNode),
               "AUGraphAddNode[kAudioUnitSubType_DefaultOutput] failed")

    
    // Generate description that matches a generator AU of type:
    // audio file player
    var fileplayercd = AudioComponentDescription()
    fileplayercd.componentType = kAudioUnitType_Generator
    fileplayercd.componentSubType = kAudioUnitSubType_AudioFilePlayer
    fileplayercd.componentManufacturer = kAudioUnitManufacturer_Apple
    // Adds a node with above description to the graph
    var fileNode = AUNode(bitPattern: 0)
    CheckError(AUGraphAddNode(player.pointee.graph, &fileplayercd, &fileNode),
               "AUGraphAddNode[kAudioUnitSubType_AudioFilePlayer] failed")

    
    // Opening the graph opens all contained audio units but does
    // not allocate any resources yet
    CheckError(AUGraphOpen(player.pointee.graph),
               "AUGraphOpen failed")
    
    
    // Get the reference to the AudioUnit object for the
    // file player graph node
    CheckError(AUGraphNodeInfo(player.pointee.graph, fileNode, nil, &player.pointee.fileAU),
               "AUGraphNodeInfo failed")


    // Connect the output source of the file player AU to
    // the input source of the output node
    CheckError(AUGraphConnectNodeInput(player.pointee.graph, fileNode, 0, outputNode, 0),
               "AUGraphConnectNodeInput")

    // Now initialize the graph (causes resources to be allocated)
    CheckError(AUGraphInitialize(player.pointee.graph),
               "AUGraphInitialize failed")

}

func PrepareFileAU(_ player: UnsafeMutablePointer<MyAUGraphPlayer>) -> Float64 {
    // Tell the file player unit to load the file we want to play
    CheckError(AudioUnitSetProperty(player.pointee.fileAU, kAudioUnitProperty_ScheduledFileIDs, kAudioUnitScope_Global,
                                    0,
                                    &player.pointee.inputFile, UInt32(MemoryLayout<AudioFileID>.size)),
               "AudioUnitSetProperty[kAudioUnitProperty_ScheduledFileIDs] failed")
    
    var nPackets: UInt64 = 0
    var propsize = UInt32(MemoryLayout<UInt64>.size)
    CheckError(AudioFileGetProperty(player.pointee.inputFile, kAudioFilePropertyAudioDataPacketCount, &propsize, &nPackets),
               "AudioFileGetProperty[kAudioFilePropertyAudioDataPacketCount] failed")

    // Tell the file player AU to play the entire file
    var rgn = ScheduledAudioFileRegion(mTimeStamp: AudioTimeStamp(mSampleTime: 0, mHostTime: 0, mRateScalar: 0, mWordClockTime: 0, mSMPTETime: SMPTETime(), mFlags: AudioTimeStampFlags(), mReserved: 0), mCompletionProc: nil, mCompletionProcUserData: nil, mAudioFile: player.pointee.inputFile, mLoopCount: 1, mStartFrame: 0, mFramesToPlay: UInt32(nPackets) * player.pointee.inputFormat.mFramesPerPacket)
    CheckError(AudioUnitSetProperty(player.pointee.fileAU, kAudioUnitProperty_ScheduledFileRegion,
                                    kAudioUnitScope_Global, 0, &rgn,
                                    UInt32(MemoryLayout<ScheduledAudioFileRegion>.size)),
               "AudioUnitSetProperty[kAudioUnitProperty_ScheduledFileRegion] failed")
    
    
    // Tell the file player AU when to start playing (-1 sample time
    // means next render cycle)
    var startTime = AudioTimeStamp(mSampleTime: -1, mHostTime: 0, mRateScalar: 0, mWordClockTime: 0, mSMPTETime: SMPTETime(),
                                   mFlags: AudioTimeStampFlags.sampleTimeValid, mReserved: 0)

    
    CheckError(AudioUnitSetProperty(player.pointee.fileAU, kAudioUnitProperty_ScheduleStartTimeStamp,
                                    kAudioUnitScope_Global, 0,
                                    &startTime, UInt32(MemoryLayout<AudioTimeStamp>.size)),
               "AudioUnitSetProperty[kAudioUnitProperty_ScheduleStartTimeStamp]")
    
    // File duration
    return (Double(nPackets) * Double(player.pointee.inputFormat.mFramesPerPacket)) /
        player.pointee.inputFormat.mSampleRate
}
