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

let outputDevice: AudioDeviceID = 69 // BlackHole 2ch
mono2stereo.createAndConnectOutputUnit(audioDeviceId: outputDevice)

mono2stereo.start(delayTime: 50*1000)

func timerFunc() {
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.0) {
        print("I: \(mono2stereo.inputSampleTime   ), \(mono2stereo.inputMaxValue ) : Avg:\(String(format:"%.4f",mono2stereo.inputSamplingRate  / 1000))kHz,  E:\(mono2stereo.inputErrorCount)")
        print("O: \(mono2stereo.outputSampleTime*2), \(mono2stereo.outputMaxValue) : Avg:\(String(format:"%.4f",mono2stereo.outputSamplingRate / 1000))kHz,  E:\(mono2stereo.outputErrorCount)")
        print("D: \(mono2stereo.bufferDiffAvg)")
        print()
        timerFunc()
    }
}
timerFunc()

RunLoop.main.run()
