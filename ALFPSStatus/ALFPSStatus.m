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

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) NSTimeInterval lastTime;
@property (nonatomic, assign) NSUInteger count;
@property (nonatomic, strong) UILabel *fpsLabel;

@property (nonatomic, assign) BOOL isStart;
@property (nonatomic, assign) UIInterfaceOrientation launchOrientation;

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

//- (id)copyWithZone:(struct _NSZone *)zone
//{
//    return self;
//}
//
//- (id)mutableCopyWithZone:(struct _NSZone *)zone
//{
//    return self;
//}

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
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillChangeStatusBarOrientationNotification:) name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];
        
        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkFired:)];
        self.displayLink.paused = YES;
        [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        
        self.fpsLabel = [[UILabel alloc] init];
        self.fpsLabel.frame = CGRectMake(([UIScreen mainScreen].bounds.size.width - 45)/2.0+50, 0, 45, 20);
        self.fpsLabel.font = [UIFont boldSystemFontOfSize:12];
        self.fpsLabel.textColor = [UIColor greenColor];
        self.fpsLabel.textAlignment = NSTextAlignmentRight;
        self.fpsLabel.backgroundColor = [UIColor clearColor];
        
        self.isStart = NO;
        self.launchOrientation = UIInterfaceOrientationUnknown;
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

    if (!self.window) {
        self.window = [[UIWindow alloc] init];
        self.window.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 20);
        self.window.windowLevel = UIWindowLevelStatusBar+1.0;
        self.window.backgroundColor = [UIColor clearColor];
        self.window.tag = 1000;
        self.window.hidden = NO;
        self.window.userInteractionEnabled = NO;
        
        self.fpsLabel.frame = CGRectMake((self.window.frame.size.width - 45)/2.0+50, 0, 45, 20);
    }
    
    [self.window addSubview:self.fpsLabel];
    
    if (self.launchOrientation == UIInterfaceOrientationUnknown) {
        self.launchOrientation = [UIApplication sharedApplication].statusBarOrientation;
    }
    
    if ([[UIDevice currentDevice].systemVersion floatValue] < 9.0) {
        [self.displayLink invalidate];
        self.displayLink = nil;
    }
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
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 9.0) {
        __weak typeof(self) weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf start];
        });
    } else {
        [self start];
    }
}

- (void)applicationWillChangeStatusBarOrientationNotification:(NSNotification *)noti
{
    NSInteger orientation = [noti.userInfo[UIApplicationStatusBarOrientationUserInfoKey] integerValue];
    if (al_isPad()) {
        CGRect frame = self.window.frame;
        frame.size.width = [self screenWidthForOrientation:orientation];
        self.window.frame = frame;
        self.fpsLabel.frame = CGRectMake(([self screenWidthForOrientation:orientation]-55)/2.0+55, 0, 55, 20);
    } else {
        [self transformInterfaceForOrientation:orientation];
    }
}

- (void)transformInterfaceForOrientation:(UIInterfaceOrientation)orientation
{
    if (!self.window) {
        return;
    }
    //此时的window坐标系以设置window时的界面方向为准.
    self.window.bounds = CGRectMake(0, 0, [self screenWidthForOrientation:orientation], 20);
    self.fpsLabel.frame = CGRectMake((self.window.bounds.size.width-55)/2.0+55, 0, 55, 20);
    switch (self.launchOrientation) {
        case UIInterfaceOrientationPortrait:
            [self resetInterfaceForPortraitLanunchWithCurrentOrientation:orientation];
            break;
        case UIInterfaceOrientationLandscapeLeft:
            [self resetInterfaceForLandscapeLeftLaunchWithCurrentOrientation:orientation];
            break;
        case UIInterfaceOrientationLandscapeRight:
            [self resetInterfaceForLandscapeRightLaunchWithCurrentOrientation:orientation];
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            break;
        default:
            NSLog(@"unknown orientation");
            break;
    }
}

