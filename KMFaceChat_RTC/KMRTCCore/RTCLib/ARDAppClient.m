//
//  WEBRTC核心类
//  socketRtc
//
//  Created by 仲阳 on 16/3/6.
//  Copyright © 2016年 spinshine. All rights reserved.
//

#import "ARDAppClient.h"

#import <AVFoundation/AVFoundation.h>


#import "socketMethods.h"

#import "iToast.h"


static NSString *kARDDefaultSTUNServerUrl =
    @"stun:test.kc-motor.com";
static NSString *kARDDefaultTURNServerUrl = @"turn:test.kc-motor.com";




@interface ARDAppClient () <RTCPeerConnectionDelegate, RTCSessionDescriptionDelegate>
{
    BOOL fisrtCreateOffer;
}


@property(nonatomic, strong) RTCPeerConnection *peerConnection;
@property(nonatomic, strong) RTCAudioTrack *defaultAudioTrack;
@property(nonatomic, strong) RTCVideoTrack *defaultVideoTrack;

@property(nonatomic, strong) RTCPeerConnectionFactory *factory;
@property(nonatomic, strong) NSMutableArray *messageQueue;

@property(nonatomic, strong) RTCSessionDescription *mysdp;

@end

@implementation ARDAppClient

@synthesize delegate = _delegate;
@synthesize state = _state;
@synthesize peerConnection = _peerConnection;
@synthesize factory = _factory;
@synthesize messageQueue = _messageQueue;
@synthesize isTurnComplete = _isTurnComplete;
@synthesize hasReceivedSdp  = _hasReceivedSdp;
@synthesize clientId = _clientId;
@synthesize isInitiator = _isInitiator;
@synthesize isSpeakerEnabled = _isSpeakerEnabled;
@synthesize iceServers = _iceServers;


- (instancetype)initWithDelegate:(id<ARDAppClientDelegate>)delegate {
  if (self = [super init])
  {
    _delegate = delegate;
      
    _factory = [[RTCPeerConnectionFactory alloc] init];
      
      
    _messageQueue = [NSMutableArray array];
      
    _iceServers = [NSMutableArray arrayWithObject:[self defaultSTUNServer]];
    [_iceServers addObject:[self defaultTURNServer]];

      [self disconnect];
      self.state = kARDAppClientStateConnected;

      // Create peer connection.
      RTCMediaConstraints *constraints = [self defaultPeerConnectionConstraints];
      _peerConnection = [_factory peerConnectionWithICEServers:_iceServers
                                                   constraints:constraints
                                                      delegate:self];
      
      RTCMediaStream *localStream = [self createLocalMediaStream];
      [_peerConnection addStream:localStream];
      
      
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMessage:) name:@"socketDidReceiveDataNotification" object:nil];
      
      self->fisrtCreateOffer = NO;
      
  }
  return self;
}

- (void)dealloc {
  [self disconnect];
}



- (void)setState:(ARDAppClientState)state {
  if (_state == state) {
    return;
  }
  _state = state;
  [_delegate appClient:self didChangeState:_state];
}


#pragma mark - ＊＊＊＊＊＊1.主动offer入口＊＊＊＊＊＊
//主动offer入口
- (void) connectToOtherClientId : (NSString *) otherClientId {
//    //创建answer
//    [_peerConnection createAnswerWithDelegate:self constraints:[self defaultAnswerConstraints]];
//    return;
    
    
    _isSpeakerEnabled = YES;
    
    self.state = kARDAppClientStateConnecting;
    
    self.isTurnComplete = YES;
    self.isInitiator = YES; //offer
    self.hasReceivedSdp = YES;
    self.otherClientId = otherClientId;
    
    
   
    
    
    //创建offer
    [_peerConnection createOfferWithDelegate:self constraints:[self defaultOfferConstraints]];
}


- (void)disconnect {
  if (_state == kARDAppClientStateDisconnected) {
    return;
  }
  _clientId = nil;
 self.otherClientId = nil;
  _isInitiator = NO;
  _hasReceivedSdp = NO;
  _messageQueue = [NSMutableArray array];
  _peerConnection = nil;
  self.state = kARDAppClientStateDisconnected;
}

