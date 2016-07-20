//
//  ALFPSStatus.m
//  ALFPSStatusDemo
//
//  Created by arien on 16/7/20.
//  Copyright © 2016年 ArienLau. All rights reserved.
//

#import "ALFPSStatus.h"
#import <UIKit/UIKit.h>

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
        self.fpsLabel.frame = CGRectMake(([UIScreen mainScreen].bounds.size.width - 50)/2.0+50, 0, 50, 20);
        self.fpsLabel.font = [UIFont boldSystemFontOfSize:12];
        self.fpsLabel.textColor = [UIColor colorWithRed:0.33 green:0.84 blue:0.43 alpha:1];
        self.fpsLabel.textAlignment = NSTextAlignmentRight;
        self.fpsLabel.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)displayLinkFired:(CADisplayLink *)link
{
    if (self.lastTime == 0) {
        self.lastTime = link.timestamp;
        return;
    }
    self.count++;
    NSTimeInterval interval = link.timestamp - self.lastTime;
    if (interval < 1) {
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
    NSLog(@"ALFPSStatus在模拟器下的数据是没有意义的");
    return;
#endif
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
    [self start];
}

@end
