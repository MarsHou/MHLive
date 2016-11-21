//
//  MhBroadcastRoomViewController.m
//  MHLive
//
//  Created by Mars on 21/11/2016.
//  Copyright © 2016 Mars. All rights reserved.
//

#import "MhBroadcastRoomViewController.h"
#import <PLCameraStreamingKit/PLCameraStreamingKit.h>

#define kHost @"http://"

@interface MhBroadcastRoomViewController ()
@property (nonatomic, strong) PLCameraStreamingSession *cameraStremaingSession;
@property (nonatomic, strong) NSString *roomID;
@end

@implementation MhBroadcastRoomViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.cameraStremaingSession = [self _generateCameraStreamingSession];
    
    [self requireDevicePermissionWithComplete:^(BOOL granted) {
        if(granted){
            [self.view addSubview:({
                UIView *preview = self.cameraStremaingSession.previewView;
                preview.frame = self.view.bounds;
                preview.autoresizingMask = UIViewAutoresizingFlexibleWidth |
                                           UIViewAutoresizingFlexibleHeight;
                preview;
            })];
        }
    }];
    
    __weak typeof(self) weakSelf = self;
    [self _genaratePushURLWithComlete:^(PLStream *stream) {
        __strong typeof(self) strongSelf = weakSelf;
        if(strongSelf){
            strongSelf.cameraStremaingSession.stream = stream;
            [strongSelf.cameraStremaingSession startWithCompleted:^(BOOL success) {
                if(!success){
                    NSLog(@"推流失败了");
                }
            }];
        }
    }];
}

- (void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.cameraStremaingSession destroy];
    [self _notifyServerExitRoom];
}

- (void)_notifyServerExitRoom
{
    if (self.roomID) {
        NSString *url = [NSString stringWithFormat:@"%@%@%@",kHost,@"api/pilipili/",self.roomID];
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
        request.HTTPMethod = @"DELETE";
        request.timeoutInterval = 10;
        
        [[[NSURLSession sharedSession] dataTaskWithRequest:request] resume];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) requireDevicePermissionWithComplete:(void (^)(BOOL granted))complete
{
    switch ([PLCameraStreamingSession cameraAuthorizationStatus]) {
        case PLAuthorizationStatusAuthorized:
            complete(YES);
            break;
        case PLAuthorizationStatusNotDetermined:{
            [PLCameraStreamingSession requestCameraAccessWithCompletionHandler:^(BOOL granted) {
                complete(granted);
            }];
        }
            break;
        default:
            complete(NO);
            break;
    }
}

- (void)_genaratePushURLWithComlete:(void (^)(PLStream *stream))complete
{
    NSString *url = [NSString stringWithFormat:@"%@%@",kHost,@"/api/pilipili"];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    request.HTTPMethod = @"POST";
    request.timeoutInterval = 10;
    [request setHTTPBody:[@"title=room" dataUsingEncoding:NSUTF8StringEncoding]];
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable responseError) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSError *error = responseError;
            if(error!=nil||response == nil||data==nil){
                NSLog(@"获取推流 url 失败 %@",error);
                return;
            }
            NSDictionary *streamJSON = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&error];
            NSLog(@"streamJSON : %@",streamJSON);
            self.roomID = streamJSON[@"id"];
            PLStream *stream = [PLStream streamWithJSON:streamJSON];
            if(complete){
                complete(stream);
            }
        });
    }];
    [task resume];
}

- (PLCameraStreamingSession *)_generateCameraStreamingSession
{
    PLVideoCaptureConfiguration *videoCaptureConfiguration = [PLVideoCaptureConfiguration defaultConfiguration];
    PLVideoStreamingConfiguration *videoStreamingConfiguration = [PLVideoStreamingConfiguration defaultConfiguration];
    PLAudioCaptureConfiguration *audioCaptureConfiguration = [PLAudioCaptureConfiguration defaultConfiguration];
    PLAudioStreamingConfiguration *audioStreamingConfiguration = [PLAudioStreamingConfiguration defaultConfiguration];
    AVCaptureVideoOrientation captureOrientation = AVCaptureVideoOrientationPortrait;
    PLStream *stream = nil;
    return [[PLCameraStreamingSession alloc] initWithVideoCaptureConfiguration:videoCaptureConfiguration
                                                     audioCaptureConfiguration:audioCaptureConfiguration
                                                   videoStreamingConfiguration:videoStreamingConfiguration
                                                   audioStreamingConfiguration:audioStreamingConfiguration
                                                                        stream:stream
                                                              videoOrientation:captureOrientation];
}

@end