#pragma mark - ＊＊＊＊＊＊ socketDidReceiveDataNotification:拿到socket数据 ＊＊＊＊＊＊
//拿到socket数据
- (void) didReceiveMessage:(NSNotification *)message
{
    NSData *rawData = [message object];
    if ((rawData == nil) || ([rawData length] == 0))
    {
        return;
    }
    
    //NSLog(@"＊＊＊＊＊＊message_NSData: %@", rawData);
    
    
    
    NSUInteger len = [rawData length];
    
    //现在只考虑rtc数据，不考虑透传部分
    if (len > 17)
    {
        //分割JSON
        NSUInteger json_len = [rawData length] - 17;
        NSData *jsonData = [rawData subdataWithRange:NSMakeRange(17, json_len)];
        id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableLeaves error:nil];
        
        NSDictionary *jsonDic;
        if ([jsonObject isKindOfClass:[NSDictionary class]])
        {
            jsonDic = (NSDictionary *)jsonObject;
            NSLog(@"jsonDic: %@", jsonDic);
        }
        else//非正常未知数据
            return;
        
        
        
        NSData *firstChar = [rawData subdataWithRange:NSMakeRange(0, 1)];
        
        if ([firstChar isEqualToData:[@"\x17" dataUsingEncoding:NSUTF8StringEncoding]])
        {
            NSLog(@"收到offer");
            [[iToast makeText:NSLocalizedString(@"get offer", @"")] show];
            
            
            
            NSData *otherClientId_Data = [rawData subdataWithRange:NSMakeRange(1, 16)];
            NSString *otherClientId_String = [[NSString alloc] initWithData:otherClientId_Data encoding:NSUTF8StringEncoding];
            self.otherClientId = otherClientId_String;
            
            NSString *type = [jsonDic[@"type"] lowercaseString];
            NSString *sdp =  jsonDic[@"description"];
            
#pragma mark ＊＊＊＊＊＊ answer setRemoteDescription: offer ＊＊＊＊＊＊
            //setRemoteDescription
            self.isInitiator = NO;
            RTCSessionDescription *remoteDescription = [[RTCSessionDescription alloc] initWithType:type sdp:sdp];
            [_peerConnection setRemoteDescriptionWithDelegate:self
                                           sessionDescription:remoteDescription];
            
            
        }
        else if ([firstChar isEqualToData:[@"\x18" dataUsingEncoding:NSUTF8StringEncoding ]])
        {
            NSLog(@"收到answer");
            [[iToast makeText:NSLocalizedString(@"get answer", @"")] show];
        
            NSString *type = [jsonDic[@"type"] lowercaseString];
            NSString *sdp =  jsonDic[@"description"];
            NSLog(@"type: %@", type);
            NSLog(@"description: %@", sdp);
            
#pragma mark ＊＊＊＊＊＊ offer setRemoteDescription: answer ＊＊＊＊＊＊
            //setRemoteDescription
            self.isInitiator = YES;
            RTCSessionDescription *remoteDescription = [[RTCSessionDescription alloc] initWithType:type sdp:sdp];
            [_peerConnection setRemoteDescriptionWithDelegate:self
                                           sessionDescription:remoteDescription];
            
            
        }
        else if ([firstChar isEqualToData:[@"\x19" dataUsingEncoding:NSUTF8StringEncoding]])
        {
            NSLog(@"收到对方发来的IceCandidate, 并addICECandidate");
            
            NSString *sdp = jsonDic[@"sdp"];
            NSInteger sdpMLineIndex = [jsonDic[@"sdpMLineIndex"] integerValue];
            NSString *sdpMid = jsonDic[@"sdpMid"];
            
            RTCICECandidate *candidate = [[RTCICECandidate alloc] initWithMid:sdpMid index:sdpMLineIndex sdp:sdp];
            [self.peerConnection addICECandidate:candidate];
        }

    }
    else//其它如OK，Hello，Connect Success数据
    {
        NSLog(@"＊＊＊＊＊＊message_NSString: %@", [[NSString alloc] initWithData:rawData encoding:NSUTF8StringEncoding]);
    }
    
    
    return;
    
}
//
//- (void)channel:(ARDWebSocketChannel *)channel
//    didChangeState:(ARDWebSocketChannelState)state {
//  switch (state) {
//    case kARDWebSocketChannelStateOpen:
//      break;
//    case kARDWebSocketChannelStateRegistered:
//      break;
//    case kARDWebSocketChannelStateClosed:
//    case kARDWebSocketChannelStateError:
//      // TODO(tkchin): reconnection scenarios. Right now we just disconnect
//      // completely if the websocket connection fails.
//      [self disconnect];
//      break;
//  }
//}

