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

    @Option(name: .shortAndLong, help: "AudioUnit ID or name for input.")
    var inputDevice: String?

    @Option(name: .shortAndLong, help: "AudioUnit ID or name for output.")
    var outputDevice: String?

    @Flag(name: .shortAndLong, help: "Invert L/R signal.")
    var InvertLR: Bool = false

    var inputDeviceId: UInt32? {
        guard let option = inputDevice else {
            return anyMS2109InputDeviceId
        }
        if let id = UInt32.init(option) {
            return id
        }
        do {
            return try AudioDeviceFinder.allDevices().first { $0.name == option }.map { $0.audioDeviceID }
        } catch {
            return nil
        }
    }

    var outputDeviceId: UInt32? {
        guard let option = outputDevice else {
            return AudioDeviceFinder.defaultOutputDeviceId
        }
        if let id = UInt32.init(option) {
            return id
        }
        do {
            return try AudioDeviceFinder.allDevices().first { $0.name == option && $0.hasOutput }.map { $0.audioDeviceID }
        } catch {
            return nil
        }
    }

    
    mutating func run() throws {
        if listAudioUnits {
            do {
                let devices = try AudioDeviceFinder.allDevices()
                for audioDevice in devices {
                    if let name = audioDevice.name, let uid = audioDevice.uid {
                        let hasOut = audioDevice.hasOutput ? "O" : "X"
                        print("Found device:\(audioDevice.audioDeviceID) hasout=\(hasOut) \"\(name)\", uid=\(uid)")
                    }
                }
            } catch AudioDeviceFinderError.fatalError(let message) {
                print(message)
            } catch let e {
                print("\(e)")
            }
            return
        }

        let mono2stereo = Mono2StereoEngine(debug: debug)
        
        guard let _inputDeviceId = self.inputDeviceId else {
            print("No MS2109 device was found. Please specify audio device id with -i option.")
            print("To find MS2109 device manually, please use -l option that lists all audio devices on your Mac.")
            return
        }
        mono2stereo.createInputUnit(inputDeviceId: _inputDeviceId)

        guard let _outputDeviceId = self.outputDeviceId else {
            print("No default output device was found. Please specify output audio device id with -o option.")
            print("To find output device manually, please use -l option that lists all audio devices on your Mac.")
            return
        }
        mono2stereo.createAndConnectOutputUnit(outputDeviceId: _outputDeviceId)

        print("Input Device : \(_inputDeviceId)")
        print("Output Device: \(_outputDeviceId)")
        
        mono2stereo.start(delayTime: 50*1000, invertLR: self.InvertLR)

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

    
    private var anyMS2109InputDeviceId: AudioDeviceID? {
        do {
            return try AudioDeviceFinder.allDevices().first { $0.name == "FY HD Audio" }.map { $0.audioDeviceID }
        } catch {
            return nil
        }
    }

}
Mono2stereo.main()


