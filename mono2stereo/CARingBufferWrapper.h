//
//  CARingBufferWrapper.h
//  mono2stereo
//
//  Created by Kunihiko Ohnaka on 2021/08/16.
//

#import <Foundation/Foundation.h>
#include <AudioToolbox/AudioToolbox.h>

typedef SInt32 CARingBufferError;

NS_ASSUME_NONNULL_BEGIN

@interface CARingBufferWrapper : NSObject

-(void)allocateWithChannelsPerFrame:(UInt32)channelsPerFrame
                      bytesPerFrame:(UInt32)bytesPerFrame
                         bufferSize:(UInt32)bufferSize;

-(CARingBufferError)storeWithBuffer:(AudioBufferList*)abl
                             frames:(UInt32)frames
                          startRead:(SInt64)frameNumber;

-(CARingBufferError)fetchWithBuffer:(AudioBufferList*)abl
                             frames:(UInt32)frames
                          startRead:(SInt64)startRead;

@end

NS_ASSUME_NONNULL_END
