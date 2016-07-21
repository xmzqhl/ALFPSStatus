//
//  ALFPSStatus.m
//  ALFPSStatusDemo
//
//  Created by arien on 16/7/20.
//  Copyright © 2016年 ArienLau. All rights reserved.
//

#import "ALFPSStatus.h"
#import <UIKit/UIKit.h>

#if !__has_feature(objc_arc)
    #error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

@interface ALFPSStatus ()

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) NSTimeInterval lastTime;
@property (nonatomic, assign) NSUInteger count;
@property (nonatomic, strong) UILabel *fpsLabel;

@end

@implementation ALFPSStatus

static ALFPSStatus *shareInstance = nil;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.displayLink.paused = YES;
    [self.displayLink removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [self.displayLink invalidate];
}

+ (void)load
{
    @autoreleasepool {
        [self shareInstance];
    }
}

+ (ALFPSStatus *)shareInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareInstance = [[ALFPSStatus alloc] init];
    });
    return shareInstance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareInstance = [super allocWithZone:zone];
    });
    return shareInstance;
}

- (instancetype)copy
{
    return self;
}

- (instancetype)mutableCopy
{
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActiveNotification) name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActiveNotification) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidFinishLaunchingNotification) name:UIApplicationDidFinishLaunchingNotification object:nil];
        
        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkFired:)];
        self.displayLink.paused = YES;
        [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        
        self.fpsLabel = [[UILabel alloc] init];
        CGFloat screenWidth = CGRectGetWidth([UIScreen mainScreen].bounds);
        self.fpsLabel.frame = CGRectMake((screenWidth - 55)/2.0+55, 0, 55, 20);
        self.fpsLabel.font = [UIFont boldSystemFontOfSize:12];
        self.fpsLabel.textColor = [UIColor magentaColor];
        self.fpsLabel.textAlignment = NSTextAlignmentRight;
        self.fpsLabel.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)displayLinkFired:(CADisplayLink *)link
{
    self.count++;
    if (self.lastTime == 0) {
        self.lastTime = link.timestamp;
        return;
    }
    NSTimeInterval interval = link.timestamp - self.lastTime;
    if (interval < 1.0) {
        return;
    }
    self.lastTime = link.timestamp;
    NSTimeInterval fps = self.count/interval;
    self.fpsLabel.text = [NSString stringWithFormat:@"%d FPS", (int)round(fps)];
    self.count = 0;
}

- (void)start
{
#if TARGET_OS_SIMULATOR
    NSLog(@"ALFPSStatus has been stoped.Because it would make no sense for the simulator device.");
    return;
#else
    if (self.window) {
        return;
    }
    self.window = [[UIWindow alloc] init];
    self.window.frame = [UIApplication sharedApplication].statusBarFrame;
    self.window.windowLevel = UIWindowLevelStatusBar+1.0;
    self.window.backgroundColor = [UIColor clearColor];
    self.window.tag = 1000;
    self.window.hidden = NO;
    
    [self.window addSubview:self.fpsLabel];
    
    if (!self.displayLink) {
        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkFired:)];
        [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    }
    self.displayLink.paused = NO;
#endif
}

- (void)end
{
    [self.displayLink invalidate];
    self.displayLink = nil;
    
    [self.fpsLabel removeFromSuperview];
    self.window = nil;
}

#pragma mark - Notifications
- (void)applicationDidBecomeActiveNotification
{
    if (self.displayLink) {
        self.displayLink.paused = NO;
    }
}

- (void)applicationWillResignActiveNotification
{
    if (self.displayLink) {
        self.displayLink.paused = YES;
    }
}

- (void)applicationDidFinishLaunchingNotification
{
    if ([[UIDevice currentDevice].systemVersion floatValue] > 9.0) {
        __weak typeof(self) weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf start];
        });
    } else {
        [self start];
    }
}

@end