- (void)resetInterfaceForPortraitLanunchWithCurrentOrientation:(UIInterfaceOrientation)orientation
{
    CGFloat screenWidth = MIN([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    CGFloat screenHeight = MAX([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    switch (orientation) {
        case UIInterfaceOrientationPortrait:
            self.window.transform = CGAffineTransformIdentity;
            self.window.frame = CGRectMake(0, 0, screenWidth, 20);
            self.window.center = CGPointMake(screenWidth/2.0, 10);
            break;
        case UIInterfaceOrientationLandscapeLeft:
            self.window.transform = CGAffineTransformMakeRotation(RADIANFORANGLE(-90));
            self.window.center = CGPointMake(10, screenHeight/2.0);
            break;
        case UIInterfaceOrientationLandscapeRight:
            self.window.transform = CGAffineTransformMakeRotation(RADIANFORANGLE(90));
            self.window.center = CGPointMake(screenWidth-10, screenHeight/2.0);
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            self.window.transform = CGAffineTransformMakeRotation(RADIANFORANGLE(180));
            self.window.center = CGPointMake(screenWidth/2.0, screenHeight-10);
            break;
        default:
            NSLog(@"unknown orientation");
            break;
    }
}

- (void)resetInterfaceForLandscapeLeftLaunchWithCurrentOrientation:(UIInterfaceOrientation)orientation
{
    CGFloat screenWidth = MIN([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    CGFloat screenHeight = MAX([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    switch (orientation) {
        case UIInterfaceOrientationPortrait:
            self.window.transform = CGAffineTransformMakeRotation(RADIANFORANGLE(90));
            self.window.center = CGPointMake(screenHeight-10, screenWidth/2.0);
            break;
        case UIInterfaceOrientationLandscapeLeft:
            self.window.transform = CGAffineTransformIdentity;
            self.window.center = CGPointMake(screenHeight/2.0, 10);
            break;
        case UIInterfaceOrientationLandscapeRight:
            self.window.transform = CGAffineTransformMakeRotation(RADIANFORANGLE(180));
            self.window.center = CGPointMake(screenHeight/2.0, screenWidth-10);
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            self.window.transform = CGAffineTransformMakeRotation(RADIANFORANGLE(-90));
            self.window.center = CGPointMake(10, screenWidth/2.0);
            break;
        default:
            NSLog(@"unknown orientation");
            break;
    }
}

- (void)resetInterfaceForLandscapeRightLaunchWithCurrentOrientation:(UIInterfaceOrientation)orientation
{
    CGFloat screenWidth = MIN([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    CGFloat screenHeight = MAX([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    switch (orientation) {
        case UIInterfaceOrientationPortrait:
            self.window.transform = CGAffineTransformMakeRotation(RADIANFORANGLE(-90));
            self.window.center = CGPointMake(10, screenWidth/2.0);
            break;
        case UIInterfaceOrientationLandscapeLeft:
            self.window.transform = CGAffineTransformMakeRotation(RADIANFORANGLE(180));
            self.window.center = CGPointMake(screenHeight/2.0, screenWidth-10);
            break;
        case UIInterfaceOrientationLandscapeRight:
            self.window.transform = CGAffineTransformIdentity;
            self.window.center = CGPointMake(screenHeight/2.0, 10);
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            self.window.transform = CGAffineTransformMakeRotation(RADIANFORANGLE(90));
            self.window.center = CGPointMake(screenHeight-10, screenWidth/2.0);
            break;
        default:
            NSLog(@"unknown orientation");
            break;
    }
}

#pragma mark - Private
BOOL al_isPad()
{
    return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
}

- (CGFloat)screenWidthForOrientation:(UIInterfaceOrientation)orientation
{
    CGFloat screenWidth = MIN([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    
    CGFloat screenHeight = MAX([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    CGFloat currentWidth = 0;
    switch (orientation) {
        case UIInterfaceOrientationLandscapeRight:
        case UIInterfaceOrientationLandscapeLeft:
            currentWidth = screenHeight;
            break;
        case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationPortraitUpsideDown:
            currentWidth = screenWidth;
            break;
        default:
            currentWidth = screenWidth;
            break;
    }
    return currentWidth;
}

@end
