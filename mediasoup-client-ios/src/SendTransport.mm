//
//  SendTransport.mm
//  mediasoup-client-ios
//
//  Created by Ethan.
//  Copyright © 2019 Ethan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SendTransport.h"
#import "TransportWrapper.h"
#import "Producer.h"

@implementation SendTransport : Transport

-(instancetype)initWithNativeTransport:(NSValue *)nativeTransport {
    self = [super initWithNativeTransport:nativeTransport];
    if (self) {
        self._nativeTransport = nativeTransport;
    }
    
    return self;
}

-(void)dispose {
    [self checkTransportExists];
    
    [TransportWrapper nativeFreeTransport:self._nativeTransport];
}

-(Producer *)produce:(id<ProducerListener>)listener track:(RTCMediaStreamTrack *)track encodings:(NSArray *)encodings codecOptions:(NSString *)codecOptions {
    return [self produce:listener track:track encodings:encodings codecOptions:codecOptions appData:nil];
}

-(Producer *)produce:(id<ProducerListener>)listener track:(RTCMediaStreamTrack *)track encodings:(NSArray *)encodings codecOptions:(NSString *)codecOptions appData:(NSString *)appData {
    NSUInteger nativeTrack = track.hash;
    
    [self checkTransportExists];
    
    __block Producer *producer;
    // The below MUST run on the same thread, otherwise it leads to a race problem
    // when called at the same time on a different thread (sdp answer is produced with both video and audio being mid:0)
    dispatch_queue_t main = dispatch_get_main_queue();
    dispatch_block_t block = ^{
        producer = [TransportWrapper nativeProduce:self._nativeTransport listener:listener track:nativeTrack encodings:encodings codecOptions:codecOptions appData:appData];
    };
    
    // Prevent deadlock if already on the main thread
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_sync(main, block);
    }
    
    return producer;
}

-(void)checkTransportExists {
    if (self._nativeTransport == nil) {
        NSException* exception = [NSException exceptionWithName:@"IllegalStateException" reason:@"RecvTransport has been disposed." userInfo:nil];
        
        throw exception;
    }
}

@end
