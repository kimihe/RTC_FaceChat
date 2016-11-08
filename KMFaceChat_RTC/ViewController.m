//
//  ViewController.m
//  KMFaceChat_RTC
//
//  Created by 周祺华 on 2016/11/7.
//  Copyright © 2016年 周祺华. All rights reserved.
//

#import "ViewController.h"
#import "KMInclude.h"

@interface ViewController ()<ARDAppClientDelegate, RTCEAGLVideoViewDelegate>
{
    BOOL cameraIsBack;
}

@property (weak, nonatomic) IBOutlet UITextField *yourIdTextField;
@property (strong ,nonatomic) IBOutlet UITextField  *peerIdTextField;
@property (strong ,nonatomic) IBOutlet UILabel      *statusLabel;
@property (weak, nonatomic) IBOutlet UIButton *confirmIdButton;
@property (weak, nonatomic) IBOutlet UIButton *makeCallButton;
@property (weak, nonatomic) IBOutlet UIButton *changeCameraButton;

@property (weak, nonatomic) IBOutlet RTCEAGLVideoView *remoteView;
@property (weak, nonatomic) IBOutlet RTCEAGLVideoView *localView;


// rtc相关
@property (strong, nonatomic) ARDAppClient *client;
@property (strong, nonatomic) RTCVideoTrack *localVideoTrack;
@property (strong, nonatomic) RTCVideoTrack *remoteVideoTrack;



@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    //RTCEAGLVideoViewDelegate provides notifications on video frame dimensions
    [self.remoteView setDelegate:self];
    [self.localView setDelegate:self];
    
    [self initData];
}

