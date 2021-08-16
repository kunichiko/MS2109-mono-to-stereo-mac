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

func timerFunc() {
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.0) {
        print("I: \(mono2stereo.inputMaxValue)")
        print("O: \(mono2stereo.outputMaxValue)")
        print("D: \(mono2stereo.bufferDiff)")
        timerFunc()
    }
}
timerFunc()

RunLoop.main.run()
