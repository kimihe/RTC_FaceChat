//
//  socketMethods.m
//  GCDAsyncSocketTest
//
//  Created by 周祺华 on 16/1/20.
//  Copyright © 2016年 周祺华. All rights reserved.
//

#import "socketMethods.h"
#import "iToast.h"

@implementation socketMethods

static socketMethods *Instance = nil;
+ (socketMethods *)getSocketMethodsInstance 
{
    if (Instance == nil)
    {
        Instance = [[socketMethods alloc] init];
    }
    return Instance;
}

#pragma mark - session
//BR和app建立session连接
- (void)BRAndAppCreateSessionToServerWithLocalSSID:(NSString *)localSSID
{
    [self sendRequestDataWithHead:@"\x11" Body:localSSID];
    
    NSString *iToastStr = [NSString stringWithFormat:@"建立socket session连接:<%@>", localSSID];
    [[iToast makeText:NSLocalizedString(iToastStr, @"")] show];
}

#pragma mark - 透传
//BR和app上报设备
- (void)BRAndAppReportDeviceToServerWithLocalSSID:(NSString *)localSSID peripheralID:(NSString *)peripheralID peripheralInfo:(NSString *)peripheralInfo
{
    NSString *body = [NSString stringWithFormat:@"%@%@%@",localSSID, peripheralID, peripheralInfo];
    [self sendRequestDataWithHead:@"\x12" Body:body];
}

- (void)appTransmitToBRWithAppSSID:(NSString *)appSSID BRSSID:(NSString *)BRSSID peripheralID:(NSString *)peripheralID controlCommand:(NSString *)controlCommand
{
    NSString *body = [NSString stringWithFormat:@"%@%@%@%@",appSSID, BRSSID, peripheralID, controlCommand];
    [self sendRequestDataWithHead:@"\x15" Body:body];

}

- (void)BRTransmitToAppWithBRSSID:(NSString *)BRSSID AppSSID:(NSString *)appSSID peripheralID:(NSString *)peripheralID data:(NSString *)data
{
    NSString *body = [NSString stringWithFormat:@"%@%@%@%@", BRSSID, appSSID, peripheralID, data];
    [self sendRequestDataWithHead:@"\x16" Body:body];

}

#pragma mark - rtc
//发送offer的description
- (void) sendOfferSessionDescriptionWithMessage:(ARDSessionDescriptionMessage *) message from:(NSString *)clientId to:(NSString *)otherClientId
{
    NSDictionary *registerMessage = @{
                                      @"type": @"OFFER",   //spinshine join
                                      @"description"  : message.sessionDescription.description,
                                      };
    NSData *jsonData =
    [NSJSONSerialization dataWithJSONObject:registerMessage
                                    options:NSJSONWritingPrettyPrinted
                                      error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData
                                                 encoding:NSUTF8StringEncoding];
    
    
    
    NSString *body = [NSString stringWithFormat:@"%@%@%@",otherClientId, clientId, jsonString];
    
    [self sendRequestDataWithHead:@"\x17" Body:body];
}

//发送answer的description
- (void) sendAnswerSessionDescriptionWithMessage:(ARDSessionDescriptionMessage *) message from:(NSString *)clientId to:(NSString *)otherClientId
{
    NSDictionary *registerMessage = @{
                                      @"type": @"answer",   //spinshine join
                                      @"description"  : message.sessionDescription.description,
                                      };
    NSData *jsonData =
    [NSJSONSerialization dataWithJSONObject:registerMessage
                                    options:NSJSONWritingPrettyPrinted
                                      error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData
                                                 encoding:NSUTF8StringEncoding];
    
    
    
    NSString *body = [NSString stringWithFormat:@"%@%@%@",otherClientId, clientId, jsonString];
    [self sendRequestDataWithHead:@"\x18" Body:body];
}

//交换ICECandidate
- (void) changeICECandidateWithMessage:(ARDICECandidateMessage *) message from:(NSString *)clientId to:(NSString *)otherClientId
{

    NSDictionary *registerMessage = @{
                                      @"sdpMLineIndex"    : [NSString stringWithFormat:@"%ld",message.candidate.sdpMLineIndex],
                                      @"sdpMid"    : message.candidate.sdpMid,
                                      @"sdp"      : message.candidate.sdp,
                                      };
    NSData *jsonData =
    [NSJSONSerialization dataWithJSONObject:registerMessage
                                    options:NSJSONWritingPrettyPrinted
                                      error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData
                                                 encoding:NSUTF8StringEncoding];
    
    
    
    NSString *iceData = [NSString stringWithFormat:@"%@%@%@", otherClientId, clientId, jsonString];
    [self sendRequestDataWithHead:@"\x19" Body:iceData];
}

@end
