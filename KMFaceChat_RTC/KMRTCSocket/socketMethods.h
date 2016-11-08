//
//  socketMethods.h
//  GCDAsyncSocketTest
//
//  Created by 周祺华 on 16/1/20.
//  Copyright © 2016年 周祺华. All rights reserved.
//

#import "socketBase.h"
#import "ARDSignalingMessage.h"


@interface socketMethods : socketBase

+ (socketMethods *)getSocketMethodsInstance;


#pragma mark - session
//BR和app建立session连接
- (void)BRAndAppCreateSessionToServerWithLocalSSID:(NSString *)localSSID;

#pragma mark - 透传
//BR和app上报设备
- (void)BRAndAppReportDeviceToServerWithLocalSSID:(NSString *)localSSID peripheralID:(NSString *)peripheralID peripheralInfo:(NSString *)peripheralInfo;

//透传
- (void)appTransmitToBRWithAppSSID:(NSString *)appSSID BRSSID:(NSString *)BRSSID peripheralID:(NSString *)peripheralID controlCommand:(NSString *)controlCommand;
- (void)BRTransmitToAppWithBRSSID:(NSString *)BRSSID AppSSID:(NSString *)appSSID peripheralID:(NSString *)peripheralID data:(NSString *)data;


#pragma mark - rtc
//发送offer的description
- (void) sendOfferSessionDescriptionWithMessage:(ARDSessionDescriptionMessage *) message from:(NSString *)clientId to:(NSString *)otherClientId;
//发送answer的description
- (void) sendAnswerSessionDescriptionWithMessage:(ARDSessionDescriptionMessage *) message from:(NSString *)clientId to:(NSString *)otherClientId;
//交换ICECandidate
- (void) changeICECandidateWithMessage:(ARDICECandidateMessage *) message from:(NSString *)clientId to:(NSString *)otherClientId;


@end
