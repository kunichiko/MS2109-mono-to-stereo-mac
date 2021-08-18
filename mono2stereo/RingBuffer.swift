//
//  RingBuffer.swift
//  mono2stereo
//
//  Created by Kunihiko Ohnaka on 2021/08/17.
//

import Foundation

import AudioUnit

typealias CARingBufferError = Int32

class SyncVar<T> {
    private let _lock: NSRecursiveLock
    private var _var: T

    init(_ lock: NSRecursiveLock, _ initial:T) {
        _lock = lock
        _var = initial
    }
    var value: T {
        get {
            defer {
                _lock.unlock()
            }
            _lock.lock()
            return _var
        }
        set (v) {
            defer {
                _lock.unlock()
            }
            _lock.lock()
            _var = v
        }
    }
}

class RingBuffer {

    private let lock = NSRecursiveLock()

    var buf : [UnsafeMutablePointer<Float32>] = []
    
    var channels: Int {
        defer {
            lock.unlock()
        }
        lock.lock()
        return buf.count
    }
    
    let bufferSize: SyncVar<Int>

    let storePos: SyncVar<UInt>

    let fetchPos: SyncVar<UInt>
    
    var bufferedFrames: Int {
        return Int(storePos.value) - Int(fetchPos.value)
    }
    
    let avgBufferedSize: SyncVar<Double>
    
    init() {
        bufferSize = SyncVar(lock, 0)
        storePos = SyncVar(lock, 0)
        fetchPos = SyncVar(lock, 0)
        avgBufferedSize = SyncVar(lock, 0)
    }
    
    func allocate( withChannelsPerFrame channelsPerFrame:UInt32,
                   bytesPerFrame :UInt32,
                   bufferSize :UInt32) {
        self.bufferSize.value = Int(bufferSize)
        for _ in 0..<channelsPerFrame {
            buf.append(UnsafeMutablePointer<Float32>(OpaquePointer(malloc( Int(bytesPerFrame) * Int(bufferSize)))))
        }
    }

    func store( withBuffer pbuffer:UnsafeMutablePointer<AudioBufferList>,
                frames:UInt32) -> CARingBufferError {
        guard pbuffer.pointee.mBuffers.mNumberChannels == self.channels else {
            return -1
        }
        
        let buffers = UnsafeMutableAudioBufferListPointer(pbuffer)!
        var ch = 0
        for buffer in buffers {
            let cp = buffer.mData!.bindMemory(to: Float32.self, capacity: Int(buffer.mDataByteSize)/4)
            for frame in 0..<Int(frames) {
                buf[ch][(Int(storePos.value) + frame)%self.bufferSize.value] = cp[frame]
            }
            ch += 1
        }
        storePos.value += UInt(frames)
        
        calcBufferedSize()
        
        return 0
    }

    func fetch( withBuffer pbuffer: UnsafeMutablePointer<AudioBufferList>,
                frames:UInt32) -> CARingBufferError {
        guard pbuffer.pointee.mBuffers.mNumberChannels == self.channels else {
            return -1
        }
        guard storePos.value - fetchPos.value > frames else {
            // fill by zero
            let buffers = UnsafeMutableAudioBufferListPointer(pbuffer)!
            var ch = 0
            for buffer in buffers {
                let cp = buffer.mData!.bindMemory(to: Float32.self, capacity: Int(buffer.mDataByteSize)/4)
                for frame in 0..<Int(frames) {
                    cp[frame] = 0
                }
                ch += 1
            }
            return 0
        }

        let buffers = UnsafeMutableAudioBufferListPointer(pbuffer)!
        var ch = 0
        for buffer in buffers {
            let cp = buffer.mData!.bindMemory(to: Float32.self, capacity: Int(buffer.mDataByteSize)/4)
            for frame in 0..<Int(frames) {
                cp[frame] = buf[ch][(Int(fetchPos.value) + frame)%self.bufferSize.value]
            }
            ch += 1
        }
        fetchPos.value += UInt(frames)
        return 0
    }

    var _sizes: [UInt] = []

    private func calcBufferedSize() {
        let size = storePos.value - fetchPos.value
        _sizes.append(size)
        if _sizes.count > 100 {
            _sizes.remove(at: 0)
        }
        let s = Double(_sizes.reduce(0, +)) / 100.0
        avgBufferedSize.value = s
    }
}
