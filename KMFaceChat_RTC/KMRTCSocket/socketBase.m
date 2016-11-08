//
//  socketBase.m
//  GCDAsyncSocketTest
//
//  Created by 周祺华 on 16/1/20.
//  Copyright © 2016年 周祺华. All rights reserved.
//

#import "socketBase.h"
#define HOST "120.26.69.176"
#define PORT 8002

@implementation socketBase
{
    //定时器相关
    NSTimer *socketHeartBeatsTimer;
    long count;
    
    //收到的socket数据缓存处理的Data
    NSMutableData *socketDataBuffer;
    
    //socket分析专用
    char buf[10000];
}

- (id)init
{
    if (self = [super init])
    {
//        NSString *host = @"120.26.69.176";
        
        [self initSocketWithHost:@HOST port:PORT];
    }
    
    return self;
}

- (void)initSocketWithHost:(NSString *)host port:(uint16_t)port
{

        dispatch_queue_t mainQueue = dispatch_get_main_queue();
    
        if ( self->asyncSocket == nil)
        {
            self->asyncSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:mainQueue];
        }
        
        
//        NSString *host = @"120.26.69.176";
//        uint16_t port = 8001;
        
        NSLog(@"Connecting to \"%@\" on port %hu...", host, port);
        
        NSError *error = nil;
        if (![self->asyncSocket connectToHost:host onPort:port error:&error])
        {
            NSLog(@"Error connecting: %@", error);
        }
}

#pragma mark - 封装的socket发送函数
- (void)sendRequestDataWithHead:(NSString *)head Body:(NSString *)body
{
    if (head == nil)
    {
        head = @"";
    }
    if (body == nil) {
        body = @"";
    }
    
    NSString *requestString = [NSString stringWithFormat:@"%@%@#", head, body];
    NSData *requestData = [requestString dataUsingEncoding:NSUTF8StringEncoding];
    
    [self->asyncSocket writeData:requestData withTimeout:-1 tag:111];
}

#pragma mark - ---定时器相关方法---
- (void)socketHeartBeatsClockStart
{
    self->socketHeartBeatsTimer = [NSTimer scheduledTimerWithTimeInterval:socketHeartBeatsTimeInterval target:self selector:@selector(socketHeartBeatsClock) userInfo:nil repeats:YES];
}

- (void)socketHeartBeatsClock
{
    [self->socketHeartBeatsTimer invalidate];
    [self sendRequestDataWithHead:@"\x10" Body:@"hi"];
    NSLog(@"＊＊＊ app／蓝牙路由器与服务器的心跳%ld ＊＊＊", (self->count++));
    [self socketHeartBeatsClockStart];
}


#pragma mark - Socket Delegate
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
    NSLog(@"socket:%p didConnectToHost:%@ port:%hu", sock, host, port);
    
//        NSData *separatorData = [NSData dataWithBytes:@"\x6F" length:1];
//        [sock readDataToData:separatorData withTimeout:-1 tag:111];
    
    //开始循环发送心跳
    [self socketHeartBeatsClockStart];
    
    [sock readDataWithTimeout:-1 tag:222];
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    NSLog(@"socket:%p didWriteDataWithTag:%ld", sock, tag);
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    //NSLog(@"socket:%p didReadData:[%@]withTag:%ld", sock, data, tag);
    NSLog(@"socket:%p didReadData:withTag:%ld", sock, tag);
    
    
    
    if (self->socketDataBuffer == nil)
    {
        self->socketDataBuffer = [NSMutableData new];
    }
    
    [self->socketDataBuffer appendData:data];
    //NSLog(@"before parsing, socketDataBuffer: %@", [[NSString alloc] initWithData:socketDataBuffer encoding:NSUTF8StringEncoding]);
    
    char *head = [self->socketDataBuffer bytes];//bytes首地址
    char *tail = [self->socketDataBuffer bytes];
    int len = [self->socketDataBuffer length];
    
    for (int i = 0; i < len; i++, tail++)
    {
        if (*tail != '#')//没遇到分隔符#
        {
            //pass
        }
        else//遇到分隔符#
        {
            int size = (tail - head)/(sizeof(char));
            memset(buf, 0, sizeof(buf));
            memcpy(buf, head, size);
            
            
            head = tail+1;
            NSData *eachData = [NSData dataWithBytes:buf length:size];
            //NSLog(@"＊＊＊＊＊＊收到数据，此次分割结果: %@", [[NSString alloc] initWithData:eachData encoding:NSUTF8StringEncoding]);
            
            //广播收到的消息通知
            [[NSNotificationCenter defaultCenter] postNotificationName:@"socketDidReceiveDataNotification" object:eachData];
            //收到数据回调
            [self.delegate socketDidReceiveData:eachData];
        }
        
        if (i == len-1)//最后一次
        {
            int size = (tail - head)/(sizeof(char)) + 1;//注意加1
            memset(buf, 0, sizeof(buf));
            memcpy(buf, head, size);
            
            
            NSData *lastData = [NSData dataWithBytes:buf length:size];
            self->socketDataBuffer = nil;
            self->socketDataBuffer = [NSMutableData new];
            [self->socketDataBuffer appendData:lastData];
        }
    }
    
    //NSLog(@"after parsing, socketDataBuffer: %@", [[NSString alloc] initWithData:socketDataBuffer encoding:NSUTF8StringEncoding]);
    
    
    
    //继续读取
    [sock readDataWithTimeout:-1 tag:222];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    NSLog(@"socketDidDisconnect:%p withError: %@", sock, err);
    
    //断线重练的消息通知
    [[NSNotificationCenter defaultCenter] postNotificationName:@"socketDidDisconnectNotification" object:nil];
    
    //断线回调
    [self.delegate socketDidDisconnect];
}





@end
