//
//  CARingBufferWrapper.m
//  mono2stereo
//
//  Created by Kunihiko Ohnaka on 2021/08/16.
//

#import "CARingBufferWrapper.h"

#include "CARingBuffer.hpp"

@implementation CARingBufferWrapper{
    CARingBuffer* ringBuffer;
}
    
-(instancetype)init
{
    if(self = [super init]){
        ringBuffer = new CARingBuffer();
    }
    return self;
}

-(void)allocateWithChannelsPerFrame:(UInt32)channelsPerFrame
                      bytesPerFrame:(UInt32)bytesPerFrame
                         bufferSize:(UInt32)bufferSize
{
    ringBuffer->Allocate(channelsPerFrame, bytesPerFrame, bufferSize);
}

-(CARingBufferError)storeWithBuffer:(AudioBufferList*)abl
                             frames:(UInt32)frames
                          startRead:(SInt64)frameNumber
{
    return ringBuffer->Store(abl,frames,frameNumber);
}

-(CARingBufferError)fetchWithBuffer:(AudioBufferList*)abl
                             frames:(UInt32)frames
                          startRead:(SInt64)startRead
{
    return ringBuffer->Fetch(abl,frames,startRead);
}

@end
