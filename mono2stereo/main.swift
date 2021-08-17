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
import ArgumentParser

struct Mono2stereo: ParsableCommand {
    @Flag(name: .shortAndLong, help: "Show the list of AudioUnits.")
    var listAudioUnits = false

    @Flag(name: .shortAndLong, help: "Enable debug log.")
    var debug = false

    @Option(name: .shortAndLong, help: "AudioUnit ID for input.")
    var inputDeviceId: UInt32?

    @Option(name: .shortAndLong, help: "AudioUnit ID for output.")
    var outputDeviceId: UInt32?

    mutating func run() throws {
        if listAudioUnits {
            AudioDeviceFinder.findDevices()
            return
        }

        let mono2stereo = Mono2StereoEngine(debug: debug)
        mono2stereo.createInputUnit(audioDeviceId: inputDeviceId)

        mono2stereo.createAndConnectOutputUnit(audioDeviceId: outputDeviceId)

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
    }
}
Mono2stereo.main()


