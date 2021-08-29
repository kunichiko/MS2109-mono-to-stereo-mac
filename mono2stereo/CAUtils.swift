//
//  CAUtils.swift
//  mono2stereo
//
//  Created by Kunihiko Ohnaka on 2021/08/16.
//

import Foundation
import Cocoa
import AVFoundation
import AudioToolbox
import AudioUnit

func CheckError(_ error: OSStatus, _ operation: String) {
    if error == noErr {
        return
    }

    // See if it appears to be a 4-char-code
    let code = CFSwapInt32HostToBig(UInt32(bitPattern: error))
    print("Error: \(operation) (\(int32To4Chars(code) ?? "\(error)"))\n")
    exit(1)
}

func int32To4Chars(_ code: UInt32) -> String? {
    let code0 = (code >> 24) & 0xff
    let code1 = (code >> 16) & 0xff
    let code2 = (code >> 8)  & 0xff
    let code3 = (code >> 0)  & 0xff
    if (isprint(Int32(code0)) != 0)  && (isprint(Int32(code1)) != 0) &&
        (isprint(Int32(code2)) != 0) && (isprint(Int32(code3)) != 0) {
        return "" + codeToString(code0) + codeToString(code1) + codeToString(code2) + codeToString(code3);
    } else {
        return nil
    }
}

func codeToString(_ code :UInt32) -> String {
    return String(UnicodeScalar(code) ?? " ")
}

func DebugStreamFormat(_ name: String, _ format: AudioStreamBasicDescription) {
    print("● \(name)");
    print("Frames Per Packet : \(format.mFramesPerPacket)")
    print("Channels Per Frame: \(format.mChannelsPerFrame)")
    print("Bits Per Channel  : \(format.mBitsPerChannel)")
    print("Sample Rate       : \(format.mSampleRate)")
    print("Bytes Per Frame   : \(format.mBytesPerFrame)")
    print("Bytes Per Packet  : \(format.mBytesPerPacket)")
    print("Format ID         : '" + (int32To4Chars(format.mFormatID) ?? "") + "'")
    print("Format Flags      : \(format.mFormatFlags)")
    print()
}

class AudioDevice {
    var audioDeviceID:AudioDeviceID

    init(deviceID:AudioDeviceID) {
        self.audioDeviceID = deviceID
    }

    var hasOutput: Bool {
        get {
            var address:AudioObjectPropertyAddress = AudioObjectPropertyAddress(
                mSelector:AudioObjectPropertySelector(kAudioDevicePropertyStreamConfiguration),
                mScope:AudioObjectPropertyScope(kAudioDevicePropertyScopeOutput),
                mElement:0)

            var propsize:UInt32 = UInt32(MemoryLayout<CFString?>.size);
            var result:OSStatus = AudioObjectGetPropertyDataSize(self.audioDeviceID, &address, 0, nil, &propsize);
            if (result != 0) {
                return false;
            }

            let bufferList = UnsafeMutablePointer<AudioBufferList>.allocate(capacity:Int(propsize))
            result = AudioObjectGetPropertyData(self.audioDeviceID, &address, 0, nil, &propsize, bufferList);
            if (result != 0) {
                return false
            }

            let buffers = UnsafeMutableAudioBufferListPointer(bufferList)
            for bufferNum in 0..<buffers.count {
                if buffers[bufferNum].mNumberChannels > 0 {
                    return true
                }
            }

            return false
        }
    }

    var uid:String? {
        get {
            var address:AudioObjectPropertyAddress = AudioObjectPropertyAddress(
                mSelector:AudioObjectPropertySelector(kAudioDevicePropertyDeviceUID),
                mScope:AudioObjectPropertyScope(kAudioObjectPropertyScopeGlobal),
                mElement:AudioObjectPropertyElement(kAudioObjectPropertyElementMaster))

            var name:CFString? = nil
            var propsize:UInt32 = UInt32(MemoryLayout<CFString?>.size)
            let result:OSStatus = AudioObjectGetPropertyData(self.audioDeviceID, &address, 0, nil, &propsize, &name)
            if (result != 0) {
                return nil
            }

            return name as String?
        }
    }

    var name:String? {
        get {
            var address:AudioObjectPropertyAddress = AudioObjectPropertyAddress(
                mSelector:AudioObjectPropertySelector(kAudioDevicePropertyDeviceNameCFString),
                mScope:AudioObjectPropertyScope(kAudioObjectPropertyScopeGlobal),
                mElement:AudioObjectPropertyElement(kAudioObjectPropertyElementMaster))

            var name:CFString? = nil
            var propsize:UInt32 = UInt32(MemoryLayout<CFString?>.size)
            let result:OSStatus = AudioObjectGetPropertyData(self.audioDeviceID, &address, 0, nil, &propsize, &name)
            if (result != 0) {
                return nil
            }

            return name as String?
        }
    }
}

enum AudioDeviceFinderError: Error {
    case fatalError(_ message: String)
    
}

class AudioDeviceFinder {

    static func allDevices() throws -> [AudioDevice] {
        var propsize:UInt32 = 0

        var address:AudioObjectPropertyAddress = AudioObjectPropertyAddress(
            mSelector:AudioObjectPropertySelector(kAudioHardwarePropertyDevices),
            mScope:AudioObjectPropertyScope(kAudioObjectPropertyScopeGlobal),
            mElement:AudioObjectPropertyElement(kAudioObjectPropertyElementMaster))

        var result:OSStatus = AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &address, UInt32(MemoryLayout<AudioObjectPropertyAddress>.size), nil, &propsize)

        guard result == 0 else {
            throw AudioDeviceFinderError.fatalError("Error \(result) from AudioObjectGetPropertyDataSize")
        }

        let numDevices = Int(propsize / UInt32(MemoryLayout<AudioDeviceID>.size))

        var devids = [AudioDeviceID]()
        for _ in 0..<numDevices {
            devids.append(AudioDeviceID())
        }

        result = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &propsize, &devids);
        guard result == 0 else {
            throw AudioDeviceFinderError.fatalError("Error \(result) from AudioObjectGetPropertyData")
        }

        var devices: [AudioDevice] = []
        for i in 0..<numDevices {
            devices.append(AudioDevice(deviceID:devids[i]))
        }
        devices.sort { a, b in
            a.audioDeviceID < b.audioDeviceID
        }
        return devices
    }


    static var defaultInputDeviceId: AudioDeviceID {
        var defaultDevice: AudioDeviceID = kAudioObjectUnknown
        var propertySize = (UInt32)(MemoryLayout<AudioDeviceID>.size)
        var defaultDeviceProperty = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDefaultInputDevice, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMaster)
        CheckError (AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject),
                                               &defaultDeviceProperty,
                                               0,
                                               nil,
                                               &propertySize,
                                               &defaultDevice),
                    "Couldn't get default input device")
        return defaultDevice
    }

    static var defaultOutputDeviceId: AudioDeviceID? {
        var defaultDevice: AudioDeviceID = kAudioObjectUnknown
        var propertySize = (UInt32)(MemoryLayout<AudioDeviceID>.size)
        var defaultDeviceProperty = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDefaultOutputDevice, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMaster)
        let status = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject),
                                               &defaultDeviceProperty,
                                               0,
                                               nil,
                                               &propertySize,
                                               &defaultDevice)
        guard status == noErr else {
            return nil
        }
        return defaultDevice
    }
}
