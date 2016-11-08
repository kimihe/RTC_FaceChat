//
//  WEBRTC核心类
//  socketRtc
//
//  Created by 仲阳 on 16/3/6.
//  Copyright © 2016年 spinshine. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ARDMessageResponse.h"
#import "ARDRegisterResponse.h"
#import "ARDSignalingMessage.h"
#import "ARDUtilities.h"
//#import "ARDWebSocketChannel.h"
#import "RTCICECandidate+JSON.h"
#import "RTCICEServer+JSON.h"
#import "RTCMediaConstraints.h"
#import "RTCMediaStream.h"
#import "RTCPair.h"
#import "RTCPeerConnection.h"
#import "RTCPeerConnectionDelegate.h"
#import "RTCPeerConnectionFactory.h"
#import "RTCSessionDescription+JSON.h"
#import "RTCSessionDescriptionDelegate.h"
#import "RTCVideoCapturer.h"
#import "RTCVideoTrack.h"

typedef NS_ENUM(NSInteger, ARDAppClientState) {
  // Disconnected from servers.
  kARDAppClientStateDisconnected,
  // Connecting to servers.
  kARDAppClientStateConnecting,
  // Connected to servers.
  kARDAppClientStateConnected,
};

@class ARDAppClient;
@protocol ARDAppClientDelegate <NSObject>

- (void)appClient:(ARDAppClient *)client
    didChangeState:(ARDAppClientState)state;

- (void)appClient:(ARDAppClient *)client
    didReceiveLocalVideoTrack:(RTCVideoTrack *)localVideoTrack;

- (void)appClient:(ARDAppClient *)client
    didReceiveRemoteVideoTrack:(RTCVideoTrack *)remoteVideoTrack;

- (void)appClient:(ARDAppClient *)client
         didError:(NSError *)error;

@end

// Handles connections to the AppRTC server for a given room.
@interface ARDAppClient : NSObject


@property(nonatomic, assign) BOOL isTurnComplete;
@property(nonatomic, assign) BOOL hasReceivedSdp;
@property(nonatomic, readonly) BOOL isRegisteredWithRoomServer;



@property(nonatomic, strong) NSString *clientId;//自己
@property(nonatomic, strong) NSString *otherClientId; //对方
@property(nonatomic, assign) BOOL isInitiator;//offer or answer
@property(nonatomic, assign) BOOL isSpeakerEnabled;
@property(nonatomic, strong) NSMutableArray *iceServers;



@property(nonatomic, readonly) ARDAppClientState state;
@property(nonatomic, weak) id<ARDAppClientDelegate> delegate;


- (instancetype)initWithDelegate:(id<ARDAppClientDelegate>)delegate;


- (void)createCall : (NSString *) name;
- (void) connectToOtherClientId : (NSString *) otherClientId;


// Mute and unmute Audio-In
- (void)muteAudioIn;
- (void)unmuteAudioIn;

// Mute and unmute Video-In
- (void)muteVideoIn;
- (void)unmuteVideoIn;

// Enabling / Disabling Speakerphone
- (void)enableSpeaker;
- (void)disableSpeaker;

// Swap camera functionality
- (void)swapCameraToFront;
- (void)swapCameraToBack;

// Disconnects from the AppRTC servers and any connected clients.
- (void)disconnect;

@end
