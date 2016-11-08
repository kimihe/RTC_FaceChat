//
//  socketBase.h
//  GCDAsyncSocketTest
//
//  Created by 周祺华 on 16/1/20.
//  Copyright © 2016年 周祺华. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CocoaAsyncSocket/CocoaAsyncSocket.h>
//@import CocoaAsyncSocket;


#define socketHeartBeatsTimeInterval 20.0

@protocol socketBaseDelegate <NSObject>

//收到数据回调
- (void)socketDidReceiveData:(NSData *)data;
//断线回调
- (void)socketDidDisconnect;

@end

@interface socketBase : NSObject
{
    GCDAsyncSocket *asyncSocket;
}

@property (weak, nonatomic) id<socketBaseDelegate> delegate;

#pragma mark - 封装的socket发送函数
- (void)initSocketWithHost:(NSString *)host port:(uint16_t)port;
- (void)sendRequestDataWithHead:(NSString *)head Body:(NSString *)body;


@end
