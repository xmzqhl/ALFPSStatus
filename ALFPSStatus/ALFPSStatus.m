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

#define RADIANFORANGLE(x) ((x) * M_PI/180)

@interface ALFPSStatus ()

@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) NSTimeInterval lastTime;
@property (nonatomic, assign) NSUInteger count;
@property (nonatomic, strong) UILabel *fpsLabel;

@property (nonatomic, assign) BOOL isStart;

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
        
        self.isStart = NO;
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
    if (interval < 1.0) {
        return;
    }
    self.lastTime = link.timestamp;
    NSTimeInterval fps = self.count/interval;
    NSInteger fpsInteger = (NSInteger)round(fps);
    self.fpsLabel.text = [NSString stringWithFormat:@"%@ FPS", @(fpsInteger)];
    if (fpsInteger >= 45) {
        self.fpsLabel.textColor = [UIColor greenColor];
    } else if (fpsInteger >= 30) {
        self.fpsLabel.textColor = [UIColor colorWithRed:255/255.0 green:215/255.0 blue:0/255.0 alpha:1];
    } else {
        self.fpsLabel.textColor = [UIColor redColor];
    }
    self.count = 0;
}

- (void)start
{
#if TARGET_OS_SIMULATOR
    NSLog(@"ALFPSStatus has been stoped.Because it would make no sense for the simulator device.");
    return;
#endif
    
#if !DEBUG
    NSLog(@"Just use ALFPSStatus in the DEBUG mode.Don't use it for the Relese mode.");
    return;
#endif
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunreachable-code"
    if (self.isStart) {
        return;
    }

    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    if (!self.fpsLabel) {
        self.fpsLabel = [[UILabel alloc] init];
        self.fpsLabel.font = [UIFont boldSystemFontOfSize:12];
        self.fpsLabel.textColor = [UIColor greenColor];
        self.fpsLabel.textAlignment = NSTextAlignmentCenter;
        self.fpsLabel.backgroundColor = [UIColor clearColor];
        self.fpsLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    }
    
    self.fpsLabel.frame = CGRectMake(0, 15, keyWindow.frame.size.width, 12);
    [keyWindow addSubview:self.fpsLabel];
    
    if (!self.displayLink) {
        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkFired:)];
        [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    }
    self.displayLink.paused = NO;
    
    self.isStart = YES;
#pragma clang diagnostic pop
}

- (void)end
{
    if (self.isStart) {
        [self.displayLink invalidate];
        self.displayLink = nil;
        
        [self.fpsLabel removeFromSuperview];
        
        self.isStart = NO;
        self.lastTime = 0;
        self.count = 0;
    }
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
        self.lastTime = 0;
        self.count = 0;
    }
}

- (void)applicationDidFinishLaunchingNotification
{
    [self start];
}

@end