- (void)initData
{
    self->cameraIsBack = NO;
    
    //iOS设备的UUID不存在才重新生成，但是这个删了应用重装就不行了
    NSString *iOSDeviceUUID = [[NSUserDefaults standardUserDefaults] objectForKey:@"iOSDeviceUUID"];
    if (iOSDeviceUUID == nil) {
        //获取iOS设备的UUID
        CFUUIDRef puuid = CFUUIDCreate( nil );
        CFStringRef uuidString = CFUUIDCreateString( nil, puuid );
        NSString * result = (NSString *)CFBridgingRelease(CFStringCreateCopy( NULL, uuidString));
        
        result = [result stringByReplacingOccurrencesOfString:@"-" withString:@""];
        NSString *iOSDeviceUUID = [result substringWithRange:NSMakeRange(0, 16)];
        
        [[NSUserDefaults standardUserDefaults] setObject:iOSDeviceUUID forKey:@"iOSDeviceUUID"];
    }
    
    //手机与服务器建立session
    //[[socketMethods getSocketMethodsInstance] BRAndAppCreateSessionToServerWithLocalSSID:[[NSUserDefaults standardUserDefaults] objectForKey:@"iOSDeviceUUID"]];
    
    //本机UUID
    //self.client.clientId = [[NSUserDefaults standardUserDefaults] objectForKey:@"iOSDeviceUUID"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - call and hang up
- (IBAction)confirmIdBtnPressed:(id)sender
{
    //自己的UUID
    NSString *selfIdentifier = self.yourIdTextField.text;
    //补全16字节
    NSInteger count = selfIdentifier.length;
    for (NSInteger i = count; i < 16;i++) {
        selfIdentifier = [selfIdentifier stringByAppendingString:@"\x00"];
    }
    
    [[socketMethods getSocketMethodsInstance] BRAndAppCreateSessionToServerWithLocalSSID:selfIdentifier];
    
    self.client = [[ARDAppClient alloc] initWithDelegate:self];
    self.client.clientId = selfIdentifier;
}

- (IBAction)makeCallBtnPressed:(id)sender
{
    // 主动make call的一方属于offer
    // 被动接听的一方属于answer
    
    //对方UUID
    NSString *otherClientId  = self.peerIdTextField.text;
    //补全16字节
    NSInteger count = otherClientId.length;
    for (NSInteger i = count; i < 16;i++) {
        otherClientId = [otherClientId stringByAppendingString:@"\x00"];
    }
    
    NSString *iToastStr = [NSString stringWithFormat:@"发起视频，连接对方标识为: %@", otherClientId];
    [[iToast makeText:NSLocalizedString(iToastStr, @"")] show];
    
    //call 对方
    [self.client connectToOtherClientId:otherClientId];
}

- (IBAction)hangUpBtnPressed:(id)sender
{
    //Clean up
    //一些奇怪的bug都可以通过hang up解决，类似于万能的重启
    [[iToast makeText:NSLocalizedString(@"挂断视频", @"")] show];
    
    
    self.yourIdTextField.hidden = NO;
    self.peerIdTextField.hidden = NO;
    self.confirmIdButton.hidden = NO;
    self.makeCallButton.hidden = NO;
    self.changeCameraButton.hidden = YES;
    
    
    [self disconnect];
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)disconnect
{
    
    if (self.client) {
        if (self.localVideoTrack)
            [self.localVideoTrack removeRenderer:self.localView];
        if (self.remoteVideoTrack)
            [self.remoteVideoTrack removeRenderer:self.remoteView];
        
        self.localVideoTrack = nil;
        [self.localView renderFrame:nil];
        
        self.remoteVideoTrack = nil;
        [self.remoteView renderFrame:nil];
        
        [self.client disconnect];
    }
}

- (IBAction)changeCameraBtnPressed:(id)sender {
    if (self->cameraIsBack) {
        [self.client swapCameraToFront];
        [[iToast makeText:NSLocalizedString(@"已切换到前置摄像头", @"")] show];
        self->cameraIsBack = NO;
    }
    else {
        [self.client swapCameraToBack];
        [[iToast makeText:NSLocalizedString(@"已切换到后置摄像头", @"")] show];
        self->cameraIsBack = YES;
    }
    
}


#pragma mark - ARDAppClientDelegate

- (void)appClient:(ARDAppClient *)client didChangeState:(ARDAppClientState)state {
    switch (state) {
        case kARDAppClientStateConnected:
            self.statusLabel.text = @"Connected";
            self.statusLabel.textColor = [UIColor greenColor];
            break;
        case kARDAppClientStateConnecting:
            self.statusLabel.text = @"Chatting";
            self.statusLabel.textColor = [UIColor orangeColor];
            break;
        case kARDAppClientStateDisconnected:
            self.statusLabel.text = @"Disconnected";
            self.statusLabel.textColor = [UIColor redColor];
            break;
    }
}

- (void)appClient:(ARDAppClient *)client didReceiveLocalVideoTrack:(RTCVideoTrack *)localVideoTrack
{
    [[iToast makeText:NSLocalizedString(@"开启本机摄像头", @"")] show];
    if (self.localVideoTrack) {
        [self.localVideoTrack removeRenderer:self.localView];
        self.localVideoTrack = nil;
        [self.localView renderFrame:nil];
    }
    self.localVideoTrack = localVideoTrack;
    [self.localVideoTrack addRenderer:self.localView];
    
}

- (void)appClient:(ARDAppClient *)client didReceiveRemoteVideoTrack:(RTCVideoTrack *)remoteVideoTrack
{
    [[iToast makeText:NSLocalizedString(@"获得对方视频流", @"")] show];
    self.remoteVideoTrack = remoteVideoTrack;
    //[remoteVideoTrack retain];
    [self.remoteVideoTrack addRenderer:self.remoteView];
    
    self.yourIdTextField.hidden = YES;
    self.peerIdTextField.hidden = YES;
    self.confirmIdButton.hidden = YES;
    self.makeCallButton.hidden = YES;
    self.changeCameraButton.hidden = NO;
}

- (void)appClient:(ARDAppClient *)client didError:(NSError *)error
{
    
}

#pragma mark - RTCEAGLVideoViewDelegate
- (void)videoView:(RTCEAGLVideoView *)videoView didChangeVideoSize:(CGSize)size
{
    
}

#pragma mark - dismiss keyboard
- (IBAction)backgroundTap:(UITapGestureRecognizer *)sender
{
    [self.yourIdTextField resignFirstResponder];
    [self.peerIdTextField resignFirstResponder];
}
@end