#pragma mark - <RTCPeerConnectionDelegate>

- (void)peerConnection:(RTCPeerConnection *)peerConnection
    signalingStateChanged:(RTCSignalingState)stateChanged {
  NSLog(@"Signaling state changed: %d", stateChanged);
}

#pragma mark  ＊＊＊＊＊＊建立视频流, Triggered when media is received on a new stream from remote peer.＊＊＊＊＊＊
- (void)peerConnection:(RTCPeerConnection *)peerConnection
           addedStream:(RTCMediaStream *)stream
{
  dispatch_async(dispatch_get_main_queue(), ^{
      
    NSLog(@"Received %lu video tracks and %lu audio tracks",
        (unsigned long)stream.videoTracks.count,
        (unsigned long)stream.audioTracks.count);
      
    [[iToast makeText:NSLocalizedString(@"视频流已建立！", @"")] show];
      
    if (stream.videoTracks.count)
    {
      RTCVideoTrack *videoTrack = stream.videoTracks[0];
      [_delegate appClient:self didReceiveRemoteVideoTrack:videoTrack];
      if (_isSpeakerEnabled) [self enableSpeaker]; //Use the "handsfree" speaker instead of the ear speaker.

    }
  });
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
        removedStream:(RTCMediaStream *)stream {
  NSLog(@"Stream was removed.");
}

- (void)peerConnectionOnRenegotiationNeeded:
    (RTCPeerConnection *)peerConnection {
  NSLog(@"WARNING: Renegotiation needed but unimplemented.");
}

- (void)peerConnection:(RTCPeerConnection*)peerConnection
    didOpenDataChannel:(RTCDataChannel*)dataChannel {
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
    iceConnectionChanged:(RTCICEConnectionState)newState {
  NSLog(@"ICE state changed: %d", newState);
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
    iceGatheringChanged:(RTCICEGatheringState)newState {
  NSLog(@"ICE gathering state changed: %d", newState);
}

#pragma mark ＊＊＊＊＊＊ 发送给peer, 交换ICE, New Ice candidate have been found.＊＊＊＊＊＊
//发送给peer，交换ICE
- (void)peerConnection:(RTCPeerConnection *)peerConnection
       gotICECandidate:(RTCICECandidate *)candidate
{
  dispatch_async(dispatch_get_main_queue(), ^{
      NSLog(@"发送给peer, 交换ICE");
      
    ARDICECandidateMessage *message =
        [[ARDICECandidateMessage alloc] initWithCandidate:candidate];
    [self sendIceCandidateMessage:message];
  });
}

#pragma mark - ＊＊＊＊＊＊ <RTCSessionDescriptionDelegate> 两个重要回调 ＊＊＊＊＊＊
#pragma mark Called when creating a session.
- (void)peerConnection:(RTCPeerConnection *)peerConnection
    didCreateSessionDescription:(RTCSessionDescription *)sdp
                          error:(NSError *)error
{
    
  dispatch_async(dispatch_get_main_queue(), ^{

      NSLog(@"Did Create Session Description");
    //_mysdp = sdp;
      
#pragma mark - ＊＊＊＊＊＊ setLocalDescription ＊＊＊＊＊＊
    //setLocalDescription
    [self.peerConnection setLocalDescriptionWithDelegate:self
                                    sessionDescription:sdp];

    //发送SessionDescription给peer
    ARDSessionDescriptionMessage *message =
    [[ARDSessionDescriptionMessage alloc] initWithDescription:sdp];
    [self sendSessionDescriptionMessage:message];
      
  });
}

#pragma mark Called when setting a local or remote description.
- (void)peerConnection:(RTCPeerConnection *)peerConnection
    didSetSessionDescriptionWithError:(NSError *)error
{
  dispatch_async(dispatch_get_main_queue(), ^{
      
    if (error)
    {
      NSLog(@"Failed to set session description. Error: %@", error);
      [self disconnect];
      NSDictionary *userInfo = @{
        NSLocalizedDescriptionKey: @"Failed to set session description.",
      };
      return;
    }
      
      
    // If we're answering and we've just set the remote offer we need to create
    // an answer and set the local description.
    if (!_isInitiator && !_peerConnection.localDescription)//answer
    {
        //创建answer
        RTCMediaConstraints *constraints = [self defaultAnswerConstraints];
        [_peerConnection createAnswerWithDelegate:self
                                      constraints:constraints];
    }
  });
}

#pragma mark - Private

- (BOOL)isRegisteredWithRoomServer {
  return _clientId.length;
}





- (void)waitForAnswer {
  [self drainMessageQueueIfReady];
}

- (void)drainMessageQueueIfReady {
  if (!_peerConnection || !_hasReceivedSdp) {
    return;
  }
  for (ARDSignalingMessage *message in _messageQueue) {
    [self processSignalingMessage:message];
  }
  [_messageQueue removeAllObjects];
}

- (void)processSignalingMessage:(ARDSignalingMessage *)message {
  NSParameterAssert(_peerConnection ||
      message.type == kARDSignalingMessageTypeBye);
  switch (message.type) {
      case kARDSignalingMessageTypeOffer: {
          
          ARDSessionDescriptionMessage *sdpMessage =
          (ARDSessionDescriptionMessage *)message;
          RTCSessionDescription *description = sdpMessage.sessionDescription;
          [_peerConnection setRemoteDescriptionWithDelegate:self
                                         sessionDescription:description];
          
          _isInitiator  = NO; 
          // 发送 answer
          RTCMediaConstraints *constraints = [self defaultAnswerConstraints];
          [_peerConnection createAnswerWithDelegate:self
                                        constraints:constraints];
          
           //[self sendSessionDescriptionMessage:message];
          break;
      }
          
    case kARDSignalingMessageTypeAnswer: {
      ARDSessionDescriptionMessage *sdpMessage =
          (ARDSessionDescriptionMessage *)message;
      RTCSessionDescription *description = sdpMessage.sessionDescription;
      [_peerConnection setRemoteDescriptionWithDelegate:self
                                     sessionDescription:description];
      break;
    }
    case kARDSignalingMessageTypeCandidate: {
      ARDICECandidateMessage *candidateMessage =
          (ARDICECandidateMessage *)message;
      [_peerConnection addICECandidate:candidateMessage.candidate];
        
        
      break;
    }
    case kARDSignalingMessageTypeBye:
      // Other client disconnected.
      // TODO(tkchin): support waiting in room for next client. For now just
      // disconnect.
      [self disconnect];
      break;
  }
}

#pragma mark - ＊＊＊＊＊＊调用socket接口＊＊＊＊＊＊
#pragma mark 发送SessionDescription给peer
//ARDSessionDescriptionMessage
- (void)sendSessionDescriptionMessage:(ARDSessionDescriptionMessage *)message
{
  if (self.isInitiator == YES)//offer方
  {
      [[socketMethods getSocketMethodsInstance] sendOfferSessionDescriptionWithMessage:message from:self.clientId to:self.otherClientId];
  }
  else//answer方
  {
      [[socketMethods getSocketMethodsInstance]  sendAnswerSessionDescriptionWithMessage:message from:self.clientId to:self.otherClientId];
  }
}

#pragma mark 发送ICECandidate给peer
- (void) sendIceCandidateMessage : (ARDICECandidateMessage *) message
{
    [[socketMethods getSocketMethodsInstance]  changeICECandidateWithMessage:message from:self.clientId to:self.otherClientId];
}


- (RTCVideoTrack *)createLocalVideoTrack {
    // The iOS simulator doesn't provide any sort of camera capture
    // support or emulation (http://goo.gl/rHAnC1) so don't bother
    // trying to open a local stream.
    // TODO(tkchin): local video capture for OSX. See
    // https://code.google.com/p/webrtc/issues/detail?id=3417.

    RTCVideoTrack *localVideoTrack = nil;
#if !TARGET_IPHONE_SIMULATOR && TARGET_OS_IPHONE

    NSString *cameraID = nil;
    for (AVCaptureDevice *captureDevice in
         [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
        if (captureDevice.position == AVCaptureDevicePositionFront) {
            cameraID = [captureDevice localizedName];
            break;
        }
    }
    NSAssert(cameraID, @"Unable to get the front camera id");
    
    RTCVideoCapturer *capturer = [RTCVideoCapturer capturerWithDeviceName:cameraID];
    RTCMediaConstraints *mediaConstraints = [self defaultMediaStreamConstraints];
    RTCVideoSource *videoSource = [_factory videoSourceWithCapturer:capturer constraints:mediaConstraints];
    localVideoTrack = [_factory videoTrackWithID:@"ARDAMSv0" source:videoSource];
#endif
    return localVideoTrack;
}

- (RTCMediaStream *)createLocalMediaStream {
    RTCMediaStream* localStream = [_factory mediaStreamWithLabel:@"ARDAMS"];

    RTCVideoTrack *localVideoTrack = [self createLocalVideoTrack];
    if (localVideoTrack) {
        [localStream addVideoTrack:localVideoTrack];
        [_delegate appClient:self didReceiveLocalVideoTrack:localVideoTrack];
    }
    
    [localStream addAudioTrack:[_factory audioTrackWithID:@"ARDAMSa0"]];
    if (_isSpeakerEnabled) [self enableSpeaker];
    return localStream;
}



#pragma mark - Defaults

- (RTCMediaConstraints *)defaultMediaStreamConstraints {
  RTCMediaConstraints* constraints =
      [[RTCMediaConstraints alloc]
          initWithMandatoryConstraints:nil
                   optionalConstraints:nil];
  return constraints;
}

- (RTCMediaConstraints *)defaultAnswerConstraints {
  return [self defaultOfferConstraints];
}

- (RTCMediaConstraints *)defaultOfferConstraints {
    NSArray *mandatoryConstraints = @[
        [[RTCPair alloc] initWithKey:@"OfferToReceiveAudio" value:@"true"],
        [[RTCPair alloc] initWithKey:@"OfferToReceiveVideo" value:@"true"]
    ];
    RTCMediaConstraints* constraints =
    [[RTCMediaConstraints alloc]
     initWithMandatoryConstraints:mandatoryConstraints
     optionalConstraints:nil];
    return constraints;
}

- (RTCMediaConstraints *)defaultPeerConnectionConstraints {
  NSArray *optionalConstraints = @[
      [[RTCPair alloc] initWithKey:@"DtlsSrtpKeyAgreement" value:@"true"]
  ];
  RTCMediaConstraints* constraints =
      [[RTCMediaConstraints alloc]
          initWithMandatoryConstraints:nil
                   optionalConstraints:optionalConstraints];
  return constraints;
}

- (RTCICEServer *)defaultSTUNServer {
  NSURL *defaultSTUNServerURL = [NSURL URLWithString:kARDDefaultSTUNServerUrl];
  return [[RTCICEServer alloc] initWithURI:defaultSTUNServerURL
                                  username:@""
                                  password:@""];
}

//spinshine turn服务器
- (RTCICEServer *)defaultTURNServer {
    NSURL *defaultTURNServerURL = [NSURL URLWithString:kARDDefaultTURNServerUrl];
    return [[RTCICEServer alloc] initWithURI:defaultTURNServerURL
                                    username:@"toto"
                                    password:@"password"];
}

#pragma mark - Audio mute/unmute
- (void)muteAudioIn {
    NSLog(@"audio muted");
    RTCMediaStream *localStream = _peerConnection.localStreams[0];
    self.defaultAudioTrack = localStream.audioTracks[0];
    [localStream removeAudioTrack:localStream.audioTracks[0]];
    [_peerConnection removeStream:localStream];
    [_peerConnection addStream:localStream];
}
- (void)unmuteAudioIn {
    NSLog(@"audio unmuted");
    RTCMediaStream* localStream = _peerConnection.localStreams[0];
    [localStream addAudioTrack:self.defaultAudioTrack];
    [_peerConnection removeStream:localStream];
    [_peerConnection addStream:localStream];
    if (_isSpeakerEnabled) [self enableSpeaker];
}

#pragma mark - Video mute/unmute
- (void)muteVideoIn {
    NSLog(@"video muted");
    RTCMediaStream *localStream = _peerConnection.localStreams[0];
    self.defaultVideoTrack = localStream.videoTracks[0];
    [localStream removeVideoTrack:localStream.videoTracks[0]];
    [_peerConnection removeStream:localStream];
    [_peerConnection addStream:localStream];
}
- (void)unmuteVideoIn {
    NSLog(@"video unmuted");
    RTCMediaStream* localStream = _peerConnection.localStreams[0];
    [localStream addVideoTrack:self.defaultVideoTrack];
    [_peerConnection removeStream:localStream];
    [_peerConnection addStream:localStream];
}

#pragma mark - swap camera
- (RTCVideoTrack *)createLocalVideoTrackBackCamera {
    RTCVideoTrack *localVideoTrack = nil;
#if !TARGET_IPHONE_SIMULATOR && TARGET_OS_IPHONE
    //AVCaptureDevicePositionFront
    NSString *cameraID = nil;
    for (AVCaptureDevice *captureDevice in
         [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
        if (captureDevice.position == AVCaptureDevicePositionBack) {
            cameraID = [captureDevice localizedName];
            break;
        }
    }
    NSAssert(cameraID, @"Unable to get the back camera id");
    
    RTCVideoCapturer *capturer = [RTCVideoCapturer capturerWithDeviceName:cameraID];
    RTCMediaConstraints *mediaConstraints = [self defaultMediaStreamConstraints];
    RTCVideoSource *videoSource = [_factory videoSourceWithCapturer:capturer constraints:mediaConstraints];
    localVideoTrack = [_factory videoTrackWithID:@"ARDAMSv0" source:videoSource];
#endif
    return localVideoTrack;
}
- (void)swapCameraToFront{
    RTCMediaStream *localStream = _peerConnection.localStreams[0];
    [localStream removeVideoTrack:localStream.videoTracks[0]];
    
    RTCVideoTrack *localVideoTrack = [self createLocalVideoTrack];

    if (localVideoTrack) {
        [localStream addVideoTrack:localVideoTrack];
        [_delegate appClient:self didReceiveLocalVideoTrack:localVideoTrack];
    }
    [_peerConnection removeStream:localStream];
    [_peerConnection addStream:localStream];
}
- (void)swapCameraToBack{
    RTCMediaStream *localStream = _peerConnection.localStreams[0];
    [localStream removeVideoTrack:localStream.videoTracks[0]];
    
    RTCVideoTrack *localVideoTrack = [self createLocalVideoTrackBackCamera];
    
    if (localVideoTrack) {
        [localStream addVideoTrack:localVideoTrack];
        [_delegate appClient:self didReceiveLocalVideoTrack:localVideoTrack];
    }
    [_peerConnection removeStream:localStream];
    [_peerConnection addStream:localStream];
}

#pragma mark - enable/disable speaker

- (void)enableSpeaker {
    [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
    _isSpeakerEnabled = YES;
}

- (void)disableSpeaker {
    [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:nil];
    _isSpeakerEnabled = NO;
}

@end
